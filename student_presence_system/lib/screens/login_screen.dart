import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'teacher/teacher_dashboard.dart';
import 'student/student_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _rememberMe = false; // Added for the UI checkbox

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your email';
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your password';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      /// 🔐 STEP 1 — Firebase Auth Login
      UserCredential userCredential =
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      String uid = userCredential.user!.uid;
      debugPrint("✅ LOGIN SUCCESS");
      debugPrint("📌 UID = $uid");

      /// 🔎 STEP 2 — Check if user is a TEACHER
      final teacherDoc = await FirebaseFirestore.instance.collection('teachers').doc(uid).get();

      if (!mounted) return;

      if (teacherDoc.exists) {
        debugPrint("👨‍🏫 Teacher profile found!");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const TeacherDashboard(),
          ),
        );
        return; // Stop execution here since we routed them
      }

      /// 🔎 STEP 3 — If not a teacher, check if user is a STUDENT
      final studentDoc = await FirebaseFirestore.instance.collection('students').doc(uid).get();

      if (!mounted) return;

      if (studentDoc.exists) {
        debugPrint("👨‍🎓 Student profile found!");
        Map<String, dynamic> studentData = studentDoc.data() as Map<String, dynamic>;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => StudentDashboard(
              studentId: studentData['roll_no'] ?? 'Unknown',
              studentName: studentData['name'] ?? 'Student',
              division: studentData['division'] ?? 'A',
            ),
          ),
        );
        return; // Stop execution here
      }

      /// 🔴 STEP 4 — User logged in via Auth, but has NO database document!
      _showError("User data not found. Please contact administrator.");

    }

    /// 🔴 AUTH ERRORS
    on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
        case 'invalid-credential':
          message = 'Incorrect email or password.';
          break;
        case 'wrong-password':
          message = 'Incorrect password.';
          break;
        case 'invalid-email':
          message = 'Invalid email address.';
          break;
        case 'user-disabled':
          message = 'Account disabled.';
          break;
        default:
          message = 'Login failed. Please try again.';
      }
      _showError(message);
    } catch (e) {
      _showError("Unexpected error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Premium UI Colors
    const Color primaryBlue = Color(0xFF1A73E8);
    const Color headerBlue = Color(0xFFDCE6FC);
    const Color bgGray = Color(0xFFF4F7FC);
    const Color textDark = Color(0xFF1E293B);
    const Color textGray = Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bgGray,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // --- MAIN LOGIN CARD ---
              Container(
                width: kIsWeb ? 420 : MediaQuery.of(context).size.width * 0.9, // Exact 420 on Web, 90% width on Mobile
                constraints: const BoxConstraints(maxWidth: 420),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    // --- LIGHT BLUE HEADER ---
                    Container(
                      width: double.infinity,
                      height: 120,
                      color: headerBlue,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.badge_outlined,
                            color: primaryBlue,
                            size: 32,
                          ),
                        ),
                      ),
                    ),

                    // --- FORM SECTION ---
                    Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Welcome Back",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: textDark,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "Please sign in to access your dashboard",
                              style: TextStyle(fontSize: 14, color: textGray),
                            ),
                            const SizedBox(height: 32),

                            // --- EMAIL FIELD ---
                            const Text("Email Address", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textDark)),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              validator: _validateEmail,
                              decoration: InputDecoration(
                                hintText: "name@school.edu",
                                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                                prefixIcon: const Icon(Icons.mail_outline, color: textGray, size: 20),
                                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: primaryBlue, width: 2),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.red.shade300, width: 1),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.red.shade400, width: 2),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // --- PASSWORD FIELD ---
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Password", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textDark)),
                                TextButton(
                                  onPressed: () {
                                    // Add logic here if you want a password reset screen
                                  },
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(0, 0),
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text("Forgot password?", style: TextStyle(fontSize: 13, color: primaryBlue, fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: !_isPasswordVisible,
                              validator: _validatePassword,
                              decoration: InputDecoration(
                                hintText: "••••••••",
                                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                                prefixIcon: const Icon(Icons.lock_outline, color: textGray, size: 20),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                    color: textGray,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isPasswordVisible = !_isPasswordVisible;
                                    });
                                  },
                                ),
                                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: primaryBlue, width: 2),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.red.shade300, width: 1),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.red.shade400, width: 2),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // --- REMEMBER ME CHECKBOX ---
                            Row(
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Checkbox(
                                    value: _rememberMe,
                                    onChanged: (value) {
                                      setState(() {
                                        _rememberMe = value ?? false;
                                      });
                                    },
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                    side: BorderSide(color: Colors.grey.shade400),
                                    activeColor: primaryBlue,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text("Remember me", style: TextStyle(fontSize: 13, color: textGray)),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // --- LOGIN BUTTON ---
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryBlue,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                                    : const Text("Sign In", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(height: 32),

                            // --- CONTACT ADMIN ---
                            Center(
                              child: Wrap(
                                alignment: WrapAlignment.center,
                                children: [
                                  const Text("Don't have an account? ", style: TextStyle(fontSize: 13, color: textGray)),
                                  GestureDetector(
                                    onTap: () {
                                      // Add logic to contact admin
                                    },
                                    child: const Text(
                                      "Contact Administrator",
                                      style: TextStyle(fontSize: 13, color: primaryBlue, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // --- BOTTOM FOOTER ---
              const Text(
                "© 2026 EDU SYSTEMS INC.",
                style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600, letterSpacing: 1.2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}