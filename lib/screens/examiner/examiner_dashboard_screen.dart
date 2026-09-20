import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ExaminerDashboardScreen extends StatefulWidget {
  const ExaminerDashboardScreen({super.key});

  @override
  State<ExaminerDashboardScreen> createState() => _ExaminerDashboardScreenState();
}

class _ExaminerDashboardScreenState extends State<ExaminerDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Examiner Screen"),
          ],
        ),
      ),
    );
  }
}
