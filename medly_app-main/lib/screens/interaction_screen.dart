// lib/screens/interaction_screen.dart
// Fixed: No more bottom overflow — chips are scrollable

import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class InteractionScreen extends StatefulWidget {
  const InteractionScreen({super.key});
  @override
  State<InteractionScreen> createState() => _InteractionScreenState();
}

class _InteractionScreenState extends State<InteractionScreen> {
  final _supa = SupabaseService.instance;
  List<Map<String, dynamic>> _medicines = [];
  final Set<int> _selected = {};
  List<Map<String, dynamic>> _results = [];
  bool _loading = false;
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    _supa.getAllMedicines().then((rows) => setState(() => _medicines = rows));
  }

  Future<void> _check() async {
    if (_selected.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least 2 medicines')),
      );
      return;
    }
    setState(() => _loading = true);
    final results = await _supa.checkInteractions(_selected.toList());
    setState(() {
      _results = results;
      _loading = false;
      _checked = true;
    });
  }

  void _clearAll() {
    setState(() {
      _selected.clear();
      _results.clear();
      _checked = false;
    });
  }

  Color _severityColor(String severity) {
    switch (severity) {
      case 'high':   return Colors.red;
      case 'medium': return Colors.orange;
      case 'low':    return Colors.yellow.shade800;
      default:       return Colors.green;
    }
  }

  IconData _severityIcon(String severity) {
    switch (severity) {
      case 'high':   return Icons.dangerous;
      case 'medium': return Icons.warning;
      case 'low':    return Icons.info;
      default:       return Icons.check_circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Drug Interaction Checker'),
        actions: [
          if (_selected.isNotEmpty)
            TextButton(
              onPressed: _clearAll,
              child: Text('Clear all', style: TextStyle(color: cs.onPrimary)),
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Select medicines to check:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                if (_selected.isNotEmpty)
                  Chip(
                    label: Text('${_selected.length} selected'),
                    backgroundColor: cs.primaryContainer,
                    labelStyle: TextStyle(color: cs.onPrimaryContainer, fontWeight: FontWeight.w600),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
              ],
            ),
          ),

          // ── Medicine chips (fixed height scrollable area) ─
          SizedBox(
            height: 160,
            child: _medicines.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: _medicines.map((m) {
                        final id = m['medicine_id'] as int;
                        return FilterChip(
                          label: Text(m['name'] as String),
                          selected: _selected.contains(id),
                          selectedColor: cs.primaryContainer,
                          checkmarkColor: cs.onPrimaryContainer,
                          onSelected: (val) => setState(() {
                            if (val) _selected.add(id);
                            else _selected.remove(id);
                          }),
                        );
                      }).toList(),
                    ),
                  ),
          ),

          // ── Check button ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _loading ? null : _check,
                icon: _loading
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.search),
                label: Text(_loading ? 'Checking...' : 'Check Interactions'),
              ),
            ),
          ),

          const SizedBox(height: 12),
          const Divider(height: 1),

          // ── Results ───────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : !_checked
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.medication_liquid, size: 56, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text(
                              'Select 2+ medicines above\nand tap Check Interactions',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : _results.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_outline, size: 56, color: Colors.green.shade300),
                                const SizedBox(height: 12),
                                const Text('No known interactions found', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                Text('These medicines appear safe together', style: TextStyle(color: Colors.grey.shade500)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            itemCount: _results.length,
                            itemBuilder: (_, i) {
                              final r = _results[i];
                              final sev = r['severity'] as String;
                              final color = _severityColor(sev);
                              return Card(
                                elevation: 0,
                                margin: const EdgeInsets.only(bottom: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(color: color.withOpacity(0.3), width: 1.5),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(_severityIcon(sev), color: color, size: 20),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              '${r['medicine1']} + ${r['medicine2']}',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: color.withOpacity(0.12),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Text(sev.toUpperCase(),
                                              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
                                          ),
                                        ],
                                      ),
                                      if ((r['description'] as String).isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Text(r['description'] as String, style: const TextStyle(fontSize: 13)),
                                      ],
                                      if ((r['advice'] as String? ?? '').isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Icon(Icons.lightbulb_outline, size: 14, color: Colors.grey),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(r['advice'] as String,
                                                style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
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
