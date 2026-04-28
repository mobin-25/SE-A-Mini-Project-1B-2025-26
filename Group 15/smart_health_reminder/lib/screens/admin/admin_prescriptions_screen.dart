import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';
import '../../providers/admin_providers.dart';
import '../../services/firestore_service.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/nebula_background.dart';
import '../../widgets/accent_bar.dart';
import '../../widgets/gradient_button.dart';

class AdminPrescriptionsScreen extends ConsumerStatefulWidget {
  const AdminPrescriptionsScreen({super.key});
  @override
  ConsumerState<AdminPrescriptionsScreen> createState() =>
      _AdminPrescriptionsScreenState();
}

class _AdminPrescriptionsScreenState
    extends ConsumerState<AdminPrescriptionsScreen> {
  @override
  void initState() {
    super.initState();
    ref.read(prescriptionsProvider.notifier).loadFromFirestore();
  }

  @override
  Widget build(BuildContext context) {
    final prescriptions = ref.watch(prescriptionsProvider);

    return NebulaBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: FloatingActionButton(
          backgroundColor: AppTheme.electricBlue,
          child: const Icon(Icons.add_rounded),
          onPressed: () => _openEditor(context, ref),
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: const [
                    Icon(
                      Icons.receipt_long_rounded,
                      color: AppTheme.vividOrange,
                      size: 28,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Prescriptions',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child:
                    prescriptions.isEmpty
                        ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.receipt_long_outlined,
                                color: AppTheme.textSecondary.withValues(
                                  alpha: 0.5,
                                ),
                                size: 64,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'No prescriptions yet',
                                style: TextStyle(color: AppTheme.textSecondary),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Tap + to create one',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        )
                        : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: prescriptions.length,
                          itemBuilder:
                              (_, i) => _PrescriptionCard(
                                prescription: prescriptions[i],
                                onTap:
                                    () => _openEditor(
                                      context,
                                      ref,
                                      prescriptions[i],
                                    ),
                              ),
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openEditor(
    BuildContext context,
    WidgetRef ref, [
    Prescription? existing,
  ]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _PrescriptionEditorScreen(existing: existing),
      ),
    );
  }
}

class _PrescriptionCard extends StatelessWidget {
  final Prescription prescription;
  final VoidCallback onTap;
  const _PrescriptionCard({required this.prescription, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            AccentBar(color: AppTheme.vividOrange, height: 48),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prescription.patientName,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    prescription.diagnosis ?? '',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${prescription.medicines.length} medication(s)',
                    style: const TextStyle(
                      color: AppTheme.vividOrange,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              DateFormat('MMM dd').format(prescription.createdAt),
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrescriptionEditorScreen extends ConsumerStatefulWidget {
  final Prescription? existing;
  const _PrescriptionEditorScreen({this.existing});
  @override
  ConsumerState<_PrescriptionEditorScreen> createState() =>
      _PrescriptionEditorScreenState();
}

class _PrescriptionEditorScreenState
    extends ConsumerState<_PrescriptionEditorScreen> {
  late TextEditingController _patientNameCtrl;
  late TextEditingController _patientIdCtrl;
  late TextEditingController _diagnosisCtrl;
  late TextEditingController _notesCtrl;
  List<PrescriptionItem> _meds = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _patientNameCtrl = TextEditingController(text: e?.patientName ?? '');
    _patientIdCtrl = TextEditingController(text: e?.patientId ?? '');
    _diagnosisCtrl = TextEditingController(text: e?.diagnosis ?? '');
    _notesCtrl = TextEditingController(text: e?.notes ?? '');
    _meds = List.from(e?.medicines ?? []);
  }

  @override
  void dispose() {
    _patientNameCtrl.dispose();
    _patientIdCtrl.dispose();
    _diagnosisCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return NebulaBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(isEdit ? 'Edit Prescription' : 'New Prescription'),
          actions: [
            if (isEdit)
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: AppTheme.radiantPink,
                ),
                onPressed: _delete,
              ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _field('Patient Name', _patientNameCtrl),
              _field('Patient ID', _patientIdCtrl),
              _field('Diagnosis', _diagnosisCtrl),
              _field('Notes (optional)', _notesCtrl, maxLines: 3),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Medications',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.add_circle_outline,
                      color: AppTheme.neonGreen,
                    ),
                    onPressed: _addMed,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ..._meds.asMap().entries.map((entry) {
                final idx = entry.key;
                final item = entry.value;
                return GlassCard(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      AccentBar(color: AppTheme.neonGreen, height: 40),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${item.dosage} • ${item.frequency} • ${item.duration}',
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: AppTheme.textSecondary,
                          size: 18,
                        ),
                        onPressed: () => _editMed(idx),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: AppTheme.radiantPink,
                          size: 18,
                        ),
                        onPressed: () => setState(() => _meds.removeAt(idx)),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: GradientButton(
                  onPressed: _saving ? () {} : _save,
                  label:
                      _saving
                          ? 'Saving...'
                          : isEdit
                          ? 'Update Prescription'
                          : 'Create Prescription',
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        style: const TextStyle(color: AppTheme.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppTheme.textSecondary),
        ),
      ),
    );
  }

  void _addMed() async {
    final item = await _showMedDialog();
    if (item != null) setState(() => _meds.add(item));
  }

  void _editMed(int index) async {
    final item = await _showMedDialog(existing: _meds[index]);
    if (item != null) setState(() => _meds[index] = item);
  }

  Future<PrescriptionItem?> _showMedDialog({PrescriptionItem? existing}) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final dosageCtrl = TextEditingController(text: existing?.dosage ?? '');
    final freqCtrl = TextEditingController(text: existing?.frequency ?? '');
    final durationCtrl = TextEditingController(text: existing?.duration ?? '');
    final instrCtrl = TextEditingController(text: existing?.instructions ?? '');

    return showDialog<PrescriptionItem>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: AppTheme.bgSecondary,
            title: Text(
              existing != null ? 'Edit Medication' : 'Add Medication',
              style: const TextStyle(color: AppTheme.textPrimary),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _dialogField('Medicine Name', nameCtrl),
                  _dialogField('Dosage (e.g. 500mg)', dosageCtrl),
                  _dialogField('Frequency (e.g. 2x daily)', freqCtrl),
                  _dialogField('Duration (e.g. 7 days)', durationCtrl),
                  _dialogField('Instructions', instrCtrl),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
              TextButton(
                onPressed: () {
                  if (nameCtrl.text.trim().isEmpty) return;
                  Navigator.pop(
                    ctx,
                    PrescriptionItem(
                      name: nameCtrl.text.trim(),
                      dosage: dosageCtrl.text.trim(),
                      frequency: freqCtrl.text.trim(),
                      duration: durationCtrl.text.trim(),
                      instructions: instrCtrl.text.trim(),
                    ),
                  );
                },
                child: const Text(
                  'Save',
                  style: TextStyle(color: AppTheme.neonGreen),
                ),
              ),
            ],
          ),
    );
  }

  Widget _dialogField(String label, TextEditingController ctrl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: ctrl,
        style: const TextStyle(color: AppTheme.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppTheme.textSecondary),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_patientNameCtrl.text.trim().isEmpty ||
        _diagnosisCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Patient name and diagnosis are required'),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    final notifier = ref.read(prescriptionsProvider.notifier);
    final firestore = FirestoreService();

    final prescription = Prescription(
      id: widget.existing?.id ?? const Uuid().v4(),
      doctorId: firestore.uid,
      doctorName: '', // Will be filled from profile
      patientId: _patientIdCtrl.text.trim(),
      patientName: _patientNameCtrl.text.trim(),
      diagnosis: _diagnosisCtrl.text.trim(),
      medicines: _meds,
      notes: _notesCtrl.text.trim(),
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
    );

    if (widget.existing != null) {
      await notifier.update(prescription);
    } else {
      await notifier.add(prescription);
    }
    if (mounted) Navigator.pop(context);
  }

  void _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: AppTheme.bgSecondary,
            title: const Text(
              'Delete Prescription',
              style: TextStyle(color: AppTheme.textPrimary),
            ),
            content: const Text(
              'Are you sure you want to delete this prescription?',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: AppTheme.radiantPink),
                ),
              ),
            ],
          ),
    );
    if (confirmed == true) {
      await ref
          .read(prescriptionsProvider.notifier)
          .delete(widget.existing!.id);
      if (mounted) Navigator.pop(context);
    }
  }
}
