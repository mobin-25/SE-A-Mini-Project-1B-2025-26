import 'package:flutter/material.dart';
import '../models/medicine.dart';
import '../services/search_service.dart';
import '../services/supabase_service.dart';
import '../services/medicine_fetch_service.dart';
import 'medicine_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchCtrl = TextEditingController();
  final _searchService = SearchService();
  final _supa = SupabaseService.instance;
  final _fetchService = MedicineFetchService();

  List<Medicine> _results = [];
  List<Map<String, dynamic>> _recentSearches = [];
  bool _loading = false;
  bool _hasSearched = false;
  bool _fetchingFromWeb = false;
  Map<String, dynamic>? _webFetchResult;

  @override
  void initState() {
    super.initState();
    _loadPopular();
  }

  Future<void> _loadPopular() async {
    // Load all medicines to show as browse tiles
    final all = await _supa.getAllMedicines();
    setState(() => _recentSearches = all);
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() { _results = []; _hasSearched = false; _webFetchResult = null; });
      return;
    }
    setState(() { _loading = true; _hasSearched = true; _webFetchResult = null; _fetchingFromWeb = false; });
    final results = await _searchService.fuzzySearch(query);
    if (results.isEmpty && query.trim().length >= 3) {
      // Fallback: try fetching from OpenFDA
      setState(() { _loading = false; _fetchingFromWeb = true; });
      final fetched = await _fetchService.fetchAndSave(query.trim());
      setState(() { _fetchingFromWeb = false; _webFetchResult = fetched; });
      if (fetched != null) {
        // Re-search now that it's in the DB
        final retry = await _searchService.fuzzySearch(query);
        setState(() { _results = retry; });
      }
    } else {
      setState(() { _results = results; _loading = false; });
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'tablet': return Icons.medication;
      case 'capsule': return Icons.medication_liquid;
      case 'syrup': return Icons.liquor;
      case 'gel': return Icons.water_drop;
      case 'injection': return Icons.vaccines;
      default: return Icons.medication;
    }
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'tablet': return Colors.blue;
      case 'capsule': return Colors.purple;
      case 'syrup': return Colors.orange;
      case 'gel': return Colors.teal;
      case 'injection': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            expandedHeight: 160,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [colorScheme.primary, colorScheme.primary.withOpacity(0.8)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 70),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text('Medly', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                        Text('Search medicines, compositions, or symptoms', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(64),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(14),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => _search(v),
                    style: const TextStyle(color: Colors.black), // Force black text
                    decoration: InputDecoration(
                      hintText: 'Search medicines, eg. Paracetamol...',
                      hintStyle: const TextStyle(color: Colors.black54), // Force dark hint
                      prefixIcon: const Icon(Icons.search, color: Colors.black54),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.black54),
                              onPressed: () {
                                _searchCtrl.clear();
                                _search('');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
            ),
          ),

          if (_loading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_fetchingFromWeb)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    const Text('Not found locally — searching web...', style: TextStyle(fontSize: 14)),
                    Text('Fetching "${_searchCtrl.text}" from OpenFDA', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
            )
          else if (_hasSearched) ...[
            if (_results.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text('No results for "${_searchCtrl.text}"', style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 8),
                      Text(
                        _webFetchResult == null
                            ? 'Not found in our database or online'
                            : 'Found online but could not save — check connection',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              if (_webFetchResult != null)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.cloud_download, color: Colors.green.shade700, size: 18),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Fetched from OpenFDA and saved to database',
                            style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _medicineListTile(_results[i], colorScheme),
                  childCount: _results.length,
                ),
              ),
            ],
          ] else ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                child: Text('All Medicines', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: colorScheme.onBackground)),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) {
                  final m = _recentSearches[i];
                  return _medicineListTileMap(m, colorScheme);
                },
                childCount: _recentSearches.length,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _medicineListTile(Medicine med, ColorScheme cs) {
    final typeColor = _getTypeColor(med.type);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: Colors.grey.shade200)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: typeColor.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
          child: Icon(_getTypeIcon(med.type), color: typeColor, size: 22),
        ),
        title: Text(med.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(med.composition, style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(med.type, style: TextStyle(color: typeColor, fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => MedicineDetailScreen(medicineId: med.id!, medicineName: med.name),
        )),
      ),
    );
  }

  Widget _medicineListTileMap(Map<String, dynamic> m, ColorScheme cs) {
    final type = m['type'] as String? ?? m['form'] as String? ?? '';
    final typeColor = _getTypeColor(type);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: Colors.grey.shade200)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: typeColor.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
          child: Icon(_getTypeIcon(type), color: typeColor, size: 22),
        ),
        title: Text(m['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(m['composition'] as String? ?? '', style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Row(
              children: [
                if (type.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: typeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text(type, style: TextStyle(color: typeColor, fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                if (m['category'] != null) ...[
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(m['category'] as String, style: const TextStyle(color: Colors.grey, fontSize: 11), overflow: TextOverflow.ellipsis),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => MedicineDetailScreen(
            medicineId: m['medicine_id'] as int,
            medicineName: m['name'] as String,
          ),
        )),
      ),
    );
  }
}
