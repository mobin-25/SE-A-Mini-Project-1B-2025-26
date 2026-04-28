import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:my_first_app/screens/security_check_page/security_check_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MultiFactorPage extends StatefulWidget {
  const MultiFactorPage({super.key});

  @override
  State<MultiFactorPage> createState() => _MultiFactorPageState();
}

class _MultiFactorPageState extends State<MultiFactorPage> {

  final LocalAuthentication auth = LocalAuthentication();
  final TextEditingController masterPass = TextEditingController();

  bool hidePass = true;



  @override
  void initState() {
    super.initState();
  }

  /// ================= LOAD USER DATA =================


  /// ================= PASSWORD CHECK =================
  void checkMasterPassword() async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) return;

  try {
    // 🔐 Re-authenticate user
    AuthCredential credential = EmailAuthProvider.credential(
      email: user.email!,
      password: masterPass.text.trim(),
    );

    await user.reauthenticateWithCredential(credential);

    // ✅ Success → next page
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const SecurityCheckPage(),
      ),
    );

  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Wrong Master Password")),
    );
  }
}

  /// ================= UI =================
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              children: [

                const SizedBox(height: 40),

                Image.asset(
                  "assets/icon/lockbook.png",
                  height: 150,
                ),

                const SizedBox(height: 50),

                const Text(
                  "Welcome to LockBook",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                const Text(
                  "Secure your access to the vault",
                  style: TextStyle(fontSize: 15),
                ),

                const SizedBox(height: 30),

                const Text(
                  "Enter Master Password",
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 15),

                /// PASSWORD FIELD
                TextField(
                  controller: masterPass,
                  obscureText: hidePass,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock),
                    border: const OutlineInputBorder(),
                    hintText: "Enter your master password",
                    suffixIcon: IconButton(
                      icon: Icon(
                        hidePass
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          hidePass = !hidePass;
                        });
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                /// ENTER APP
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: checkMasterPassword,
                    child: const Text("Enter App"),
                  ),
                ),

                const SizedBox(height: 25),

                const Text(
                  "Please verify your identity to continue",
                  style: TextStyle(fontSize: 12),
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }
}