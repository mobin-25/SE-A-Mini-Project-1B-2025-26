/// Medicines list — glassmorphic cards with accent bars, gradient FAB,
/// neon filter chips, nebula background.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/providers.dart';
import '../models/models.dart';
import '../widgets/nebula_background.dart';
import 'add_medicine_screen.dart';

class MedicinesScreen extends ConsumerStatefulWidget {
  const MedicinesScreen({super.key});

  @override
  ConsumerState<MedicinesScreen> createState() => _MedicinesScreenState();
}

class _MedicinesScreenState extends ConsumerState<MedicinesScreen> {
  String _searchQuery = '';
  String _activeFilter = 'All';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Medicine> _filteredMedicines(List<Medicine> all) {
    var list =
        all.where((m) {
          if (_searchQuery.isNotEmpty) {
            return m.name.toLowerCase().contains(_searchQuery.toLowerCase());
          }
          return true;
        }).toList();

    switch (_activeFilter) {
      case 'Active':
        list = list.where((m) => !m.isCompleted).toList();
        break;
      case 'Completed':
        list = list.where((m) => m.isCompleted).toList();
        break;
      case 'Today':
        list = list.where((m) => m.reminderTimes.isNotEmpty).toList();
        break;
    }
    return list;
  }

  // Rotating accent color per card index
  static const _cardAccents = [
    AppTheme.electricBlue,
    AppTheme.neonGreen,
    AppTheme.vividOrange,
    AppTheme.radiantPink,
  ];

