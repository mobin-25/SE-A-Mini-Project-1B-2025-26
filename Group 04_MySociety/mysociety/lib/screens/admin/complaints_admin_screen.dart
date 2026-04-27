import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';

class ComplaintsAdminScreen extends StatelessWidget {
  const ComplaintsAdminScreen({super.key});

  void _showResolveDialog(BuildContext context, ComplaintModel complaint) {
    final noteCtrl = TextEditingController(text: complaint.adminNote);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Resolve Complaint',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 17)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Category: ${complaint.category}',
                style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            Text(complaint.description,
                style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            TextField(
              controller: noteCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Admin Note (optional)',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('complaints')
                  .doc(complaint.id)
                  .update({
                'status': 'resolved',
                'adminNote': noteCtrl.text.trim(),
              });
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Mark Resolved'),
          ),
        ],
      ),
    );
  }

  void _reopenComplaint(String id) {
    FirebaseFirestore.instance
        .collection('complaints')
        .doc(id)
        .update({'status': 'open', 'adminNote': ''});
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Complaints'),
          automaticallyImplyLeading: false,
          bottom: TabBar(
            indicatorColor: Colors.white,
            labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
            unselectedLabelStyle: GoogleFonts.poppins(fontSize: 13),
            tabs: const [
              Tab(text: 'Open'),
              Tab(text: 'Resolved'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ComplaintList(status: 'open', onTap: (c) => _showResolveDialog(context, c)),
            _ComplaintList(
              status: 'resolved',
              onTap: (c) {},
              trailingBuilder: (c) => TextButton(
                onPressed: () => _reopenComplaint(c.id),
                child: Text('Reopen',
                    style: GoogleFonts.poppins(fontSize: 12, color: AppColors.warning)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComplaintList extends StatelessWidget {
  final String status;
  final void Function(ComplaintModel) onTap;
  final Widget Function(ComplaintModel)? trailingBuilder;

  const _ComplaintList({
    required this.status,
    required this.onTap,
    this.trailingBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('complaints')
          .where('status', isEqualTo: status)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                    status == 'open'
                        ? Icons.check_circle_outline_rounded
                        : Icons.inbox_rounded,
                    size: 72,
                    color: AppColors.textSecondary.withOpacity(0.4)),
                const SizedBox(height: 14),
                Text(
                  status == 'open'
                      ? 'No open complaints. 🎉'
                      : 'No resolved complaints yet.',
                  style: GoogleFonts.poppins(
                      color: AppColors.textSecondary, fontSize: 14),
                ),
              ],
            ),
          );
        }
        final complaints = snap.data!.docs
            .map((d) => ComplaintModel.fromDoc(d))
            .toList();
            
        // In-memory sort to bypass Firestore composite index requirement
        complaints.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: complaints.length,
          itemBuilder: (_, i) {
            final c = complaints[i];
            return GestureDetector(
              onTap: () => onTap(c),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(c.category,
                              style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w500)),
                        ),
                        const SizedBox(width: 8),
                        Text(DateFormat('dd MMM').format(c.createdAt),
                            style: GoogleFonts.poppins(
                                fontSize: 11, color: AppColors.textSecondary)),
                        const Spacer(),
                        if (trailingBuilder != null) trailingBuilder!(c),
                        if (status == 'open')
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text('Tap to Resolve',
                                style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    color: AppColors.warning,
                                    fontWeight: FontWeight.w600)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${c.residentName} • Flat ${c.flatNo}',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(c.description,
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            height: 1.4)),
                    if (c.adminNote.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.admin_panel_settings_rounded,
                                size: 14, color: AppColors.success),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text('Note: ${c.adminNote}',
                                  style: GoogleFonts.poppins(
                                      fontSize: 11, color: AppColors.success)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
