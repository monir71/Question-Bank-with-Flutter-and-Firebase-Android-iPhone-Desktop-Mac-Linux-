import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:questionbank/models/exam.dart';
import 'package:questionbank/models/exam_attempt.dart';
import 'package:questionbank/models/exam_result.dart';
import 'package:questionbank/models/learning_area.dart';
import 'package:questionbank/services/exam_attempt_service.dart';
import 'package:questionbank/services/exam_result_service.dart';
import 'package:questionbank/services/exam_service.dart';
import 'package:questionbank/services/learning_area_service.dart';

import '../../models/exam_question_result.dart';
import 'exam_result_screen.dart';
import 'examinee_learning_area_screen.dart';

class ExamineeDashboardScreen extends StatefulWidget {
  const ExamineeDashboardScreen({super.key});

  @override
  State<ExamineeDashboardScreen> createState() =>
      _ExamineeDashboardScreenState();
}

class _ExamineeDashboardScreenState extends State<ExamineeDashboardScreen> {
  final LearningAreaService _learningAreaService = LearningAreaService();

  final ExamResultService _resultService = ExamResultService();

  final ExamService _examService = ExamService();

  final ExamAttemptService _attemptService = ExamAttemptService();

  bool _isLoading = true;
  String? _errorMessage;

  List<LearningArea> _learningAreas = [];
  List<ExamResult> _publishedResults = [];