  @override
  Widget build(BuildContext context) {
    final medicines = ref.watch(medicinesProvider);
    final filtered = _filteredMedicines(medicines);

    return NebulaBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Medicines'),
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_list_rounded),
              onPressed: () => _showFilterSheet(context),
            ),
          ],
        ),
        body: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Search medicines...',
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppTheme.textSecondary,
                  ),
                  suffixIcon:
                      _searchQuery.isNotEmpty
                          ? IconButton(
                            icon: const Icon(
                              Icons.close_rounded,
                              color: AppTheme.textSecondary,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                          : null,
                ),
              ),
            ),

            // Filter chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                children:
                    ['All', 'Active', 'Completed', 'Today'].map((label) {
                      final isActive = _activeFilter == label;
                      final idx = [
                        'All',
                        'Active',
                        'Completed',
                        'Today',
                      ].indexOf(label);
                      final accent = _cardAccents[idx % _cardAccents.length];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(label),
                          selected: isActive,
                          onSelected:
                              (_) => setState(() => _activeFilter = label),
                          selectedColor: accent.withValues(alpha: 0.25),
                          backgroundColor: AppTheme.glassWhite,
                          labelStyle: TextStyle(
                            color: isActive ? accent : AppTheme.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isActive ? accent : AppTheme.glassBorder,
                            ),
                          ),
                          showCheckmark: false,
                        ),
                      );
                    }).toList(),
              ),
            ),
            const SizedBox(height: 8),

            // Section title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 3,
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppTheme.electricBlue,
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: AppTheme.glow(AppTheme.electricBlue, blur: 6),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'ACTIVE MEDICINES',
                    style: TextStyle(
                      color: AppTheme.electricBlue,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${filtered.length} Total',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Medicine cards list
            Expanded(
              child:
                  filtered.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.medication_outlined,
                              size: 56,
                              color: AppTheme.textSecondary.withValues(
                                alpha: 0.3,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'No medicines found',
                              style: TextStyle(color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      )
                      : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                        itemCount: filtered.length,
                        itemBuilder:
                            (ctx, i) => _buildMedicineCard(
                              context,
                              ref,
                              filtered[i],
                              i,
                            ),
                      ),
            ),
          ],
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 80),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: AppTheme.accentGradient,
              boxShadow: AppTheme.glow(
                AppTheme.electricBlue,
                blur: 20,
                spread: 2,
              ),
            ),
            child: FloatingActionButton(
              tooltip: 'Add Medicine',
              backgroundColor: Colors.transparent,
              elevation: 0,
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddMedicineScreen()),
                );
              },
              child: const Icon(
                Icons.add_rounded,
                size: 28,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMedicineCard(
    BuildContext context,
    WidgetRef ref,
    Medicine med,
    int index,
  ) {
    final accent = _cardAccents[index % _cardAccents.length];

    String? nextTime;
    for (final t in med.reminderTimes) {
      if (!med.takenTimes.contains(t)) {
        nextTime = t;
        break;
      }
    }

    IconData formIcon;
    switch (med.form.toLowerCase()) {
      case 'capsule':
        formIcon = Icons.medication_rounded;
        break;
      case 'syrup':
        formIcon = Icons.local_drink_rounded;
        break;
      case 'injection':
        formIcon = Icons.vaccines_rounded;
        break;
      default:
        formIcon = Icons.medication_liquid_rounded;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
            decoration: BoxDecoration(
              color: const Color(0x28FFFFFF),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: accent.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                // Accent bar
                Container(
                  width: 4,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [accent, accent.withValues(alpha: 0.3)],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                    ),
                    boxShadow: AppTheme.glow(accent, blur: 8),
                  ),
                ),
                // Card content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(9),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: Icon(formIcon, color: accent, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    med.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    '${med.dosage}, ${med.form}',
                                    style: const TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (med.isCompleted)
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppTheme.neonGreen.withValues(
                                    alpha: 0.15,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppTheme.neonGreen,
                                  size: 22,
                                ),
                              )
                            else
                              PopupMenuButton<String>(
                                icon: const Icon(
                                  Icons.more_vert_rounded,
                                  color: AppTheme.textSecondary,
                                ),
                                color: AppTheme.bgSecondary,
                                onSelected: (val) {
                                  if (val == 'edit') {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => AddMedicineScreen(
                                              editMedicine: med,
                                            ),
                                      ),
                                    );
                                  } else if (val == 'markAll') {
                                    ref
                                        .read(medicinesProvider.notifier)
                                        .markAllTaken(med.id);
                                  } else if (val == 'delete') {
                                    ref
                                        .read(medicinesProvider.notifier)
                                        .delete(med.id);
                                  }
                                },
                                itemBuilder:
                                    (_) => [
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Text('Edit'),
                                      ),
                                      const PopupMenuItem(
                                        value: 'markAll',
                                        child: Text('Mark All Taken'),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Text(
                                          'Delete',
                                          style: TextStyle(
                                            color: AppTheme.radiantPink,
                                          ),
                                        ),
                                      ),
                                    ],
                              ),
                          ],
                        ),

                        // Time chips
                        if (med.reminderTimes.length > 1) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            children:
                                med.reminderTimes.map((t) {
                                  final isTaken = med.takenTimes.contains(t);
                                  final isNext = t == nextTime;
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient:
                                          isNext
                                              ? LinearGradient(
                                                colors: [
                                                  accent,
                                                  accent.withValues(alpha: 0.7),
                                                ],
                                              )
                                              : null,
                                      color:
                                          isNext
                                              ? null
                                              : isTaken
                                              ? accent.withValues(alpha: 0.15)
                                              : AppTheme.glassWhite,
                                      borderRadius: BorderRadius.circular(14),
                                      border:
                                          isNext
                                              ? null
                                              : Border.all(
                                                color: AppTheme.glassBorder,
                                              ),
                                      boxShadow:
                                          isNext
                                              ? AppTheme.glow(accent, blur: 8)
                                              : null,
                                    ),
                                    child: Text(
                                      t,
                                      style: TextStyle(
                                        color:
                                            isNext
                                                ? Colors.white
                                                : AppTheme.textSecondary,
                                        fontSize: 11,
                                        fontWeight:
                                            isNext
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                      ),
                                    ),
                                  );
                                }).toList(),
                          ),
                        ],

                        // Next time info
                        if (nextTime != null && !med.isCompleted) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                color: accent,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Next at $nextTime',
                                style: TextStyle(color: accent, fontSize: 12),
                              ),
                            ],
                          ),
                        ] else if (med.reminderTimes.length == 1) ...[
                          const SizedBox(height: 8),
                          Text(
                            '${med.frequency} at ${med.reminderTimes.first}',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],

                        // Status chip
                        if (med.isCompleted) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.neonGreen.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppTheme.neonGreen.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                            child: const Text(
                              'Completed',
                              style: TextStyle(
                                color: AppTheme.neonGreen,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ] else if (med.isReminderOn) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: accent.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.notifications_active_rounded,
                                  color: accent,
                                  size: 13,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Reminders ON',
                                  style: TextStyle(
                                    color: accent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter Options',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(
                  Icons.sort_rounded,
                  color: AppTheme.electricBlue,
                ),
                title: const Text('Sort by Name'),
                onTap: () => Navigator.pop(ctx),
              ),
              ListTile(
                leading: const Icon(
                  Icons.access_time_rounded,
                  color: AppTheme.neonGreen,
                ),
                title: const Text('Sort by Time'),
                onTap: () => Navigator.pop(ctx),
              ),
              ListTile(
                leading: const Icon(
                  Icons.category_rounded,
                  color: AppTheme.vividOrange,
                ),
                title: const Text('Filter by Form'),
                onTap: () => Navigator.pop(ctx),
              ),
            ],
          ),
        );
      },
    );
  }
}
