import 'package:flutter/material.dart';
import 'package:questionbank/models/exam.dart';
import 'package:questionbank/models/exam_attempt.dart';
import 'package:questionbank/models/exam_question_result.dart';
import 'package:questionbank/models/exam_result.dart';
import 'package:questionbank/models/question.dart';
import 'package:questionbank/services/question_service.dart';

import 'examinee_detailed_result_screen.dart';

class ExamineeExamReviewScreen extends StatefulWidget {
  final Exam exam;
  final ExamAttempt attempt;
  final ExamResult result;

  const ExamineeExamReviewScreen({
    super.key,
    required this.exam,
    required this.attempt,
    required this.result,
  });

  @override
  State<ExamineeExamReviewScreen> createState() =>
      _ExamineeExamReviewScreenState();
}

class _ExamineeExamReviewScreenState extends State<ExamineeExamReviewScreen> {
  final QuestionService _questionService = QuestionService();

  bool _isLoading = true;
  String? _errorMessage;

  final List<Question> _questions = [];

  @override
  void initState() {
    super.initState();
    _loadReviewData();
  }

  // ============================================================
  // DATA
  // ============================================================

  Future<void> _loadReviewData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final loadedQuestions = <Question>[];

      for (final questionId in widget.attempt.questionOrder) {
        final question = await _questionService.getQuestionById(questionId);

        if (question != null) {
          loadedQuestions.add(question);
        }
      }

      if (!mounted) return;

