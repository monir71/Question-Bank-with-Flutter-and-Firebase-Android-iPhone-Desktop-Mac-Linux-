import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:questionbank/models/exam_question_result.dart';
import 'package:questionbank/models/exam_result.dart';
import 'package:questionbank/models/question.dart';
import 'package:questionbank/services/exam_manual_assessment_service.dart';
import 'package:questionbank/services/exam_result_service.dart';
import 'package:questionbank/services/question_service.dart';

class ExaminerResultAssessmentScreen extends StatefulWidget {
  final ExamResult result;

  const ExaminerResultAssessmentScreen({super.key, required this.result});

  @override
  State<ExaminerResultAssessmentScreen> createState() =>
      _ExaminerResultAssessmentScreenState();
}

class _ExaminerResultAssessmentScreenState
    extends State<ExaminerResultAssessmentScreen> {
  final QuestionService _questionService = QuestionService();
  final ExamResultService _resultService = ExamResultService();
  final ExamManualAssessmentService _assessmentService =
      ExamManualAssessmentService();

  bool _isLoading = true;
  String? _errorMessage;

  late ExamResult _result;

  List<Question> _questions = [];

  final Map<String, TextEditingController> _markControllers = {};
  final Map<String, TextEditingController> _feedbackControllers = {};
  final Set<String> _savingQuestionIds = {};

  @override
  void initState() {
    super.initState();

    _result = widget.result;
    _loadQuestions();
  }

  @override
  void dispose() {
    for (final controller in _markControllers.values) {
      controller.dispose();
    }

    for (final controller in _feedbackControllers.values) {
      controller.dispose();
    }

    super.dispose();
  }

  Future<void> _loadQuestions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final questions = await _questionService.getAllQuestions();

      if (!mounted) return;

      setState(() {
        _questions = questions;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'The questions could not be loaded.';
        _isLoading = false;
      });
    }
  }

  Question? _getQuestion(String questionId) {
    for (final question in _questions) {
      if (question.questionId == questionId) {
        return question;
      }
    }

    return null;
  }

  ExamQuestionResult? _getQuestionResult(String questionId) {
    for (final questionResult in _result.questionResults) {
      if (questionResult.questionId == questionId) {
        return questionResult;
      }
    }

    return null;
  }

  TextEditingController _getMarkController(ExamQuestionResult questionResult) {
    return _markControllers.putIfAbsent(
      questionResult.questionId,
      () => TextEditingController(
        text:
            questionResult.assessmentStatus ==
                QuestionAssessmentStatus.manuallyAssessed
            ? questionResult.awardedMarks.toString()
            : '',
      ),
    );
  }

  TextEditingController _getFeedbackController(
    ExamQuestionResult questionResult,
  ) {
    return _feedbackControllers.putIfAbsent(
      questionResult.questionId,
      () => TextEditingController(text: questionResult.feedback ?? ''),
    );
  }

  Future<void> _saveAssessment(ExamQuestionResult questionResult) async {
    final firebaseUser = FirebaseAuth.instance.currentUser;

    if (firebaseUser == null) {
      _showMessage('You must be signed in to assess a result.');
      return;
    }

    final marksText = _getMarkController(questionResult).text.trim();

    if (marksText.isEmpty) {
      _showMessage('Please enter the awarded marks.');
      return;
    }

    final awardedMarks = double.tryParse(marksText);

    if (awardedMarks == null) {
      _showMessage('Please enter a valid mark.');
      return;
    }

    if (awardedMarks < 0 || awardedMarks > questionResult.maximumMarks) {
      _showMessage(
        'Awarded marks must be between 0 and '
        '${_formatMarks(questionResult.maximumMarks)}.',
      );
      return;
    }

    final questionId = questionResult.questionId;

    setState(() {
      _savingQuestionIds.add(questionId);
    });

    try {
      await _assessmentService.assessWrittenQuestion(
        resultId: _result.resultId,
        questionId: questionId,
        awardedMarks: awardedMarks,
        assessedBy: firebaseUser.uid,
        feedback: _getFeedbackController(questionResult).text,
      );

      final updatedResult = await _resultService.getResultById(
        _result.resultId,
      );

      if (!mounted) return;

      if (updatedResult == null) {
        throw Exception('The updated result could not be loaded.');
      }

      setState(() {
        _result = updatedResult;
      });

      _showMessage('Assessment saved successfully.');
    } catch (e) {
      if (!mounted) return;

      _showMessage(_friendlyErrorMessage(e));
    } finally {
      if (!mounted) return;

      setState(() {
        _savingQuestionIds.remove(questionId);
      });
    }
  }

  String _friendlyErrorMessage(Object error) {
    final message = error.toString();

    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }

    return 'The assessment could not be saved.';
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

  String _questionTypeLabel(Question question) {
    switch (question.questionType) {
      case QuestionType.multiple:
        return 'Multiple Choice';
      case QuestionType.trueFalse:
        return 'True / False';
      case QuestionType.written:
        return 'Written';
    }
  }

  String _assessmentStatusLabel(QuestionAssessmentStatus status) {
    switch (status) {
      case QuestionAssessmentStatus.automatic:
        return 'Automatically Assessed';
      case QuestionAssessmentStatus.pending:
        return 'Pending Assessment';
      case QuestionAssessmentStatus.manuallyAssessed:
        return 'Manually Assessed';
    }
  }

  Color _assessmentStatusColor(QuestionAssessmentStatus status) {
    switch (status) {
      case QuestionAssessmentStatus.automatic:
        return Colors.green;
      case QuestionAssessmentStatus.pending:
        return Colors.orange;
      case QuestionAssessmentStatus.manuallyAssessed:
        return Colors.indigo;
    }
  }

  IconData _assessmentStatusIcon(QuestionAssessmentStatus status) {
    switch (status) {
      case QuestionAssessmentStatus.automatic:
        return Icons.auto_awesome_rounded;
      case QuestionAssessmentStatus.pending:
        return Icons.pending_actions_rounded;
      case QuestionAssessmentStatus.manuallyAssessed:
        return Icons.fact_check_rounded;
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Result Assessment'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading
                ? null
                : () async {
                    final updatedResult = await _resultService.getResultById(
                      _result.resultId,
                    );

                    if (!mounted) return;

                    if (updatedResult != null) {
                      setState(() {
                        _result = updatedResult;
                      });
                    }

                    await _loadQuestions();
                  },
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 16),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _loadQuestions,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;

        return SingleChildScrollView(
          padding: EdgeInsets.all(isWide ? 28 : 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildResultHeader(theme),
                  const SizedBox(height: 24),
                  _buildAssessmentProgress(theme),
                  const SizedBox(height: 24),
                  if (_result.questionResults.isEmpty)
                    _buildEmptyResults(theme)
                  else
                    ..._result.questionResults.asMap().entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 18),
                        child: _buildQuestionCard(
                          theme,
                          entry.key + 1,
                          entry.value,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildResultHeader(ThemeData theme) {
    final pendingCount = _result.questionResults
        .where(
          (result) =>
              result.assessmentStatus == QuestionAssessmentStatus.pending,
        )
        .length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            offset: const Offset(0, 6),
            color: Colors.black.withValues(alpha: 0.05),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 650;

          final titleSection = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Exam Result',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Review and assess the candidate\'s answers.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          );

          final summary = Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildSummaryPill(
                icon: Icons.grade_rounded,
                label:
                    '${_formatMarks(_result.score)} / '
                    '${_formatMarks(_result.totalMarks)}',
                color: Colors.indigo,
              ),
              _buildSummaryPill(
                icon: Icons.percent_rounded,
                label: _formatPercentage(_result.percentage),
                color: Colors.blue,
              ),
              _buildSummaryPill(
                icon: _result.passed
                    ? Icons.check_circle_rounded
                    : Icons.cancel_rounded,
                label: _result.passed ? 'Passed' : 'Not Passed',
                color: _result.passed ? Colors.green : Colors.red,
              ),
              if (pendingCount > 0)
                _buildSummaryPill(
                  icon: Icons.pending_actions_rounded,
                  label: '$pendingCount Pending',
                  color: Colors.orange,
                ),
            ],
          );

          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [titleSection, const SizedBox(height: 18), summary],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: titleSection),
              const SizedBox(width: 20),
              Flexible(
                child: Align(alignment: Alignment.topRight, child: summary),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryPill({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssessmentProgress(ThemeData theme) {
    final total = _result.questionResults.length;

    final assessed = _result.questionResults
        .where(
          (result) =>
              result.assessmentStatus != QuestionAssessmentStatus.pending,
        )
        .length;

    final progress = total == 0 ? 0.0 : assessed / total;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.fact_check_outlined, size: 20),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Assessment Progress',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '$assessed / $total assessed',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(value: progress, minHeight: 8),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(
    ThemeData theme,
    int questionNumber,
    ExamQuestionResult questionResult,
  ) {
    final question = _getQuestion(questionResult.questionId);

    final statusColor = _assessmentStatusColor(questionResult.assessmentStatus);

    final isPending =
        questionResult.assessmentStatus == QuestionAssessmentStatus.pending;

    final isSaving = _savingQuestionIds.contains(questionResult.questionId);

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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildQuestionHeader(
              theme,
              questionNumber,
              questionResult,
              question,
              statusColor,
            ),
            const SizedBox(height: 18),
            if (question == null)
              _buildMissingQuestionMessage(theme)
            else
              _buildQuestionContent(theme, question, questionResult),
            if (isPending &&
                question?.questionType == QuestionType.written) ...[
              const SizedBox(height: 20),
              _buildAssessmentForm(theme, questionResult, isSaving),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionHeader(
    ThemeData theme,
    int questionNumber,
    ExamQuestionResult questionResult,
    Question? question,
    Color statusColor,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$questionNumber',
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildTypePill(
                    question == null
                        ? 'Question'
                        : _questionTypeLabel(question),
                  ),
                  _buildStatusPill(
                    questionResult.assessmentStatus,
                    statusColor,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Maximum Marks: '
                '${_formatMarks(questionResult.maximumMarks)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTypePill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildStatusPill(QuestionAssessmentStatus status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_assessmentStatusIcon(status), size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            _assessmentStatusLabel(status),
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionContent(
    ThemeData theme,
    Question question,
    ExamQuestionResult questionResult,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question.questionDescription,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 18),
        if (question.questionType == QuestionType.written)
          _buildWrittenAnswer(theme, questionResult)
        else
          _buildObjectiveAnswer(theme, question, questionResult),
      ],
    );
  }

  Widget _buildWrittenAnswer(
    ThemeData theme,
    ExamQuestionResult questionResult,
  ) {
    final answer = questionResult.writtenAnswer.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.35,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Candidate Answer',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            answer.isEmpty ? 'No answer provided.' : answer,
            style: theme.textTheme.bodyLarge?.copyWith(
              height: 1.6,
              color: answer.isEmpty ? theme.colorScheme.onSurfaceVariant : null,
              fontStyle: answer.isEmpty ? FontStyle.italic : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildObjectiveAnswer(
    ThemeData theme,
    Question question,
    ExamQuestionResult questionResult,
  ) {
    final selectedIds = questionResult.selectedOptionIds.toSet();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Candidate Selection',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        if (selectedIds.isEmpty)
          Text(
            'No answer provided.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          )
        else
          ...question.options.map((option) {
            final selected = selectedIds.contains(option.optionId);

            if (!selected) {
              return const SizedBox.shrink();
            }

            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: questionResult.correct
                    ? Colors.green.withValues(alpha: 0.08)
                    : Colors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: questionResult.correct
                      ? Colors.green.withValues(alpha: 0.22)
                      : Colors.red.withValues(alpha: 0.22),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    questionResult.correct
                        ? Icons.check_circle_rounded
                        : Icons.cancel_rounded,
                    size: 19,
                    color: questionResult.correct ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      option.optionText,
                      style: const TextStyle(height: 1.4),
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildAssessmentForm(
    ThemeData theme,
    ExamQuestionResult questionResult,
    bool isSaving,
  ) {
    final markController = _getMarkController(questionResult);

    final feedbackController = _getFeedbackController(questionResult);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.rate_review_outlined,
                size: 20,
                color: Colors.orange.shade800,
              ),
              const SizedBox(width: 8),
              Text(
                'Manual Assessment',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.orange.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 600;

              final marksField = TextFormField(
                controller: markController,
                enabled: !isSaving,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Awarded Marks',
                  hintText: '0 - ${_formatMarks(questionResult.maximumMarks)}',
                  prefixIcon: const Icon(Icons.grade_outlined),
                  border: const OutlineInputBorder(),
                ),
              );

              final feedbackField = TextFormField(
                controller: feedbackController,
                enabled: !isSaving,
                minLines: 2,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Feedback (optional)',
                  hintText: 'Enter feedback for the candidate...',
                  prefixIcon: Icon(Icons.comment_outlined),
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              );

              if (compact) {
                return Column(
                  children: [
                    marksField,
                    const SizedBox(height: 14),
                    feedbackField,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 220, child: marksField),
                  const SizedBox(width: 14),
                  Expanded(child: feedbackField),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: isSaving
                  ? null
                  : () => _saveAssessment(questionResult),
              icon: isSaving
                  ? const SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_rounded),
              label: Text(isSaving ? 'Saving...' : 'Save Assessment'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissingQuestionMessage(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Text(
        'The question could not be found. '
        'The question may have been removed from '
        'the question bank.',
      ),
    );
  }

  Widget _buildEmptyResults(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 14),
          Text(
            'No question-level results found.',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'This result may have been created '
            'before question-level assessment was added.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
