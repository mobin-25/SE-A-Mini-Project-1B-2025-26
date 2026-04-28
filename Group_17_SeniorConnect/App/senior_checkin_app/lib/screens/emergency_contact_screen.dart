import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/firebase_service.dart';
import '../services/auth_service.dart';
import '../providers/app_provider.dart';
import '../models/emergency_contact_model.dart';

const kPrimary  = Color(0xFF2D7DD2);
const kSuccess  = Color(0xFF27AE60);
const kDanger   = Color(0xFFE74C3C);
const kWarning  = Color(0xFFF39C12);
const kBg       = Color(0xFFF5F7FA);
const kCard     = Colors.white;
const kTextDark = Color(0xFF1A2535);
const kTextGrey = Color(0xFF7F8C9A);

class EmergencyContactScreen extends StatefulWidget {
  const EmergencyContactScreen({super.key});

  @override
  State<EmergencyContactScreen> createState() => _EmergencyContactScreenState();
}

class _EmergencyContactScreenState extends State<EmergencyContactScreen>
    with SingleTickerProviderStateMixin {
  List<EmergencyContact> _contacts = [];
  bool _isSaving = false;

  static const _prefsKey = 'emergency_contacts_v2';

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  // ── Persistence ─────────────────────────────────────────────────────────

  Future<void> _loadContacts() async {
    final prefs = await SharedPreferences.getInstance();

    // Try new multi-contact format first
    final raw = prefs.getString(_prefsKey);
    if (raw != null) {
      try {
        final list = (json.decode(raw) as List)
            .map((e) => EmergencyContact.fromMap(e as Map<String, dynamic>))
            .toList();
        if (mounted) setState(() => _contacts = list);
        return;
      } catch (_) {}
    }

    // Migrate single legacy contact
    final legacy = prefs.getString('emergency_contact') ?? '';
    if (legacy.isNotEmpty) {
      final migrated = [
        EmergencyContact(
          id: '0',
          name: 'Emergency Contact',
          phone: legacy,
          relation: 'Family',
        )
      ];
      setState(() => _contacts = migrated);
      _persistContacts(migrated);
    }

    // Also check provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final profile = context.read<AppProvider>().profile;
      if (profile != null &&
          profile.emergencyContact != null &&
          _contacts.isEmpty) {
        final migrated = [
          EmergencyContact(
            id: '0',
            name: 'Emergency Contact',
            phone: profile.emergencyContact!,
            relation: 'Family',
          )
        ];
        setState(() => _contacts = migrated);
        _persistContacts(migrated);
      }
    });
  }

  Future<void> _persistContacts(List<EmergencyContact> contacts) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(contacts.map((c) => c.toMap()).toList());
    await prefs.setString(_prefsKey, encoded);

    // Also keep the first contact in legacy key for backward compat (SOS etc)
    if (contacts.isNotEmpty) {
      await prefs.setString('emergency_contact', contacts.first.phone);
    } else {
      await prefs.remove('emergency_contact');
    }

    // Save to Firebase
    final uid = AuthService.uid;
    if (uid != null) {
      await FirebaseService.updateProfile(uid, {
        'emergencyContacts': contacts.map((c) => c.toMap()).toList(),
        'emergencyContact': contacts.isNotEmpty ? contacts.first.phone : null,
      });
      if (mounted) {
        context.read<AppProvider>().updateEmergencyContact(
            contacts.isNotEmpty ? contacts.first.phone : '');
      }
    }
  }

  // ── Add / Edit dialog ────────────────────────────────────────────────────

  void _showAddEditDialog({EmergencyContact? existing}) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    String relation = existing?.relation ?? 'Family';

    final relations = ['Family', 'Son', 'Daughter', 'Spouse', 'Doctor', 'Friend', 'Other'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: kDanger.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_add_rounded, color: kDanger, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      existing == null ? 'Add Contact' : 'Edit Contact',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w800, color: kTextDark),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Name field
                _buildInputLabel('Full Name'),
                const SizedBox(height: 8),
                _dialogTextField(nameCtrl, 'e.g. Rahul Sharma', Icons.person_outline_rounded, false),
                const SizedBox(height: 16),

                // Phone field
                _buildInputLabel('Phone Number'),
                const SizedBox(height: 8),
                _dialogTextField(phoneCtrl, '+91 98765 43210', Icons.phone_outlined, true),
                const SizedBox(height: 16),

                // Relation chips
                _buildInputLabel('Relation'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: relations.map((r) {
                    final sel = relation == r;
                    return GestureDetector(
                      onTap: () => setS(() => relation = r),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: sel ? kDanger : kBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: sel ? kDanger : const Color(0xFFDDE3EC),
                          ),
                        ),
                        child: Text(
                          r,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: sel ? Colors.white : kTextGrey,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 28),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final name = nameCtrl.text.trim();
                          final phone = phoneCtrl.text.trim();
                          if (name.isEmpty || phone.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Name and phone are required')),
                            );
                            return;
                          }
                          Navigator.pop(ctx);
                          setState(() => _isSaving = true);

                          final newContact = EmergencyContact(
                            id: existing?.id ??
                                DateTime.now().millisecondsSinceEpoch.toString(),
                            name: name,
                            phone: phone,
                            relation: relation,
                          );

                          List<EmergencyContact> updated;
                          if (existing != null) {
                            updated = _contacts
                                .map((c) => c.id == existing.id ? newContact : c)
                                .toList();
                          } else {
                            updated = [..._contacts, newContact];
                          }

                          await _persistContacts(updated);
                          setState(() {
                            _contacts = updated;
                            _isSaving = false;
                          });
                          if (mounted) _showSavedSnack();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kDanger,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                        ),
                        child: Text(
                          existing == null ? 'Add' : 'Save',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String text) => Text(
        text,
        style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w700, color: kTextGrey),
      );

  Widget _dialogTextField(
      TextEditingController ctrl, String hint, IconData icon, bool isPhone) {
    return Container(
      decoration: BoxDecoration(
        color: kBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDE3EC)),
      ),
      child: TextField(
        controller: ctrl,
        keyboardType: isPhone ? TextInputType.phone : TextInputType.name,
        inputFormatters: isPhone ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\- ]'))] : [],
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: kTextDark),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(fontSize: 14, color: kTextGrey.withOpacity(0.6)),
          prefixIcon: Icon(icon, color: kTextGrey, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Future<void> _deleteContact(EmergencyContact contact) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Remove Contact?', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text('Remove ${contact.name} from emergency contacts?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove', style: TextStyle(color: kDanger)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final updated = _contacts.where((c) => c.id != contact.id).toList();
      await _persistContacts(updated);
      setState(() => _contacts = updated);
    }
  }

  void _showSavedSnack() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: kSuccess,
        duration: const Duration(seconds: 2),
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white),
            SizedBox(width: 10),
            Text('Contact saved!',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Color _relationColor(String relation) {
    switch (relation) {
      case 'Doctor':   return const Color(0xFF2D7DD2);
      case 'Son':
      case 'Daughter': return const Color(0xFF8E44AD);
      case 'Spouse':   return const Color(0xFFE91E8C);
      case 'Friend':   return const Color(0xFF16A085);
      default:         return kDanger;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Emergency\nContacts',
                              style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: kTextDark,
                                  height: 1.2),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'People to call in an emergency',
                              style: TextStyle(fontSize: 13, color: kTextGrey),
                            ),
                          ],
                        ),
                      ),
                      // Contact count badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: kDanger.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.contacts_rounded, color: kDanger, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              '${_contacts.length}',
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: kDanger),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ── Info Banner ──────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3CD),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFFFE69C)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            color: Color(0xFF856404), size: 18),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'First contact gets the SOS call. All contacts receive alerts.',
                            style: TextStyle(fontSize: 12, color: Color(0xFF664D03)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),

            // ── Contact List ───────────────────────────────────────────────
            Expanded(
              child: _contacts.isEmpty
                  ? _buildEmptyState()
                  : ReorderableListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _contacts.length,
                      onReorder: (oldIndex, newIndex) async {
                        if (newIndex > oldIndex) newIndex--;
                        final updated = List<EmergencyContact>.from(_contacts);
                        final item = updated.removeAt(oldIndex);
                        updated.insert(newIndex, item);
                        setState(() => _contacts = updated);
                        await _persistContacts(updated);
                      },
                      itemBuilder: (context, i) {
                        final contact = _contacts[i];
                        final isFirst = i == 0;
                        final relColor = _relationColor(contact.relation);
                        return _ContactCard(
                          key: ValueKey(contact.id),
                          contact: contact,
                          isFirst: isFirst,
                          relColor: relColor,
                          onEdit: () => _showAddEditDialog(existing: contact),
                          onDelete: () => _deleteContact(contact),
                          onCall: () =>
                              launchUrl(Uri(scheme: 'tel', path: contact.phone)),
                        );
                      },
                    ),
            ),

            // ── Add Button ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : () => _showAddEditDialog(),
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.add_rounded, size: 22),
                  label: Text(
                    _isSaving ? 'Saving...' : 'Add Emergency Contact',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kDanger,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                    elevation: 0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 110, height: 110,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE74C3C), Color(0xFFFF6B6B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: kDanger.withOpacity(0.3), blurRadius: 24, offset: const Offset(0, 8))
              ],
            ),
            child: const Icon(Icons.phone_in_talk_rounded, color: Colors.white, size: 52),
          ),
          const SizedBox(height: 24),
          const Text('No contacts yet',
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w800, color: kTextDark)),
          const SizedBox(height: 8),
          const Text(
            'Add a family member or trusted\ncaregiver as emergency contact',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: kTextGrey, height: 1.5),
          ),
        ],
      ),
    );
  }
}

// ── Contact Card Widget ───────────────────────────────────────────────────────

class _ContactCard extends StatelessWidget {
  final EmergencyContact contact;
  final bool isFirst;
  final Color relColor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onCall;

  const _ContactCard({
    super.key,
    required this.contact,
    required this.isFirst,
    required this.relColor,
    required this.onEdit,
    required this.onDelete,
    required this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(20),
        border: isFirst
            ? Border.all(color: kDanger.withOpacity(0.3), width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: relColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: relColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          contact.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: kTextDark,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isFirst)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: kDanger,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'PRIMARY',
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.5),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    contact.phone,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: kTextGrey,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: relColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      contact.relation.isEmpty ? 'Contact' : contact.relation,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: relColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Action buttons
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ActionBtn(
                  icon: Icons.phone_rounded,
                  color: kSuccess,
                  onTap: onCall,
                ),
                const SizedBox(height: 8),
                _ActionBtn(
                  icon: Icons.edit_rounded,
                  color: kPrimary,
                  onTap: onEdit,
                ),
                const SizedBox(height: 8),
                _ActionBtn(
                  icon: Icons.delete_outline_rounded,
                  color: kDanger,
                  onTap: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34, height: 34,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 17),
      ),
    );
  }
}