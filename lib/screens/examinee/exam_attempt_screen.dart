import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:questionbank/models/exam.dart';
import 'package:questionbank/models/exam_attempt.dart';
import 'package:questionbank/models/question.dart';
import 'package:questionbank/services/exam_attempt_service.dart';
import 'package:questionbank/services/question_service.dart';

import 'exam_result_screen.dart';

class ExamAttemptScreen extends StatefulWidget {
  final Exam exam;
  final ExamAttempt attempt;

  const ExamAttemptScreen({
    super.key,
    required this.exam,
    required this.attempt,
  });

  @override
  State<ExamAttemptScreen> createState() => _ExamAttemptScreenState();
}

class _ExamAttemptScreenState extends State<ExamAttemptScreen> {
  final QuestionService _questionService = QuestionService();
  final ExamAttemptService _attemptService = ExamAttemptService();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isAutoSubmitting = false;

  String? _errorMessage;

  Timer? _examTimer;
  Duration _remainingTime = Duration.zero;

  List<Question> _questions = [];
  int _currentQuestionIndex = 0;

  /// Local answers.
  ///
  /// Key   = questionId
  /// Value = complete answer object for that question.
  final Map<String, ExamAttemptAnswer> _answers = {};

  /// Controllers for written-answer questions.
  final Map<String, TextEditingController> _writtenControllers = {};

  @override
  void initState() {
    super.initState();

    _currentQuestionIndex = widget.attempt.currentQuestionIndex;

    _loadExistingAnswers();
    _loadQuestions();
    _startExamTimer();
  }

