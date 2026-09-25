import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:questionbank/models/question.dart';
import 'package:questionbank/services/question_service.dart';
import 'package:questionbank/screens/examinee/examinee_edit_question_screen.dart';

class ExamineeMyQuestionsScreen extends StatefulWidget {
  const ExamineeMyQuestionsScreen({
    super.key,
  });

  @override
  State<ExamineeMyQuestionsScreen> createState() =>
      _ExamineeMyQuestionsScreenState();
}

class _ExamineeMyQuestionsScreenState
    extends State<ExamineeMyQuestionsScreen> {
  final QuestionService _questionService = QuestionService();

  bool _isLoading = true;
  String? _errorMessage;

  List<Question> _questions = [];

  QuestionStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  // ---------------------------------------------------------------------------
  // DATA
  // ---------------------------------------------------------------------------

  Future<void> _loadQuestions() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'You are not logged in.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final questions =
      await _questionService.getQuestionsByCreator(user.uid);

      if (!mounted) return;

      setState(() {
        _questions = questions;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load your submitted questions: $e';
      });
    }
  }

  List<Question> get _filteredQuestions {
    List<Question> result;

    if (_selectedStatus == null) {
      result = List<Question>.from(_questions);
    } else {
      result = _questions
          .where(
            (question) =>
        question.status == _selectedStatus,
      )
          .toList();
    }

    // When "All" is selected, show Pending first,
    // then Approved, then Rejected.
    result.sort((a, b) {
      final statusComparison =
      _statusOrder(a.status).compareTo(
        _statusOrder(b.status),
      );

      if (statusComparison != 0) {
        return statusComparison;
      }

      return b.createdAt.compareTo(a.createdAt);
    });

    return result;
  }

  int _statusOrder(QuestionStatus status) {
    switch (status) {
      case QuestionStatus.pending:
        return 0;
      case QuestionStatus.approved:
        return 1;
      case QuestionStatus.rejected:
        return 2;
    }
  }

  // ---------------------------------------------------------------------------
  // NAVIGATION
  // ---------------------------------------------------------------------------

  Future<void> _openQuestion(Question question) async {
    if (question.status == QuestionStatus.pending) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ExamineeEditQuestionScreen(
            question: question,
          ),
        ),
      );

      if (mounted) {
        _loadQuestions();
      }

      return;
    }

    await _showQuestionDetails(question);
  }

  // ---------------------------------------------------------------------------
  // QUESTION DETAILS
  // ---------------------------------------------------------------------------

  Future<void> _showQuestionDetails(
      Question question,
      ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _QuestionDetailsSheet(
          question: question,
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------

  String _statusLabel(QuestionStatus status) {
    switch (status) {
      case QuestionStatus.pending:
        return 'Pending';
      case QuestionStatus.approved:
        return 'Approved';
      case QuestionStatus.rejected:
        return 'Rejected';
    }
  }

  Color _statusColor(QuestionStatus status) {
    switch (status) {
      case QuestionStatus.pending:
        return Colors.orange;
      case QuestionStatus.approved:
        return Colors.green;
      case QuestionStatus.rejected:
        return Colors.red;
    }
  }

  IconData _statusIcon(QuestionStatus status) {
    switch (status) {
      case QuestionStatus.pending:
        return Icons.schedule_rounded;
      case QuestionStatus.approved:
        return Icons.check_circle_rounded;
      case QuestionStatus.rejected:
        return Icons.cancel_rounded;
    }
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

  String _difficultyLabel(DifficultyLevel difficulty) {
    switch (difficulty) {
      case DifficultyLevel.easy:
        return 'Easy';
      case DifficultyLevel.medium:
        return 'Medium';
      case DifficultyLevel.hard:
        return 'Hard';
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$day/$month/$year';
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: colorScheme.primary.withValues(
        alpha: 0.035,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: Colors.grey.shade300,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: Colors.grey.shade300,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: colorScheme.primary,
          width: 1.5,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.indigo.shade800,
            Colors.indigo.shade600,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.library_books_rounded,
              color: Colors.white,
              size: 29,
            ),
          ),
          const SizedBox(width: 15),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Submitted Questions',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'View and manage the questions you have contributed to the question bank.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
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

  Widget _buildFilterCard() {
    final filteredCount = _filteredQuestions.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filter Questions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Select which type of submitted questions you want to see.',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<QuestionStatus?>(
            value: _selectedStatus,
            isExpanded: true,
            decoration: _inputDecoration(
              label: 'Question Status',
              icon: Icons.filter_list_rounded,
            ),
            items: const [
              DropdownMenuItem<QuestionStatus?>(
                value: null,
                child: Text('All Questions'),
              ),
              DropdownMenuItem<QuestionStatus?>(
                value: QuestionStatus.pending,
                child: Text('Pending'),
              ),
              DropdownMenuItem<QuestionStatus?>(
                value: QuestionStatus.approved,
                child: Text('Approved'),
              ),
              DropdownMenuItem<QuestionStatus?>(
                value: QuestionStatus.rejected,
                child: Text('Rejected'),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _selectedStatus = value;
              });
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 18,
                color: Colors.indigo.shade500,
              ),
              const SizedBox(width: 8),
              Text(
                '$filteredCount question${filteredCount == 1 ? '' : 's'} shown',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(
      Question question,
      ) {
    final statusColor = _statusColor(question.status);
    final isPending =
        question.status == QuestionStatus.pending;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _openQuestion(question),
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      question.questionDescription,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _buildStatusBadge(question.status),
                ],
              ),

              const SizedBox(height: 14),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildInfoChip(
                    Icons.quiz_outlined,
                    _questionTypeLabel(
                      question.questionType,
                    ),
                  ),
                  _buildInfoChip(
                    Icons.speed_rounded,
                    _difficultyLabel(
                      question.difficulty,
                    ),
                  ),
                  _buildInfoChip(
                    Icons.star_outline_rounded,
                      '${question.marks % 1 == 0 ? question.marks.toInt() : question.marks} '
                          '${question.marks == 1 ? 'mark' : 'marks'}'
                  ),
                ],
              ),

              const SizedBox(height: 13),

              Divider(
                height: 1,
                color: Colors.grey.shade200,
              ),

              const SizedBox(height: 11),

              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 15,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Submitted ${_formatDate(question.createdAt)}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  if (isPending)
                    TextButton.icon(
                      onPressed: () =>
                          _openQuestion(question),
                      icon: const Icon(
                        Icons.edit_rounded,
                        size: 17,
                      ),
                      label: const Text('Edit'),
                    )
                  else
                    TextButton.icon(
                      onPressed: () =>
                          _showQuestionDetails(question),
                      icon: const Icon(
                        Icons.visibility_outlined,
                        size: 17,
                      ),
                      label: const Text('View'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(
      QuestionStatus status,
      ) {
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.20),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _statusIcon(status),
            color: color,
            size: 15,
          ),
          const SizedBox(width: 5),
          Text(
            _statusLabel(status),
            style: TextStyle(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(
      IconData icon,
      String text,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: Colors.grey.shade600,
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final statusText = _selectedStatus == null
        ? 'No questions submitted yet.'
        : 'No ${_statusLabel(_selectedStatus!)} questions found.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(35),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.quiz_outlined,
            size: 58,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 14),
          Text(
            statusText,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            _selectedStatus == null
                ? 'Questions you contribute will appear here.'
                : 'Try selecting another status from the filter above.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 55,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 15),
            const Text(
              'Unable to load your questions',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ??
                  'An unexpected error occurred.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _loadQuestions,
              icon: const Icon(
                Icons.refresh_rounded,
              ),
              label: const Text('Retry'),
            ),
          ],
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
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () =>
              Navigator.of(context).pop(),
          icon: const Icon(
            Icons.arrow_back_rounded,
          ),
        ),
        title: const Text(
          'My Submitted Questions',
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading
                ? null
                : _loadQuestions,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoading()
          : _errorMessage != null
          ? _buildError()
          : SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadQuestions,
          child: SingleChildScrollView(
            physics:
            const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              20,
              20,
              20,
              35,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints:
                const BoxConstraints(
                  maxWidth: 1000,
                ),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 18),
                    _buildFilterCard(),
                    const SizedBox(height: 18),
                    if (_filteredQuestions.isEmpty)
                      _buildEmptyState()
                    else
                      ..._filteredQuestions.map(
                        _buildQuestionCard,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// QUESTION DETAILS SHEET
// =============================================================================

class _QuestionDetailsSheet extends StatelessWidget {
  final Question question;

  const _QuestionDetailsSheet({
    required this.question,
  });

  String _statusLabel(QuestionStatus status) {
    switch (status) {
      case QuestionStatus.pending:
        return 'Pending';
      case QuestionStatus.approved:
        return 'Approved';
      case QuestionStatus.rejected:
        return 'Rejected';
    }
  }

  Color _statusColor(QuestionStatus status) {
    switch (status) {
      case QuestionStatus.pending:
        return Colors.orange;
      case QuestionStatus.approved:
        return Colors.green;
      case QuestionStatus.rejected:
        return Colors.red;
    }
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

  String _difficultyLabel(DifficultyLevel difficulty) {
    switch (difficulty) {
      case DifficultyLevel.easy:
        return 'Easy';
      case DifficultyLevel.medium:
        return 'Medium';
      case DifficultyLevel.hard:
        return 'Hard';
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(question.status);

    return SafeArea(
      child: Container(
        constraints: const BoxConstraints(
          maxHeight: 700,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            22,
            8,
            22,
            30,
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Question Details',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(
                        alpha: 0.09,
                      ),
                      borderRadius:
                      BorderRadius.circular(20),
                    ),
                    child: Text(
                      _statusLabel(question.status),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                question.questionDescription,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(
                    avatar: const Icon(
                      Icons.quiz_outlined,
                      size: 17,
                    ),
                    label: Text(
                      _questionTypeLabel(
                        question.questionType,
                      ),
                    ),
                  ),
                  Chip(
                    avatar: const Icon(
                      Icons.speed_rounded,
                      size: 17,
                    ),
                    label: Text(
                      _difficultyLabel(
                        question.difficulty,
                      ),
                    ),
                  ),
                  Chip(
                    avatar: const Icon(
                      Icons.star_outline_rounded,
                      size: 17,
                    ),
                    label: Text(
                        '${question.marks % 1 == 0 ? question.marks.toInt() : question.marks} '
                            '${question.marks == 1 ? 'mark' : 'marks'}'
                    ),
                  ),
                ],
              ),
              if (question.options.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text(
                  'Options',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...question.options.map(
                      (option) {
                    final isCorrect =
                    question.correctAnswers
                        .contains(option.optionId);

                    return Container(
                      margin:
                      const EdgeInsets.only(bottom: 8),
                      padding:
                      const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isCorrect
                            ? Colors.green.withValues(
                          alpha: 0.06,
                        )
                            : Colors.grey.shade50,
                        borderRadius:
                        BorderRadius.circular(12),
                        border: Border.all(
                          color: isCorrect
                              ? Colors.green.withValues(
                            alpha: 0.25,
                          )
                              : Colors.grey.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              option.optionText,
                              style: const TextStyle(
                                fontSize: 13.5,
                              ),
                            ),
                          ),
                          if (isCorrect)
                            const Icon(
                              Icons.check_circle_rounded,
                              color: Colors.green,
                              size: 19,
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ],
              if (question.writtenAssessment !=
                  null) ...[
                const SizedBox(height: 20),
                const Text(
                  'Reference Answer',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  question
                      .writtenAssessment!
                      .referenceAnswer,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    height: 1.45,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}