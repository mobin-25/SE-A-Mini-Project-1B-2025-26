import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/demo_service.dart';
import '../services/auth_service.dart';

const kPrimary  = Color(0xFF2D7DD2);
const kBg       = Color(0xFFF5F7FA);
const kTextDark = Color(0xFF1A2535);
const kTextGrey = Color(0xFF7F8C9A);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nameController = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _continue() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) { setState(() => _error = 'Please enter your name'); return; }
    setState(() { _loading = true; _error = null; });
    await context.read<AppProvider>().completeOnboarding(name);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadDemoProfile() async {
    setState(() { _loading = true; _error = null; });
    
    // Sign in first to get UID
    final uid = await AuthService.signInAnonymously();
    if (uid != null) {
      // Load all the demo data into Firestore/Prefs
      await DemoService.populateDemoData(uid);
    }
    
    // Complete onboarding which tells provider we are done
    if (mounted) {
      await context.read<AppProvider>().completeOnboarding('Demo Senior');
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() { _nameController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              // Icon
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF2D7DD2), Color(0xFF5BA4E8)]),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 44),
              ),
              const SizedBox(height: 28),
              const Text('Welcome to\nCareCheck', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: kTextDark, height: 1.1)),
              const SizedBox(height: 12),
              const Text('Your personal health companion.\nStay safe, stay connected.', style: TextStyle(fontSize: 16, color: kTextGrey, height: 1.5)),
              const SizedBox(height: 48),
              const Text('What should we call you?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kTextDark)),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 14, offset: const Offset(0, 4))],
                ),
                child: TextField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: kTextDark),
                  decoration: InputDecoration(
                    hintText: 'Your name',
                    hintStyle: TextStyle(color: kTextGrey.withOpacity(0.6)),
                    prefixIcon: const Icon(Icons.person_rounded, color: kPrimary),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  ),
                  onSubmitted: (_) => _continue(),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: Color(0xFFE74C3C), fontSize: 13)),
              ],
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _continue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary, foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    elevation: 0,
                  ),
                  child: _loading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : const Text('Get Started', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _loading ? null : _loadDemoProfile,
                  icon: const Icon(Icons.auto_awesome_rounded, size: 20),
                  label: const Text('Try Demo Profile'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF8E44AD),
                    side: const BorderSide(color: Color(0xFF8E44AD), width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'No account needed. Your data stays private on your device\nand syncs securely to the cloud.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: kTextGrey.withOpacity(0.8), height: 1.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}