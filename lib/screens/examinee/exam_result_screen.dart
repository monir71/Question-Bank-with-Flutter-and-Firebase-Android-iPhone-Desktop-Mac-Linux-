import 'package:flutter/material.dart';
import 'package:questionbank/models/exam.dart';
import 'package:questionbank/models/exam_attempt.dart';
import 'package:questionbank/models/exam_result.dart';
import 'package:questionbank/services/exam_result_service.dart';

import '../../models/exam_question_result.dart';
import 'examinee_detailed_result_screen.dart';

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

  void _openDetailedResult(ExamResult result) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExamineeDetailedResultScreen(
          exam: widget.exam,
          attempt: widget.attempt,
          result: result,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 2,
        title: const Text(
          'Exam Result',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;

          final horizontalPadding = width >= 1100
              ? 30.0
              : width >= 700
              ? 22.0
              : 14.0;

          return RefreshIndicator(
            onRefresh: _loadResult,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                20,
                horizontalPadding,
                32,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 1050,
                  ),
                  child: _buildBody(context),
                ),
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
        padding: EdgeInsets.all(70),
        child: Center(
          child: CircularProgressIndicator(),
        ),
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

  Widget _buildResult(
      BuildContext context,
      ExamResult result,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildExamHeader(context, result),
        const SizedBox(height: 16),
        _buildResultHero(context, result),
        const SizedBox(height: 16),
        _buildStatistics(context, result),
        const SizedBox(height: 16),
        _buildSubmissionInformation(context, result),
        const SizedBox(height: 16),
        _buildAssessmentInformation(context, result),
        const SizedBox(height: 22),
        _buildActionButtons(context, result),
      ],
    );
  }

  // ============================================================
  // EXAM HEADER
  // ============================================================

  Widget _buildExamHeader(
      BuildContext context,
      ExamResult result,
      ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final pending = _pendingAssessmentCount;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer,
            colorScheme.secondaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              Icons.assignment_turned_in_rounded,
              color: colorScheme.primary,
              size: 27,
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
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  pending == 0
                      ? 'Your examination has been completed and assessed.'
                      : 'Your examination has been submitted and is awaiting assessment.',
                  softWrap: true,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
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

  // ============================================================
  // RESULT HERO
  // ============================================================

  Widget _buildResultHero(
      BuildContext context,
      ExamResult result,
      ) {
    final theme = Theme.of(context);

    final isPublished = result.isPublished;

    final statusColor = !isPublished
        ? Colors.orange
        : result.passed
        ? Colors.green
        : Colors.red;

    final statusIcon = !isPublished
        ? Icons.pending_actions_rounded
        : result.passed
        ? Icons.check_circle_rounded
        : Icons.cancel_rounded;

    final statusText = !isPublished
        ? 'AWAITING ASSESSMENT'
        : result.passed
        ? 'PASSED'
        : 'NOT PASSED';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            statusColor.withValues(alpha: 0.10),
            statusColor.withValues(alpha: 0.035),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.22),
          width: 1.2,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 560) {
            return Column(
              children: [
                _buildScoreDisplay(
                  context,
                  result,
                ),
                const SizedBox(height: 20),
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: _buildScoreDisplay(
                  context,
                  result,
                ),
              ),
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

  Widget _buildScoreDisplay(
      BuildContext context,
      ExamResult result,
      ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (!result.isPublished) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Result Status',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Assessment in progress',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: Colors.orange.shade800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Your final score will be available after all written answers are assessed.',
            softWrap: true,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Score',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${_formatMarks(result.score)} / '
              '${_formatMarks(result.totalMarks)}',
          style: theme.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 11,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _formatPercentage(result.percentage),
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w800,
            ),
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
      constraints: const BoxConstraints(
        minWidth: 175,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 17,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: color.withValues(alpha: 0.20),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 29,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
              fontSize: 13,
            ),
          ),
          if (result.isPublished) ...[
            const SizedBox(height: 5),
            Text(
              'Pass mark: '
                  '${_formatPercentage(result.passPercentage)}',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color.withValues(alpha: 0.85),
                fontWeight: FontWeight.w500,
              ),
            ),
          ] else ...[
            const SizedBox(height: 5),
            Text(
              'Final result pending',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color.withValues(alpha: 0.85),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // STATISTICS
  // ============================================================

  Widget _buildStatistics(
      BuildContext context,
      ExamResult result,
      ) {
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 500) {
            return Column(
              children: [
                for (int i = 0; i < cards.length; i++)
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: i == cards.length - 1 ? 0 : 10,
                    ),
                    child: cards[i],
                  ),
              ],
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
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: color.withValues(alpha: 0.13),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              color: color,
              size: 21,
            ),
          ),
          const SizedBox(width: 11),
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
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
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

  Widget _buildSubmissionInformation(
      BuildContext context,
      ExamResult result,
      ) {
    return _buildInformationCard(
      context,
      title: 'Submission Information',
      icon: Icons.info_outline_rounded,
      iconColor: Colors.indigo,
      children: [
        _buildInformationRow(
          context,
          icon: Icons.send_outlined,
          label: 'Submission Type',
          value: _formatSubmissionType(
            result.submissionType,
          ),
        ),
        _buildInformationRow(
          context,
          icon: Icons.tag_outlined,
          label: 'Attempt ID',
          value: result.attemptId,
        ),
        _buildInformationRow(
          context,
          icon: Icons.schedule_outlined,
          label: 'Completed',
          value: _formatDateTime(
            result.completedAt,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ASSESSMENT INFORMATION
  // ============================================================

  Widget _buildAssessmentInformation(
      BuildContext context,
      ExamResult result,
      ) {
    final pending = _pendingAssessmentCount;
    final theme = Theme.of(context);

    return _buildInformationCard(
      context,
      title: 'Assessment Status',
      icon: Icons.rate_review_outlined,
      iconColor: pending == 0
          ? Colors.green
          : Colors.orange,
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
          const SizedBox(height: 9),
          Text(
            'The final score, percentage and pass/fail status '
                'will be available after assessment is complete.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.45,
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.065),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: color.withValues(alpha: 0.16),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 19,
              color: color,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              softWrap: true,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
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
        required Color iconColor,
        required List<Widget> children,
      }) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInformationRow(
      BuildContext context, {
        required IconData icon,
        required String label,
        required String value,
      }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 9),
          SizedBox(
            width: 125,
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              softWrap: true,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                height: 1.35,
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

    return '$day/$month/${date.year} $hour:$minute';
  }

  // ============================================================
  // ACTIONS
  // ============================================================

  Widget _buildActionButtons(
      BuildContext context,
      ExamResult result,
      ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 520) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton.icon(
                onPressed: () => _openDetailedResult(result),
                icon: const Icon(
                  Icons.fact_check_outlined,
                ),
                label: const Text(
                  'View Detailed Result',
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(
                  Icons.arrow_back_rounded,
                ),
                label: const Text('Back'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                  ),
                ),
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _openDetailedResult(result),
                icon: const Icon(
                  Icons.fact_check_outlined,
                ),
                label: const Text(
                  'View Detailed Result',
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(
                  Icons.arrow_back_rounded,
                ),
                label: const Text('Back'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                  ),
                ),
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
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.red.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              size: 38,
              color: Colors.redAccent,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage ??
                'Something went wrong while loading the result.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _loadResult,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}