import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../services/firebase_service.dart';
import '../services/auth_service.dart';

const kPrimary  = Color(0xFF2D7DD2);
const kSuccess  = Color(0xFF27AE60);
const kDanger   = Color(0xFFE74C3C);
const kWarning  = Color(0xFFF39C12);
const kBg       = Color(0xFFF5F7FA);
const kCard     = Colors.white;
const kTextDark = Color(0xFF1A2535);
const kTextGrey = Color(0xFF7F8C9A);

class FamilyViewScreen extends StatefulWidget {
  const FamilyViewScreen({super.key});

  @override
  State<FamilyViewScreen> createState() => _FamilyViewScreenState();
}

class _FamilyViewScreenState extends State<FamilyViewScreen> {
  final _noteController = TextEditingController();
  final _alertController = TextEditingController();
  int _streak = 0;
  int _wellness = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final uid = AuthService.uid;
    if (uid != null) {
      final streak = await FirebaseService.getCheckInStreak(uid);
      final wellness = await FirebaseService.getWellnessScore(uid);
      if (mounted) {
        setState(() {
          _streak = streak;
          _wellness = wellness;
        });
      }
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    _alertController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.uid;
    final userName = context.watch<AppProvider>().profile?.userName ?? 'Family Member';

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text('Family View', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: kTextDark)),
              const SizedBox(height: 4),
              const Text('Live status your family can see', style: TextStyle(fontSize: 14, color: kTextGrey)),
              const SizedBox(height: 24),

