import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:qr_flutter/qr_flutter.dart';

const String baseUrl = 'http://10.165.205.124:5000';

String? globalStudentId;
String? globalStudentName;
String? globalUserRole;
String? globalAdminEmail;

void main() {
  runApp(const LinelessApp());
}

class LinelessTheme {
  static const Color primary = Color(0xFF4A4E69);
  static const Color background = Color(0xFFF9F9F4);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF22223B);
  static const Color textSecondary = Color(0xFF9A8C98);
  static const Color success = Color(0xFF6B9080);
  static const Color danger = Color(0xFFE07A5F);
}

class LinelessApp extends StatelessWidget {
  const LinelessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lineless',
      theme: ThemeData(
        scaffoldBackgroundColor: LinelessTheme.background,
        colorScheme: ColorScheme.fromSeed(seedColor: LinelessTheme.primary),
        textTheme: GoogleFonts.plusJakartaSansTextTheme(),
        useMaterial3: true,
      ),
      home: const LoginSelectionScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// ==================== LOGIN SELECTION ====================
class LoginSelectionScreen extends StatelessWidget {
  const LoginSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: LinelessTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(Icons.grid_view_rounded, size: 40, color: LinelessTheme.primary),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Lineless', textAlign: TextAlign.center, style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: LinelessTheme.textPrimary)),
              const Text('Enterprise Student Portal', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: LinelessTheme.textSecondary)),
              const SizedBox(height: 80),
              const Text('Select Login Type', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: LinelessTheme.textPrimary)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: LinelessTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.person_rounded),
                label: const Text('Student Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentLoginScreen()));
                },
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: LinelessTheme.primary, width: 2),
                  foregroundColor: LinelessTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.admin_panel_settings_rounded),
                label: const Text('Admin Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminLoginScreen()));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== STUDENT LOGIN ====================
class StudentLoginScreen extends StatefulWidget {
  const StudentLoginScreen({super.key});

  @override
  State<StudentLoginScreen> createState() => _StudentLoginScreenState();
}

class _StudentLoginScreenState extends State<StudentLoginScreen> {
  final _idController = TextEditingController();
  final _pinController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
  if (_idController.text.isEmpty || _pinController.text.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please enter Student ID and PIN')),
    );
    return;
  }

  setState(() => _isLoading = true);
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'student_id': _idController.text,
        'pin': _pinController.text,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        globalStudentId = data['user']['id'].toString();
        globalStudentName = data['user']['name'];
        globalUserRole = 'student';
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainDashboard()),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? 'Login failed')),
          );
        }
      }
    } else {
      final data = jsonDecode(response.body);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Invalid credentials')),
        );
      }
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection error: $e')),
      );
    }
  }
  setState(() => _isLoading = false);
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: LinelessTheme.background, elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Student Authentication', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
              const SizedBox(height: 24),
              TextField(
                controller: _idController,
                keyboardType: TextInputType.number,
                maxLength: 8,
                decoration: const InputDecoration(
                  labelText: 'University Student ID',
                  hintText: 'e.g. 24107095',
                  prefixIcon: Icon(Icons.badge_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  filled: true,
                  fillColor: LinelessTheme.surface,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'Access PIN',
                  hintText: 'Enter 6-digit PIN',
                  prefixIcon: Icon(Icons.lock_outline_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  filled: true,
                  fillColor: LinelessTheme.surface,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: LinelessTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isLoading ? null : _login,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Authenticate Identity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
              // NEW: Registration Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Don't have an account? ",
                    style: TextStyle(color: LinelessTheme.textSecondary),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegistrationScreen()),
                      );
                    },
                    child: const Text(
                      'Register',
                      style: TextStyle(
                        color: LinelessTheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== REGISTRATION SCREEN ====================
class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _studentIdController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePin = true;
  bool _obscureConfirmPin = true;

  @override
  void dispose() {
    _studentIdController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_pinController.text != _confirmPinController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PINs do not match'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'student_id': _studentIdController.text,
          'name': _nameController.text,
          'email': _emailController.text,
          'phone': _phoneController.text.isEmpty ? null : _phoneController.text,
          'pin': _pinController.text,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registration successful! Please login.'), backgroundColor: Colors.green),
          );
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? 'Registration failed'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: LinelessTheme.background,
        elevation: 0,
      ),
      backgroundColor: LinelessTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Student Registration', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: LinelessTheme.textPrimary)),
                const SizedBox(height: 8),
                const Text('Create your Lineless account', style: TextStyle(fontSize: 14, color: LinelessTheme.textSecondary)),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _studentIdController,
                  keyboardType: TextInputType.number,
                  maxLength: 8,
                  decoration: const InputDecoration(
                    labelText: 'University Student ID',
                    hintText: 'Enter 8-digit ID',
                    prefixIcon: Icon(Icons.badge_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                    filled: true,
                    fillColor: Colors.white,
                    counterText: '',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Student ID is required';
                    if (value.length != 8 || !RegExp(r'^\d+$').hasMatch(value)) return 'Student ID must be 8 digits';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    hintText: 'Enter your full name',
                    prefixIcon: Icon(Icons.person_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Name is required';
                    if (value.length < 3) return 'Name must be at least 3 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    hintText: 'your.email@example.com',
                    prefixIcon: Icon(Icons.email_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Email is required';
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number (Optional)',
                    hintText: '+91 9876543210',
                    prefixIcon: Icon(Icons.phone_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _pinController,
                  obscureText: _obscurePin,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: InputDecoration(
                    labelText: 'Create 6-digit PIN',
                    hintText: 'Enter 6-digit PIN',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePin ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscurePin = !_obscurePin),
                    ),
                    border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                    filled: true,
                    fillColor: Colors.white,
                    counterText: '',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'PIN is required';
                    if (value.length != 6 || !RegExp(r'^\d+$').hasMatch(value)) return 'PIN must be 6 digits';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPinController,
                  obscureText: _obscureConfirmPin,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: InputDecoration(
                    labelText: 'Confirm PIN',
                    hintText: 'Re-enter 6-digit PIN',
                    prefixIcon: const Icon(Icons.lock_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirmPin ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscureConfirmPin = !_obscureConfirmPin),
                    ),
                    border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                    filled: true,
                    fillColor: Colors.white,
                    counterText: '',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please confirm your PIN';
                    if (value != _pinController.text) return 'PINs do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LinelessTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isLoading ? null : _register,
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Create Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account? ', style: TextStyle(color: LinelessTheme.textSecondary)),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Login', style: TextStyle(color: LinelessTheme.primary, fontWeight: FontWeight.bold)),
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
}

// ==================== ADMIN LOGIN ====================
class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _emailController = TextEditingController(text: 'admin@apsit.edu.in');
  final _passwordController = TextEditingController(text: 'admin123');
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/admin/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text,
          'password': _passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          globalAdminEmail = data['user']['email'];
          globalStudentName = data['user']['name'];
          globalUserRole = 'admin';
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const AdminDashboard()),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid admin credentials')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: LinelessTheme.background, elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Admin Authentication', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
              const SizedBox(height: 24),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Admin Email',
                  prefixIcon: Icon(Icons.email_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  filled: true,
                  fillColor: LinelessTheme.surface,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock_outline_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  filled: true,
                  fillColor: LinelessTheme.surface,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: LinelessTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isLoading ? null : _login,
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Admin Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== MAIN DASHBOARD (STUDENT) ====================
class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});
  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  List<dynamic> _tokens = [];

  @override
  void initState() {
    super.initState();
    _fetchTokens();
  }

  Future<void> _fetchTokens() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/tokens?student_id=$globalStudentId'));
      if (res.statusCode == 200) {
        setState(() => _tokens = jsonDecode(res.body)['tokens']);
      }
    } catch (e) {
      print('Error fetching tokens: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: LinelessTheme.background,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Lineless', style: TextStyle(fontWeight: FontWeight.w900, color: LinelessTheme.textPrimary)),
            Text('Campus Service Portal', style: TextStyle(fontSize: 12, color: LinelessTheme.textSecondary)),
          ],
        ),
        actions: [
          CircleAvatar(
            backgroundColor: LinelessTheme.primary,
            child: Text(globalStudentName?.substring(0, 2).toUpperCase() ?? 'ST', style: const TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 20)
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchTokens,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [LinelessTheme.primary, Color(0xFF22223B)]),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Active Queues', style: TextStyle(color: Colors.white70)),
                      Text('${_tokens.where((t) => t['status'] == 'ACTIVE').length} Services', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                  const Icon(Icons.confirmation_number_rounded, color: Colors.white, size: 40)
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text('Your Recent Tokens', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: LinelessTheme.textPrimary)),
            const SizedBox(height: 16),
            ..._tokens.map((token) => _buildTokenCard(token)).toList(),
            if (_tokens.isEmpty) const Text("No tokens generated yet.", style: TextStyle(color: LinelessTheme.textSecondary)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const ServiceSelectionScreen()));
          _fetchTokens();
        },
        backgroundColor: LinelessTheme.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('New Token', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildTokenCard(dynamic token) {
    bool isActive = token['status'] == 'ACTIVE';
    bool isCompleted = token['status'] == 'COMPLETED';

    Color statusColor = isActive ? const Color(0xFFE8F5E9) : isCompleted ? const Color(0xFFE3F2FD) : const Color(0xFFFFF3E0);
    Color statusTextColor = isActive ? Colors.green.shade800 : isCompleted ? Colors.blue.shade800 : Colors.orange.shade800;

    return InkWell(
      onTap: isActive
          ? () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => TokenDetailScreen(token: token)));
              _fetchTokens();
            }
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: LinelessTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: LinelessTheme.background, borderRadius: BorderRadius.circular(12)),
              child: Text(token['id'].split('-')[1].substring(0, 3), style: const TextStyle(fontWeight: FontWeight.bold, color: LinelessTheme.primary)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(token['service_name'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  Text(token['display_time'] ?? token['created_at'], style: const TextStyle(fontSize: 12, color: LinelessTheme.textSecondary)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(20)),
              child: Text(token['status'], style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusTextColor)),
            )
          ],
        ),
      ),
    );
  }
}

