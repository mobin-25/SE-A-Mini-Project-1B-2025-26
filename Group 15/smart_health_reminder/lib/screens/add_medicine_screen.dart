/// Add / Edit Medicine — glassmorphic form fields, gradient save button,
/// accent-colored time chips, nebula background.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/providers.dart';
import '../models/models.dart';
import '../widgets/nebula_background.dart';
import '../widgets/glass_card.dart';

class AddMedicineScreen extends ConsumerStatefulWidget {
  final Medicine? editMedicine;
  const AddMedicineScreen({super.key, this.editMedicine});

  @override
  ConsumerState<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends ConsumerState<AddMedicineScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _dosageCtrl;
  late final TextEditingController _notesCtrl;
  String _form = 'Tablet';
  String _freq = 'Once a day';
  bool _withFood = true;
  List<String> _times = ['08:00 AM', '08:00 PM'];

  static const _forms = ['Tablet', 'Capsule', 'Syrup', 'Injection', 'Other'];
  static const _freqs = [
    'Once a day',
    'Twice a day',
    'Three times a day',
    'Every 6 hours',
    'Custom',
  ];

  @override
  void initState() {
    super.initState();
    final m = widget.editMedicine;
    _nameCtrl = TextEditingController(text: m?.name ?? '');
    _dosageCtrl = TextEditingController(text: m?.dosage ?? '');
    _notesCtrl = TextEditingController(text: m?.notes ?? '');
    if (m != null) {
      _form = m.form;
      _freq = m.frequency;
      _withFood = m.withFood;
      _times = List.from(m.reminderTimes);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _dosageCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (t != null) {
      final p = t.period == DayPeriod.am ? 'AM' : 'PM';
      final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
      final formatted =
          '${h.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')} $p';
      if (!_times.contains(formatted)) setState(() => _times.add(formatted));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final med = Medicine(
      id: widget.editMedicine?.id,
      name: _nameCtrl.text.trim(),
      dosage: _dosageCtrl.text.trim(),
      form: _form,
      reminderTimes: _times,
      frequency: _freq,
      withFood: _withFood,
      notes: _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
      isReminderOn: true,
      takenTimes: widget.editMedicine?.takenTimes ?? [],
      isCompleted: widget.editMedicine?.isCompleted ?? false,
    );
    if (widget.editMedicine != null) {
      await ref.read(medicinesProvider.notifier).update(med);
    } else {
      await ref.read(medicinesProvider.notifier).add(med);
    }
    if (mounted) Navigator.pop(context);
  }

  Widget _sectionLabel(String t, {Color color = AppTheme.electricBlue}) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
            boxShadow: AppTheme.glow(color, blur: 5),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          t,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 13,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return NebulaBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            widget.editMedicine != null ? 'Edit Medicine' : 'Add Medicine',
          ),
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                _sectionLabel('Medicine Name'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(
                    hintText: 'e.g. Paracetamol',
                    suffixIcon: Icon(
                      Icons.medication_rounded,
                      color: AppTheme.textSecondary.withValues(alpha: 0.5),
                    ),
                  ),
                  validator:
                      (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 20),

                // Dosage
                _sectionLabel('Dosage', color: AppTheme.neonGreen),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _dosageCtrl,
                  decoration: InputDecoration(
                    hintText: 'e.g. 500 mg',
                    suffixIcon: Icon(
                      Icons.straighten_rounded,
                      color: AppTheme.textSecondary.withValues(alpha: 0.5),
                    ),
                  ),
                  validator:
                      (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 20),

                // Form & Frequency dropdowns in glass cards
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionLabel('Form', color: AppTheme.vividOrange),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: const Color(0x28FFFFFF),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppTheme.glassBorder),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _form,
                                isExpanded: true,
                                dropdownColor: AppTheme.bgSecondary,
                                items:
                                    _forms
                                        .map(
                                          (f) => DropdownMenuItem(
                                            value: f,
                                            child: Text(f),
                                          ),
                                        )
                                        .toList(),
                                onChanged: (v) => setState(() => _form = v!),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionLabel(
                            'Frequency',
                            color: AppTheme.radiantPink,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: const Color(0x28FFFFFF),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppTheme.glassBorder),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _freq,
                                isExpanded: true,
                                dropdownColor: AppTheme.bgSecondary,
                                items:
                                    _freqs
                                        .map(
                                          (f) => DropdownMenuItem(
                                            value: f,
                                            child: Text(
                                              f,
                                              style: const TextStyle(
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                onChanged: (v) => setState(() => _freq = v!),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                // Reminder Times
                Row(
                  children: [
                    _sectionLabel('Reminder Times'),
                    const Spacer(),
                    GestureDetector(
                      onTap: _pickTime,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: AppTheme.accentGradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: AppTheme.glow(
                            AppTheme.electricBlue,
                            blur: 8,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.add_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Add',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    ..._times.asMap().entries.map((e) {
                      final idx = e.key;
                      final t = e.value;
                      final colors = [
                        AppTheme.electricBlue,
                        AppTheme.neonGreen,
                        AppTheme.vividOrange,
                        AppTheme.radiantPink,
                      ];
                      final c = colors[idx % colors.length];
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [c, c.withValues(alpha: 0.7)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: AppTheme.glow(c, blur: 8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              t,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () => setState(() => _times.remove(t)),
                              child: const Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    GestureDetector(
                      onTap: _pickTime,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.glassWhite,
                          border: Border.all(color: AppTheme.glassBorder),
                        ),
                        child: const Icon(
                          Icons.access_time_rounded,
                          color: AppTheme.electricBlue,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Take with food glass card
                GlassCard(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.neonGreen.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.restaurant_rounded,
                          color: AppTheme.neonGreen,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Take with food?',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Better absorption with meals',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _withFood,
                        onChanged: (v) => setState(() => _withFood = v),
                        activeTrackColor: AppTheme.neonGreen,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Notes
                _sectionLabel(
                  'Additional Notes',
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _notesCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Do not take with caffeine...',
                  ),
                ),
                const SizedBox(height: 32),

                // Save button
                SizedBox(
                  width: double.infinity,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: AppTheme.accentGradient,
                      boxShadow: AppTheme.glow(AppTheme.electricBlue, blur: 16),
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.save_rounded, size: 20),
                      label: Text(
                        widget.editMedicine != null
                            ? 'Update Medicine'
                            : 'Save Medicine',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
