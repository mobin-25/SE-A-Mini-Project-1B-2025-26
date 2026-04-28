import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:my_first_app/screens/main_page/main_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:otp/otp.dart';

class SecurityCheckPage extends StatefulWidget {
  const SecurityCheckPage({super.key});

  @override
  State<SecurityCheckPage> createState() => _SecurityCheckPageState();
}

class _SecurityCheckPageState extends State<SecurityCheckPage> {
  final LocalAuthentication auth = LocalAuthentication();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  int seconds = 120;
  bool canResend = false;
  Timer? timer;

  final otpController = TextEditingController();

  String totpSecret = "";
  bool totpEnabled = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadTotpData();
  }

  Future<void> loadTotpData() async {
    await _auth.currentUser?.reload();

    final user = _auth.currentUser;

    if (user == null) {
      print("❌ USER NULL");
      setState(() {
        isLoading = false;
      });
      return;
    }

    print("✅ UID: ${user.uid}");

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final data = doc.data();

    print("🔥 FIRESTORE DATA: $data");

    setState(() {
      totpSecret = data?['totp_secret'] ?? "";
      totpEnabled = data?['totp_enabled'] ?? false;
      isLoading = false;
    });

    print("🔥 SECRET AFTER LOAD: $totpSecret");
  }

  void startTimer() {
    seconds = 120;
    canResend = false;

    timer?.cancel();

    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (seconds == 0) {
        t.cancel();
        setState(() {
          canResend = true;
        });
      } else {
        setState(() {
          seconds--;
        });
      }
    });
  }

  Future<void> resendSetupInfo() async {
    startTimer();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Use the secret key again in Google Authenticator."),
      ),
    );
  }

  Future<void> verifyTotp() async {
    final enteredOtp = otpController.text.trim();

    if (enteredOtp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter authenticator code")),
      );
      return;
    }

    if (totpSecret.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Secret key not loaded")),
      );
      return;
    }

    final currentOtp = OTP.generateTOTPCodeString(
      totpSecret,
      DateTime.now().millisecondsSinceEpoch,
      interval: 30,
      length: 6,
      algorithm: Algorithm.SHA1,
      isGoogle: true,
    );

    print("ENTERED OTP: $enteredOtp");
    print("CURRENT OTP: $currentOtp");

    if (enteredOtp == currentOtp) {
      final user = _auth.currentUser;

      if (user != null && !totpEnabled) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
          'totp_enabled': true,
        }, SetOptions(merge: true));
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const MainAppScreen(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid authenticator code")),
      );
    }
  }

  Future<void> authenticateBiometric() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Fingerprint not supported on Web")),
      );
      return;
    }

    try {
      bool canCheckBiometrics = await auth.canCheckBiometrics;
      bool isSupported = await auth.isDeviceSupported();

      if (!canCheckBiometrics || !isSupported) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Biometric not available on this device"),
          ),
        );
        return;
      }

      bool authenticated = await auth.authenticate(
        localizedReason: "Scan fingerprint to unlock LockBook",
        biometricOnly: true,
      );

      if (authenticated) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const MainAppScreen(),
          ),
        );
      }
    } catch (e) {
      debugPrint("Biometric Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final userEmail = _auth.currentUser?.email ?? "No email found";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Security Verification 🔐"),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Image.asset(
                      "assets/icon/security.png",
                      height: 160,
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      "Two Factor Authentication",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Use fingerprint first or Google Authenticator as backup.",
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),

                    ElevatedButton.icon(
                      onPressed: authenticateBiometric,
                      icon: const Icon(Icons.fingerprint),
                      label: const Text("Unlock with Fingerprint"),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 55),
                      ),
                    ),

                    const SizedBox(height: 30),

                    if (!totpEnabled) ...[
                      const Text(
                        "SET UP GOOGLE AUTHENTICATOR",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),

                      TextField(
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: "Registered Email",
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.email),
                          hintText: userEmail,
                        ),
                      ),

                      const SizedBox(height: 20),

                      const Text(
                        "Open Google Authenticator → Tap '+' → Enter a setup key",
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 15),

                      SelectableText(
                        "Account: LockBook ($userEmail)",
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 10),

                      Column(
                        children: [
                          const Text(
                            "Setup Key:",
                            style: TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          SelectableText(
                            totpSecret.isEmpty ? "No secret found ❌" : totpSecret,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),

                      const SizedBox(height: 15),

                      ElevatedButton.icon(
                        onPressed: () {
                          if (totpSecret.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Secret key not loaded yet"),
                              ),
                            );
                            return;
                          }

                          Clipboard.setData(
                            ClipboardData(text: totpSecret),
                          );

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Secret key copied"),
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy),
                        label: const Text("Copy Setup Key"),
                      ),

                      const SizedBox(height: 20),

                      TextField(
                        controller: otpController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Enter 6-digit code",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.lock),
                        ),
                      ),

                      const SizedBox(height: 20),

                      ElevatedButton(
                        onPressed: verifyTotp,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: const Text("Verify & Continue"),
                      ),

                      const SizedBox(height: 10),

                      TextButton(
                        onPressed: canResend ? resendSetupInfo : null,
                        child: Text(
                          canResend
                              ? "Show Secret Key Again"
                              : "Show again in $seconds sec",
                        ),
                      ),
                    ] else ...[
                      const Text(
                        "OR USE GOOGLE AUTHENTICATOR",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),

                      TextField(
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: "Registered Email",
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.email),
                          hintText: userEmail,
                        ),
                      ),

                      const SizedBox(height: 20),

                      TextField(
                        controller: otpController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Enter Authenticator Code",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.lock),
                        ),
                      ),

                      const SizedBox(height: 20),

                      ElevatedButton(
                        onPressed: verifyTotp,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: const Text("Verify Code"),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    otpController.dispose();
    super.dispose();
  }
}