  /// Exam names are loaded only for exams that actually appear
  /// in the examinee's published results.
  final Map<String, String> _examNames = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception('You are not logged in.');
      }

      /*
       * IMPORTANT:
       *
       * The dashboard no longer loads:
       *   - all exams
       *   - all programs
       *   - all subjects
       *
       * Those are loaded only when the examinee drills down
       * into the hierarchy.
       */
      final learningAreas = await _learningAreaService.getAllLearningAreas();

      final allResults = await _resultService.getResultsByUser(user.uid);

      if (!mounted) return;

      /*
       * A result is visible to the examinee only when all
       * questions have completed assessment.
       *
       * This is the current interim publication rule.
       */
      final publishedResults = allResults.where((result) {
        return !result.questionResults.any(
          (question) =>
              question.assessmentStatus == QuestionAssessmentStatus.pending,
        );
      }).toList();

      setState(() {
        _learningAreas = learningAreas;
        _publishedResults = publishedResults;
        _isLoading = false;
      });

      /*
       * Load names only for exams represented in the
       * published results.
       *
       * This avoids loading the entire exams collection.
       */
      await _loadExamNames(publishedResults);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _loadExamNames(List<ExamResult> results) async {
    final examIds = results
        .map((result) => result.examId)
        .where((id) => id.isNotEmpty)
        .toSet();

    if (examIds.isEmpty) return;

    for (final examId in examIds) {
      try {
        final exam = await _examService.getExamById(examId);

        if (exam != null && mounted) {
          setState(() {
            _examNames[examId] = exam.examName;
          });
        }
      } catch (_) {
        // Do not make the dashboard fail because an old
        // or unavailable exam document cannot be loaded.
      }
    }
  }

  String _displayName() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return 'Examinee';
    }

    if (user.displayName != null && user.displayName!.trim().isNotEmpty) {
      return user.displayName!.trim();
    }

    final email = user.email;

    if (email != null && email.contains('@')) {
      return email.split('@').first;
    }

    return 'Examinee';
  }

  String _formatMarks(double marks) {
    if (marks == marks.roundToDouble()) {
      return marks.toInt().toString();
    }

    return marks.toStringAsFixed(1);
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(1);
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> _openResult(ExamResult result) async {
    try {
      final results = await Future.wait([
        _examService.getExamById(result.examId),
        _attemptService.getAttemptById(result.attemptId),
      ]);

      if (!mounted) return;

      final exam = results[0] as Exam?;
      final attempt = results[1] as ExamAttempt?;

      if (exam == null || attempt == null) {
        throw Exception('The exam result could not be loaded.');
      }

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) {
            return ExamResultScreen(exam: exam, attempt: attempt);
          },
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to open result: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildWelcomeHeader() {
    final name = _displayName();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(26, 25, 26, 25),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade800, Colors.indigo.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withValues(alpha: 0.20),
            blurRadius: 18,
            offset: const Offset(0, 8),
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
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: const Icon(
              Icons.school_rounded,
              color: Colors.white,
              size: 31,
            ),
          ),
          const SizedBox(width: 17),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back, $name 👋',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Choose your learning area, explore your program and take examinations.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color, size: 23),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle({
    required IconData icon,
    required String title,
    required String count,
  }) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.indigo.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: Colors.indigo, size: 20),
        ),
        const SizedBox(width: 11),
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 9),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.indigo.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            count,
            style: const TextStyle(
              color: Colors.indigo,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLearningAreaTile(LearningArea area) {
    return InkWell(
      borderRadius: BorderRadius.circular(19),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) {
              return ExamineeLearningAreaScreen(learningArea: area);
            },
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.indigo.withValues(alpha: 0.14),
                    Colors.indigo.withValues(alpha: 0.06),
                  ],
                ),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(
                Icons.auto_stories_rounded,
                color: Colors.indigo,
                size: 27,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    area.name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Explore programs and examinations',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 17,
              color: Colors.grey.shade500,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLearningAreas() {
    final activeAreas = _learningAreas.where((area) => area.isActive).toList()
      ..sort((a, b) {
        final sortComparison = a.sortOrder.compareTo(b.sortOrder);

        if (sortComparison != 0) {
          return sortComparison;
        }

        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

    if (activeAreas.isEmpty) {
      return _buildEmptyCard(
        icon: Icons.auto_stories_outlined,
        title: 'No learning areas available',
        message:
            'Learning programs will appear here when they become available.',
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 850;

        if (!isWide) {
          return Column(
            children: activeAreas.map(_buildLearningAreaTile).toList(),
          );
        }

        final cardWidth = (constraints.maxWidth - 16) / 2;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: activeAreas.map((area) {
            return SizedBox(
              width: cardWidth,
              child: _buildLearningAreaTile(area),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildResultCard(ExamResult result) {
    final passedColor = result.passed ? Colors.green : Colors.orange;

    final examName = _examNames[result.examId] ?? 'Exam Result';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 47,
            height: 47,
            decoration: BoxDecoration(
              color: passedColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              result.passed
                  ? Icons.emoji_events_rounded
                  : Icons.assessment_rounded,
              color: passedColor,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  examName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${_formatDate(result.completedAt)} • '
                  '${_formatMarks(result.score)} / '
                  '${_formatMarks(result.totalMarks)}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_formatNumber(result.percentage)}%',
                style: TextStyle(
                  color: passedColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: passedColor.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  result.passed ? 'Passed' : 'Not Passed',
                  style: TextStyle(
                    color: passedColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'View Result',
            onPressed: () => _openResult(result),
            icon: const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 17,
              color: Colors.indigo,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsSection() {
    if (_publishedResults.isEmpty) {
      return _buildEmptyCard(
        icon: Icons.bar_chart_rounded,
        title: 'No published results yet',
        message:
            'Your completed exam results will appear here after assessment is complete.',
      );
    }

    return Column(
      children: _publishedResults.take(10).map(_buildResultCard).toList(),
    );
  }

  Widget _buildEmptyCard({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 13),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 7),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(60),
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 54, color: Colors.red.shade300),
            const SizedBox(height: 15),
            const Text(
              'Unable to load your dashboard',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'An unexpected error occurred.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    final activeLearningAreaCount = _learningAreas
        .where((area) => area.isActive)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildWelcomeHeader(),

        const SizedBox(height: 18),

        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 800;

            if (isWide) {
              return Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      icon: Icons.auto_stories_rounded,
                      value: '$activeLearningAreaCount',
                      label: 'Learning Areas',
                      color: Colors.indigo,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      icon: Icons.emoji_events_outlined,
                      value: '${_publishedResults.length}',
                      label: 'Published Results',
                      color: Colors.green,
                    ),
                  ),
                ],
              );
            }

            return Column(
              children: [
                _buildSummaryCard(
                  icon: Icons.auto_stories_rounded,
                  value: '$activeLearningAreaCount',
                  label: 'Learning Areas',
                  color: Colors.indigo,
                ),
                const SizedBox(height: 10),
                _buildSummaryCard(
                  icon: Icons.emoji_events_outlined,
                  value: '${_publishedResults.length}',
                  label: 'Published Results',
                  color: Colors.green,
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 30),

        _buildSectionTitle(
          icon: Icons.account_tree_rounded,
          title: 'Learning Areas',
          count: '$activeLearningAreaCount',
        ),

        const SizedBox(height: 14),

        _buildLearningAreas(),

        const SizedBox(height: 30),

        _buildSectionTitle(
          icon: Icons.bar_chart_rounded,
          title: 'My Results',
          count: '${_publishedResults.length}',
        ),

        const SizedBox(height: 14),

        _buildResultsSection(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1400),
                child: _buildContent(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
