import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_first_app/main.dart';
import 'package:my_first_app/screens/MultiFactor_Page/MultiFactor_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  final username = TextEditingController();
  final email = TextEditingController();
  final phone = TextEditingController();
  final password = TextEditingController();
  final confirmPassword = TextEditingController();
  final emergencyEmail = TextEditingController();
  final emergencyPhone = TextEditingController();

  bool acceptTerms = false;
  bool showPassword = false;
  bool showConfirmPassword = false;
  bool isLoading = false;

  /// ================= VALIDATIONS =================

  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Email required";
    }
    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@gmail\.com$')
        .hasMatch(value.trim())) {
      return "Enter valid Gmail";
    }
    return null;
  }

  String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Phone required";
    }
    if (!RegExp(r'^[0-9]{10}$').hasMatch(value.trim())) {
      return "Enter 10 digit number";
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return "Password required";
    }
    if (value.length < 8) {
      return "Min 8 characters";
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return "Add 1 uppercase";
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return "Add 1 number";
    }
    return null;
  }

  String? validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return "Confirm your password";
    }
    if (value != password.text) {
      return "Passwords do not match";
    }
    return null;
  }

  /// ================= GOOGLE AUTH SECRET GENERATOR =================
  String generateTotpSecret([int length = 32]) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
  }

  /// ================= REGISTER =================

  Future<void> registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    if (!acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please accept terms")),
      );
      return;
    }

    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    try {
      print("STEP 1: Create auth user");

      final userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.text.trim(),
        password: password.text.trim(),
      );

      final uid = userCredential.user!.uid;
      print("STEP 2: Auth success UID = $uid");

      String phoneNumber = phone.text.trim();
      if (!phoneNumber.startsWith('+91')) {
        phoneNumber = '+91$phoneNumber';
      }

      String emergencyPhoneNumber = emergencyPhone.text.trim();
      if (!emergencyPhoneNumber.startsWith('+91')) {
        emergencyPhoneNumber = '+91$emergencyPhoneNumber';
      }

      /// 🔥 NEW: Generate Google Authenticator secret
      final totpSecret = generateTotpSecret();

      print("STEP 3: Save user data in Firestore");

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'username': username.text.trim(),
        'email': email.text.trim(),
        'phone': phoneNumber,
        'emergency_email': emergencyEmail.text.trim(),
        'emergency_phone': emergencyPhoneNumber,
        'createdAt': FieldValue.serverTimestamp(),

        /// 🔥 NEW FIELDS
        'totp_secret': totpSecret,
        'totp_enabled': false,
      });

      print("STEP 4: Firestore success");

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("username", username.text.trim());

      loggedInUser = username.text.trim();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Account Created Successfully")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MultiFactorPage()),
      );
    } on FirebaseAuthException catch (e) {
      String message = e.message ?? "Signup failed";

      if (e.code == 'email-already-in-use') {
        message = "This email is already registered. Please login.";
      } else if (e.code == 'weak-password') {
        message = "Password is too weak.";
      } else if (e.code == 'invalid-email') {
        message = "Invalid email address.";
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      print("ERROR AFTER AUTH: $e");

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Firestore or next-step error: $e")),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  /// ================= FIELD BUILDER =================

  Widget buildField(
    String label,
    TextEditingController controller, {
    bool isPassword = false,
    String? Function(String?)? validator,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        validator: validator ?? (v) => v!.trim().isEmpty ? "Required" : null,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }

  /// ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Account")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              buildField("Username", username),

              buildField("Gmail", email, validator: validateEmail),

              buildField(
                "Phone",
                phone,
                validator: validatePhone,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
              ),

              /// Password
              buildField(
                "Password",
                password,
                isPassword: !showPassword,
                validator: validatePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    showPassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      showPassword = !showPassword;
                    });
                  },
                ),
              ),

              /// Confirm Password
              buildField(
                "Confirm Password",
                confirmPassword,
                isPassword: !showConfirmPassword,
                validator: validateConfirmPassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    showConfirmPassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      showConfirmPassword = !showConfirmPassword;
                    });
                  },
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                "Emergency Contact Information\n"
                "This will notify you if someone accesses your device or vault.",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 15),

              buildField("Emergency Gmail", emergencyEmail,
                  validator: validateEmail),

              buildField(
                "Emergency Phone",
                emergencyPhone,
                validator: validatePhone,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
              ),

              Row(
                children: [
                  Checkbox(
                    value: acceptTerms,
                    onChanged: (v) {
                      setState(() {
                        acceptTerms = v ?? false;
                      });
                    },
                  ),
                  const Text("Accept"),
                  GestureDetector(
                    onTap: () {
                      showTermsDialog();
                    },
                    child: const Text(
                      " Terms & Conditions",
                      style: TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              ElevatedButton(
                onPressed: isLoading ? null : registerUser,
                child: Text(isLoading ? "Creating..." : "Create Account"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ================= TERMS DIALOG =================

  void showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Terms & Conditions"),
          content: const SingleChildScrollView(
            child: Text(
              "1. LockBook stores your passwords securely.\n\n"
              "2. Your master password is required to access the vault.\n\n"
              "3. Emergency contacts may receive alerts if suspicious access occurs.\n\n"
              "4. This app is built for educational project purposes.\n\n"
              "5. Users must keep their credentials safe.",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Close"),
            )
          ],
        );
      },
    );
  }

  /// ================= DISPOSE =================

  @override
  void dispose() {
    username.dispose();
    email.dispose();
    phone.dispose();
    password.dispose();
    confirmPassword.dispose();
    emergencyEmail.dispose();
    emergencyPhone.dispose();
    super.dispose();
  }
}