// ==================== SERVICE SELECTION ====================
class ServiceSelectionScreen extends StatefulWidget {
  const ServiceSelectionScreen({super.key});
  @override
  State<ServiceSelectionScreen> createState() => _ServiceSelectionScreenState();
}

class _ServiceSelectionScreenState extends State<ServiceSelectionScreen> {
  List<dynamic> _services = [];

  @override
  void initState() {
    super.initState();
    _fetchServices();
  }

  Future<void> _fetchServices() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/services'));
      if (res.statusCode == 200) {
        setState(() => _services = jsonDecode(res.body)['services']);
      }
    } catch (e) {
      print('Error fetching services: $e');
    }
  }

  IconData _getIcon(String name) {
    switch (name) {
      case 'school':
        return Icons.school_rounded;
      case 'train':
        return Icons.train_rounded;
      case 'payments':
        return Icons.payments_rounded;
      default:
        return Icons.description_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Available Services'), backgroundColor: LinelessTheme.background),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _services.length,
        itemBuilder: (context, index) {
          final s = _services[index];
          int queueCount = s['queue_count'] ?? 0;

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            color: LinelessTheme.surface,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: LinelessTheme.background, borderRadius: BorderRadius.circular(12)),
                child: Icon(_getIcon(s['icon']), color: LinelessTheme.primary),
              ),
              title: Text(s['name'], style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s['desc']),
                  const SizedBox(height: 4),
                  Text('$queueCount in queue', style: TextStyle(fontSize: 12, color: queueCount > 0 ? LinelessTheme.primary : LinelessTheme.textSecondary, fontWeight: FontWeight.w600)),
                ],
              ),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: LinelessTheme.primary, foregroundColor: Colors.white),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => TokenGenerationScreen(serviceName: s['name'])));
                },
                child: const Text('Select'),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ==================== TOKEN GENERATION (WITH POPUPS) ====================
