import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class SymptomScreen extends StatefulWidget {
  const SymptomScreen({super.key});
  @override
  State<SymptomScreen> createState() => _SymptomScreenState();
}

class _SymptomScreenState extends State<SymptomScreen> {
  final _supa = SupabaseService.instance;
  List<Map<String, dynamic>> _symptoms = [];
  final Set<int> _selected = {};
  List<Map<String, dynamic>> _recommendations = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadSymptoms();
  }

  Future<void> _loadSymptoms() async {
    final rows = await _supa.getAllSymptoms();
    setState(() => _symptoms = rows);
  }

  Future<void> _getRecommendations() async {
    if (_selected.isEmpty) return;
    setState(() => _loading = true);
    final results = await _supa.getRecommendations(_selected.toList());
    setState(() { _recommendations = results; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Symptom Checker')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Select your symptoms:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _symptoms.map((s) {
                final id = s['symptom_id'] as int;
                return FilterChip(
                  label: Text(s['name'] as String),
                  selected: _selected.contains(id),
                  onSelected: (val) => setState(() {
                    if (val) _selected.add(id); else _selected.remove(id);
                  }),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FilledButton.icon(
              onPressed: _selected.isNotEmpty ? _getRecommendations : null,
              icon: _loading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.recommend),
              label: const Text('Get Recommendations'),
            ),
          ),
          const Divider(height: 32),
          Expanded(
            child: _recommendations.isEmpty
                ? const Center(child: Text('Select symptoms and tap Recommend'))
                : ListView.builder(
                    itemCount: _recommendations.length,
                    itemBuilder: (_, i) {
                      final rec = _recommendations[i];
                      final medicines = rec['medicines'] as List;
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: ExpansionTile(
                          title: Text(rec['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Match score: ${(rec['score'] as double).toStringAsFixed(1)}'),
                          children: medicines.map((m) => ListTile(
                            leading: const Icon(Icons.medication),
                            title: Text(m['name'] as String),
                            subtitle: Text(m['dosage_info'] as String? ?? ''),
                          )).toList(),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}