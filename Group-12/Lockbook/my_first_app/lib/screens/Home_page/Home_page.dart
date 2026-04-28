/// ================= HOME =================
/// import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:my_first_app/screens/signin_page/sigin_page.dart';
import 'package:my_first_app/screens/signup_/signup_page.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.security,
                  size: 90, color: Colors.white),
              const SizedBox(height: 20),
              const Text(
                "Your privacy is our priority",
                style: TextStyle(
                    color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.deepPurple),
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              const SignInScreen()));
                },
                child: const Text("Sign In 🔐"),
              ),
              const SizedBox(height: 20),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side:
                        const BorderSide(color: Colors.white)),
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              const SignUpScreen()));
                },
                child: const Text("Sign Up 👤"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}