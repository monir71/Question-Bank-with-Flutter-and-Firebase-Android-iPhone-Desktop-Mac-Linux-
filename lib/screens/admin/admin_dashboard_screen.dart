import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:questionbank/models/question.dart';
import 'package:questionbank/screens/admin/exams_screen.dart';
import 'package:questionbank/screens/admin/programs_screen.dart';
import 'package:questionbank/screens/admin/questions_screen.dart';
import 'package:questionbank/screens/admin/question_from_others_screen.dart';
import 'package:questionbank/screens/admin/result_screen.dart';
import 'package:questionbank/screens/admin/subjects_screen.dart';
import 'package:questionbank/screens/admin/topics_screen.dart';
import 'package:questionbank/screens/admin/users_screen.dart';
import 'package:questionbank/services/question_service.dart';
import 'package:questionbank/services/user_service.dart';

import 'learning_areas_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

  final UserService _userService = UserService();
  final QuestionService _questionService = QuestionService();

  int _totalUsers = 0;
  int _totalApprovedQuestions = 0;
  int _totalExams = 0;
  int _totalApprovedResults = 0;

  bool _usersLoading = true;
  bool _questionsLoading = true;
  bool _examsLoading = true;
  bool _resultsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    _loadTotalUsers();
    _loadApprovedQuestions();
    _loadTotalExams();
    _loadApprovedResults();
  }

  Future<void> _loadTotalUsers() async {
    try {
      final users = await _userService.getAllUsers();

      if (!mounted) return;

      setState(() {
        _totalUsers = users.length;
        _usersLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _usersLoading = false;
      });

      _showMessage('Unable to load total users.\n$e', isError: true);
    }
  }

  Future<void> _loadApprovedQuestions() async {
    try {
      final questions = await _questionService.getQuestionsByStatus(
        QuestionStatus.approved,
      );

      if (!mounted) return;

      setState(() {
        _totalApprovedQuestions = questions.length;
        _questionsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _questionsLoading = false;
      });

      _showMessage('Unable to load approved questions.\n$e', isError: true);
    }
  }

  Future<void> _loadTotalExams() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('exams')
          .get();

      if (!mounted) return;

      setState(() {
        _totalExams = snapshot.docs.length;
        _examsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _examsLoading = false;
      });

      _showMessage('Unable to load total exams.\n$e', isError: true);
    }
  }

  Future<void> _loadApprovedResults() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('examResults')
          .where('isPublished', isEqualTo: true)
          .get();

      if (!mounted) return;

      setState(() {
        _totalApprovedResults = snapshot.docs.length;
        _resultsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _resultsLoading = false;
      });

      _showMessage('Unable to load approved results.\n$e', isError: true);
    }
  }

  void _refreshDashboard() {
    setState(() {
      _usersLoading = true;
      _questionsLoading = true;
      _examsLoading = true;
      _resultsLoading = true;
    });

    _loadDashboardData();
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red.shade700 : null,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _selectSection(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      _refreshDashboard();
    }

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

      case 7:
        return const QuestionFromOthersScreen();

      case 8:
        return const ExamsScreen();

      case 9:
        return const ResultScreen();

      case 0:
      default:
        return _buildDashboardHome();
    }
  }

  Widget _buildDashboardHome() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dashboard',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      'Welcome to Question Bank Administration',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              IconButton(
                tooltip: 'Refresh dashboard',
                onPressed: _refreshDashboard,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),

          const SizedBox(height: 28),

          _buildDashboardCards(context),

          const SizedBox(height: 28),

          _buildWelcomePanel(),
        ],
      ),
    );
  }

  Widget _buildWelcomePanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [Colors.blue.shade900, Colors.blue.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade900.withValues(alpha: 0.15),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.admin_panel_settings_outlined,
              color: Colors.white,
              size: 32,
            ),
          ),

          const SizedBox(width: 18),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Administration Center',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  'Manage users, learning areas, programs, '
                  'subjects, topics and questions from one place.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCard({
    required String title,
    required String value,
    required IconData icon,
    required bool isLoading,
  }) {
    return SizedBox(
      height: 110,
      child: Card(
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 28, color: Colors.blue.shade800),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 5),

                    if (isLoading)
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.blue.shade700,
                        ),
                      )
                    else
                      Text(
                        value,
                        style: const TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardCards(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        int columns;

        if (width < 600) {
          columns = 1;
        } else if (width < 1000) {
          columns = 2;
        } else {
          columns = 4;
        }

        const spacing = 16.0;

        final cardWidth = (width - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            SizedBox(
              width: cardWidth,
              child: _buildDashboardCard(
                title: 'Total Users',
                value: _totalUsers.toString(),
                icon: Icons.people_outline,
                isLoading: _usersLoading,
              ),
            ),

            SizedBox(
              width: cardWidth,
              child: _buildDashboardCard(
                title: 'Approved Questions',
                value: _totalApprovedQuestions.toString(),
                icon: Icons.question_mark_outlined,
                isLoading: _questionsLoading,
              ),
            ),

            SizedBox(
              width: cardWidth,
              child: _buildDashboardCard(
                title: 'Total Exams',
                value: _totalExams.toString(),
                icon: Icons.assignment_outlined,
                isLoading: _examsLoading,
              ),
            ),

            SizedBox(
              width: cardWidth,
              child: _buildDashboardCard(
                title: 'Approved Results',
                value: _totalApprovedResults.toString(),
                icon: Icons.bar_chart_outlined,
                isLoading: _resultsLoading,
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
      width: 250,
      decoration: BoxDecoration(
        color: Colors.blue.shade900,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 22),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                  child: const Icon(
                    Icons.menu_book_outlined,
                    color: Colors.white,
                    size: 25,
                  ),
                ),

                const SizedBox(width: 12),

                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'QUESTION BANK',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),

                      SizedBox(height: 3),

                      Text(
                        'ADMIN PANEL',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: Colors.white.withValues(alpha: 0.10)),

          const SizedBox(height: 18),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  _buildSectionLabel('MAIN MENU'),

                  const SizedBox(height: 8),

                  _buildMenuItem(
                    index: 0,
                    icon: Icons.dashboard_outlined,
                    selectedIcon: Icons.dashboard_rounded,
                    title: 'Dashboard',
                  ),

                  _buildMenuItem(
                    index: 1,
                    icon: Icons.people_outline,
                    selectedIcon: Icons.people_rounded,
                    title: 'Users',
                  ),

                  const SizedBox(height: 16),

                  _buildSectionLabel('QUESTION MANAGEMENT'),

                  const SizedBox(height: 8),

                  _buildMenuItem(
                    index: 2,
                    icon: Icons.account_tree_outlined,
                    selectedIcon: Icons.account_tree_rounded,
                    title: 'Learning Areas',
                  ),

                  _buildMenuItem(
                    index: 3,
                    icon: Icons.school_outlined,
                    selectedIcon: Icons.school_rounded,
                    title: 'Programs',
                  ),

                  _buildMenuItem(
                    index: 4,
                    icon: Icons.menu_book_outlined,
                    selectedIcon: Icons.menu_book_rounded,
                    title: 'Subjects',
                  ),

                  _buildMenuItem(
                    index: 5,
                    icon: Icons.topic_outlined,
                    selectedIcon: Icons.topic_rounded,
                    title: 'Topics',
                  ),

                  _buildMenuItem(
                    index: 6,
                    icon: Icons.question_mark_outlined,
                    selectedIcon: Icons.question_mark_rounded,
                    title: 'Questions',
                  ),

                  _buildMenuItem(
                    index: 7,
                    icon: Icons.question_answer_outlined,
                    selectedIcon: Icons.question_answer_rounded,
                    title: 'Questions from Others',
                  ),

                  const SizedBox(height: 16),

                  _buildSectionLabel('EXAMINATION'),

                  const SizedBox(height: 8),

                  _buildMenuItem(
                    index: 8,
                    icon: Icons.assignment_outlined,
                    selectedIcon: Icons.assignment_rounded,
                    title: 'Exams',
                  ),

                  _buildMenuItem(
                    index: 9,
                    icon: Icons.bar_chart_outlined,
                    selectedIcon: Icons.bar_chart_rounded,
                    title: 'Results',
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 18),
            child: Column(
              children: [
                Divider(color: Colors.white.withValues(alpha: 0.10)),

                const SizedBox(height: 8),

                _buildDisabledMenuItem(
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          title,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.48),
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required int index,
    required IconData icon,
    required IconData selectedIcon,
    required String title,
  }) {
    final isSelected = _selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _selectSection(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.white.withValues(alpha: 0.16)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: Colors.white.withValues(alpha: 0.10))
                  : null,
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.14)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(
                    isSelected ? selectedIcon : icon,
                    size: 20,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ),

                if (isSelected)
                  Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDisabledMenuItem({
    required IconData icon,
    required String title,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                SizedBox(
                  width: 34,
                  height: 34,
                  child: Icon(icon, size: 20, color: Colors.white38),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                const Icon(Icons.lock_outline, size: 14, color: Colors.white30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = _isMobile(context);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue.shade900,
        surfaceTintColor: Colors.transparent,

        title: const Text(
          'Admin Dashboard',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),

        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.admin_panel_settings_outlined,
                    size: 18,
                    color: Colors.blue.shade800,
                  ),

                  const SizedBox(width: 6),

                  Text(
                    'Admin',
                    style: TextStyle(
                      color: Colors.blue.shade800,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      drawer: isMobile ? Drawer(child: _buildSidebar()) : null,

      body: Row(
        children: [
          if (!isMobile) _buildSidebar(),

          Expanded(child: _buildMainContent()),
        ],
      ),
    );
  }
}
