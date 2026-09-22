import 'package:flutter/material.dart';
import 'package:questionbank/models/exam.dart';
import 'package:questionbank/models/question.dart';
import 'package:questionbank/services/question_service.dart';

import '../../services/exam_service.dart';

class ManageExamQuestionsDialog extends StatefulWidget {
  final Exam exam;

  const ManageExamQuestionsDialog({super.key, required this.exam});

  @override
  State<ManageExamQuestionsDialog> createState() =>
      _ManageExamQuestionsDialogState();
}

class _ManageExamQuestionsDialogState extends State<ManageExamQuestionsDialog> {
  final QuestionService _questionService = QuestionService();

  bool _isLoading = true;
  String? _errorMessage;

  List<Question> _questions = [];
  final Set<String> _selectedQuestionIds = {};

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final approvedQuestions = await _questionService.getQuestionsByStatus(
        QuestionStatus.approved,
      );

      final eligibleQuestions = approvedQuestions.where((question) {
        // The exam must have a program.
        if (widget.exam.programId == null || widget.exam.programId!.isEmpty) {
          return false;
        }

        // Question must belong to the exam's program.
        if (question.programId != widget.exam.programId) {
          return false;
        }

        // Question must belong to one of the exam's selected subjects.
        if (!widget.exam.subjectIds.contains(question.subjectId)) {
          return false;
        }

        return true;
      }).toList();

      // Pre-select questions that are already attached to the exam.
      final existingQuestionIds = widget.exam.questions
          .map((q) => q.questionId)
          .toSet();

      if (!mounted) return;

      setState(() {
        _questions = eligibleQuestions;
        _selectedQuestionIds
          ..clear()
          ..addAll(
            existingQuestionIds.where(
              (id) => eligibleQuestions.any(
                (question) => question.questionId == id,
              ),
            ),
          );
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    } 
  }

  void _toggleQuestion(String questionId) {
    setState(() {
      if (_selectedQuestionIds.contains(questionId)) {
        _selectedQuestionIds.remove(questionId);
      } else {
        _selectedQuestionIds.add(questionId);
      }
    });
  }

  int get _selectedCount => _selectedQuestionIds.length;

  double get _totalMarks {
    return _questions
        .where(
          (question) =>
          _selectedQuestionIds.contains(question.questionId),
    )
        .fold<double>(
      0,
          (total, question) => total + question.marks,
    );
  }

  bool get _allSelected =>
      _questions.isNotEmpty && _selectedQuestionIds.length == _questions.length;

  void _toggleSelectAll() {
    setState(() {
      if (_allSelected) {
        _selectedQuestionIds.clear();
      } else {
        _selectedQuestionIds
          ..clear()
          ..addAll(_questions.map((question) => question.questionId));
      }
    });
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

  Color _difficultyColor(DifficultyLevel difficulty) {
    switch (difficulty) {
      case DifficultyLevel.easy:
        return Colors.green;
      case DifficultyLevel.medium:
        return Colors.orange;
      case DifficultyLevel.hard:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      title: Row(
        children: [
          const Icon(Icons.playlist_add_check_outlined, color: Colors.indigo),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Manage Questions',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      content: SizedBox(width: 900, height: 600, child: _buildContent()),
      actions: [
        TextButton(
          onPressed: _isLoading
              ? null
              : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: _isLoading || _questions.isEmpty
              ? null
              : _saveQuestions,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Save Questions'),
        ),
      ],
    );
  }

  Future<void> _saveQuestions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final existingQuestions = {
        for (final question in widget.exam.questions)
          question.questionId: question,
      };

      final selectedQuestions = <ExamQuestion>[];

      for (final question in _questions) {
        if (!_selectedQuestionIds.contains(question.questionId)) {
          continue;
        }

        final existingQuestion =
        existingQuestions[question.questionId];

        if (existingQuestion != null) {
          selectedQuestions.add(
            existingQuestion,
          );
        } else {
          selectedQuestions.add(
            ExamQuestion(
              questionId: question.questionId,
              marks: question.marks,
              order: selectedQuestions.length + 1,
            ),
          );
        }
      }

      // Rebuild the order so that the saved questions always have
      // a clean sequential order.
      final orderedQuestions = <ExamQuestion>[];

      for (int index = 0;
      index < selectedQuestions.length;
      index++) {
        orderedQuestions.add(
          selectedQuestions[index].copyWith(
            order: index + 1,
          ),
        );
      }

      final examService = ExamService();

      await examService.updateExamQuestions(
        examId: widget.exam.examId,
        questions: orderedQuestions,
      );

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (widget.exam.questionSelectionMode ==
        ExamQuestionSelectionMode.automatic) {
      return _buildAutomaticModeMessage();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildExamInformation(),
        const SizedBox(height: 14),
        _buildSelectionSummary(),
        const SizedBox(height: 14),
        if (_questions.isEmpty)
          Expanded(child: _buildEmptyState())
        else
          Expanded(child: _buildQuestionList()),
      ],
    );
  }

  Widget _buildExamInformation() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.assignment_outlined, color: Colors.indigo),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.exam.examName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          const Text(
            'Manual Selection',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.indigo,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionSummary() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.indigo.shade100),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryItem(
              icon: Icons.checklist_outlined,
              label: 'Selected',
              value: '$_selectedCount',
            ),
          ),
          Container(width: 1, height: 34, color: Colors.indigo.shade100),
          Expanded(
            child: _buildSummaryItem(
              icon: Icons.stars_outlined,
              label: 'Total Marks',
              value: '$_totalMarks',
            ),
          ),
          const SizedBox(width: 12),
          TextButton.icon(
            onPressed: _questions.isEmpty ? null : _toggleSelectAll,
            icon: Icon(
              _allSelected
                  ? Icons.deselect_outlined
                  : Icons.select_all_outlined,
            ),
            label: Text(_allSelected ? 'Clear All' : 'Select All'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.indigo),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildQuestionList() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(10),
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 48),
                Expanded(
                  child: Text(
                    'QUESTION',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
                const SizedBox(
                  width: 120,
                  child: Text(
                    'TYPE',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(
                  width: 90,
                  child: Text(
                    'DIFFICULTY',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(
                  width: 70,
                  child: Text(
                    'MARKS',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: _questions.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: Colors.grey.shade200),
              itemBuilder: (context, index) {
                return _buildQuestionRow(_questions[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionRow(Question question) {
    final isSelected = _selectedQuestionIds.contains(question.questionId);

    return InkWell(
      onTap: () => _toggleQuestion(question.questionId),
      child: Container(
        color: isSelected ? Colors.indigo.withValues(alpha: 0.04) : null,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            Checkbox(
              value: isSelected,
              onChanged: (_) => _toggleQuestion(question.questionId),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                question.questionDescription,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13),
              ),
            ),
            SizedBox(
              width: 120,
              child: Text(
                _questionTypeLabel(question.questionType),
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
            ),
            SizedBox(
              width: 90,
              child: Text(
                _difficultyLabel(question.difficulty),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _difficultyColor(question.difficulty),
                ),
              ),
            ),
            SizedBox(
              width: 70,
              child: Text(
                '${question.marks}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.quiz_outlined, size: 52, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          const Text(
            'No eligible questions found',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            'Only approved questions from this exam\'s\n'
            'program and selected subjects are shown.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
          const SizedBox(height: 12),
          Text(
            _errorMessage!,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _loadQuestions,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildAutomaticModeMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shuffle_outlined, size: 54, color: Colors.indigo.shade300),
          const SizedBox(height: 14),
          const Text(
            'Automatic Question Selection',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Automatic question selection will be configured\n'
            'in the next step.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
