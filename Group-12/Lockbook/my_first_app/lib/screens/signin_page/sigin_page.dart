import 'package:flutter/material.dart';
import 'package:my_first_app/main.dart';
import 'package:my_first_app/screens/MultiFactor_Page/MultiFactor_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final username = TextEditingController();
  final password = TextEditingController();

  bool isPasswordHidden = true;

  void loginUser() async {
  try {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: username.text.trim(),
      password: password.text.trim(),
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("username", username.text.trim());

    loggedInUser = username.text.trim();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const MultiFactorPage(),
      ),
    );

  } on FirebaseAuthException catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.message ?? "Login failed")),
    );
  }
}

  void forgotPassword() async {
  if (username.text.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Enter your email first")),
    );
    return;
  }

  try {
    await FirebaseAuth.instance.sendPasswordResetEmail(
      email: username.text.trim(),
    );

    showDialog(
      context: context,
      builder: (_) => const AlertDialog(
        title: Text("Password Reset"),
        content: Text(
          "Password reset link sent to your email.\nCheck your inbox.",
        ),
      ),
    );

  } on FirebaseAuthException catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.message ?? "Error")),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sign In")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            buildField("Email", username),
            buildField("Password", password,
                isPassword: true),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: forgotPassword,
                child: const Text("Forgot Password?"),
              ),
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: loginUser,
              child: const Text("Login 🔓"),
            )
          ],
        ),
      ),
    );
  }

  Widget buildField(String label,
      TextEditingController controller,
      {bool isPassword = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? isPasswordHidden : false,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    isPasswordHidden
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      isPasswordHidden =
                          !isPasswordHidden;
                    });
                  },
                )
              : null,
        ),
      ),
    );
  }
}