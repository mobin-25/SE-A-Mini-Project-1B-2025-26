import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../services/admin_service.dart';
import '../services/notification_service.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  StreamSubscription<List<Map<String, dynamic>>>? _alertSub;
  // Track IDs we've already notified about so we don't re-fire on rebuild
  final Set<String> _notifiedIds = {};

  @override
  void initState() {
    super.initState();
    // Listen for new alerts and fire local push notifications
    if (!kIsWeb) {
      _alertSub = AdminService.alertsStream().listen((alerts) {
        for (final alert in alerts) {
          final id = alert['id'] as String?;
          if (id != null && !_notifiedIds.contains(id)) {
            _notifiedIds.add(id);
            // Don't notify admin about their own alerts (they already get one in sendAlert)
            final currentEmail =
                FirebaseAuth.instance.currentUser?.email ?? '';
            if (!AdminService.isAdmin(currentEmail)) {
              NotificationService.showLocalNotification(
                title: alert['title'] ?? 'APSIT Smart Park',
                body: alert['body'] ?? '',
                id: id.hashCode,
              );
            }
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _alertSub?.cancel();
    super.dispose();
  }

  bool get _isAdmin {
    final email = FirebaseAuth.instance.currentUser?.email;
    return AdminService.isAdmin(email);
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'critical':
        return Icons.warning_amber_rounded;
      case 'warning':
        return Icons.info_outline;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'critical':
        return AppColors.red;
      case 'warning':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF3B82F6);
    }
  }

  String _timeAgo(Timestamp? ts) {
    if (ts == null) return '';
    final diff = DateTime.now().difference(ts.toDate());
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays}d ago';
  }

  void _showSendAlertDialog() {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    String selectedType = 'info';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Send Alert to All Users',
            style: GoogleFonts.inter(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogField(titleCtrl, 'Title', Icons.title),
              const SizedBox(height: 12),
              _dialogField(bodyCtrl, 'Message body', Icons.message_outlined,
                  maxLines: 3),
              const SizedBox(height: 12),
              Row(
                children: ['info', 'warning', 'critical'].map((t) {
                  final isSelected = selectedType == t;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setDialogState(() => selectedType = t),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _colorForType(t)
                              : AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? _colorForType(t)
                                : AppColors.inputBorder,
                          ),
                        ),
                        child: Text(
                          t[0].toUpperCase() + t.substring(1),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            color:
                                isSelected ? Colors.white : AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel',
                  style: GoogleFonts.inter(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                final title = titleCtrl.text.trim();
                final body = bodyCtrl.text.trim();
                if (title.isEmpty || body.isEmpty) return;
                Navigator.pop(ctx);
                await AdminService.sendAlert(
                    title: title, body: body, type: selectedType);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Alert sent to all users!',
                        style: GoogleFonts.inter(color: Colors.white)),
                    backgroundColor: AppColors.green,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ));
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              child:
                  Text('Send', style: GoogleFonts.inter(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dialogField(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.inputBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        style: GoogleFonts.inter(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(color: AppColors.textMuted),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Alerts & Notifications',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_isAdmin)
            IconButton(
              icon: const Icon(Icons.add_alert_outlined,
                  color: AppColors.primaryLight, size: 24),
              tooltip: 'Send alert',
              onPressed: _showSendAlertDialog,
            ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: AdminService.alertsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }

          final alerts = snapshot.data ?? [];

          if (alerts.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.notifications_off_outlined,
                      color: AppColors.textMuted, size: 56),
                  const SizedBox(height: 16),
                  Text(
                    'No alerts yet',
                    style: GoogleFonts.inter(
                        color: AppColors.textSecondary, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: alerts.length,
            itemBuilder: (ctx, i) {
              final alert = alerts[i];
              final type = alert['type'] as String? ?? 'info';
              final ts = alert['sentAt'] as Timestamp?;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: type == 'critical'
                        ? AppColors.red.withOpacity(0.4)
                        : AppColors.inputBorder,
                    width: type == 'critical' ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _colorForType(type).withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(_iconForType(type),
                          color: _colorForType(type), size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  alert['title'] ?? '',
                                  style: GoogleFonts.inter(
                                    color: type == 'critical'
                                        ? AppColors.red
                                        : Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Text(
                                _timeAgo(ts),
                                style: GoogleFonts.inter(
                                    color: AppColors.textMuted, fontSize: 11),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            alert['body'] ?? '',
                            style: GoogleFonts.inter(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_isAdmin)
                      GestureDetector(
                        onTap: () => AdminService.deleteAlert(alert['id']),
                        child: const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: Icon(Icons.delete_outline,
                              color: AppColors.textMuted, size: 18),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    final items = [
      {'icon': Icons.map_outlined, 'label': 'Map'},
      {'icon': Icons.directions_car_outlined, 'label': 'Slots'},
      {'icon': Icons.notifications, 'label': 'Alerts'},
      {'icon': Icons.person_outline, 'label': 'Profile'},
    ];
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.navBarBg,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: List.generate(items.length, (i) {
          final isActive = i == 2;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (i == 0) Navigator.of(context).pushNamed('/map');
                if (i == 1) Navigator.of(context).pushNamed('/parking-map');
                if (i == 3) Navigator.of(context).pushNamed('/profile');
              },
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(items[i]['icon'] as IconData,
                        color:
                            isActive ? AppColors.primary : AppColors.textMuted,
                        size: 26),
                    const SizedBox(height: 4),
                    Text(items[i]['label'] as String,
                        style: GoogleFonts.inter(
                          color: isActive
                              ? AppColors.primary
                              : AppColors.textMuted,
                          fontSize: 11,
                          fontWeight:
                              isActive ? FontWeight.w700 : FontWeight.w400,
                        )),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