              if (uid == null)
                const _NoUserCard()
              else ...[
                // ── Live profile stream ──────────────────────────────────
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseService.userStream(uid),
                  builder: (context, snap) {
                    if (!snap.hasData) return const _LoadingCard();
                    final data = snap.data!.data() as Map<String, dynamic>? ?? {};
                    final name    = data['userName']   as String? ?? 'User';
                    final contact = data['emergencyContact'] as String? ?? 'Not set';
                    final diabetes = data['diabetes'] == true;
                    final bp       = data['bp']       == true;
                    final heart    = data['heart']    == true;
                    final customConditions = List<String>.from(data['customConditions'] ?? []);

                    return Column(children: [
                      // Profile card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF2D7DD2), Color(0xFF5BA4E8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
                        ),
                        child: Row(children: [
                          Container(
                            width: 56, height: 56,
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), shape: BoxShape.circle),
                            child: Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900))),
                          ),
                          const SizedBox(width: 16),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 2),
                            Text('Emergency: $contact', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
                          ])),
                        ]),
                      ),
                      const SizedBox(height: 16),

                      // Conditions row (predefined + custom)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(children: [
                          if (diabetes) _ConditionBadge('Diabetes', true, const Color(0xFFE67E22)),
                          if (diabetes) const SizedBox(width: 10),
                          if (bp) _ConditionBadge('Blood Pressure', true, const Color(0xFFE74C3C)),
                          if (bp) const SizedBox(width: 10),
                          if (heart) _ConditionBadge('Heart', true, const Color(0xFF8E44AD)),
                          if (heart && customConditions.isNotEmpty) const SizedBox(width: 10),
                          for (int i = 0; i < customConditions.length; i++) ...[
                            _ConditionBadge(customConditions[i], true, const Color(0xFF16A085)),
                            if (i < customConditions.length - 1) const SizedBox(width: 10),
                          ]
                        ]),
                      ),

                      const SizedBox(height: 20),

                      // ── WELLNESS SCORE & STREAK ──────────────────────────
                      Row(children: [
                        // Wellness Score
                        Expanded(
                          child: _StatsCard(
                            icon: Icons.favorite_rounded,
                            label: 'Wellness',
                            value: '$_wellness%',
                            color: _getWellnessColor(_wellness),
                            detail: _getWellnessLabel(_wellness),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Streak
                        Expanded(
                          child: _StatsCard(
                            icon: Icons.local_fire_department_rounded,
                            label: 'Check-in Streak',
                            value: '$_streak',
                            color: _streak > 0 ? const Color(0xFFE67E22) : kTextGrey,
                            detail: _streak > 0 ? 'days in a row! 🔥' : 'Start checking in',
                          ),
                        ),
                      ]),

                      const SizedBox(height: 20),

                      // ── LAST CHECK-IN INFO ────────────────────────────
                      FutureBuilder<DateTime?>(
                        future: FirebaseService.getLastCheckInTime(uid),
                        builder: (context, snap) {
                          if (snap.hasData && snap.data != null) {
                            final time = snap.data!;
                            final now = DateTime.now();
                            final diff = now.difference(time);
                            final text = _formatDuration(diff);
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2ECC71).withOpacity(0.08),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFF2ECC71).withOpacity(0.2)),
                              ),
                              child: Row(children: [
                                Container(
                                  width: 48, height: 48,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2ECC71).withOpacity(0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.check_circle_rounded, color: Color(0xFF2ECC71), size: 24),
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  const Text('Last checked in', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: kTextDark)),
                                  const SizedBox(height: 2),
                                  Text(text, style: const TextStyle(fontSize: 12, color: kTextGrey)),
                                ])),
                                const Icon(Icons.arrow_forward_rounded, color: kTextGrey, size: 20),
                              ]),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ]);
                  },
                ),

                const SizedBox(height: 28),

                // ── ACTIVITY HEATMAP (Last 30 days) ──────────────────────
                const Text('Activity Heatmap (Last 30 Days)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: kTextDark)),
                const SizedBox(height: 14),
                FutureBuilder<Map<String, bool>>(
                  future: FirebaseService.getLast30DaysCheckIns(uid),
                  builder: (context, snap) {
                    if (!snap.hasData) return const _LoadingCard();
                    final history = snap.data ?? {};
                    final today = DateTime.now();
                    
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: kCard,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
                      ),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: List.generate(30, (i) {
                          final date = today.subtract(Duration(days: 29 - i));
                          final dateStr = date.toString().substring(0, 10);
                          final checked = history[dateStr] ?? false;
                          return Tooltip(
                            message: dateStr,
                            child: Container(
                              width: 28, height: 28,
                              decoration: BoxDecoration(
                                color: checked ? kSuccess.withOpacity(0.8) : const Color(0xFFECF0F1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: checked ? const Icon(Icons.check_rounded, color: Colors.white, size: 14) : null,
                            ),
                          );
                        }),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 28),

                // ── RECENT CHECK-INS ─────────────────────────────────────
                const Text('Last 7 Days', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: kTextDark)),
                const SizedBox(height: 14),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseService.checkinsStream(uid),
                  builder: (context, snap) {
                    if (!snap.hasData) return const _LoadingCard();
                    if (snap.data!.docs.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(children: [
                            Icon(Icons.history_rounded, size: 48, color: kTextGrey.withOpacity(0.4)),
                            const SizedBox(height: 12),
                            const Text('No check-ins yet', style: TextStyle(color: kTextGrey, fontSize: 15)),
                          ]),
                        ),
                      );
                    }
                    return Column(
                      children: snap.data!.docs.map((doc) {
                        final d       = doc.data() as Map<String, dynamic>;
                        final date    = d['date'] as String? ?? doc.id;
                        final checked = d['checkedIn'] == true;
                        return _CheckInTile(date: date, checked: checked);
                      }).toList(),
                    );
                  },
                ),

                const SizedBox(height: 28),

                // ── MEDICATION LOGS ──────────────────────────────────────
                const Text('Recent Medication Logs', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: kTextDark)),
                const SizedBox(height: 14),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: FirebaseService.getMedicationLogs(uid),
                  builder: (context, snap) {
                    if (!snap.hasData) return const _LoadingCard();
                    final logs = snap.data ?? [];
                    if (logs.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(children: [
                            Icon(Icons.medication_rounded, size: 48, color: kTextGrey.withOpacity(0.4)),
                            const SizedBox(height: 12),
                            const Text('No medication logs yet', style: TextStyle(color: kTextGrey, fontSize: 15)),
                          ]),
                        ),
                      );
                    }
                    return Column(
                      children: logs.take(5).map((log) {
                        final taken = log['taken'] == true;
                        final note = log['note'] as String? ?? '';
                        final timestamp = (log['timestamp'] as Timestamp?)?.toDate();
                        return _MedicationLogTile(taken: taken, note: note, timestamp: timestamp);
                      }).toList(),
                    );
                  },
                ),

                const SizedBox(height: 28),

                // ── FAMILY NOTES ──────────────────────────────────────────
                const Text('Family Notes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: kTextDark)),
                const SizedBox(height: 14),

                // Add note section
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: kCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE8EDF5), width: 1),
                  ),
                  child: Row(children: [
                    Expanded(
                      child: TextField(
                        controller: _noteController,
                        decoration: InputDecoration(
                          hintText: 'Leave a note...',
                          hintStyle: TextStyle(color: kTextGrey.withOpacity(0.6)),
                          border: InputBorder.none,
                        ),
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () async {
                        if (_noteController.text.trim().isNotEmpty) {
                          await FirebaseService.addFamilyNote(uid, userName, _noteController.text.trim());
                          _noteController.clear();
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: const Text('Note added!'), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: kPrimary, shape: BoxShape.circle),
                        child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                      ),
                    ),
                  ]),
                ),

                const SizedBox(height: 12),

                // Family notes stream
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseService.familyNotesStream(uid),
                  builder: (context, snap) {
                    if (!snap.hasData || snap.data!.docs.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text('No notes yet', style: TextStyle(color: kTextGrey.withOpacity(0.7), fontSize: 13)),
                      );
                    }
                    return Column(
                      children: snap.data!.docs.map((doc) {
                        final d = doc.data() as Map<String, dynamic>;
                        final author = d['author'] as String? ?? 'Family';
                        final message = d['message'] as String? ?? '';
                        final timestamp = (d['timestamp'] as Timestamp?)?.toDate();
                        return _FamilyNoteTile(author: author, message: message, timestamp: timestamp);
                      }).toList(),
                    );
                  },
                ),

                const SizedBox(height: 28),

                // ── QUICK ALERT BUTTON ───────────────────────────────────
                const Text('Send Alert', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: kTextDark)),
                const SizedBox(height: 14),

                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: kCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE8EDF5), width: 1),
                  ),
                  child: Row(children: [
                    Expanded(
                      child: TextField(
                        controller: _alertController,
                        decoration: InputDecoration(
                          hintText: 'Message...',
                          hintStyle: TextStyle(color: kTextGrey.withOpacity(0.6)),
                          border: InputBorder.none,
                        ),
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () async {
                        if (_alertController.text.trim().isNotEmpty) {
                          await FirebaseService.sendAlert(uid, userName, _alertController.text.trim());
                          _alertController.clear();
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: const Text('Alert sent!'), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: kDanger, shape: BoxShape.circle),
                        child: const Icon(Icons.error_rounded, color: Colors.white, size: 18),
                      ),
                    ),
                  ]),
                ),

                const SizedBox(height: 28),

                // Share UID hint
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kPrimary.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: kPrimary.withOpacity(0.2)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.info_outline_rounded, color: kPrimary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Share with family', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: kTextDark)),
                      const SizedBox(height: 2),
                      Text('User ID: $uid', style: const TextStyle(fontSize: 11, color: kTextGrey, fontFamily: 'monospace')),
                    ])),
                  ]),
                ),
              ],

              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  Color _getWellnessColor(int score) {
    if (score >= 80) return kSuccess;
    if (score >= 50) return kWarning;
    return kDanger;
  }

  String _getWellnessLabel(int score) {
    if (score >= 80) return 'Excellent';
    if (score >= 50) return 'Fair';
    return 'Needs attention';
  }

  String _formatDuration(Duration diff) {
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _StatsCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final String detail;

  const _StatsCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 12),
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: kTextGrey, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(detail, style: const TextStyle(fontSize: 11, color: kTextGrey)),
      ]),
    );
  }
}

