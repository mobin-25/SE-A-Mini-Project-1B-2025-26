import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class MedicineDetailScreen extends StatefulWidget {
  final int medicineId;
  final String medicineName;

  const MedicineDetailScreen({
    super.key,
    required this.medicineId,
    required this.medicineName,
  });

  @override
  State<MedicineDetailScreen> createState() => _MedicineDetailScreenState();
}

class _MedicineDetailScreenState extends State<MedicineDetailScreen> {
  final _supa = SupabaseService.instance;
  Map<String, dynamic>? _medicine;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await _supa.getMedicineDetail(widget.medicineId);
    setState(() {
      _medicine = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceVariant.withOpacity(0.3),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _medicine == null
              ? Center(child: Text('Medicine not found'))
              : CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      expandedHeight: 180,
                      pinned: true,
                      flexibleSpace: FlexibleSpaceBar(
                        title: Text(
                          _medicine!['name'] as String,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        background: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                colorScheme.primary,
                                colorScheme.primary.withOpacity(0.7),
                              ],
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              _getTypeIcon(_medicine!['form'] as String? ?? _medicine!['type'] as String? ?? ''),
                              size: 64,
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Badges
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                if (_medicine!['category'] != null)
                                  _badge(_medicine!['category']!, colorScheme.primaryContainer, colorScheme.onPrimaryContainer),
                                if (_medicine!['requires_prescription'] == true)
                                  _badge('Rx Required', Colors.red.shade100, Colors.red.shade800),
                                if (_medicine!['form'] != null)
                                  _badge(_medicine!['form']!, colorScheme.secondaryContainer, colorScheme.onSecondaryContainer),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Generic name & brands
                            if (_medicine!['generic_name'] != null) ...[
                              _sectionCard(
                                icon: Icons.science,
                                title: 'Generic Name',
                                content: _medicine!['generic_name']!,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(height: 12),
                            ],

                            if (_medicine!['brand_names'] != null && (_medicine!['brand_names'] as List).isNotEmpty) ...[
                              _listCard(
                                icon: Icons.label,
                                title: 'Also Known As',
                                items: List<String>.from(_medicine!['brand_names'] as List),
                                color: Colors.purple,
                              ),
                              const SizedBox(height: 12),
                            ],

                            // Description
                            if (_medicine!['description'] != null) ...[
                              _sectionCard(
                                icon: Icons.info_outline,
                                title: 'About This Medicine',
                                content: _medicine!['description']!,
                                color: Colors.blue,
                              ),
                              const SizedBox(height: 12),
                            ],

                            // Dosage info
                            if (_medicine!['dosage_info'] != null) ...[
                              _sectionCard(
                                icon: Icons.medication,
                                title: 'Dosage',
                                content: _medicine!['dosage_info']!,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(height: 12),
                            ],

                            // When to use
                            if (_medicine!['when_to_use'] != null) ...[
                              _sectionCard(
                                icon: Icons.schedule,
                                title: 'When to Use',
                                content: _medicine!['when_to_use']!,
                                color: Colors.green,
                              ),
                              const SizedBox(height: 12),
                            ],

                            // How to use
                            if (_medicine!['how_to_use'] != null) ...[
                              _sectionCard(
                                icon: Icons.how_to_reg,
                                title: 'How to Take',
                                content: _medicine!['how_to_use']!,
                                color: Colors.teal,
                              ),
                              const SizedBox(height: 12),
                            ],

                            // Side effects
                            if (_medicine!['side_effects'] != null && (_medicine!['side_effects'] as List).isNotEmpty) ...[
                              _listCard(
                                icon: Icons.warning_amber,
                                title: 'Possible Side Effects',
                                items: List<String>.from(_medicine!['side_effects'] as List),
                                color: Colors.orange,
                                isWarning: false,
                              ),
                              const SizedBox(height: 12),
                            ],

                            // Warnings
                            if (_medicine!['warnings'] != null && (_medicine!['warnings'] as List).isNotEmpty) ...[
                              _listCard(
                                icon: Icons.dangerous,
                                title: 'Warnings & Precautions',
                                items: List<String>.from(_medicine!['warnings'] as List),
                                color: Colors.red,
                                isWarning: true,
                              ),
                              const SizedBox(height: 12),
                            ],

                            // Storage
                            if (_medicine!['storage_instructions'] != null) ...[
                              _sectionCard(
                                icon: Icons.inventory_2,
                                title: 'Storage',
                                content: _medicine!['storage_instructions']!,
                                color: Colors.brown,
                              ),
                              const SizedBox(height: 12),
                            ],

                            // Alternate medicines
                            if (_medicine!['alternates'] != null && (_medicine!['alternates'] as List).isNotEmpty) ...[
                              _alternatesCard(_medicine!['alternates'] as List),
                              const SizedBox(height: 12),
                            ],

                            const SizedBox(height: 80),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addReminder(context),
        icon: const Icon(Icons.alarm_add),
        label: const Text('Set Reminder'),
      ),
    );
  }

  Widget _badge(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 10),
            Text(content, style: const TextStyle(fontSize: 15, height: 1.5)),
          ],
        ),
      ),
    );
  }

  Widget _listCard({
    required IconData icon,
    required String title,
    required List<String> items,
    required Color color,
    bool isWarning = false,
  }) {
    return Card(
      elevation: 0,
      color: isWarning ? Colors.red.shade50 : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 10),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    isWarning ? Icons.warning_amber_rounded : Icons.circle,
                    color: color,
                    size: isWarning ? 16 : 6,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: isWarning ? Colors.red.shade900 : null,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _alternatesCard(List alternates) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.indigo.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.swap_horiz, color: Colors.indigo, size: 20),
                SizedBox(width: 8),
                Text('Alternate Medicines', style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 10),
            ...alternates.map((alt) {
              final med = alt['medicines'] as Map<String, dynamic>?;
              if (med == null) return const SizedBox();
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(_getTypeIcon(med['type'] as String? ?? ''), color: Colors.indigo),
                title: Text(med['name'] as String, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(alt['reason'] as String? ?? ''),
                dense: true,
              );
            }),
          ],
        ),
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'tablet': return Icons.medication;
      case 'capsule': return Icons.medication_liquid;
      case 'syrup': return Icons.liquor;
      case 'gel': return Icons.water_drop;
      case 'injection': return Icons.vaccines;
      case 'drops': return Icons.opacity;
      default: return Icons.medication;
    }
  }

  Future<void> _addReminder(BuildContext context) async {
    TimeOfDay selectedTime = TimeOfDay.now();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Text('Set Reminder for ${_medicine!['name']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 24),
              ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
                title: Text('Time: ${selectedTime.format(ctx)}'),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final t = await showTimePicker(context: ctx, initialTime: selectedTime);
                  if (t != null) setS(() => selectedTime = t);
                },
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () async {
                  final timeStr = '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
                  await SupabaseService.instance.addSchedule(
                    medicineId: widget.medicineId,
                    medicineName: _medicine!['name'],
                    time: timeStr,
                  );
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Reminder set for ${_medicine!['name']} at $timeStr'), backgroundColor: Colors.green),
                    );
                  }
                },
                child: const Text('Set Reminder'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
