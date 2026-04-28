import 'package:flutter/material.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "About Us",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              "About the Application",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              "This User Profile Application is designed to provide users "
                  "with a simple and secure way to manage their personal information. "
                  "The application focuses on usability, privacy, and clean design.",
              style: TextStyle(fontSize: 15, height: 1.6),
            ),
            SizedBox(height: 20),
            Text(
              "Key Features",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              "• View personal profile details\n"
                  "• Edit name, phone number, and profile image\n"
                  "• Secure logout functionality\n"
                  "• Clean and user-friendly interface\n",
              style: TextStyle(fontSize: 15, height: 1.6),
            ),
            SizedBox(height: 20),
            Text(
              "Purpose & Vision",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              "The goal of this application is to demonstrate a modular and "
                  "scalable Flutter architecture while ensuring a smooth user experience. "
                  "It is suitable for academic projects, hackathons, and real-world use cases.",
              style: TextStyle(fontSize: 15, height: 1.6),
            ),
            SizedBox(height: 20),
            Center(
              child: Text(
                "“A profile is not just data, it represents identity.”",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}