class _CheckInTile extends StatelessWidget {
  final String date;
  final bool checked;

  const _CheckInTile({required this.date, required this.checked});

  String _fmt(String date) {
    try {
      final d = DateTime.parse(date);
      return DateFormat('EEE, MMM d').format(d);
    } catch (e) {
      return date;
    }
  }

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      color: kCard,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: Row(
      children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: checked ? kSuccess.withOpacity(0.12) : kDanger.withOpacity(0.10),
            shape: BoxShape.circle,
          ),
          child: Icon(checked ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: checked ? kSuccess : kDanger, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_fmt(date), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: kTextDark)),
          Text(checked ? 'Checked in safely' : 'No check-in recorded',
              style: TextStyle(fontSize: 12, color: checked ? kSuccess : kDanger)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: checked ? kSuccess.withOpacity(0.10) : kDanger.withOpacity(0.10),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(checked ? 'Safe' : 'Missed',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: checked ? kSuccess : kDanger)),
        ),
      ],
    ),
  );
}

class _MedicationLogTile extends StatelessWidget {
  final bool taken;
  final String note;
  final DateTime? timestamp;

  const _MedicationLogTile({required this.taken, required this.note, this.timestamp});

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    return DateFormat('MMM d, h:mm a').format(time);
  }

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      color: kCard,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: Row(children: [
      Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: taken ? kSuccess.withOpacity(0.12) : kWarning.withOpacity(0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(taken ? Icons.check_circle_rounded : Icons.schedule_rounded,
            color: taken ? kSuccess : kWarning, size: 22),
      ),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(note.isNotEmpty ? note : 'Medication log', 
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: kTextDark)),
        const SizedBox(height: 2),
        Text(_formatTime(timestamp), style: TextStyle(fontSize: 12, color: kTextGrey)),
      ])),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: taken ? kSuccess.withOpacity(0.10) : kWarning.withOpacity(0.10),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(taken ? 'Taken' : 'Pending',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: taken ? kSuccess : kWarning)),
      ),
    ]),
  );
}

class _FamilyNoteTile extends StatelessWidget {
  final String author;
  final String message;
  final DateTime? timestamp;

  const _FamilyNoteTile({required this.author, required this.message, this.timestamp});

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: kCard,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFE8EDF5), width: 1),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text(author, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: kTextDark))),
        Text(_formatTime(timestamp), style: TextStyle(fontSize: 11, color: kTextGrey)),
      ]),
      const SizedBox(height: 6),
      Text(message, style: const TextStyle(fontSize: 13, color: kTextDark)),
    ]),
  );
}

class _ConditionBadge extends StatelessWidget {
  final String title;
  final bool value;
  final Color color;

  const _ConditionBadge(this.title, this.value, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: value ? color.withOpacity(0.15) : const Color(0xFFECF0F1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: value ? color.withOpacity(0.3) : const Color(0xFFBDC3C7).withOpacity(0.5)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.check_circle_rounded, color: value ? color : const Color(0xFFBDC3C7), size: 14),
      const SizedBox(width: 6),
      Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: value ? color : const Color(0xFF7F8C8D))),
    ]),
  );
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();
  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()),
  );
}

class _NoUserCard extends StatelessWidget {
  const _NoUserCard();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16)),
    child: const Text('Please complete setup first.', style: TextStyle(color: kTextGrey)),
  );
}
