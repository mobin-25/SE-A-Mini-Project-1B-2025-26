import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:reusex/widgets/widget_supporter/widget_supporter.dart';
import 'package:reusex/screens/login/login.dart';

class Welcome extends StatefulWidget {
  const Welcome({super.key});

  @override
  State<Welcome> createState() => _WelcomeState();
}

class _WelcomeState extends State<Welcome> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Center(child: Image.asset("assets/images/reusex_logo2.png")),
            const SizedBox(height: 15.0),
            Padding(
              padding: const EdgeInsets.only(left: 20.0, right: 20.0),
              child: Text(
                "Welcome To ReUseX",
                style: WidgetSupporter.healinetextstyle(30.0),
              ),
            ),
            const SizedBox(height: 15.0),
            Padding(
              padding: const EdgeInsets.only(left: 20.0, right: 20.0),
              child: Text(
                "Give Tech a Second Life",
                style: WidgetSupporter.greentextstyle(25.0),
              ),
            ),
            const SizedBox(height: 28.0),
            Padding(
              padding: const EdgeInsets.only(left: 20.0, right: 20.0),
              child: Text(
                "The hub for circular electronics",
                style: WidgetSupporter.normaltextstyle(18.0),
              ),
            ),
            const SizedBox(height: 10.0),
            Padding(
              padding: const EdgeInsets.only(left: 20.0, right: 20.0),
              child: Text(
                "Sell Used Components",
                style: WidgetSupporter.normaltextstyle(18.0),
              ),
            ),
            const SizedBox(height: 10.0),
            Padding(
              padding: const EdgeInsets.only(left: 20.0, right: 20.0),
              child: Text(
                "(RAMs,Lenses,GPUs,etc)",
                style: WidgetSupporter.normaltextstyle(18.0),
              ),
            ),
            const SizedBox(height: 10.0),
            Padding(
              padding: const EdgeInsets.only(left: 20.0, right: 20.0),
              child: Text(
                "Recycle E-waste For Rewards",
                style: WidgetSupporter.normaltextstyle(18.0),
              ),
            ),
            const SizedBox(height: 10.0),
            Padding(
              padding: const EdgeInsets.only(left: 20.0, right: 20.0),
              child: Text(
                "Shop Verified Listings",
                style: WidgetSupporter.normaltextstyle(18.0),
              ),
            ),
            const SizedBox(height: 50.0),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                Navigator.pushReplacement( // 👈 Changed from push to pushReplacement
                  context,
                  CupertinoPageRoute(builder: (context) => const Login()),
                );
              },
              child: Material(
                elevation: 5.0,
                borderRadius: BorderRadius.circular(40),
                child: Container(
                  height: 70,
                  width: MediaQuery.of(context).size.width / 1.6,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Center(
                    child: Text(
                      "Get Started",
                      style: WidgetSupporter.whitetextstyle(24.0),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}