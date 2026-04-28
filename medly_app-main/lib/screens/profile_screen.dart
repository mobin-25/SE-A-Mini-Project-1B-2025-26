import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _supa = SupabaseService.instance;
  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();

  String? _gender;
  String? _bloodGroup;
  String _bpStatus = 'normal';
  String _diabetesStatus = 'none';
  bool _pregnant = false;
  bool _loading = true;
  bool _saving = false;

  List<String> _allergies = [];
  List<String> _conditions = [];
  List<Map<String, dynamic>> _stock = [];
  List<Map<String, dynamic>> _lowStockAlerts = [];
  List<Map<String, dynamic>> _expiringAlerts = [];

  final _allergyCtrl = TextEditingController();
  final _conditionCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile = await _supa.getUserProfile();
    final stock = await _supa.getMedicineStock();
    final low = await _supa.getLowStockAlerts();
    final exp = await _supa.getExpiringMedicines();

    setState(() {
      if (profile != null) {
        _nameCtrl.text = profile['name'] as String? ?? '';
        _ageCtrl.text = profile['age']?.toString() ?? '';
        _weightCtrl.text = profile['weight_kg']?.toString() ?? '';
        _heightCtrl.text = profile['height_cm']?.toString() ?? '';
        _gender = profile['gender'] as String?;
        _bloodGroup = profile['blood_group'] as String?;
        _bpStatus = profile['bp_status'] as String? ?? 'normal';
        _diabetesStatus = profile['diabetes_status'] as String? ?? 'none';
        _pregnant = profile['pregnant'] as bool? ?? false;
        _allergies = List<String>.from(profile['allergies'] as List? ?? []);
        _conditions = List<String>.from(profile['chronic_conditions'] as List? ?? []);
      }
      _stock = stock;
      _lowStockAlerts = low;
      _expiringAlerts = exp;
      _loading = false;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await _supa.saveUserProfile({
      'name': _nameCtrl.text,
      'age': int.tryParse(_ageCtrl.text),
      'gender': _gender,
      'blood_group': _bloodGroup,
      'weight_kg': double.tryParse(_weightCtrl.text),
      'height_cm': double.tryParse(_heightCtrl.text),
      'bp_status': _bpStatus,
      'diabetes_status': _diabetesStatus,
      'pregnant': _pregnant,
      'allergies': _allergies,
      'chronic_conditions': _conditions,
    });
    setState(() => _saving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved!'), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Health Profile'),
        actions: [
          IconButton(
            icon: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.save),
            onPressed: _save,
            tooltip: 'Save Profile',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Alerts
                  if (_lowStockAlerts.isNotEmpty || _expiringAlerts.isNotEmpty) ...[
                    _alertsSection(colorScheme),
                    const SizedBox(height: 20),
                  ],

                  // Basic info
                  _sectionHeader('Basic Information', Icons.person),
                  const SizedBox(height: 12),
                  _buildTextField(_nameCtrl, 'Full Name', Icons.person_outline),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildTextField(_ageCtrl, 'Age', Icons.cake, keyboardType: TextInputType.number)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _gender,
                          decoration: _inputDecoration('Gender', Icons.wc),
                          items: ['Male', 'Female', 'Other']
                              .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                              .toList(),
                          onChanged: (v) => setState(() => _gender = v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildTextField(_weightCtrl, 'Weight (kg)', Icons.monitor_weight, keyboardType: TextInputType.number)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildTextField(_heightCtrl, 'Height (cm)', Icons.height, keyboardType: TextInputType.number)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _bloodGroup,
                    decoration: _inputDecoration('Blood Group', Icons.bloodtype),
                    items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']
                        .map((bg) => DropdownMenuItem(value: bg, child: Text(bg)))
                        .toList(),
                    onChanged: (v) => setState(() => _bloodGroup = v),
                  ),

                  const SizedBox(height: 24),
                  _sectionHeader('Medical Conditions', Icons.medical_information),
                  const SizedBox(height: 12),

                  // BP Status
                  _optionSelector(
                    label: 'Blood Pressure',
                    icon: Icons.favorite,
                    options: {'normal': 'Normal', 'low': 'Low BP', 'high': 'High BP'},
                    selected: _bpStatus,
                    onSelect: (v) => setState(() => _bpStatus = v),
                    colors: {'normal': Colors.green, 'low': Colors.blue, 'high': Colors.red},
                  ),
                  const SizedBox(height: 12),

                  // Diabetes
                  _optionSelector(
                    label: 'Diabetes',
                    icon: Icons.water_drop,
                    options: {'none': 'None', 'pre': 'Pre-diabetic', 'type1': 'Type 1', 'type2': 'Type 2'},
                    selected: _diabetesStatus,
                    onSelect: (v) => setState(() => _diabetesStatus = v),
                    colors: {'none': Colors.green, 'pre': Colors.orange, 'type1': Colors.red, 'type2': Colors.red},
                  ),
                  const SizedBox(height: 12),

                  // Pregnant
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                    child: SwitchListTile(
                      title: const Text('Pregnant', style: TextStyle(fontWeight: FontWeight.w600)),
                      secondary: const Icon(Icons.pregnant_woman, color: Colors.pink),
                      value: _pregnant,
                      onChanged: (v) => setState(() => _pregnant = v),
                    ),
                  ),

                  const SizedBox(height: 24),
                  _sectionHeader('Allergies', Icons.warning_amber_rounded),
                  const SizedBox(height: 12),
                  _chipInputSection(
                    items: _allergies,
                    controller: _allergyCtrl,
                    hint: 'Add allergy (e.g. Penicillin)',
                    color: Colors.red,
                    onAdd: (v) => setState(() => _allergies.add(v)),
                    onRemove: (v) => setState(() => _allergies.remove(v)),
                  ),

                  const SizedBox(height: 24),
                  _sectionHeader('Chronic Conditions', Icons.local_hospital),
                  const SizedBox(height: 12),
                  _chipInputSection(
                    items: _conditions,
                    controller: _conditionCtrl,
                    hint: 'Add condition (e.g. Hypertension)',
                    color: Colors.orange,
                    onAdd: (v) => setState(() => _conditions.add(v)),
                    onRemove: (v) => setState(() => _conditions.remove(v)),
                  ),

                  const SizedBox(height: 24),
                  _sectionHeader('Medicine Stock Tracker', Icons.inventory),
                  const SizedBox(height: 12),
                  _stockSection(colorScheme),

                  const SizedBox(height: 80),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddStockDialog,
        icon: const Icon(Icons.add),
        label: const Text('Track Medicine'),
      ),
    );
  }

  Widget _alertsSection(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ..._lowStockAlerts.map((s) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Row(
            children: [
              const Icon(Icons.inventory_2, color: Colors.orange, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Low Stock: ${s['medicine_name']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('${s['current_count']} tablets remaining — time to refill!', style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        )),
        ..._expiringAlerts.map((s) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today, color: Colors.red, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Expiring Soon: ${s['medicine_name']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('Expires: ${s['expiry_date']}', style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _stockSection(ColorScheme cs) {
    if (_stock.isEmpty) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
        child: const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text('No medicines tracked yet.\nTap + to add one.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey))),
        ),
      );
    }

    return Column(
      children: _stock.map((s) {
        final current = s['current_count'] as int;
        final total = s['total_count'] as int;
        final threshold = s['low_stock_threshold'] as int;
        final isLow = current <= threshold;
        final progress = total > 0 ? current / total : 0.0;

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: isLow ? Colors.orange.shade200 : Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(s['medicine_name'] as String,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                    if (isLow) const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 18),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 20),
                      onPressed: () async {
                        if (current > 0) {
                          await _supa.updateStock(s['id'] as int, current - 1);
                          _load();
                        }
                      },
                      tooltip: 'Take one',
                      color: cs.primary,
                    ),
                    Text('$current', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, size: 20),
                      onPressed: () async {
                        await _supa.updateStock(s['id'] as int, current + 1);
                        _load();
                      },
                      color: cs.primary,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      onPressed: () async {
                        await _supa.deleteMedicineStock(s['id'] as int);
                        _load();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation(isLow ? Colors.orange : cs.primary),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('$current of $total left', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    if (s['expiry_date'] != null)
                      Text('Exp: ${s['expiry_date']}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 22),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
      ],
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label, IconData icon, {TextInputType? keyboardType}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: _inputDecoration(label, icon),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  Widget _optionSelector({
    required String label,
    required IconData icon,
    required Map<String, String> options,
    required String selected,
    required Function(String) onSelect,
    required Map<String, Color> colors,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: options.entries.map((e) {
                final isSelected = selected == e.key;
                final color = colors[e.key] ?? Colors.grey;
                return ChoiceChip(
                  label: Text(e.value),
                  selected: isSelected,
                  selectedColor: color.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: isSelected ? color : Colors.grey,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (_) => onSelect(e.key),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chipInputSection({
    required List<String> items,
    required TextEditingController controller,
    required String hint,
    required Color color,
    required Function(String) onAdd,
    required Function(String) onRemove,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: hint,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    final v = controller.text.trim();
                    if (v.isNotEmpty && !items.contains(v)) {
                      onAdd(v);
                      controller.clear();
                    }
                  },
                ),
              ],
            ),
            if (items.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: items.map((item) => Chip(
                  label: Text(item),
                  deleteIcon: const Icon(Icons.close, size: 14),
                  backgroundColor: color.withOpacity(0.1),
                  labelStyle: TextStyle(color: color, fontWeight: FontWeight.w500),
                  onDeleted: () => onRemove(item),
                )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showAddStockDialog() async {
    int? selectedMedicineId;
    String selectedMedicineName = '';
    final countCtrl = TextEditingController();
    final thresholdCtrl = TextEditingController(text: '5');
    final dailyDoseCtrl = TextEditingController(text: '1');
    DateTime? expiryDate;

    final medicines = await _supa.getAllMedicines();

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              const Text('Track Medicine Stock', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 20),
              DropdownButtonFormField<int>(
                decoration: InputDecoration(labelText: 'Medicine', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                items: medicines.map((m) => DropdownMenuItem<int>(
                  value: m['medicine_id'] as int,
                  child: Text(m['name'] as String),
                )).toList(),
                onChanged: (v) {
                  selectedMedicineId = v;
                  selectedMedicineName = medicines.firstWhere((m) => m['medicine_id'] == v)['name'] as String;
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: TextFormField(controller: countCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Total Count', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))),
                  const SizedBox(width: 12),
                  Expanded(child: TextFormField(controller: dailyDoseCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Daily Dose', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: thresholdCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Alert when below (tablets)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), prefixIcon: const Icon(Icons.notifications_active)),
              ),
              const SizedBox(height: 12),
              ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
                title: Text(expiryDate == null ? 'Set Expiry Date (optional)' : 'Expires: ${expiryDate!.toLocal().toString().split(' ')[0]}'),
                leading: const Icon(Icons.calendar_today),
                onTap: () async {
                  final d = await showDatePicker(
                    context: ctx,
                    initialDate: DateTime.now().add(const Duration(days: 180)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 1825)),
                  );
                  if (d != null) setS(() => expiryDate = d);
                },
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () async {
                  if (selectedMedicineId == null || countCtrl.text.isEmpty) return;
                  final count = int.tryParse(countCtrl.text) ?? 0;
                  await _supa.addMedicineStock(
                    medicineId: selectedMedicineId!,
                    medicineName: selectedMedicineName,
                    totalCount: count,
                    currentCount: count,
                    dailyDose: int.tryParse(dailyDoseCtrl.text) ?? 1,
                    lowStockThreshold: int.tryParse(thresholdCtrl.text) ?? 5,
                    expiryDate: expiryDate,
                  );
                  Navigator.pop(ctx);
                  _load();
                },
                child: const Text('Add to Tracker'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
