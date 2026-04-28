import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _userCtrl  = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _pass2Ctrl = TextEditingController();
  bool   _loading  = false;
  bool   _obscure1 = true;
  bool   _obscure2 = true;
  String _error    = '';

  static const Color _bg   = Color(0xFF071E27);
  static const Color _cyan = Color(0xFF00E5FF);

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    _pass2Ctrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final u  = _userCtrl.text.trim();
    final p  = _passCtrl.text.trim();
    final p2 = _pass2Ctrl.text.trim();

    if (u.isEmpty || p.isEmpty || p2.isEmpty) {
      setState(() => _error = 'Please fill all fields');
      return;
    }
    if (u.length < 3) {
      setState(() => _error = 'Username must be at least 3 characters');
      return;
    }
    if (p.length < 4) {
      setState(() => _error = 'Password must be at least 4 characters');
      return;
    }
    if (p != p2) {
      setState(() => _error = 'Passwords do not match');
      return;
    }

    setState(() { _loading = true; _error = ''; });
    final res = await ApiService().register(u, p);
    if (!mounted) return;
    setState(() => _loading = false);

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Registered successfully! Please login.'),
        backgroundColor: Colors.green,
      ));
      Navigator.pop(context);
    } else {
      setState(() => _error = res['error'] as String? ?? 'Register failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Create Account',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _cyan.withOpacity(0.1),
                    border: Border.all(color: _cyan.withOpacity(0.5), width: 2),
                  ),
                  child: const Icon(Icons.person_add_rounded, color: _cyan, size: 38),
                ),
                const SizedBox(height: 24),
                const Text('Register',
                    style: TextStyle(color: Colors.white, fontSize: 24,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text('Create your UniAccess account',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.5), fontSize: 13)),
                const SizedBox(height: 32),

                _Field(controller: _userCtrl, label: 'Username',
                    icon: Icons.person_rounded),
                const SizedBox(height: 16),

                _Field(controller: _passCtrl, label: 'Password',
                    icon: Icons.lock_rounded, obscure: _obscure1,
                    suffix: IconButton(
                      icon: Icon(_obscure1 ? Icons.visibility_off_rounded
                                           : Icons.visibility_rounded,
                          color: Colors.white38, size: 20),
                      onPressed: () => setState(() => _obscure1 = !_obscure1),
                    )),
                const SizedBox(height: 16),

                _Field(controller: _pass2Ctrl, label: 'Confirm Password',
                    icon: Icons.lock_outline_rounded, obscure: _obscure2,
                    suffix: IconButton(
                      icon: Icon(_obscure2 ? Icons.visibility_off_rounded
                                           : Icons.visibility_rounded,
                          color: Colors.white38, size: 20),
                      onPressed: () => setState(() => _obscure2 = !_obscure2),
                    ),
                    onSubmit: (_) => _register()),
                const SizedBox(height: 12),

                if (_error.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: Colors.redAccent.withOpacity(0.4)),
                    ),
                    child: Text(_error,
                        style: const TextStyle(
                            color: Colors.redAccent, fontSize: 13),
                        textAlign: TextAlign.center),
                  ),
                  const SizedBox(height: 12),
                ],

                SizedBox(
                  width: double.infinity, height: 54,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _cyan,
                      foregroundColor: Colors.black,
                      disabledBackgroundColor: _cyan.withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: _loading
                        ? const SizedBox(width: 24, height: 24,
                            child: CircularProgressIndicator(
                                color: Colors.black, strokeWidth: 2.5))
                        : const Text('Register',
                            style: TextStyle(fontSize: 16,
                                fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 20),

                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('Already have an account? ',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.5))),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text('Login',
                        style: TextStyle(
                            color: _cyan, fontWeight: FontWeight.bold)),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController      controller;
  final String                     label;
  final IconData                   icon;
  final bool                       obscure;
  final Widget?                    suffix;
  final void Function(String)?     onSubmit;

  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscure  = false,
    this.suffix,
    this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller:  controller,
      obscureText: obscure,
      onSubmitted: onSubmit,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText:  label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
        prefixIcon: Icon(icon, color: const Color(0xFF00E5FF), size: 20),
        suffixIcon: suffix,
        filled:     true,
        fillColor:  const Color(0xFF0C2F3C),
        border:     OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
                color: Color(0xFF00E5FF), width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 16),
      ),
    );
  }
}