  @override
  void dispose() {
    _examTimer?.cancel();

    for (final controller in _writtenControllers.values) {
      controller.dispose();
    }

    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // TIMER
  // ---------------------------------------------------------------------------

  void _startExamTimer() {
    final duration = Duration(minutes: widget.exam.durationMinutes);

    final endTime = widget.attempt.startedAt.add(duration);

    void updateRemainingTime() {
      final remaining = endTime.difference(DateTime.now());

      if (remaining <= Duration.zero) {
        if (mounted) {
          setState(() {
            _remainingTime = Duration.zero;
          });
        }

        _examTimer?.cancel();
        _handleTimeExpired();
        return;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _remainingTime = remaining;
      });
    }

    updateRemainingTime();

    _examTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      updateRemainingTime();
    });
  }

  String _formatRemainingTime() {
    final totalSeconds = _remainingTime.inSeconds;

    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  Color _getTimerColor() {
    final seconds = _remainingTime.inSeconds;

    if (seconds <= 60) {
      return Colors.red.shade700;
    }

    if (seconds <= 300) {
      return Colors.orange.shade800;
    }

    return Colors.indigo.shade700;
  }

  Widget _buildTimerDisplay() {
    final timerColor = _getTimerColor();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: timerColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: timerColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 17, color: timerColor),
          const SizedBox(width: 6),
          Text(
            _formatRemainingTime(),
            style: TextStyle(
              color: timerColor,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleTimeExpired() async {
    if (_isAutoSubmitting || !mounted) {
      return;
    }

    setState(() {
      _isAutoSubmitting = true;
    });

    await _saveCurrentWrittenAnswer();

    try {
      final finalAttempt = widget.attempt.copyWith(
        answers: _getAnswersForSaving(),
        answeredCount: _getAnsweredCount(),
        currentQuestionIndex: _currentQuestionIndex,
      );

      await _attemptService.updateProgress(
        attemptId: widget.attempt.attemptId,
        answers: _getAnswersForSaving(),
        answeredCount: _getAnsweredCount(),
        currentQuestionIndex: _currentQuestionIndex,
      );

      await _attemptService.autoSubmitAttempt(
        exam: widget.exam,
        attempt: finalAttempt,
        score: 0.0,
        percentage: 0.0,
      );

      if (!mounted) {
        return;
      }

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.timer_off_rounded, color: Colors.red),
                SizedBox(width: 10),
                Expanded(child: Text('Time Is Up')),
              ],
            ),
            content: const Text(
              'Your exam has been submitted automatically '
              'because the allotted time has ended.',
            ),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isAutoSubmitting = false;
      });

      _showMessage(
        'Time expired, but the exam could not be submitted. '
        'Please try again.',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // LOAD QUESTIONS AND ANSWERS
  // ---------------------------------------------------------------------------

  void _loadExistingAnswers() {
    for (final answer in widget.attempt.answers) {
      _answers[answer.questionId] = answer;
    }
  }

  Future<void> _loadQuestions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final allQuestions = await _questionService.getAllQuestions();

      final questionsById = <String, Question>{
        for (final question in allQuestions) question.questionId: question,
      };

      final orderedQuestions = <Question>[];

      for (final questionId in widget.attempt.questionOrder) {
        final question = questionsById[questionId];

        if (question != null) {
          orderedQuestions.add(question);
        }
      }

      if (orderedQuestions.isEmpty) {
        throw Exception('No questions could be loaded for this exam attempt.');
      }

      if (_currentQuestionIndex < 0 ||
          _currentQuestionIndex >= orderedQuestions.length) {
        _currentQuestionIndex = 0;
      }

      if (!mounted) {
        return;
      }

      for (final question in orderedQuestions) {
        if (question.questionType != QuestionType.written) {
          continue;
        }

        final existingAnswer = _answers[question.questionId];

        _writtenControllers[question.questionId] = TextEditingController(
          text: existingAnswer?.writtenAnswer ?? '',
        );
      }

      setState(() {
        _questions = orderedQuestions;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Question? get _currentQuestion {
    if (_questions.isEmpty) {
      return null;
    }

    if (_currentQuestionIndex < 0 ||
        _currentQuestionIndex >= _questions.length) {
      return null;
    }

    return _questions[_currentQuestionIndex];
  }

  // ---------------------------------------------------------------------------
  // OPTIONS
  // ---------------------------------------------------------------------------

  List<QuestionOption> _getOrderedOptions(Question question) {
    final savedOrder = widget.attempt.optionOrder[question.questionId];

    if (savedOrder == null || savedOrder.isEmpty) {
      return question.options;
    }

    final optionsById = <String, QuestionOption>{
      for (final option in question.options) option.optionId: option,
    };

    final orderedOptions = <QuestionOption>[];

    for (final optionId in savedOrder) {
      final option = optionsById[optionId];

      if (option != null) {
        orderedOptions.add(option);
      }
    }

    // Add any options not present in the saved order.
    for (final option in question.options) {
      if (!orderedOptions.any((item) => item.optionId == option.optionId)) {
        orderedOptions.add(option);
      }
    }

    return orderedOptions;
  }

  String _formatMarks(double marks) {
    if (marks == marks.roundToDouble()) {
      return marks.toInt().toString();
    }

    return marks.toStringAsFixed(1);
  }

  String _getOptionLabel(int index) {
    if (index >= 0 && index < 26) {
      return String.fromCharCode('A'.codeUnitAt(0) + index);
    }

    return '${index + 1}';
  }

  bool _isOptionSelected(String questionId, String optionId) {
    final answer = _answers[questionId];

    if (answer == null) {
      return false;
    }

    return answer.selectedOptionIds.contains(optionId);
  }

  // ---------------------------------------------------------------------------
  // ANSWERS
  // ---------------------------------------------------------------------------

  int _getAnsweredCount() {
    return _answers.values.where((answer) {
      return answer.selectedOptionIds.isNotEmpty ||
          answer.writtenAnswer.trim().isNotEmpty;
    }).length;
  }

  List<ExamAttemptAnswer> _getAnswersForSaving() {
    return _answers.values.toList();
  }

  Future<void> _saveProgress() async {
    if (_isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _attemptService.updateProgress(
        attemptId: widget.attempt.attemptId,
        answers: _getAnswersForSaving(),
        answeredCount: _getAnsweredCount(),
        currentQuestionIndex: _currentQuestionIndex,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });

      _showMessage('Could not save your progress. Please try again.');
    }
  }

  Future<void> _selectOption({
    required Question question,
    required String optionId,
  }) async {
    final existingAnswer = _answers[question.questionId];

    final currentSelection = List<String>.from(
      existingAnswer?.selectedOptionIds ?? [],
    );

    if (question.questionType == QuestionType.multiple) {
      if (currentSelection.contains(optionId)) {
        currentSelection.remove(optionId);
      } else {
        currentSelection.add(optionId);
      }
    } else {
      currentSelection
        ..clear()
        ..add(optionId);
    }

    final updatedAnswer = ExamAttemptAnswer(
      questionId: question.questionId,
      selectedOptionIds: currentSelection,
      writtenAnswer: existingAnswer?.writtenAnswer ?? '',
      markedForReview: existingAnswer?.markedForReview ?? false,
    );

    setState(() {
      _answers[question.questionId] = updatedAnswer;
    });

    await _saveProgress();
  }

  Future<void> _saveCurrentWrittenAnswer() async {
    final question = _currentQuestion;

    if (question == null || question.questionType != QuestionType.written) {
      return;
    }

    final controller = _writtenControllers[question.questionId];

    if (controller == null) {
      return;
    }

    final existingAnswer = _answers[question.questionId];

    _answers[question.questionId] = ExamAttemptAnswer(
      questionId: question.questionId,
      selectedOptionIds: existingAnswer?.selectedOptionIds ?? const [],
      writtenAnswer: controller.text,
      markedForReview: existingAnswer?.markedForReview ?? false,
    );
  }

  // ---------------------------------------------------------------------------
  // MARK FOR REVIEW
  // ---------------------------------------------------------------------------

  bool _isCurrentQuestionMarkedForReview() {
    final question = _currentQuestion;

    if (question == null) {
      return false;
    }

    return _answers[question.questionId]?.markedForReview ?? false;
  }

  Future<void> _toggleMarkForReview() async {
    final question = _currentQuestion;

    if (question == null || _isSaving || _isAutoSubmitting) {
      return;
    }

    final existingAnswer = _answers[question.questionId];

    final updatedAnswer = ExamAttemptAnswer(
      questionId: question.questionId,
      selectedOptionIds: existingAnswer?.selectedOptionIds ?? const [],
      writtenAnswer: existingAnswer?.writtenAnswer ?? '',
      markedForReview: !(existingAnswer?.markedForReview ?? false),
    );

    setState(() {
      _answers[question.questionId] = updatedAnswer;
    });

    await _saveProgress();
  }

  // ---------------------------------------------------------------------------
  // QUESTION NAVIGATION
  // ---------------------------------------------------------------------------

  bool _isQuestionAnswered(String questionId) {
    final answer = _answers[questionId];

    if (answer == null) {
      return false;
    }

    return answer.selectedOptionIds.isNotEmpty ||
        answer.writtenAnswer.trim().isNotEmpty;
  }

  bool _isQuestionMarkedForReview(String questionId) {
    return _answers[questionId]?.markedForReview ?? false;
  }

  Future<void> _goToQuestion(int index) async {
    if (_isSaving ||
        _isAutoSubmitting ||
        index < 0 ||
        index >= _questions.length ||
        index == _currentQuestionIndex) {
      return;
    }

    await _saveCurrentWrittenAnswer();

    if (!mounted) {
      return;
    }

    setState(() {
      _currentQuestionIndex = index;
    });

    await _saveProgress();
  }

  Future<void> _goToPreviousQuestion() async {
    if (_currentQuestionIndex <= 0 || _isSaving || _isAutoSubmitting) {
      return;
    }

    await _saveCurrentWrittenAnswer();

    if (!mounted) {
      return;
    }

    setState(() {
      _currentQuestionIndex--;
    });

    await _saveProgress();
  }

  Future<void> _goToNextQuestion() async {
    if (_currentQuestionIndex >= _questions.length - 1 ||
        _isSaving ||
        _isAutoSubmitting) {
      return;
    }

    await _saveCurrentWrittenAnswer();

    if (!mounted) {
      return;
    }

    setState(() {
      _currentQuestionIndex++;
    });

    await _saveProgress();
  }

  // ---------------------------------------------------------------------------
  // MANUAL SUBMISSION
  // ---------------------------------------------------------------------------

  Future<void> _submitExam() async {
    if (_isSaving || _isAutoSubmitting) {
      return;
    }

    await _saveCurrentWrittenAnswer();

    if (!mounted) {
      return;
    }

    final totalQuestions = _questions.length;
    final answeredQuestions = _getAnsweredCount();
    final unansweredQuestions = totalQuestions - answeredQuestions;

    final markedForReviewQuestions = _answers.values
        .where((answer) => answer.markedForReview)
        .length;

    final shouldSubmit = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.assignment_turned_in_rounded, color: Colors.indigo),
              SizedBox(width: 10),
              Expanded(child: Text('Submit Exam?')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Please review your exam summary before submitting.'),
              const SizedBox(height: 20),
              _buildSubmissionSummaryRow(
                icon: Icons.quiz_outlined,
                label: 'Total Questions',
                value: '$totalQuestions',
              ),
              const SizedBox(height: 10),
              _buildSubmissionSummaryRow(
                icon: Icons.check_circle_outline_rounded,
                label: 'Answered',
                value: '$answeredQuestions',
              ),
              const SizedBox(height: 10),
              _buildSubmissionSummaryRow(
                icon: Icons.radio_button_unchecked_rounded,
                label: 'Unanswered',
                value: '$unansweredQuestions',
              ),
              const SizedBox(height: 10),
              _buildSubmissionSummaryRow(
                icon: Icons.bookmark_outline_rounded,
                label: 'Marked for Review',
                value: '$markedForReviewQuestions',
              ),
              if (unansweredQuestions > 0) ...[
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 20,
                        color: Colors.orange.shade800,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'You still have $unansweredQuestions '
                          'unanswered question'
                          '${unansweredQuestions == 1 ? '' : 's'}. '
                          'Are you sure you want to submit?',
                          style: TextStyle(
                            color: Colors.orange.shade900,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              icon: const Icon(Icons.send_rounded),
              label: const Text('Submit Exam'),
            ),
          ],
        );
      },
    );

    if (shouldSubmit != true || !mounted) {
      return;
    }

    setState(() {
      _isAutoSubmitting = true;
    });

    try {
      final finalAttempt = widget.attempt.copyWith(
        answers: _getAnswersForSaving(),
        answeredCount: _getAnsweredCount(),
        currentQuestionIndex: _currentQuestionIndex,
      );

      await _attemptService.updateProgress(
        attemptId: widget.attempt.attemptId,
        answers: _getAnswersForSaving(),
        answeredCount: _getAnsweredCount(),
        currentQuestionIndex: _currentQuestionIndex,
      );

      await _attemptService.completeAttempt(
        exam: widget.exam,
        attempt: finalAttempt,
        score: 0.0,
        percentage: 0.0,
      );

      _examTimer?.cancel();

      if (!mounted) {
        return;
      }

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.green),
                SizedBox(width: 10),
                Expanded(child: Text('Exam Submitted')),
              ],
            ),
            content: const Text('Your exam has been submitted successfully.'),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) {
            return ExamResultScreen(
              exam: widget.exam,
              attempt: finalAttempt,
            );
          },
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isAutoSubmitting = false;
      });

      _showMessage(
        'The exam could not be submitted. '
        'Please try again.',
      );
    }
  }

  Widget _buildSubmissionSummaryRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 19, color: Colors.indigo.shade700),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // QUIT
  // ---------------------------------------------------------------------------

  Future<void> _quitExam() async {
    if (_isSaving || _isAutoSubmitting) {
      return;
    }

    await _saveCurrentWrittenAnswer();

    final shouldQuit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.exit_to_app_rounded, color: Colors.orange),
              SizedBox(width: 10),
              Expanded(child: Text('Quit Exam?')),
            ],
          ),
          content: const Text(
            'Your current progress has been saved. '
            'You can return to this attempt later.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Stay'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              icon: const Icon(Icons.exit_to_app_rounded),
              label: const Text('Quit'),
            ),
          ],
        );
      },
    );

    if (shouldQuit != true || !mounted) {
      return;
    }

    await _saveProgress();

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  // ---------------------------------------------------------------------------
  // LOADING / ERROR
  // ---------------------------------------------------------------------------

  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: Colors.red.shade400,
                ),
                const SizedBox(height: 14),
                const Text(
                  'Unable to Load Questions',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage ??
                      'Something went wrong while loading the questions.',
                  style: TextStyle(color: Colors.grey.shade700, height: 1.4),
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
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // QUESTION HEADER
  // ---------------------------------------------------------------------------

  Widget _buildQuestionHeader(Question question) {
    final questionNumber = _currentQuestionIndex + 1;
    final totalQuestions = _questions.length;

    final progress = totalQuestions == 0
        ? 0.0
        : questionNumber / totalQuestions;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.indigo.shade700,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Question $questionNumber of $totalQuestions',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_outline_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${_formatMarks(question.marks)} marks',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.16),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // QUESTION CARD
  // ---------------------------------------------------------------------------

  Widget _buildQuestionCard(Question question) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question.questionDescription,
            style: const TextStyle(
              fontSize: 18,
              height: 1.55,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          _buildQuestionContent(question),
        ],
      ),
    );
  }

  Widget _buildQuestionContent(Question question) {
    if (question.questionType == QuestionType.written) {
      final controller = _writtenControllers[question.questionId];

      if (controller == null) {
        return const SizedBox.shrink();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Write your answer',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Write your answer clearly in the space below.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            enabled: !_isSaving && !_isAutoSubmitting,
            minLines: 7,
            maxLines: 14,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              hintText: 'Type your answer here...',
              alignLabelWithHint: true,
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Colors.indigo, width: 1.5),
              ),
            ),
          ),
        ],
      );
    }

    final orderedOptions = _getOrderedOptions(question);

    if (orderedOptions.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
        ),
        child: const Text('No answer options are available for this question.'),
      );
    }

    return Column(
      children: [
        for (int index = 0; index < orderedOptions.length; index++)
          _buildOptionCard(
            question: question,
            option: orderedOptions[index],
            index: index,
          ),
      ],
    );
  }

  Widget _buildOptionCard({
    required Question question,
    required QuestionOption option,
    required int index,
  }) {
    final label = _getOptionLabel(index);

    final isSelected = _isOptionSelected(question.questionId, option.optionId);

    final isMultiple = question.questionType == QuestionType.multiple;

    return InkWell(
      onTap: _isSaving || _isAutoSubmitting
          ? null
          : () {
              _selectOption(question: question, optionId: option.optionId);
            },
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.indigo.withValues(alpha: 0.06)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? Colors.indigo : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.indigo
                    : Colors.indigo.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.indigo,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                option.optionText,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.4,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IgnorePointer(
              child: isMultiple
                  ? Checkbox(
                      value: isSelected,
                      onChanged: (_) {},
                      activeColor: Colors.indigo,
                    )
                  : Radio<bool>(
                      value: true,
                      groupValue: isSelected ? true : null,
                      onChanged: (_) {},
                      activeColor: Colors.indigo,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // MARK FOR REVIEW UI
  // ---------------------------------------------------------------------------

  Widget _buildMarkForReviewButton() {
    final isMarked = _isCurrentQuestionMarkedForReview();

    return Align(
      alignment: Alignment.centerRight,
      child: OutlinedButton.icon(
        onPressed: _isSaving || _isAutoSubmitting ? null : _toggleMarkForReview,
        icon: Icon(
          isMarked ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
        ),
        label: Text(isMarked ? 'Marked for Review' : 'Mark for Review'),
        style: OutlinedButton.styleFrom(
          foregroundColor: isMarked
              ? Colors.orange.shade800
              : Colors.grey.shade700,
          side: BorderSide(
            color: isMarked ? Colors.orange.shade300 : Colors.grey.shade300,
          ),
          backgroundColor: isMarked
              ? Colors.orange.withValues(alpha: 0.06)
              : Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // QUESTION NAVIGATOR
  // ---------------------------------------------------------------------------

  Widget _buildQuestionNavigator() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.grid_view_rounded,
                size: 20,
                color: Colors.indigo.shade700,
              ),
              const SizedBox(width: 8),
              const Text(
                'Question Navigator',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (int index = 0; index < _questions.length; index++)
                _buildQuestionNavigatorItem(index),
            ],
          ),
          const SizedBox(height: 16),
          _buildNavigatorLegend(),
        ],
      ),
    );
  }

  Widget _buildQuestionNavigatorItem(int index) {
    final question = _questions[index];

    final isCurrent = index == _currentQuestionIndex;
    final isAnswered = _isQuestionAnswered(question.questionId);
    final isMarked = _isQuestionMarkedForReview(question.questionId);

    Color backgroundColor;
    Color foregroundColor;
    Color borderColor;

    if (isCurrent) {
      backgroundColor = Colors.indigo;
      foregroundColor = Colors.white;
      borderColor = Colors.indigo;
    } else if (isMarked && isAnswered) {
      backgroundColor = Colors.orange.shade50;
      foregroundColor = Colors.orange.shade900;
      borderColor = Colors.orange.shade400;
    } else if (isMarked) {
      backgroundColor = Colors.orange.shade50;
      foregroundColor = Colors.orange.shade900;
      borderColor = Colors.orange.shade300;
    } else if (isAnswered) {
      backgroundColor = Colors.green.shade50;
      foregroundColor = Colors.green.shade800;
      borderColor = Colors.green.shade300;
    } else {
      backgroundColor = Colors.grey.shade50;
      foregroundColor = Colors.grey.shade700;
      borderColor = Colors.grey.shade300;
    }

    return InkWell(
      onTap: _isSaving || _isAutoSubmitting
          ? null
          : () {
              _goToQuestion(index);
            },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: isCurrent ? 1.5 : 1),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              '${index + 1}',
              style: TextStyle(
                color: foregroundColor,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            if (isMarked && !isCurrent)
              Positioned(
                top: 3,
                right: 3,
                child: Icon(
                  Icons.bookmark_rounded,
                  size: 10,
                  color: Colors.orange.shade700,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigatorLegend() {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        _buildLegendItem(color: Colors.indigo, label: 'Current'),
        _buildLegendItem(color: Colors.green.shade400, label: 'Answered'),
        _buildLegendItem(color: Colors.orange.shade400, label: 'Review'),
        _buildLegendItem(color: Colors.grey.shade400, label: 'Unanswered'),
      ],
    );
  }

  Widget _buildLegendItem({required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // BOTTOM NAVIGATION
  // ---------------------------------------------------------------------------

  Widget _buildNavigationBar() {
    final isFirst = _currentQuestionIndex == 0;

    final isLast = _currentQuestionIndex == _questions.length - 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isFirst || _isSaving || _isAutoSubmitting
                    ? null
                    : _goToPreviousQuestion,
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Previous'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: _isSaving || _isAutoSubmitting
                    ? null
                    : isLast
                    ? _submitExam
                    : _goToNextQuestion,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        isLast
                            ? Icons.send_rounded
                            : Icons.arrow_forward_rounded,
                      ),
                label: Text(
                  _isSaving
                      ? 'Saving...'
                      : isLast
                      ? 'Submit Exam'
                      : 'Next',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CONTENT
  // ---------------------------------------------------------------------------

  Widget _buildContent() {
    final question = _currentQuestion;

    if (question == null) {
      return const Center(child: Text('Question not available.'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildQuestionHeader(question),
              const SizedBox(height: 12),
              _buildMarkForReviewButton(),
              const SizedBox(height: 14),
              _buildQuestionCard(question),
              const SizedBox(height: 18),
              _buildQuestionNavigator(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            const Icon(Icons.assignment_rounded, color: Colors.indigo),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.exam.examName,
                style: const TextStyle(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          _buildTimerDisplay(),
          const SizedBox(width: 8),
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Center(
                child: Text(
                  'Saving...',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: TextButton.icon(
              onPressed: _isSaving || _isAutoSubmitting ? null : _quitExam,
              icon: const Icon(Icons.exit_to_app_rounded),
              label: const Text('Quit'),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _isLoading || _errorMessage != null
          ? null
          : _buildNavigationBar(),
      body: _isLoading
          ? _buildLoadingState()
          : _errorMessage != null
          ? _buildErrorState()
          : _buildContent(),
    );
  }
}
