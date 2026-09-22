import 'package:flutter/material.dart';
import 'package:questionbank/models/exam.dart';
import 'package:questionbank/models/exam_attempt.dart';
import 'package:questionbank/models/exam_result.dart';
import 'package:questionbank/services/exam_result_service.dart';

import '../../models/exam_question_result.dart';

class ExamResultScreen extends StatefulWidget {
  final Exam exam;
  final ExamAttempt attempt;

  const ExamResultScreen({
    super.key,
    required this.exam,
    required this.attempt,
  });

  @override
  State<ExamResultScreen> createState() => _ExamResultScreenState();
}

class _ExamResultScreenState extends State<ExamResultScreen> {
  final ExamResultService _resultService = ExamResultService();

  bool _isLoading = true;
  String? _errorMessage;
  ExamResult? _result;

  @override
  void initState() {
    super.initState();
    _loadResult();
  }

  Future<void> _loadResult() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final result = await _resultService.getResultByAttemptId(
        widget.attempt.attemptId,
      );

      if (!mounted) return;

      if (result == null) {
        setState(() {
          _errorMessage = 'The exam result could not be found.';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _result = result;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'The exam result could not be loaded.';
        _isLoading = false;
      });
    }
  }

  int get _pendingAssessmentCount {
    final result = _result;

    if (result == null) return 0;

    return result.questionResults
        .where(
          (question) =>
              question.assessmentStatus == QuestionAssessmentStatus.pending,
        )
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

  String _formatSubmissionType(ExamResultSubmissionType type) {
    switch (type) {
      case ExamResultSubmissionType.manual:
        return 'Manual Submission';

      case ExamResultSubmissionType.automatic:
        return 'Automatic Submission';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exam Result')),
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
              20,
              horizontalPadding,
              30,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: _buildBody(context),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(60),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState(context);
    }

    if (_result == null) {
      return _buildErrorState(context);
    }

    return _buildResult(context, _result!);
  }

  Widget _buildResult(BuildContext context, ExamResult result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildExamHeader(context, result),
        const SizedBox(height: 18),
        _buildResultHero(context, result),
        const SizedBox(height: 18),
        _buildStatistics(context, result),
        const SizedBox(height: 18),
        _buildSubmissionInformation(context, result),
        const SizedBox(height: 18),
        _buildAssessmentInformation(context, result),
        const SizedBox(height: 24),
        _buildActionButtons(context, result),
      ],
    );
  }

  // ============================================================
  // EXAM HEADER
  // ============================================================

  Widget _buildExamHeader(BuildContext context, ExamResult result) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.assignment_turned_in_rounded,
              color: theme.colorScheme.primary,
              size: 25,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.exam.examName,
                  softWrap: true,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Your examination has been submitted.',
                  softWrap: true,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
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
  // RESULT HERO
  // ============================================================

  Widget _buildResultHero(BuildContext context, ExamResult result) {
    final theme = Theme.of(context);

    final statusColor = result.passed ? Colors.green : Colors.red;

    final statusIcon = result.passed
        ? Icons.check_circle_rounded
        : Icons.cancel_rounded;

    final statusText = result.passed ? 'PASSED' : 'NOT PASSED';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withValues(alpha: 0.20)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 520) {
            return Column(
              children: [
                _buildScoreDisplay(context, result),
                const SizedBox(height: 22),
                _buildPassStatus(
                  context,
                  result,
                  statusColor,
                  statusIcon,
                  statusText,
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: _buildScoreDisplay(context, result)),
              const SizedBox(width: 20),
              _buildPassStatus(
                context,
                result,
                statusColor,
                statusIcon,
                statusText,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildScoreDisplay(BuildContext context, ExamResult result) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Score',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          '${_formatMarks(result.score)} / '
          '${_formatMarks(result.totalMarks)}',
          style: theme.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          _formatPercentage(result.percentage),
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildPassStatus(
    BuildContext context,
    ExamResult result,
    Color color,
    IconData icon,
    String text,
  ) {
    final theme = Theme.of(context);

    return Container(
      constraints: const BoxConstraints(minWidth: 150),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 7),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pass mark: '
            '${_formatPercentage(result.passPercentage)}',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STATISTICS
  // ============================================================

  Widget _buildStatistics(BuildContext context, ExamResult result) {
    final theme = Theme.of(context);

    final cards = [
      _buildStatisticCard(
        context,
        icon: Icons.quiz_outlined,
        label: 'Questions',
        value: '${result.totalQuestions}',
        color: Colors.indigo,
      ),
      _buildStatisticCard(
        context,
        icon: Icons.check_circle_outline_rounded,
        label: 'Correct',
        value: '${result.correctAnswers}',
        color: Colors.green,
      ),
      _buildStatisticCard(
        context,
        icon: Icons.cancel_outlined,
        label: 'Wrong',
        value: '${result.wrongAnswers}',
        color: Colors.red,
      ),
      _buildStatisticCard(
        context,
        icon: Icons.help_outline_rounded,
        label: 'Unanswered',
        value: '${result.unansweredQuestions}',
        color: Colors.orange,
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.35)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 500) {
            return Column(
              children: cards
                  .map(
                    (card) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: card,
                    ),
                  )
                  .toList(),
            );
          }

          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: cards
                .map(
                  (card) => SizedBox(
                    width: (constraints.maxWidth - 10) / 2,
                    child: card,
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }

  Widget _buildStatisticCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.titleLarge?.copyWith(
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
  // SUBMISSION INFORMATION
  // ============================================================

  Widget _buildSubmissionInformation(BuildContext context, ExamResult result) {
    final theme = Theme.of(context);

    return _buildInformationCard(
      context,
      title: 'Submission Information',
      icon: Icons.info_outline_rounded,
      children: [
        _buildInformationRow(
          context,
          label: 'Submission Type',
          value: _formatSubmissionType(result.submissionType),
        ),
        _buildInformationRow(
          context,
          label: 'Attempt ID',
          value: result.attemptId,
        ),
        _buildInformationRow(
          context,
          label: 'Completed',
          value: _formatDateTime(result.completedAt),
        ),
      ],
    );
  }

  // ============================================================
  // ASSESSMENT INFORMATION
  // ============================================================

  Widget _buildAssessmentInformation(BuildContext context, ExamResult result) {
    final pending = _pendingAssessmentCount;
    final theme = Theme.of(context);

    return _buildInformationCard(
      context,
      title: 'Assessment Status',
      icon: Icons.rate_review_outlined,
      children: [
        if (pending == 0)
          _buildAssessmentMessage(
            context,
            icon: Icons.check_circle_outline_rounded,
            color: Colors.green,
            message: 'All questions have been assessed.',
          )
        else
          _buildAssessmentMessage(
            context,
            icon: Icons.pending_actions_rounded,
            color: Colors.orange,
            message:
                '$pending written question'
                '${pending == 1 ? '' : 's'} '
                'still require manual assessment.',
          ),
        if (pending > 0) ...[
          const SizedBox(height: 8),
          Text(
            'The displayed score may change after '
            'written answers are assessed.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAssessmentMessage(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              softWrap: true,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INFORMATION CARD
  // ============================================================

  Widget _buildInformationCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 21, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInformationRow(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 135,
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
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              softWrap: true,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day/$month/${date.year} '
        '$hour:$minute';
  }

  // ============================================================
  // ACTIONS
  // ============================================================

  Widget _buildActionButtons(BuildContext context, ExamResult result) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 520) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Detailed result view '
                        'will be added in the next step.',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.fact_check_outlined),
                label: const Text('View Detailed Result'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Back'),
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Detailed result view '
                        'will be added in the next step.',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.fact_check_outlined),
                label: const Text('View Detailed Result'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Back'),
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // ERROR STATE
  // ============================================================

  Widget _buildErrorState(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.red.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 52,
            color: Colors.redAccent,
          ),
          const SizedBox(height: 14),
          Text(
            _errorMessage ??
                'Something went wrong while '
                    'loading the result.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _loadResult,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
