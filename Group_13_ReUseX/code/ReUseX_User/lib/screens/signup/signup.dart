import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:reusex/firebase/auth_helper.dart';
import 'package:reusex/screens/login/login.dart';
import 'package:reusex/widgets/primary_buttons/primary_buttons.dart';
import 'package:reusex/widgets/top_titles/top_titles.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  bool isShowPassword = true;
  bool isLoading = false;

  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  bool _isValidIndianPhone(String phone) {
    return RegExp(r'^[6-9][0-9]{9}$').hasMatch(phone);
  }

  bool _isValidGmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@gmail\.com$').hasMatch(email);
  }

  bool _isValidPassword(String password) {
    return RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$&*~%^()_\-+=\[\]{};:"\\|,.<>\/?]).{8,}$',
    ).hasMatch(password);
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final email = emailController.text.trim().toLowerCase();
      final phone = phoneController.text.trim();
      final password = passwordController.text.trim();

      final userCredential = await AuthHelper.instance.signUp(
        email,
        password,
      );

      final uid = userCredential.user!.uid;

      await FirebaseFirestore.instance.collection("users").doc(uid).set({
        "name": nameController.text.trim(),
        "email": email,
        "phone": "+91$phone",
        "address": "",
        "profileImage": "",
        "role": "user",
        "createdAt": FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp(),
      });

      if (mounted) {
        setState(() => isLoading = false);
      }

      await AuthHelper.instance.logout();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Account created successfully")),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const Login()),
            (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst("Exception: ", ""),
          ),
        ),
      );
    }
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
    Widget? prefix,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: Icon(prefixIcon),
      prefix: prefix,
      suffixIcon: suffixIcon,
      hintStyle: TextStyle(
        color: Colors.grey.shade600,
        fontSize: 16,
      ),
      errorStyle: const TextStyle(
        color: Colors.red,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      contentPadding: const EdgeInsets.symmetric(
        vertical: 18,
        horizontal: 14,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Theme.of(context).primaryColor,
          width: 1.4,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const TopTitles(
                        subtitle: "Welcome to ReUseX!",
                        title: "Create Account",
                      ),
                      // rest of your code...
                      const SizedBox(height: 40),

                      TextFormField(
                        controller: nameController,
                        textInputAction: TextInputAction.next,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Enter your name";
                          }
                          return null;
                        },
                        decoration: _inputDecoration(
                          hintText: "Name",
                          prefixIcon: Icons.person,
                        ),
                      ),
                      const SizedBox(height: 15),

                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                        ),
                        validator: (value) {
                          final email = value?.trim() ?? '';
                          if (email.isEmpty) {
                            return "Enter email";
                          }
                          if (!_isValidGmail(email)) {
                            return "Enter valid Gmail address";
                          }
                          return null;
                        },
                        decoration: _inputDecoration(
                          hintText: "E-mail",
                          prefixIcon: Icons.email_outlined,
                        ),
                      ),
                      const SizedBox(height: 15),

                      TextFormField(
                        controller: phoneController,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                          height: 1.2,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        validator: (value) {
                          final phone = value?.trim() ?? '';
                          if (phone.isEmpty) {
                            return "Enter phone number";
                          }
                          if (!_isValidIndianPhone(phone)) {
                            return "Enter valid Indian phone number";
                          }
                          return null;
                        },
                        decoration: _inputDecoration(
                          hintText: "Phone Number",
                          prefixIcon: Icons.phone,
                          prefix: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Text(
                              "+91",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade800,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),

                      TextFormField(
                        controller: passwordController,
                        obscureText: isShowPassword,
                        textInputAction: TextInputAction.done,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                        ),
                        validator: (value) {
                          final password = value?.trim() ?? '';
                          if (password.isEmpty) {
                            return "Enter password";
                          }
                          if (password.contains(" ")) {
                            return "Password should not contain spaces";
                          }
                          if (password.length < 8) {
                            return "At least 8 characters required";
                          }
                          if (!RegExp(r'[A-Z]').hasMatch(password)) {
                            return "Add at least 1 uppercase letter";
                          }
                          if (!RegExp(r'[a-z]').hasMatch(password)) {
                            return "Add at least 1 lowercase letter";
                          }
                          if (!RegExp(r'[0-9]').hasMatch(password)) {
                            return "Add at least 1 number";
                          }
                          if (!RegExp(r'[!@#\$&*~%^()_\-+=\[\]{};:"\\|,.<>\/?]')
                              .hasMatch(password)) {
                            return "Add at least 1 special character";
                          }
                          return null;
                        },
                        decoration: _inputDecoration(
                          hintText: "Create Password",
                          prefixIcon: Icons.password,
                          suffixIcon: CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: () {
                              setState(() => isShowPassword = !isShowPassword);
                            },
                            child: Icon(
                              isShowPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 45),

                      isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : PrimaryButtons(
                        title: "Create an account",
                        onPressed: _handleSignup,
                      ),

                      const SizedBox(height: 15),

                      Center(
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Text(
                              "Already have an account? ",
                              style: TextStyle(fontSize: 18),
                            ),
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const Login(),
                                  ),
                                );
                              },
                              child: Text(
                                "Login",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}