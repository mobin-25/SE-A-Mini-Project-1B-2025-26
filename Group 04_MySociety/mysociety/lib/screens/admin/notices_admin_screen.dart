import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';

class NoticesAdminScreen extends StatefulWidget {
  const NoticesAdminScreen({super.key});

  @override
  State<NoticesAdminScreen> createState() => _NoticesAdminScreenState();
}

class _NoticesAdminScreenState extends State<NoticesAdminScreen> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  bool _posting = false;

  Future<void> _postNotice() async {
    if (_titleCtrl.text.trim().isEmpty || _bodyCtrl.text.trim().isEmpty) return;
    setState(() => _posting = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final adminName = (userDoc.data() as Map<String, dynamic>)['name'] ?? 'Admin';
      await FirebaseFirestore.instance.collection('notices').add({
        'title': _titleCtrl.text.trim(),
        'body': _bodyCtrl.text.trim(),
        'postedBy': adminName,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _titleCtrl.clear();
      _bodyCtrl.clear();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Notice posted successfully!'),
              backgroundColor: AppColors.success),
        );
      }
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  void _showPostDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(16),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          left: 24,
          right: 24,
          top: 24,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.campaign_rounded, color: AppColors.primary),
                const SizedBox(width: 8),
                Text('Post Notice',
                    style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary)),
                const Spacer(),
                IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded)),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Notice Title'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _bodyCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Notice Content',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _posting ? null : _postNotice,
              icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
              label: _posting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Post Notice'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Manage Notices'),
        automaticallyImplyLeading: false,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showPostDialog,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text('Post Notice',
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notices')
            .orderBy('createdAt', descending: true)
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
                  Icon(Icons.campaign_outlined,
                      size: 72,
                      color: AppColors.textSecondary.withOpacity(0.4)),
                  const SizedBox(height: 14),
                  Text('No notices posted yet.',
                      style: GoogleFonts.poppins(
                          color: AppColors.textSecondary, fontSize: 14)),
                ],
              ),
            );
          }
          final notices =
              snap.data!.docs.map((d) => NoticeModel.fromDoc(d)).toList();
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: notices.length,
            itemBuilder: (_, i) {
              final n = notices[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
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
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(n.title,
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: AppColors.textPrimary)),
                          ),
                          IconButton(
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: Text('Delete Notice',
                                      style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold)),
                                  content: Text(
                                      'Are you sure you want to delete this notice?',
                                      style: GoogleFonts.poppins(fontSize: 13)),
                                  actions: [
                                    TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: const Text('Cancel')),
                                    TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        child: const Text('Delete',
                                            style: TextStyle(
                                                color: AppColors.error))),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await FirebaseFirestore.instance
                                    .collection('notices')
                                    .doc(n.id)
                                    .delete();
                              }
                            },
                            icon: const Icon(Icons.delete_outline_rounded,
                                color: AppColors.error, size: 20),
                          ),
                        ],
                      ),
                      Text(n.body,
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              height: 1.5)),
                      const SizedBox(height: 8),
                      Text(
                        DateFormat('dd MMM yyyy, hh:mm a').format(n.createdAt),
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }
}
