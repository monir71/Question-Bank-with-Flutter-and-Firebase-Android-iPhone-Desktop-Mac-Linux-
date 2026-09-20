import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:questionbank/screens/admin/admin_dashboard_screen.dart';
import 'package:questionbank/screens/auth/register_screen.dart';
import 'package:questionbank/screens/examinee/examinee_dashboard_screen.dart';
import 'package:questionbank/screens/examiner/examiner_dashboard_screen.dart';
import 'package:window_manager/window_manager.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // -------------------------------------------------
  // Windows / macOS / Linux Window Setup
  // -------------------------------------------------
  if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
    await windowManager.ensureInitialized();

    const WindowOptions windowOptions = WindowOptions(
      size: Size(1200, 800),
      center: true,
      title: 'Question Bank',
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.maximize();
      await windowManager.show();
      await windowManager.focus();
    });
  }

  // -------------------------------------------------
  // Firebase
  // -------------------------------------------------
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // -------------------------------------------------
  // Start Application
  // -------------------------------------------------
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Question Bank',
      debugShowCheckedModeBanner: false,

      // -------------------------------------------------
      // Application Theme
      // -------------------------------------------------
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),

      home: RegisterScreen(),

      // -------------------------------------------------
      // Named Routes
      // -------------------------------------------------
      routes: {
        '/admin': (context) {
          return const AdminDashboardScreen();
        },

        '/examiner': (context) {
          return const ExaminerDashboardScreen();
        },

        '/examinee': (context) {
          return const ExamineeDashboardScreen();
        },

        '/register': (context) {
          return const RegisterScreen();
        },
      },
    );
  }
}
