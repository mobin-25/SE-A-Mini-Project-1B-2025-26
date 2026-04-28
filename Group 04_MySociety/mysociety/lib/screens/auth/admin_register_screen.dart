import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class AdminRegisterScreen extends StatefulWidget {
  const AdminRegisterScreen({super.key});

  @override
  State<AdminRegisterScreen> createState() => _AdminRegisterScreenState();
}

class _AdminRegisterScreenState extends State<AdminRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _secretCtrl = TextEditingController();

  bool _loading = false;
  bool _obscure = true;
  bool _obscureConfirm = true;
  bool _obscureSecret = true;
  String _error = '';

  // A simple admin secret code — change this to your own secret
  static const _adminSecret = 'ADMIN2024';

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_secretCtrl.text.trim() != _adminSecret) {
      setState(() => _error = 'Invalid admin secret code.');
      return;
    }
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
      await FirebaseFirestore.instance
          .collection('users')
          .doc(cred.user!.uid)
          .set({
        'name': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'flatNo': 'Admin',
        'phone': '',
        'role': 'admin',
        'status': 'approved', // Admins are auto-approved
        'createdAt': FieldValue.serverTimestamp(),
      });
      // Stay signed in — AuthGate will route to AdminNav automatically
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = switch (e.code) {
          'email-already-in-use' => 'An account with this email already exists.',
          'weak-password' => 'Password is too weak (min 6 characters).',
          'invalid-email' => 'Please enter a valid email address.',
          _ => 'Registration failed: ${e.message}',
        };
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E3A5F), Color(0xFF0D1B2A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Header
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white),
                    ),
                    const SizedBox(width: 4),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Admin Registration',
                            style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                        Text('Society Administration Access',
                            style: GoogleFonts.poppins(
                                fontSize: 12, color: Colors.white60)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Admin Icon
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.adminAccent.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppColors.adminAccent.withOpacity(0.4),
                        width: 2),
                  ),
                  child: const Icon(Icons.admin_panel_settings_rounded,
                      size: 48, color: AppColors.adminAccent),
                ),
                const SizedBox(height: 24),

                // Form card
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Create Admin Account',
                            style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1E3A5F))),
                        const SizedBox(height: 4),
                        Text('Restricted access — admin secret required',
                            style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: AppColors.textSecondary)),
                        const SizedBox(height: 24),

                        // Name
                        TextFormField(
                          controller: _nameCtrl,
                          decoration: InputDecoration(
                            labelText: 'Full Name',
                            prefixIcon: const Icon(Icons.person_outline_rounded,
                                color: Color(0xFF1E3A5F)),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: Color(0xFF1E3A5F), width: 2),
                            ),
                          ),
                          validator: (v) => v == null || v.isEmpty
                              ? 'Enter your name'
                              : null,
                        ),
                        const SizedBox(height: 14),

                        // Email
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          autocorrect: false,
                          decoration: InputDecoration(
                            labelText: 'Email Address',
                            prefixIcon: const Icon(Icons.email_outlined,
                                color: Color(0xFF1E3A5F)),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: Color(0xFF1E3A5F), width: 2),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Enter your email';
                            }
                            final regex = RegExp(
                                r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');
                            if (!regex.hasMatch(v.trim())) {
                              return 'Enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Password
                        TextFormField(
                          controller: _passCtrl,
                          obscureText: _obscure,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outlined,
                                color: Color(0xFF1E3A5F)),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: Color(0xFF1E3A5F), width: 2),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                  _obscure
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: AppColors.textSecondary),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                          ),
                          validator: (v) => v == null || v.length < 6
                              ? 'Minimum 6 characters'
                              : null,
                        ),
                        const SizedBox(height: 14),

                        // Confirm Password
                        TextFormField(
                          controller: _confirmCtrl,
                          obscureText: _obscureConfirm,
                          decoration: InputDecoration(
                            labelText: 'Confirm Password',
                            prefixIcon: const Icon(Icons.lock_outlined,
                                color: Color(0xFF1E3A5F)),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: Color(0xFF1E3A5F), width: 2),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                  _obscureConfirm
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: AppColors.textSecondary),
                              onPressed: () => setState(
                                  () => _obscureConfirm = !_obscureConfirm),
                            ),
                          ),
                          validator: (v) => v != _passCtrl.text
                              ? 'Passwords do not match'
                              : null,
                        ),
                        const SizedBox(height: 14),

                        // Admin Secret Code
                        TextFormField(
                          controller: _secretCtrl,
                          obscureText: _obscureSecret,
                          decoration: InputDecoration(
                            labelText: 'Admin Secret Code',
                            hintText: 'Enter the admin access code',
                            prefixIcon: const Icon(Icons.key_rounded,
                                color: AppColors.adminAccent),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: AppColors.adminAccent, width: 2),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                  _obscureSecret
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: AppColors.textSecondary),
                              onPressed: () => setState(
                                  () => _obscureSecret = !_obscureSecret),
                            ),
                          ),
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Enter secret code' : null,
                        ),

                        if (_error.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline,
                                    color: AppColors.error, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(_error,
                                      style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: AppColors.error)),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),

                        // Register button
                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E3A5F),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _loading ? null : _register,
                            child: _loading
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2),
                                  )
                                : Text('Create Admin Account',
                                    style: GoogleFonts.poppins(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white)),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Info note
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.adminAccent.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline_rounded,
                                  color: AppColors.adminAccent, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Admin accounts get instant access without approval.',
                                  style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: AppColors.adminAccent),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _secretCtrl.dispose();
    super.dispose();
  }
}
