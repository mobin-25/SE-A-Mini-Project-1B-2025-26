import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/websocket_service.dart';
import 'admin_dashboard.dart';
import 'client_dashboard.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool   _loading = false;
  bool   _obscure = true;
  String _error   = '';

  static const Color _bg   = Color(0xFF071E27);
  static const Color _cyan = Color(0xFF00E5FF);

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final u = _userCtrl.text.trim();
    final p = _passCtrl.text.trim();
    if (u.isEmpty || p.isEmpty) {
      setState(() => _error = 'Please enter username and password');
      return;
    }
    setState(() { _loading = true; _error = ''; });
    final res = await ApiService().login(u, p);
    if (!mounted) return;
    setState(() => _loading = false);

    if (res['success'] == true) {
      final token   = res['token']    as String;
      final isAdmin = res['is_admin'] as bool;
      AuthService().login(u, isAdmin, token);
      if (isAdmin) {
        WebSocketService().connectAdmin(token);
        Navigator.pushReplacement(context,
            MaterialPageRoute<void>(builder: (_) => const AdminDashboard()));
      } else {
        WebSocketService().connectClient(u, token);
        Navigator.pushReplacement(context,
            MaterialPageRoute<void>(builder: (_) => ClientDashboard(username: u)));
      }
    } else {
      final err = res['error'] as String? ?? 'Login failed';
      setState(() => _error = err == 'BLOCKED'
          ? 'Your account has been blocked by admin'
          : err);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  width: 90, height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _cyan.withOpacity(0.1),
                    border: Border.all(color: _cyan.withOpacity(0.5), width: 2),
                  ),
                  child: const Icon(Icons.security_rounded, color: _cyan, size: 44),
                ),
                const SizedBox(height: 20),
                const Text('UniAccess',
                    style: TextStyle(color: Colors.white, fontSize: 28,
                        fontWeight: FontWeight.bold, letterSpacing: 1)),
                const SizedBox(height: 6),
                Text('Network Access Control',
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14)),
                const SizedBox(height: 40),

                // Username
                _Field(
                  controller: _userCtrl,
                  label: 'Username',
                  icon: Icons.person_rounded,
                ),
                const SizedBox(height: 16),

                // Password
                _Field(
                  controller: _passCtrl,
                  label: 'Password',
                  icon: Icons.lock_rounded,
                  obscure: _obscure,
                  suffix: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off_rounded
                                        : Icons.visibility_rounded,
                        color: Colors.white38, size: 20),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  onSubmit: (_) => _login(),
                ),
                const SizedBox(height: 12),

                // Error
                if (_error.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
                    ),
                    child: Text(_error,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                        textAlign: TextAlign.center),
                  ),
                if (_error.isNotEmpty) const SizedBox(height: 12),

                // Login button
                SizedBox(
                  width: double.infinity, height: 54,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _login,
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
                        : const Text('Login',
                            style: TextStyle(fontSize: 16,
                                fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 20),

                // Register link
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text("Don't have an account? ",
                      style: TextStyle(color: Colors.white.withOpacity(0.5))),
                  GestureDetector(
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute<void>(builder: (_) => const RegisterScreen())),
                    child: const Text('Register',
                        style: TextStyle(color: _cyan, fontWeight: FontWeight.bold)),
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
  final TextEditingController controller;
  final String    label;
  final IconData  icon;
  final bool      obscure;
  final Widget?   suffix;
  final void Function(String)? onSubmit;

  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscure = false,
    this.suffix,
    this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller:    controller,
      obscureText:   obscure,
      onSubmitted:   onSubmit,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText:      label,
        labelStyle:     TextStyle(color: Colors.white.withOpacity(0.5)),
        prefixIcon:     Icon(icon, color: const Color(0xFF00E5FF), size: 20),
        suffixIcon:     suffix,
        filled:         true,
        fillColor:      const Color(0xFF0C2F3C),
        border:         OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        focusedBorder:  OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF00E5FF), width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}