class TokenGenerationScreen extends StatefulWidget {
  final String serviceName;
  const TokenGenerationScreen({super.key, required this.serviceName});

  @override
  State<TokenGenerationScreen> createState() => _TokenGenerationScreenState();
}

class _TokenGenerationScreenState extends State<TokenGenerationScreen> {
  bool _isLoading = false;

  Future<void> _generateToken() async {
    setState(() => _isLoading = true);
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/tokens'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'student_id': globalStudentId,
          'service_name': widget.serviceName,
        }),
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 201 && data['success'] == true) {
        // SUCCESS POPUP
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.check_circle, color: LinelessTheme.success, size: 28),
                  SizedBox(width: 12),
                  Text('Token Generated!'),
                ],
              ),
              content: Text(data['message'] ?? 'Your token has been generated successfully!'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Go back to services
                    Navigator.pop(context); // Go back to dashboard
                  },
                  child: const Text('OK', style: TextStyle(color: LinelessTheme.primary, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        }
      } else {
        // ERROR POPUP
        String errorMessage = data['message'] ?? 'Failed to generate token';
        String? errorType = data['error_type'];

        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Row(
                children: [
                  Icon(
                    errorType == 'limit_reached' ? Icons.block : Icons.warning,
                    color: LinelessTheme.danger,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(errorType == 'limit_reached' ? 'Limit Reached!' : 'Cannot Generate Token'),
                ],
              ),
              content: Text(errorMessage),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK', style: TextStyle(color: LinelessTheme.primary, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connection error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.serviceName), backgroundColor: LinelessTheme.background),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Confirm Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            TextField(
              controller: TextEditingController(text: globalStudentName),
              readOnly: true,
              decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder(), filled: true, fillColor: LinelessTheme.surface),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: TextEditingController(text: globalStudentId),
              readOnly: true,
              decoration: const InputDecoration(labelText: 'Student ID', border: OutlineInputBorder(), filled: true, fillColor: LinelessTheme.surface),
            ),
            const Spacer(),
            ElevatedButton.icon(
              icon: const Icon(Icons.qr_code_2_rounded),
              label: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Generate Queue Token', style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: LinelessTheme.textPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isLoading ? null : _generateToken,
            )
          ],
        ),
      ),
    );
  }
}

