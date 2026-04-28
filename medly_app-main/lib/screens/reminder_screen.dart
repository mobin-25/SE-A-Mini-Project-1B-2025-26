import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../services/notification_service.dart';

class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key});
  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  final _supa = SupabaseService.instance;
  final _notif = NotificationService.instance;
  List<Map<String, dynamic>> _schedules = [];
  List<Map<String, dynamic>> _medicines = [];
  bool _loading = true;

  final List<String> _allDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    _notif.initialize();
    _load();
  }

  Future<void> _load() async {
    final schedules = await _supa.getSchedules();
    final medicines = await _supa.getAllMedicines();
    setState(() {
      _schedules = schedules;
      _medicines = medicines;
      _loading = false;
    });
  }

  Future<void> _addReminder() async {
    int? selectedMedicineId;
    String selectedMedicineName = '';
    TimeOfDay selectedTime = TimeOfDay.now();
    bool withFood = false;
    List<String> selectedDays = List.from(_allDays);

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
              const Text('Add Medicine Reminder', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 20),
              DropdownButtonFormField<int>(
                decoration: InputDecoration(
                  labelText: 'Select Medicine',
                  prefixIcon: const Icon(Icons.medication),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: _medicines.map((m) => DropdownMenuItem<int>(
                  value: m['medicine_id'] as int,
                  child: Text(m['name'] as String),
                )).toList(),
                onChanged: (v) {
                  selectedMedicineId = v;
                  selectedMedicineName = _medicines.firstWhere((m) => m['medicine_id'] == v)['name'] as String;
                },
              ),
              const SizedBox(height: 16),
              // Time picker tile
              InkWell(
                onTap: () async {
                  final t = await showTimePicker(context: ctx, initialTime: selectedTime);
                  if (t != null) setS(() => selectedTime = t);
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, color: Colors.grey),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Reminder Time', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          Text(selectedTime.format(ctx), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Days selector
              const Text('Repeat on', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: _allDays.map((day) => FilterChip(
                  label: Text(day, style: const TextStyle(fontSize: 12)),
                  selected: selectedDays.contains(day),
                  onSelected: (v) => setS(() {
                    if (v) selectedDays.add(day); else selectedDays.remove(day);
                  }),
                )).toList(),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Take with food', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('You\'ll be reminded to eat before taking'),
                value: withFood,
                onChanged: (v) => setS(() => withFood = v),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    if (selectedMedicineId == null) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Please select a medicine')),
                      );
                      return;
                    }
                    if (selectedDays.isEmpty) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Select at least one day')),
                      );
                      return;
                    }

                    final timeStr = '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
                    await _supa.addSchedule(
                      medicineId: selectedMedicineId!,
                      medicineName: selectedMedicineName,
                      time: timeStr,
                      withFood: withFood,
                      daysOfWeek: selectedDays,
                    );

                    // Schedule local notification
                    await _notif.scheduleDailyReminder(
                      id: '${selectedMedicineId}_$timeStr'.hashCode,
                      medicineName: selectedMedicineName,
                      time: timeStr,
                      withFood: withFood,
                    );

                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      _load();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Reminder set for $selectedMedicineName at $timeStr'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  child: const Text('Set Reminder'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'taken': return Colors.green;
      case 'missed': return Colors.red;
      default: return Colors.orange;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'taken': return Icons.check_circle;
      case 'missed': return Icons.cancel;
      default: return Icons.schedule;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final now = TimeOfDay.now();

    // Sort: upcoming first
    final sorted = List<Map<String, dynamic>>.from(_schedules);
    sorted.sort((a, b) => (a['time'] as String).compareTo(b['time'] as String));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medicine Reminders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addReminder,
        icon: const Icon(Icons.add_alarm),
        label: const Text('Add Reminder'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : sorted.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.alarm_off, size: 72, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      const Text('No reminders set', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Tap the button below to add one', style: TextStyle(color: Colors.grey.shade500)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: sorted.length,
                  itemBuilder: (_, i) {
                    final s = sorted[i];
                    final missedCount = s['missed_count'] as int? ?? 0;
                    final medicineName = s['medicine_name'] as String? ??
                        (s['medicines'] as Map?)?['name'] as String? ?? 'Unknown';
                    final status = s['status'] as String? ?? 'pending';
                    final time = s['time'] as String;
                    final withFood = s['with_food'] as bool? ?? false;
                    final days = (s['days_of_week'] as List?)?.join(', ') ?? 'Daily';

                    return Dismissible(
                      key: Key(s['schedule_id'].toString()),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) async {
                        await _supa.deleteSchedule(s['schedule_id'] as int);
                        await _notif.cancelReminder('${s['medicine_id']}_$time'.hashCode);
                        _load();
                      },
                      child: Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: missedCount >= 2 ? Colors.red.shade200 : Colors.grey.shade200,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Time display
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      _formatTime(time),
                                      style: TextStyle(
                                        color: colorScheme.onPrimaryContainer,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(medicineName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            if (withFood) ...[
                                              const Icon(Icons.restaurant, size: 12, color: Colors.grey),
                                              const SizedBox(width: 2),
                                              const Text('With food', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                              const SizedBox(width: 8),
                                            ],
                                            Icon(Icons.repeat, size: 12, color: Colors.grey),
                                            const SizedBox(width: 2),
                                            Flexible(child: Text(days, style: const TextStyle(color: Colors.grey, fontSize: 12), overflow: TextOverflow.ellipsis)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Status chip — Flexible to avoid overflow
                                  Flexible(
                                    flex: 0,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _statusColor(status).withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(_statusIcon(status), color: _statusColor(status), size: 14),
                                          const SizedBox(width: 4),
                                          Text(status, style: TextStyle(color: _statusColor(status), fontWeight: FontWeight.w600, fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (missedCount >= 2) ...[
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 16),
                                      const SizedBox(width: 6),
                                      Text('Missed $missedCount times — please consult your doctor', style: const TextStyle(color: Colors.red, fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.green,
                                        side: const BorderSide(color: Colors.green),
                                      ),
                                      onPressed: () async {
                                        await _supa.markTaken(s['schedule_id'] as int);
                                        _load();
                                      },
                                      icon: const Icon(Icons.check, size: 16),
                                      label: const Text('Taken'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.red,
                                        side: const BorderSide(color: Colors.red),
                                      ),
                                      onPressed: () async {
                                        await _supa.markMissed(s['schedule_id'] as int, missedCount);
                                        _load();
                                      },
                                      icon: const Icon(Icons.close, size: 16),
                                      label: const Text('Missed'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  String _formatTime(String time) {
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final ampm = hour >= 12 ? 'PM' : 'AM';
    final h = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$h:${minute.toString().padLeft(2, '0')} $ampm';
  }
}
