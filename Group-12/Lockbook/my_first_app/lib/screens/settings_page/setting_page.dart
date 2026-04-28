import 'package:flutter/material.dart';
import 'package:my_first_app/screens/Home_page/Home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_first_app/main.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isDarkMode = false;
  bool isPasswordVisible = false;
  bool isBiometricEnabled = false;

  Color selectedThemeColor = Colors.deepPurple;

  final masterPassController = TextEditingController();
  final confirmPassController = TextEditingController();

  final List<Color> themeColors = [
    Colors.black,
    Colors.green,
    Colors.red,
    Colors.purple,
    Colors.pink,
    Colors.lime,
    Colors.blue,
    Colors.orange,
    Colors.teal,
  ];

  @override
  void initState() {
    super.initState();
    loadSettings();
  }

  void loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      isDarkMode = prefs.getBool("dark_mode") ?? false;
      isBiometricEnabled = prefs.getBool("biometric_lock") ?? false;

      String? colorString = prefs.getString("theme_color");
      if (colorString != null) {
        selectedThemeColor = Color(int.parse(colorString));
      }
    });
  }

  void saveDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("dark_mode", value);

    setState(() => isDarkMode = value);

    LockBookApp.updateTheme(context);
  }

  void saveThemeColor(Color color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("theme_color", color.value.toString());

    setState(() => selectedThemeColor = color);

    LockBookApp.updateTheme(context);
  }

  /// 🔑 CHANGE MASTER PASSWORD
  void changeMasterPassword() async {
    if (masterPassController.text.isEmpty ||
        confirmPassController.text.isEmpty) {
      showMessage("Password cannot be empty");
      return;
    }

    if (masterPassController.text != confirmPassController.text) {
      showMessage("Passwords do not match");
      return;
    }

    try {
      await FirebaseAuth.instance.currentUser!
          .updatePassword(masterPassController.text.trim());

      showMessage("Password Updated Successfully ✅");

      masterPassController.clear();
      confirmPassController.clear();
    } catch (e) {
      showMessage("Re-login required before changing password");
    }
  }

  void showMessage(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  void deleteAccount() async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Account"),
        content: const Text(
            "This action is permanent.\nAre you sure?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              try {
                await FirebaseAuth.instance.currentUser!.delete();

                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();

                loggedInUser = null;

                Navigator.pop(context);

                Navigator.pushNamedAndRemoveUntil(
                  context,
                  "/signin",
                  (route) => false,
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Re-login required to delete account"),
                  ),
                );
              }
            },
            child: const Text("Delete",
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [

            /// DARK MODE
            SwitchListTile(
              title: const Text("Dark Mode"),
              value: isDarkMode,
              onChanged: saveDarkMode,
            ),

            const SizedBox(height: 15),

            /// THEME COLORS
            const Text("Theme Colors",
                style: TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              children: themeColors.map((color) {
                return GestureDetector(
                  onTap: () =>
                      saveThemeColor(color),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: color,
                    child: selectedThemeColor == color
                        ? const Icon(Icons.check,
                            color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 25),

            /// ABOUT US
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text("About Us"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AboutUsScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 25),

            /// MASTER PASSWORD
            const Text("Change Master Password",
                style: TextStyle(fontSize: 18)),
            const SizedBox(height: 10),

            TextField(
              controller: masterPassController,
              obscureText: !isPasswordVisible,
              decoration: InputDecoration(
                labelText: "New Password",
                border:
                    const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(isPasswordVisible
                      ? Icons.visibility
                      : Icons.visibility_off),
                  onPressed: () {
                    setState(() =>
                        isPasswordVisible =
                            !isPasswordVisible);
                  },
                ),
              ),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: confirmPassController,
              obscureText: !isPasswordVisible,
              decoration: const InputDecoration(
                labelText: "Confirm Password",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 10),

            ElevatedButton(
                onPressed: changeMasterPassword,
                child: const Text("Update")),

            const SizedBox(height: 30),

            /// LOGOUT
            Center(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 30, vertical: 12),
                ),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();

                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear();

                  loggedInUser = null;

                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.logout,
                    color: Colors.white),
                label: const Text(
                  "Logout",
                  style:
                      TextStyle(color: Colors.white),
                ),
              ),
            ),

            const SizedBox(height: 15),

            /// DELETE ACCOUNT
            Center(
              child: ElevatedButton.icon(
                style:
                    ElevatedButton.styleFrom(
                        backgroundColor:
                            Colors.red),
                onPressed: deleteAccount,
                icon: const Icon(Icons.delete),
                label: const Text(
                    "Delete Account"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("About Us"),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "About the Application",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Text(
              "LockBook is a secure password manager designed to help users safely store and manage their sensitive credentials. The application focuses on privacy, security, and a seamless user experience.",
              style: TextStyle(fontSize: 16, height: 1.6),
            ),
            SizedBox(height: 30),
            Text(
              "Key Features",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Text(
              "• Secure password storage\n"
              "• Password update reminders\n"
              "• Easy access and management\n"
              "• Clean and user-friendly interface\n"
              "• Secure logout functionality",
              style: TextStyle(fontSize: 16, height: 1.6),
            ),
            SizedBox(height: 30),
            Text(
              "Purpose & Vision",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Text(
              "The goal of LockBook is to provide a reliable and secure solution for managing digital credentials while ensuring simplicity and performance. It is suitable for academic projects, hackathons, and real-world usage.",
              style: TextStyle(fontSize: 16, height: 1.6),
            ),
            SizedBox(height: 30),
            Center(
              child: Text(
                "“Your passwords deserve protection, not just storage.”",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}