// ==================== TOKEN DETAIL ====================
class TokenDetailScreen extends StatefulWidget {
  final dynamic token;
  const TokenDetailScreen({super.key, required this.token});

  @override
  State<TokenDetailScreen> createState() => _TokenDetailScreenState();
}

class _TokenDetailScreenState extends State<TokenDetailScreen> {
  Future<void> _cancelToken(BuildContext context) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Token?'),
        content: const Text('Are you sure you want to cancel this token? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Cancel', style: TextStyle(color: LinelessTheme.danger)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final res = await http.post(Uri.parse('$baseUrl/tokens/${widget.token['id']}/cancel'));
      if (res.statusCode == 200 && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Token cancelled successfully'), backgroundColor: LinelessTheme.danger),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Token Detail'), backgroundColor: LinelessTheme.background),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: LinelessTheme.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.shade200)),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('TOKEN ID', style: TextStyle(fontSize: 12, color: LinelessTheme.textSecondary)),
                          Text(widget.token['id'], style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: LinelessTheme.primary)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(20)),
                        child: Text(widget.token['status'], style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade800)),
                      )
                    ],
                  ),
                  const Divider(height: 32),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Service'), Text(widget.token['service_name'], style: const TextStyle(fontWeight: FontWeight.bold))]),
                  const SizedBox(height: 12),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Name'), Text(globalStudentName ?? '', style: const TextStyle(fontWeight: FontWeight.bold))]),
                  const SizedBox(height: 12),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Student ID'), Text(globalStudentId ?? '', style: const TextStyle(fontWeight: FontWeight.bold))]),
                  const SizedBox(height: 32),
                  QrImageView(data: widget.token['id'], version: QrVersions.auto, size: 200.0),
                  const SizedBox(height: 16),
                  const Text('Scan at Counter', style: TextStyle(color: LinelessTheme.textSecondary, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: LinelessTheme.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.shade200)),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Queue Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('${widget.token['queue_position']}${_getPositionSuffix(widget.token['queue_position'])} in Line', style: const TextStyle(color: LinelessTheme.primary, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(value: 0.75, backgroundColor: LinelessTheme.background, color: LinelessTheme.primary, minHeight: 8, borderRadius: BorderRadius.circular(4)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [const Text('Est. Wait Time', style: TextStyle(fontSize: 12)), Text(widget.token['est_wait'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))],
                      ),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 32),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: LinelessTheme.danger),
                foregroundColor: LinelessTheme.danger,
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => _cancelToken(context),
              child: const Text('Cancel Token'),
            )
          ],
        ),
      ),
    );
  }

  String _getPositionSuffix(int position) {
    if (position % 100 >= 11 && position % 100 <= 13) return 'th';
    switch (position % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }
}

