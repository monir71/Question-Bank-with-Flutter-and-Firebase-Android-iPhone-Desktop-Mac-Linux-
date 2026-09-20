import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ExamineeDashboardScreen extends StatefulWidget {
  const ExamineeDashboardScreen({super.key});

  @override
  State<ExamineeDashboardScreen> createState() => _ExamineeDashboardScreen();
}

class _ExamineeDashboardScreen extends State<ExamineeDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Examinee Screen"),
          ],
        ),
      ),
    );
  }
}
