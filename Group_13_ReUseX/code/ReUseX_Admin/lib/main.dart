import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:reusex/screens/main_navigation/dashboard/admin_dashboard.dart';
import 'firebase_options.dart';
import 'package:reusex/screens/login/admin_login.dart';
import 'package:reusex/widgets/constants/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    DevicePreview(
      enabled: true,
      builder: (context) => const ReUseXAdmin(),
    ),
  );
}

class ReUseXAdmin extends StatelessWidget {
  const ReUseXAdmin({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      useInheritedMediaQuery: true, // IMPORTANT for DevicePreview
      builder: DevicePreview.appBuilder,
      locale: DevicePreview.locale(context),

      title: 'ReUseX Admin Dashboard',
      theme: themeData,
      debugShowCheckedModeBanner: false,
      home: const AdminLogin(),
    );
  }
}