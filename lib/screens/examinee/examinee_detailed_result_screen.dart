import 'package:flutter/material.dart';
import 'package:questionbank/models/exam.dart';
import 'package:questionbank/models/exam_attempt.dart';
import 'package:questionbank/models/exam_question_result.dart';
import 'package:questionbank/models/exam_result.dart';
import 'package:questionbank/models/question.dart';
import 'package:questionbank/services/question_service.dart';

class ExamineeDetailedResultScreen extends StatefulWidget {
  final Exam exam;
  final ExamAttempt attempt;
  final ExamResult result;

  const ExamineeDetailedResultScreen({
    super.key,
    required this.exam,
    required this.attempt,
    required this.result,
  });

  @override
  State<ExamineeDetailedResultScreen> createState() =>
      _ExamineeDetailedResultScreenState();
}

class _ExamineeDetailedResultScreenState
    extends State<ExamineeDetailedResultScreen> {
  final QuestionService _questionService = QuestionService();

  bool _isLoading = true;
  String? _errorMessage;

  final Map<String, Question> _questions = {};

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      _questions.clear();

      for (final questionId in widget.attempt.questionOrder) {
        final question = await _questionService.getQuestionById(questionId);

        if (question != null) {
          _questions[questionId] = question;
        }
      }

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load the detailed result.';
      });
    }
  }

  ExamAttemptAnswer? _getAnswerForQuestion(String questionId) {
    for (final answer in widget.attempt.answers) {
      if (answer.questionId == questionId) {
        return answer;
      }
    }

    return null;
  }

  ExamQuestionResult? _getQuestionResult(String questionId) {
    for (final questionResult in widget.result.questionResults) {
      if (questionResult.questionId == questionId) {
        return questionResult;
      }
    }

    return null;
  }

  bool _isObjectiveQuestion(Question question) {
    return question.questionType != QuestionType.written;
  }

  bool _isAnswered(Question question, ExamAttemptAnswer? answer) {
    if (answer == null) return false;

    if (question.questionType == QuestionType.written) {
      return answer.writtenAnswer.trim().isNotEmpty;
    }

    return answer.selectedOptionIds.isNotEmpty;
  }

  bool _isObjectiveCorrect(Question question, ExamAttemptAnswer? answer) {
    if (!_isObjectiveQuestion(question)) {
      return false;
    }

    if (answer == null || answer.selectedOptionIds.isEmpty) {
      return false;
    }

    final selected = answer.selectedOptionIds.toSet();
    final correct = question.correctAnswers.toSet();

    return selected.length == correct.length && selected.containsAll(correct);
  }

  String _questionTypeLabel(QuestionType type) {
    switch (type) {
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
        return 'Awaiting Examiner';
      case QuestionAssessmentStatus.manuallyAssessed:
        return 'Manually Assessed';
    }
  }

  IconData _assessmentStatusIcon(QuestionAssessmentStatus status) {
    switch (status) {
      case QuestionAssessmentStatus.automatic:
        return Icons.auto_awesome_rounded;
      case QuestionAssessmentStatus.pending:
        return Icons.hourglass_top_rounded;
      case QuestionAssessmentStatus.manuallyAssessed:
        return Icons.fact_check_rounded;
    }
  }

  Color _assessmentStatusColor(QuestionAssessmentStatus status) {
    switch (status) {
      case QuestionAssessmentStatus.automatic:
        return Colors.blue;
      case QuestionAssessmentStatus.pending:
        return Colors.orange;
      case QuestionAssessmentStatus.manuallyAssessed:
        return Colors.deepPurple;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detailed Result'), centerTitle: false),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;

          final horizontalPadding = width >= 1100
              ? 32.0
              : width >= 700
              ? 24.0
              : 14.0;

          return RefreshIndicator(
            onRefresh: _loadQuestions,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                16,
                horizontalPadding,
                30,
              ),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1050),
                    child: _buildBody(context),
                  ),
                ),
              ],
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
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildResultSummary(context),
        const SizedBox(height: 18),
        _buildSectionHeading(context),
        const SizedBox(height: 8),
        _buildQuestions(context),
      ],
    );
  }

  // ============================================================
  // RESULT SUMMARY
  // ============================================================

  Widget _buildResultSummary(BuildContext context) {
    final theme = Theme.of(context);

    if (!widget.result.isPublished) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange.shade50, Colors.amber.shade50],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.30)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.hourglass_top_rounded,
                color: Colors.orange,
                size: 27,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Assessment in Progress',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.orange.shade900,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Your detailed answers are shown below. '
                    'The final result will be available after '
                    'all written questions have been assessed.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.orange.shade900,
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

    final passed = widget.result.passed;
    final statusColor = passed ? Colors.green : Colors.red;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            statusColor.withValues(alpha: 0.10),
            statusColor.withValues(alpha: 0.035),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withValues(alpha: 0.25)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 560) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildExamTitle(context),
                const SizedBox(height: 20),
                _buildScoreBlock(context, statusColor),
                const SizedBox(height: 18),
                _buildStatusBlock(context, statusColor),
              ],
            );
          }

          return Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildExamTitle(context),
                    const SizedBox(height: 20),
                    _buildScoreBlock(context, statusColor),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              _buildStatusBlock(context, statusColor),
            ],
          );
        },
      ),
    );
  }

  Widget _buildExamTitle(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            Icons.assignment_turned_in_rounded,
            color: theme.colorScheme.primary,
            size: 25,
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.exam.examName,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Question-by-question assessment',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScoreBlock(BuildContext context, Color statusColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          widget.result.score.toStringAsFixed(2),
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w900,
            color: statusColor,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 7, bottom: 8),
          child: Text(
            '/ ${widget.result.totalMarks.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBlock(BuildContext context, Color statusColor) {
    final passed = widget.result.passed;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 17),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Icon(
            passed ? Icons.verified_rounded : Icons.cancel_rounded,
            color: statusColor,
            size: 34,
          ),
          const SizedBox(height: 6),
          Text(
            passed ? 'PASSED' : 'NOT PASSED',
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${widget.result.percentage.toStringAsFixed(1)}%',
            style: TextStyle(color: statusColor, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION HEADING
  // ============================================================

  Widget _buildSectionHeading(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          width: 5,
          height: 27,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'Question Details',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // QUESTIONS
  // ============================================================

  Widget _buildQuestions(BuildContext context) {
    final questionIds = widget.attempt.questionOrder;

    if (questionIds.isEmpty) {
      return _buildEmptyQuestions(context);
    }

    return Column(
      children: [
        for (int index = 0; index < questionIds.length; index++)
          if (_questions.containsKey(questionIds[index]))
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _buildQuestionCard(
                context,
                number: index + 1,
                question: _questions[questionIds[index]]!,
              ),
            ),
      ],
    );
  }

  Widget _buildQuestionCard(
    BuildContext context, {
    required int number,
    required Question question,
  }) {
    final theme = Theme.of(context);

    final answer = _getAnswerForQuestion(question.questionId);

    final questionResult = _getQuestionResult(question.questionId);

    final answered = _isAnswered(question, answer);

    final objectiveCorrect = _isObjectiveCorrect(question, answer);

    final status =
        questionResult?.assessmentStatus ?? QuestionAssessmentStatus.pending;

    final statusColor = _assessmentStatusColor(status);

    Color cardAccent;

    if (_isObjectiveQuestion(question)) {
      if (!answered) {
        cardAccent = Colors.orange;
      } else if (objectiveCorrect) {
        cardAccent = Colors.green;
      } else {
        cardAccent = Colors.red;
      }
    } else {
      cardAccent = statusColor;
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardAccent.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildQuestionTopBar(
            context,
            number: number,
            question: question,
            status: status,
            accentColor: cardAccent,
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildQuestionDescription(context, question),
                const SizedBox(height: 18),
                if (_isObjectiveQuestion(question))
                  _buildObjectiveDetails(
                    context,
                    question: question,
                    answer: answer,
                  )
                else
                  _buildWrittenDetails(
                    context,
                    question: question,
                    answer: answer,
                    questionResult: questionResult,
                  ),
                const SizedBox(height: 16),
                _buildMarksPanel(
                  context,
                  question: question,
                  questionResult: questionResult,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // QUESTION TOP BAR
  // ============================================================

  Widget _buildQuestionTopBar(
    BuildContext context, {
    required int number,
    required Question question,
    required QuestionAssessmentStatus status,
    required Color accentColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.055),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        border: Border(
          bottom: BorderSide(color: accentColor.withValues(alpha: 0.14)),
        ),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accentColor,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$number',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          _buildTag(
            context,
            icon: Icons.quiz_outlined,
            label: _questionTypeLabel(question.questionType),
            color: Theme.of(context).colorScheme.primary,
          ),
          _buildTag(
            context,
            icon: _assessmentStatusIcon(status),
            label: _assessmentStatusLabel(status),
            color: _assessmentStatusColor(status),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // QUESTION DESCRIPTION
  // ============================================================

  Widget _buildQuestionDescription(BuildContext context, Question question) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.075),
            theme.colorScheme.primary.withValues(alpha: 0.025),
          ],
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.16),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.help_outline_rounded,
              color: theme.colorScheme.primary,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              question.questionDescription,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w700,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // OBJECTIVE QUESTIONS
  // ============================================================

  Widget _buildObjectiveDetails(
    BuildContext context, {
    required Question question,
    required ExamAttemptAnswer? answer,
  }) {
    final selectedIds = answer?.selectedOptionIds.toSet() ?? <String>{};

    final correctIds = question.correctAnswers.toSet();

    final optionsById = {
      for (final option in question.options) option.optionId: option,
    };

    final savedOrder = widget.attempt.optionOrder[question.questionId];

    final optionOrder = savedOrder != null && savedOrder.isNotEmpty
        ? savedOrder
        : question.options.map((option) => option.optionId).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Answer Options',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        ...optionOrder.asMap().entries.map((entry) {
          final option = optionsById[entry.value];

          if (option == null) {
            return const SizedBox.shrink();
          }

          final isSelected = selectedIds.contains(option.optionId);

          final isCorrect = correctIds.contains(option.optionId);

          return Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: _buildOptionTile(
              context,
              optionNumber: entry.key + 1,
              optionText: option.optionText,
              isSelected: isSelected,
              isCorrect: isCorrect,
            ),
          );
        }),
        if (answer == null || answer.selectedOptionIds.isEmpty)
          _buildNotAnsweredBanner(context),
      ],
    );
  }

  Widget _buildOptionTile(
    BuildContext context, {
    required int optionNumber,
    required String optionText,
    required bool isSelected,
    required bool isCorrect,
  }) {
    Color accentColor;
    Color backgroundColor;
    IconData icon;
    String? statusText;

    if (isSelected && isCorrect) {
      accentColor = Colors.green;
      backgroundColor = Colors.green.withValues(alpha: 0.075);
      icon = Icons.check_circle_rounded;
      statusText = 'YOUR ANSWER  •  CORRECT ANSWER';
    } else if (isSelected && !isCorrect) {
      accentColor = Colors.red;
      backgroundColor = Colors.red.withValues(alpha: 0.075);
      icon = Icons.cancel_rounded;
      statusText = 'YOUR ANSWER  •  WRONG ANSWER';
    } else if (!isSelected && isCorrect) {
      accentColor = Colors.green;
      backgroundColor = Colors.green.withValues(alpha: 0.045);
      icon = Icons.check_circle_outline_rounded;
      statusText = 'CORRECT ANSWER';
    } else {
      accentColor = Theme.of(context).colorScheme.outlineVariant;
      backgroundColor = Theme.of(context).colorScheme.surface;
      icon = Icons.radio_button_unchecked_rounded;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: isSelected || isCorrect
              ? accentColor.withValues(alpha: 0.45)
              : accentColor,
          width: isSelected || isCorrect ? 1.5 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              String.fromCharCode(64 + optionNumber),
              style: TextStyle(color: accentColor, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  optionText,
                  style: TextStyle(
                    fontWeight: isSelected || isCorrect
                        ? FontWeight.w700
                        : FontWeight.w500,
                    height: 1.4,
                  ),
                ),
                if (statusText != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(icon, size: 16, color: accentColor),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          statusText,
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.25,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotAnsweredBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.25)),
      ),
      child: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
          SizedBox(width: 8),
          Text(
            'Not Answered',
            style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // WRITTEN QUESTIONS
  // ============================================================

  Widget _buildWrittenDetails(
    BuildContext context, {
    required Question question,
    required ExamAttemptAnswer? answer,
    required ExamQuestionResult? questionResult,
  }) {
    final writtenAnswer = answer?.writtenAnswer.trim() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Written Answer',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 9),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.deepPurple.withValues(alpha: 0.045),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.deepPurple.withValues(alpha: 0.16),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.edit_note_rounded, color: Colors.deepPurple),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  writtenAnswer.isEmpty ? 'Not answered' : writtenAnswer,
                  style: TextStyle(
                    height: 1.55,
                    fontWeight: writtenAnswer.isEmpty
                        ? FontWeight.w500
                        : FontWeight.w600,
                    color: writtenAnswer.isEmpty
                        ? Colors.deepPurple.shade300
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (questionResult != null &&
            questionResult.assessmentStatus == QuestionAssessmentStatus.pending)
          _buildPendingWrittenAssessment(context)
        else if (questionResult != null &&
            questionResult.assessmentStatus ==
                QuestionAssessmentStatus.manuallyAssessed)
          _buildManualWrittenAssessment(context, questionResult),
      ],
    );
  }

  Widget _buildPendingWrittenAssessment(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.075),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.22)),
      ),
      child: const Row(
        children: [
          Icon(Icons.hourglass_top_rounded, color: Colors.orange),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Awaiting Examiner\'s Assessment',
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualWrittenAssessment(
    BuildContext context,
    ExamQuestionResult result,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: Colors.deepPurple.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.fact_check_rounded, color: Colors.deepPurple),
              SizedBox(width: 8),
              Text(
                'Examiner Assessment',
                style: TextStyle(
                  color: Colors.deepPurple,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Text(
            'Marks awarded: '
            '${result.awardedMarks.toStringAsFixed(2)} / '
            '${result.maximumMarks.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          if (result.feedback != null &&
              result.feedback!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text(
              'Examiner Feedback',
              style: TextStyle(
                color: Colors.deepPurple,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(result.feedback!, style: const TextStyle(height: 1.45)),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // MARKS
  // ============================================================

  Widget _buildMarksPanel(
    BuildContext context, {
    required Question question,
    required ExamQuestionResult? questionResult,
  }) {
    if (questionResult == null) {
      return _buildMissingAssessment(context);
    }

    final pending =
        questionResult.assessmentStatus == QuestionAssessmentStatus.pending;

    if (!widget.result.isPublished && pending) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            Icon(Icons.pending_actions_rounded, color: Colors.orange, size: 20),
            SizedBox(width: 9),
            Expanded(
              child: Text(
                'Marks pending examiner assessment',
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final automatic =
        questionResult.assessmentStatus == QuestionAssessmentStatus.automatic;

    final color = automatic ? Colors.blue : Colors.deepPurple;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(
            automatic ? Icons.auto_awesome_rounded : Icons.fact_check_rounded,
            color: color,
            size: 21,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              'Marks: '
              '${questionResult.awardedMarks.toStringAsFixed(2)} / '
              '${questionResult.maximumMarks.toStringAsFixed(2)}',
              style: TextStyle(color: color, fontWeight: FontWeight.w800),
            ),
          ),
          Text(
            automatic ? 'Automatic' : 'Examiner',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissingAssessment(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(11),
      ),
      child: const Text(
        'Assessment information is unavailable.',
        style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
      ),
    );
  }

  // ============================================================
  // EMPTY / ERROR
  // ============================================================

  Widget _buildEmptyQuestions(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        children: [
          Icon(Icons.quiz_outlined, size: 50),
          SizedBox(height: 12),
          Text(
            'No question details are available.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.red.withValues(alpha: 0.20)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, size: 52, color: Colors.red),
          const SizedBox(height: 14),
          Text(
            _errorMessage ?? 'Unable to load detailed result.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _loadQuestions,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