      setState(() {
        _questions
          ..clear()
          ..addAll(loadedQuestions);

        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
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
    for (final result in widget.result.questionResults) {
      if (result.questionId == questionId) {
        return result;
      }
    }

    return null;
  }

  List<String> _getOptionOrder(String questionId) {
    return widget.attempt.optionOrder[questionId] ?? [];
  }

  bool _isAnswered({
    required Question question,
    required ExamAttemptAnswer? answer,
  }) {
    if (answer == null) {
      return false;
    }

    if (question.questionType == QuestionType.written) {
      return answer.writtenAnswer.trim().isNotEmpty;
    }

    return answer.selectedOptionIds.isNotEmpty;
  }

  bool _isObjectiveAnswerCorrect({
    required Question question,
    required ExamAttemptAnswer? answer,
  }) {
    if (question.questionType == QuestionType.written) {
      return false;
    }

    if (answer == null || answer.selectedOptionIds.isEmpty) {
      return false;
    }

    final selected = answer.selectedOptionIds.toSet();
    final correct = question.correctAnswers.toSet();

    return selected.length == correct.length && selected.containsAll(correct);
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exam Review'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _loadReviewData,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
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
            onRefresh: _loadReviewData,
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

    if (_questions.isEmpty) {
      return _buildEmptyState(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildExamHeader(context),
        const SizedBox(height: 16),
        _buildReviewSummary(context),
        const SizedBox(height: 22),
        _buildSectionHeading(context),
        const SizedBox(height: 10),
        _buildQuestionList(context),
        const SizedBox(height: 8),
        _buildBottomAction(context),
      ],
    );
  }

  // ============================================================
  // EXAM HEADER
  // ============================================================

  Widget _buildExamHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.78),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.20),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.assignment_turned_in_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.exam.examName,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Review your submitted examination',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.88),
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
  // SUMMARY
  // ============================================================

  Widget _buildReviewSummary(BuildContext context) {
    final theme = Theme.of(context);

    int correct = 0;
    int wrong = 0;
    int unanswered = 0;
    int written = 0;

    for (final question in _questions) {
      final answer = _getAnswerForQuestion(question.questionId);

      if (question.questionType == QuestionType.written) {
        written++;

        if (!_isAnswered(question: question, answer: answer)) {
          unanswered++;
        }

        continue;
      }

      if (!_isAnswered(question: question, answer: answer)) {
        unanswered++;
      } else if (_isObjectiveAnswerCorrect(
        question: question,
        answer: answer,
      )) {
        correct++;
      } else {
        wrong++;
      }
    }

    final items = [
      _buildSummaryItem(
        context,
        icon: Icons.quiz_outlined,
        label: 'Questions',
        value: '${_questions.length}',
        color: Colors.indigo,
      ),
      _buildSummaryItem(
        context,
        icon: Icons.check_circle_rounded,
        label: 'Correct',
        value: '$correct',
        color: Colors.green,
      ),
      _buildSummaryItem(
        context,
        icon: Icons.cancel_rounded,
        label: 'Wrong',
        value: '$wrong',
        color: Colors.red,
      ),
      _buildSummaryItem(
        context,
        icon: Icons.help_rounded,
        label: 'Unanswered',
        value: '$unanswered',
        color: Colors.orange,
      ),
      _buildSummaryItem(
        context,
        icon: Icons.edit_note_rounded,
        label: 'Written',
        value: '$written',
        color: Colors.deepPurple,
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = (constraints.maxWidth - 16) / 2;

          if (constraints.maxWidth < 560) {
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items
                  .map((item) => SizedBox(width: itemWidth, child: item))
                  .toList(),
            );
          }

          return Row(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                Expanded(child: items[i]),
                if (i < items.length - 1) const SizedBox(width: 8),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: color.withValues(alpha: 0.13)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
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
          'Submitted Answers',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // QUESTION LIST
  // ============================================================

  Widget _buildQuestionList(BuildContext context) {
    return Column(
      children: [
        for (int index = 0; index < _questions.length; index++)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _buildQuestionCard(
              context,
              question: _questions[index],
              questionNumber: index + 1,
              answer: _getAnswerForQuestion(_questions[index].questionId),
              questionResult: _getQuestionResult(_questions[index].questionId),
              optionOrder: _getOptionOrder(_questions[index].questionId),
            ),
          ),
      ],
    );
  }

  // ============================================================
  // QUESTION CARD
  // ============================================================

  Widget _buildQuestionCard(
    BuildContext context, {
    required Question question,
    required int questionNumber,
    required ExamAttemptAnswer? answer,
    required ExamQuestionResult? questionResult,
    required List<String> optionOrder,
  }) {
    final answered = _isAnswered(question: question, answer: answer);

    final isWritten = question.questionType == QuestionType.written;

    final correct =
        !isWritten &&
        _isObjectiveAnswerCorrect(question: question, answer: answer);

    final accentColor = isWritten
        ? Colors.deepPurple
        : !answered
        ? Colors.orange
        : correct
        ? Colors.green
        : Colors.red;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withValues(alpha: 0.25)),
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
            number: questionNumber,
            question: question,
            answered: answered,
            correct: correct,
            accentColor: accentColor,
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildQuestionDescription(context, question),
                const SizedBox(height: 18),
                if (isWritten)
                  _buildWrittenReview(
                    context,
                    answer: answer,
                    questionResult: questionResult,
                  )
                else
                  _buildObjectiveReview(
                    context,
                    question: question,
                    answer: answer,
                    optionOrder: optionOrder,
                  ),
                const SizedBox(height: 15),
                _buildQuestionMarks(context, questionResult: questionResult),
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
    required bool answered,
    required bool correct,
    required Color accentColor,
  }) {
    final isWritten = question.questionType == QuestionType.written;

    String statusText;
    IconData statusIcon;

    if (isWritten) {
      statusText = 'Written Question';
      statusIcon = Icons.edit_note_rounded;
    } else if (!answered) {
      statusText = 'Not Answered';
      statusIcon = Icons.help_outline_rounded;
    } else if (correct) {
      statusText = 'Correct';
      statusIcon = Icons.check_circle_rounded;
    } else {
      statusText = 'Wrong';
      statusIcon = Icons.cancel_rounded;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.055),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        border: Border(
          bottom: BorderSide(color: accentColor.withValues(alpha: 0.13)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 39,
            height: 39,
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
          const SizedBox(width: 11),
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _buildQuestionTag(
                  context,
                  icon: Icons.quiz_outlined,
                  label: _questionTypeLabel(question.questionType),
                  color: Theme.of(context).colorScheme.primary,
                ),
                _buildQuestionTag(
                  context,
                  icon: statusIcon,
                  label: statusText,
                  color: accentColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionTag(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
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

  // ============================================================
  // QUESTION DESCRIPTION
  // ============================================================

  Widget _buildQuestionDescription(BuildContext context, Question question) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.075),
            theme.colorScheme.primary.withValues(alpha: 0.025),
          ],
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              Icons.help_outline_rounded,
              color: theme.colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              question.questionDescription,
              style: theme.textTheme.titleMedium?.copyWith(
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
  // OBJECTIVE REVIEW
  // ============================================================

  Widget _buildObjectiveReview(
    BuildContext context, {
    required Question question,
    required ExamAttemptAnswer? answer,
    required List<String> optionOrder,
  }) {
    final optionsById = {
      for (final option in question.options) option.optionId: option,
    };

    final orderedIds = optionOrder.isNotEmpty
        ? optionOrder
        : question.options.map((option) => option.optionId).toList();

    final selectedIds = answer?.selectedOptionIds.toSet() ?? <String>{};

    final correctIds = question.correctAnswers.toSet();

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
        ...orderedIds.asMap().entries.map((entry) {
          final option = optionsById[entry.value];

          if (option == null) {
            return const SizedBox.shrink();
          }

          final isSelected = selectedIds.contains(option.optionId);

          final isCorrect = correctIds.contains(option.optionId);

          return Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: _buildOptionReviewTile(
              context,
              optionNumber: entry.key + 1,
              optionText: option.optionText,
              isSelected: isSelected,
              isCorrect: isCorrect,
            ),
          );
        }),
        if (selectedIds.isEmpty) _buildNotAnsweredBanner(context),
      ],
    );
  }

  Widget _buildOptionReviewTile(
    BuildContext context, {
    required int optionNumber,
    required String optionText,
    required bool isSelected,
    required bool isCorrect,
  }) {
    late final Color accentColor;
    late final Color backgroundColor;
    late final IconData icon;
    String? statusText;

    if (isSelected && isCorrect) {
      accentColor = Colors.green;
      backgroundColor = Colors.green.withValues(alpha: 0.075);
      icon = Icons.check_circle_rounded;
      statusText = 'YOUR ANSWER • CORRECT';
    } else if (isSelected && !isCorrect) {
      accentColor = Colors.red;
      backgroundColor = Colors.red.withValues(alpha: 0.075);
      icon = Icons.cancel_rounded;
      statusText = 'YOUR ANSWER • WRONG';
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
      padding: const EdgeInsets.all(12),
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
              style: TextStyle(color: accentColor, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 10),
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
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.2,
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
        border: Border.all(color: Colors.orange.withValues(alpha: 0.24)),
      ),
      child: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
          SizedBox(width: 8),
          Text(
            'You did not answer this question.',
            style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // WRITTEN REVIEW
  // ============================================================

  Widget _buildWrittenReview(
    BuildContext context, {
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
        _buildWrittenAssessment(context, questionResult: questionResult),
      ],
    );
  }

  Widget _buildWrittenAssessment(
    BuildContext context, {
    required ExamQuestionResult? questionResult,
  }) {
    if (questionResult == null) {
      return _buildAssessmentMessage(
        context,
        icon: Icons.info_outline_rounded,
        color: Colors.grey,
        text: 'Assessment information is unavailable.',
      );
    }

    switch (questionResult.assessmentStatus) {
      case QuestionAssessmentStatus.pending:
        return _buildAssessmentMessage(
          context,
          icon: Icons.hourglass_top_rounded,
          color: Colors.orange,
          text: "Awaiting Examiner's Assessment",
        );

      case QuestionAssessmentStatus.manuallyAssessed:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.deepPurple.withValues(alpha: 0.055),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: Colors.deepPurple.withValues(alpha: 0.18),
            ),
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
              const SizedBox(height: 10),
              Text(
                'Marks awarded: '
                '${questionResult.awardedMarks.toStringAsFixed(2)} / '
                '${questionResult.maximumMarks.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              if (questionResult.feedback != null &&
                  questionResult.feedback!.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                const Text(
                  'Examiner Feedback',
                  style: TextStyle(
                    color: Colors.deepPurple,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  questionResult.feedback!,
                  style: const TextStyle(height: 1.45),
                ),
              ],
            ],
          ),
        );

      case QuestionAssessmentStatus.automatic:
        return _buildAssessmentMessage(
          context,
          icon: Icons.auto_awesome_rounded,
          color: Colors.blue,
          text: 'Automatically Assessed',
        );
    }
  }

  Widget _buildAssessmentMessage(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.065),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 21),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MARKS
  // ============================================================

  Widget _buildQuestionMarks(
    BuildContext context, {
    required ExamQuestionResult? questionResult,
  }) {
    if (questionResult == null) {
      return const SizedBox.shrink();
    }

    final isPending =
        questionResult.assessmentStatus == QuestionAssessmentStatus.pending;

    if (!widget.result.isPublished && isPending) {
      return _buildAssessmentMessage(
        context,
        icon: Icons.pending_actions_rounded,
        color: Colors.orange,
        text: 'Marks pending examiner assessment',
      );
    }

    final isAutomatic =
        questionResult.assessmentStatus == QuestionAssessmentStatus.automatic;

    final color = isAutomatic ? Colors.blue : Colors.deepPurple;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Icon(
            isAutomatic ? Icons.auto_awesome_rounded : Icons.fact_check_rounded,
            color: color,
            size: 20,
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
            isAutomatic ? 'Automatic' : 'Examiner',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BOTTOM ACTION
  // ============================================================

  Widget _buildBottomAction(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.025),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Want to see the complete assessment?',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ExamineeDetailedResultScreen(
                    exam: widget.exam,
                    attempt: widget.attempt,
                    result: widget.result,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.fact_check_outlined),
            label: const Text('View Detailed Result'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY / ERROR
  // ============================================================

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(42),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: const Column(
        children: [
          Icon(Icons.quiz_outlined, size: 54),
          SizedBox(height: 14),
          Text(
            'No questions were found for this exam.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(42),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.withValues(alpha: 0.20)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, size: 54, color: Colors.red),
          const SizedBox(height: 14),
          Text(
            'Unable to load exam review.\n\n'
            '$_errorMessage',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _loadReviewData,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
