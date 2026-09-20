import 'package:flutter/material.dart';
import 'package:questionbank/screens/admin/programs_screen.dart';
import 'package:questionbank/screens/admin/questions_screen.dart';
import 'package:questionbank/screens/admin/subjects_screen.dart';
import 'package:questionbank/screens/admin/topics_screen.dart';
import 'package:questionbank/screens/admin/users_screen.dart';

import 'learning_areas_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {

  int _selectedIndex = 0;

  void _selectSection(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (_isMobile(context)) {
      Navigator.pop(context);
    }
  }

  Widget _buildMainContent() {
    switch (_selectedIndex) {
      case 1:
        return const UsersScreen();

      case 2:
        return const LearningAreasScreen();

      case 3:
        return const ProgramsScreen();

      case 4:
        return const SubjectsScreen();

      case 5:
        return const TopicsScreen();

        case 6:
        return const QuestionsScreen();

      case 0:
      default:
        return _buildDashboardHome();
    }
  }

  Widget _buildDashboardHome() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dashboard',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Welcome to Question Bank Administration',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),

          const SizedBox(height: 30),

          _buildDashboardCards(context),
        ],
      ),
    );
  }

  Widget _buildDashboardCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return SizedBox(
      height: 100,
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                icon,
                size: 36,
                color: Colors.blue.shade700,
              ),

              const SizedBox(width: 14),

              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardCards(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    int columns;

    if (width < 600) {
      columns = 1;
    } else if (width < 1000) {
      columns = 2;
    } else {
      columns = 4;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 16.0;

        final cardWidth =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            SizedBox(
              width: cardWidth,
              child: _buildDashboardCard(
                title: 'Users',
                value: '25',
                icon: Icons.people_outline,
              ),
            ),

            SizedBox(
              width: cardWidth,
              child: _buildDashboardCard(
                title: 'Total Questions',
                value: '430',
                icon: Icons.question_mark_outlined,
              ),
            ),

            SizedBox(
              width: cardWidth,
              child: _buildDashboardCard(
                title: 'Exams',
                value: '8',
                icon: Icons.assignment_outlined,
              ),
            ),

            SizedBox(
              width: cardWidth,
              child: _buildDashboardCard(
                title: 'Results',
                value: '56',
                icon: Icons.bar_chart_outlined,
              ),
            ),
          ],
        );
      },
    );
  }

  bool _isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 700;
  }

  Widget _buildSidebar() {
    return Container(
      width: 240,
      color: Colors.blue.shade900,
      child: Column(
        children: [
          const SizedBox(height: 30),

          const Text(
            'QUESTION BANK',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 40),

          Material(
            color: Colors.transparent,
            child: ListTile(
              leading: const Icon(
                Icons.dashboard_outlined,
                color: Colors.white,
              ),
              title: const Text(
                'Dashboard',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                setState(() {
                  _selectSection(0);
                });
              },
            ),
          ),

          Material(
            color: Colors.transparent,
            child: ListTile(
              leading: const Icon(
                Icons.people_outline,
                color: Colors.white,
              ),
              title: const Text(
                'Users',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                setState(() {
                  _selectSection(1);
                });
              },
            ),
          ),

          Material(
            color: Colors.transparent,
            child: ListTile(
              leading: const Icon(
                Icons.question_mark_outlined,
                color: Colors.white,
              ),
              title: const Text(
                'Questions',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
              onTap: () {
                _selectSection(2);
              },
            ),
          ),

          Material(
            color: Colors.transparent,
            child: ListTile(
              leading: const Icon(
                Icons.school_outlined,
                color: Colors.white,
              ),
              title: const Text(
                'Programs',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
              onTap: () {
                _selectSection(3);
              },
            ),
          ),

          Material(
            color: Colors.transparent,
            child: ListTile(
              leading: const Icon(
                Icons.school_outlined,
                color: Colors.white,
              ),
              title: const Text(
                'Subjects',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
              onTap: () {
                _selectSection(4);
              },
            ),
          ),

          Material(
            color: Colors.transparent,
            child: ListTile(
              leading: const Icon(
                Icons.school_outlined,
                color: Colors.white,
              ),
              title: const Text(
                'Topics',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
              onTap: () {
                _selectSection(5);
              },
            ),
          ),

          Material(
            color: Colors.transparent,
            child: ListTile(
              leading: const Icon(
                Icons.school_outlined,
                color: Colors.white,
              ),
              title: const Text(
                'Manage Questions',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
              onTap: () {
                _selectSection(6);
              },
            ),
          ),

          Material(
            color: Colors.transparent,
            child: ListTile(
              leading: const Icon(
                Icons.assignment_outlined,
                color: Colors.white,
              ),
              title: const Text(
                'Exams',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {},
            ),
          ),

          Material(
            color: Colors.transparent,
            child: ListTile(
              leading: const Icon(
                Icons.bar_chart_outlined,
                color: Colors.white,
              ),
              title: const Text(
                'Results',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {},
            ),
          ),

          const Spacer(),

          Material(
            color: Colors.transparent,
            child: ListTile(
              leading: const Icon(
                Icons.settings_outlined,
                color: Colors.white,
              ),
              title: const Text(
                'Settings',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {},
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Admin Dashboard"),
      ),
      drawer: _isMobile(context)
          ? Drawer(
        child: _buildSidebar(),
      )
          : null,
      body: Row(
        children: [
          // Sidebar
          if (!_isMobile(context))
            _buildSidebar(),

          // Main content
          Expanded(
            child: _buildMainContent(),
          ),
        ],
      ),
    );
  }
}
