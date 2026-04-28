import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

const kPrimary  = Color(0xFF2D7DD2);
const kSuccess  = Color(0xFF27AE60);
const kDanger   = Color(0xFFE74C3C);
const kBg       = Color(0xFFF5F7FA);
const kCard     = Colors.white;
const kTextDark = Color(0xFF1A2535);
const kTextGrey = Color(0xFF7F8C9A);

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().refreshCheckIns();
    });
  }

  int get checkedInCount {
    if (!mounted) return 0;
    return context.read<AppProvider>().checkIns.where((v) => v.checkedIn).length;
  }

  @override
  Widget build(BuildContext context) {
    final history = context.watch<AppProvider>().checkIns;

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("History", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: kTextDark)),
                  const SizedBox(height: 4),
                  const Text("Your daily check-in log", style: TextStyle(fontSize: 14, color: kTextGrey)),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Stats Row ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _StatCard(
                    label: "Total Days",
                    value: "${history.length}",
                    icon: Icons.calendar_month_rounded,
                    color: kPrimary,
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    label: "Safe Days",
                    value: "$checkedInCount",
                    icon: Icons.check_circle_rounded,
                    color: kSuccess,
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    label: "Streak",
                    value: "${_calculateStreak(history)}🔥",
                    icon: Icons.local_fire_department_rounded,
                    color: const Color(0xFFF39C12),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── List ────────────────────────────────────────────────────
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : history.isEmpty
                      ? _EmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: history.length,
                          itemBuilder: (context, index) {
                            final entry = history[index];
                            return _HistoryTile(
                              date: entry.date,
                              checked: entry.checkedIn,
                              index: index,
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  int _calculateStreak(List<dynamic> history) {
    int streak = 0;
    final today = DateTime.now();
    for (int i = 0; i < 365; i++) {
      final day = today.subtract(Duration(days: i)).toString().substring(0, 10);
      if (history.any((r) => r.date == day && r.checkedIn)) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
            Text(label, style: const TextStyle(fontSize: 11, color: kTextGrey, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final String date;
  final bool checked;
  final int index;

  const _HistoryTile({required this.date, required this.checked, required this.index});

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      const days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
      return "${days[dt.weekday - 1]}, ${months[dt.month - 1]} ${dt.day}, ${dt.year}";
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: checked ? kSuccess.withOpacity(0.12) : kDanger.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              checked ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: checked ? kSuccess : kDanger,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_formatDate(date), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: kTextDark)),
                const SizedBox(height: 2),
                Text(
                  checked ? "Checked in safely ✓" : "No check-in recorded",
                  style: TextStyle(fontSize: 12, color: checked ? kSuccess : kDanger),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: checked ? kSuccess.withOpacity(0.10) : kDanger.withOpacity(0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              checked ? "Safe" : "Missed",
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: checked ? kSuccess : kDanger),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded, size: 72, color: kTextGrey.withOpacity(0.4)),
          const SizedBox(height: 16),
          const Text("No history yet", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: kTextGrey)),
          const SizedBox(height: 6),
          const Text("Your daily check-ins will appear here", style: TextStyle(fontSize: 13, color: kTextGrey)),
        ],
      ),
    );
  }
}