// ==================== ADMIN DASHBOARD (CATEGORY VIEW) ====================
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  List<dynamic> _serviceGroups = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTokensByService();
  }

  Future<void> _fetchTokensByService() async {
    setState(() => _isLoading = true);
    try {
      final res = await http.get(Uri.parse('$baseUrl/admin/tokens/by-service'));
      if (res.statusCode == 200) {
        setState(() {
          _serviceGroups = jsonDecode(res.body)['services'];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _completeToken(String tokenId) async {
    try {
      final res = await http.post(Uri.parse('$baseUrl/tokens/$tokenId/complete'));
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Token marked as completed'), backgroundColor: LinelessTheme.success),
        );
        _fetchTokensByService();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _removeToken(String tokenId) async {
    try {
      final res = await http.post(Uri.parse('$baseUrl/tokens/$tokenId/remove'));
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Token removed'), backgroundColor: LinelessTheme.danger),
        );
        _fetchTokensByService();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _showNotificationDialog() {
    showDialog(
      context: context,
      builder: (context) => const AdminNotificationDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: LinelessTheme.background,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Lineless Admin', style: TextStyle(fontWeight: FontWeight.w900, color: LinelessTheme.textPrimary)),
            Text('Queue Management Portal', style: TextStyle(fontSize: 12, color: LinelessTheme.textSecondary)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active_rounded, color: LinelessTheme.primary),
            tooltip: 'Send Notification',
            onPressed: _showNotificationDialog,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginSelectionScreen()),
                (route) => false,
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchTokensByService,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  ..._serviceGroups.map((serviceGroup) => _buildServiceGroup(serviceGroup)).toList(),
                  if (_serviceGroups.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(40.0), child: Text("No tokens found.", style: TextStyle(color: LinelessTheme.textSecondary)))),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showNotificationDialog,
        backgroundColor: LinelessTheme.primary,
        icon: const Icon(Icons.send_rounded, color: Colors.white),
        label: const Text('Send Notification', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildServiceGroup(dynamic serviceGroup) {
    String serviceName = serviceGroup['service_name'];
    List tokens = serviceGroup['tokens'];
    int activeCount = serviceGroup['active_tokens'];

    if (tokens.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: LinelessTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: LinelessTheme.primary.withOpacity(0.1),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(serviceName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: LinelessTheme.primary)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: LinelessTheme.primary, borderRadius: BorderRadius.circular(20)),
                  child: Text('$activeCount Active', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
          ),
          ...tokens.map((token) => _buildAdminTokenCard(token)).toList(),
        ],
      ),
    );
  }

  Widget _buildAdminTokenCard(dynamic token) {
    bool isActive = token['status'] == 'ACTIVE';
    bool isCompleted = token['status'] == 'COMPLETED';

    Color statusColor = isActive ? const Color(0xFFE8F5E9) : isCompleted ? const Color(0xFFE3F2FD) : const Color(0xFFFFF3E0);
    Color statusTextColor = isActive ? Colors.green.shade800 : isCompleted ? Colors.blue.shade800 : Colors.orange.shade800;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: LinelessTheme.background, borderRadius: BorderRadius.circular(12)),
                child: Text(token['id'].split('-')[1], style: const TextStyle(fontWeight: FontWeight.bold, color: LinelessTheme.primary, fontSize: 12)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(token['student_name'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                    Text('ID: ${token['student_id']}', style: const TextStyle(fontSize: 12, color: LinelessTheme.textSecondary)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(20)),
                child: Text(token['status'], style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusTextColor)),
              )
            ],
          ),
          if (isActive) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: LinelessTheme.success,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Complete'),
                    onPressed: () => _completeToken(token['id']),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: LinelessTheme.danger),
                      foregroundColor: LinelessTheme.danger,
                    ),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Remove'),
                    onPressed: () => _removeToken(token['id']),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ==================== ADMIN NOTIFICATION DIALOG ====================
class AdminNotificationDialog extends StatefulWidget {
  const AdminNotificationDialog({super.key});

  @override
  State<AdminNotificationDialog> createState() => _AdminNotificationDialogState();
}

class _AdminNotificationDialogState extends State<AdminNotificationDialog> {
  final _messageController = TextEditingController();
  String _selectedTarget = 'all';
  String? _selectedService;
  bool _isSending = false;
  List<dynamic> _services = [];

  @override
  void initState() {
    super.initState();
    _fetchServices();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _fetchServices() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/services'));
      if (res.statusCode == 200) {
        setState(() => _services = jsonDecode(res.body)['services']);
      }
    } catch (e) {
      print('Error fetching services: $e');
    }
  }

  Future<void> _sendNotification() async {
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a message'), backgroundColor: Colors.red),
      );
      return;
    }

    if (_selectedTarget == 'service' && _selectedService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a service'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      final body = {
        'message': _messageController.text.trim(),
        'target': _selectedTarget,
      };

      if (_selectedTarget == 'service' && _selectedService != null) {
        body['service_name'] = _selectedService!;
      }

      final res = await http.post(
        Uri.parse('$baseUrl/admin/send-notification'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 200 && data['success'] == true) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Notification sent to ${data['sent']} users'),
              backgroundColor: LinelessTheme.success,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Failed to send notification'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.notifications_active, color: LinelessTheme.primary),
          SizedBox(width: 12),
          Text('Send Notification'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Send To:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 12),
            RadioListTile<String>(
              title: const Text('All Students'),
              value: 'all',
              groupValue: _selectedTarget,
              onChanged: (value) => setState(() {
                _selectedTarget = value!;
                _selectedService = null;
              }),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
            RadioListTile<String>(
              title: const Text('Specific Service Queue'),
              value: 'service',
              groupValue: _selectedTarget,
              onChanged: (value) => setState(() => _selectedTarget = value!),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
            if (_selectedTarget == 'service') ...[
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Select Service',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: LinelessTheme.background,
                ),
                value: _selectedService,
                items: _services.map((service) {
                  return DropdownMenuItem<String>(
                    value: service['name'],
                    child: Text(service['name']),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedService = value),
              ),
            ],
            const SizedBox(height: 20),
            const Text('Message:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 12),
            TextField(
              controller: _messageController,
              maxLines: 4,
              maxLength: 200,
              decoration: const InputDecoration(
                hintText: 'e.g., "Scholarship services will be unavailable today from 2-4 PM"',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: LinelessTheme.background,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This will send a push notification to ${_selectedTarget == 'all' ? 'all students' : 'students in the selected service queue'}',
                      style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSending ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: LinelessTheme.primary,
            foregroundColor: Colors.white,
          ),
          icon: _isSending
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Icon(Icons.send, size: 20),
          label: Text(_isSending ? 'Sending...' : 'Send'),
          onPressed: _isSending ? null : _sendNotification,
        ),
      ],
    );
  }
}