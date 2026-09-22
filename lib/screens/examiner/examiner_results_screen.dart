import 'package:flutter/material.dart';
import 'package:questionbank/models/exam.dart';
import 'package:questionbank/models/exam_result.dart';
import 'package:questionbank/services/exam_result_service.dart';
import 'package:questionbank/services/exam_service.dart';

import 'examiner_result_assessment_screen.dart';

class ExaminerResultsScreen extends StatefulWidget {
  const ExaminerResultsScreen({super.key});

  @override
  State<ExaminerResultsScreen> createState() => _ExaminerResultsScreenState();
}

class _ExaminerResultsScreenState extends State<ExaminerResultsScreen> {
  final ExamResultService _resultService = ExamResultService();
  final ExamService _examService = ExamService();

  bool _isLoading = true;
  String? _errorMessage;

  List<ExamResult> _results = [];
  Map<String, Exam> _examsById = {};

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  Future<void> _loadResults() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final results = await _resultService.getAllResults();
      final exams = await _examService.getAllExams();

      if (!mounted) return;

      setState(() {
        _results = results;
        _examsById = {for (final exam in exams) exam.examId: exam};
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'The exam results could not be loaded.';
        _isLoading = false;
      });
    }
  }

  Exam? _getExam(String examId) {
    return _examsById[examId];
  }

  int _getPendingCount(ExamResult result) {
    return result.questionResults
        .where((question) => question.assessmentStatus.name == 'pending')
        .length;
  }

  String _formatMarks(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toString();
  }

  String _formatPercentage(double value) {
    return '${value.toStringAsFixed(1)}%';
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  void _openAssessment(ExamResult result) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) =>
                ExaminerResultAssessmentScreen(result: result),
          ),
        )
        .then((_) {
          if (mounted) {
            _loadResults();
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;

          final horizontalPadding = width >= 1000
              ? 28.0
              : width >= 600
              ? 22.0
              : 14.0;

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              width >= 600 ? 28 : 18,
              horizontalPadding,
              28,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 22),
                    _buildSummary(context),
                    const SizedBox(height: 22),
                    _buildContent(context),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Exam Results',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Review submitted examinations '
                'and assess written answers.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: 'Refresh',
          onPressed: _isLoading ? null : _loadResults,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    );
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Widget _buildSummary(BuildContext context) {
    final theme = Theme.of(context);

    final totalResults = _results.length;

    final pendingResults = _results
        .where((result) => _getPendingCount(result) > 0)
        .length;

    final completedResults = _results
        .where((result) => _getPendingCount(result) == 0)
        .length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final cards = [
          _buildSummaryCard(
            theme,
            icon: Icons.assignment_rounded,
            title: 'Total Results',
            value: '$totalResults',
            color: Colors.indigo,
          ),
          _buildSummaryCard(
            theme,
            icon: Icons.pending_actions_rounded,
            title: 'Pending Assessment',
            value: '$pendingResults',
            color: Colors.orange,
          ),
          _buildSummaryCard(
            theme,
            icon: Icons.check_circle_outline_rounded,
            title: 'Completed',
            value: '$completedResults',
            color: Colors.green,
          ),
        ];

        if (width < 520) {
          return Column(
            children: cards
                .map(
                  (card) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: card,
                  ),
                )
                .toList(),
          );
        }

        if (width < 850) {
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: cards
                .map((card) => SizedBox(width: (width - 12) / 2, child: card))
                .toList(),
          );
        }

        return Row(
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: 12),
            Expanded(child: cards[1]),
            const SizedBox(width: 12),
            Expanded(child: cards[2]),
          ],
        );
      },
    );
  }

  Widget _buildSummaryCard(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            offset: const Offset(0, 4),
            color: Colors.black.withValues(alpha: 0.035),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CONTENT
  // ============================================================

  Widget _buildContent(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(50),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState(context);
    }

    if (_results.isEmpty) {
      return _buildEmptyState(context);
    }

    return _buildResultsContent(context);
  }

  Widget _buildResultsContent(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 850) {
          return _buildResponsiveResultCards(context);
        }

        return _buildDesktopResultsTable(context);
      },
    );
  }

  // ============================================================
  // DESKTOP RESULTS TABLE
  // ============================================================

  Widget _buildDesktopResultsTable(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            blurRadius: 14,
            offset: const Offset(0, 5),
            color: Colors.black.withValues(alpha: 0.035),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            _buildDesktopTableHeader(context),
            ..._results.map((result) => _buildDesktopTableRow(context, result)),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopTableHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
      child: Row(
        children: [
          _buildTableHeaderCell('EXAM', flex: 3),
          _buildTableHeaderCell('CANDIDATE', flex: 2),
          _buildTableHeaderCell('DATE', flex: 1),
          _buildTableHeaderCell('SCORE', flex: 1),
          _buildTableHeaderCell('PERCENTAGE', flex: 1),
          _buildTableHeaderCell('STATUS', flex: 1),
          _buildTableHeaderCell('ASSESSMENT', flex: 1),
          _buildTableHeaderCell('ACTION', flex: 1),
        ],
      ),
    );
  }

  Widget _buildTableHeaderCell(String text, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.65,
        ),
      ),
    );
  }

  Widget _buildDesktopTableRow(BuildContext context, ExamResult result) {
    final theme = Theme.of(context);

    final exam = _getExam(result.examId);
    final pending = _getPendingCount(result);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.30)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // EXAM
          Expanded(flex: 3, child: _buildExamCell(context, exam, result)),

          const SizedBox(width: 10),

          // CANDIDATE
          Expanded(flex: 2, child: _buildCandidateCell(context, result)),

          const SizedBox(width: 10),

          // DATE
          Expanded(
            flex: 1,
            child: Text(
              _formatDate(result.completedAt),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
          ),

          const SizedBox(width: 10),

          // SCORE
          Expanded(
            flex: 1,
            child: Text(
              '${_formatMarks(result.score)} / '
              '${_formatMarks(result.totalMarks)}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),

          const SizedBox(width: 10),

          // PERCENTAGE
          Expanded(
            flex: 1,
            child: Text(
              _formatPercentage(result.percentage),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
          ),

          const SizedBox(width: 10),

          // STATUS
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildResultStatus(context, result),
            ),
          ),

          const SizedBox(width: 10),

          // ASSESSMENT
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildAssessmentStatus(context, pending),
            ),
          ),

          const SizedBox(width: 10),

          // ACTION
          Expanded(flex: 1, child: _buildDesktopActionButton(context, result)),
        ],
      ),
    );
  }

  Widget _buildDesktopActionButton(BuildContext context, ExamResult result) {
    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        height: 38,
        child: FilledButton(
          onPressed: () => _openAssessment(result),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          child: const Icon(Icons.rate_review_outlined, size: 17),
        ),
      ),
    );
  }

  // ============================================================
  // RESPONSIVE CARDS
  // ============================================================

  Widget _buildResponsiveResultCards(BuildContext context) {
    return Column(
      children: _results.map((result) {
        final exam = _getExam(result.examId);
        final pending = _getPendingCount(result);

        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _buildResultCard(
            context,
            result: result,
            exam: exam,
            pending: pending,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildResultCard(
    BuildContext context, {
    required ExamResult result,
    required Exam? exam,
    required int pending,
  }) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            offset: const Offset(0, 4),
            color: Colors.black.withValues(alpha: 0.035),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMobileExamHeader(context, exam: exam, result: result),

          const SizedBox(height: 16),

          Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.35)),

          const SizedBox(height: 16),

          _buildMobileInfoRow(
            context,
            icon: Icons.person_outline_rounded,
            label: 'Candidate',
            child: Text(
              result.userId,
              softWrap: true,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),

          const SizedBox(height: 13),

          _buildMobileInfoRow(
            context,
            icon: Icons.calendar_today_outlined,
            label: 'Completed',
            child: Text(_formatDate(result.completedAt)),
          ),

          const SizedBox(height: 13),

          _buildMobileInfoRow(
            context,
            icon: Icons.scoreboard_outlined,
            label: 'Score',
            child: Text(
              '${_formatMarks(result.score)} / '
              '${_formatMarks(result.totalMarks)}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),

          const SizedBox(height: 13),

          _buildMobileInfoRow(
            context,
            icon: Icons.percent_rounded,
            label: 'Percentage',
            child: Text(
              _formatPercentage(result.percentage),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),

          const SizedBox(height: 13),

          _buildMobileInfoRow(
            context,
            icon: Icons.rate_review_outlined,
            label: 'Assessment',
            child: _buildAssessmentStatus(context, pending),
          ),

          const SizedBox(height: 18),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _openAssessment(result),
              icon: const Icon(Icons.rate_review_outlined, size: 18),
              label: const Text('Assess Result'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileExamHeader(
    BuildContext context, {
    required Exam? exam,
    required ExamResult result,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.assignment_rounded,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                exam?.examName ?? 'Unknown Exam',
                softWrap: true,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        Text(
          'Exam ID: ${result.examId}',
          softWrap: true,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),

        const SizedBox(height: 12),

        _buildResultStatus(context, result),
      ],
    );
  }

  Widget _buildMobileInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Widget child,
  }) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          child: Icon(
            icon,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 78,
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: child),
      ],
    );
  }

  // ============================================================
  // DESKTOP CELLS
  // ============================================================

  Widget _buildExamCell(BuildContext context, Exam? exam, ExamResult result) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.assignment_rounded,
            size: 18,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                exam?.examName ?? 'Unknown Exam',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                softWrap: true,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                result.examId,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCandidateCell(BuildContext context, ExamResult result) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.person_outline_rounded,
            size: 17,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            result.userId,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // STATUS
  // ============================================================

  Widget _buildResultStatus(BuildContext context, ExamResult result) {
    final color = result.passed ? Colors.green : Colors.red;

    return _buildStatusPill(
      icon: result.passed ? Icons.check_circle_rounded : Icons.cancel_rounded,
      label: result.passed ? 'Passed' : 'Not Passed',
      color: color,
    );
  }

  Widget _buildAssessmentStatus(BuildContext context, int pending) {
    if (pending == 0) {
      return _buildStatusPill(
        icon: Icons.check_circle_outline_rounded,
        label: 'Complete',
        color: Colors.green,
      );
    }

    return _buildStatusPill(
      icon: Icons.pending_actions_rounded,
      label: '$pending Pending',
      color: Colors.orange,
    );
  }

  Widget _buildStatusPill({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 120),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 54,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No Exam Results',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 7),
          Text(
            'Submitted exam results will '
            'appear here.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR STATE
  // ============================================================

  Widget _buildErrorState(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 50,
            color: Colors.redAccent,
          ),
          const SizedBox(height: 14),
          Text(
            _errorMessage ?? 'Something went wrong.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _loadResults,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
