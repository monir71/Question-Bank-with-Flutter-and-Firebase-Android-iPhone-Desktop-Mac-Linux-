import 'package:flutter/material.dart';
import 'package:questionbank/models/program.dart';
import 'package:questionbank/models/question.dart';
import 'package:questionbank/models/subject.dart';
import 'package:questionbank/models/topic.dart';

import '../../services/question_service.dart';

class EditQuestionDialog extends StatefulWidget {
  final Question question;
  final List<Program> programs;
  final List<Subject> subjects;
  final List<Topic> topics;

  const EditQuestionDialog({
    super.key,
    required this.question,
    required this.programs,
    required this.subjects,
    required this.topics,
  });

  @override
  State<EditQuestionDialog> createState() => _EditQuestionDialogState();
}

class _EditQuestionDialogState extends State<EditQuestionDialog> {
  final _formKey = GlobalKey<FormState>();

  late String _selectedProgramId;
  String? _selectedSubjectId;
  String? _selectedTopicId;

  late QuestionType _selectedQuestionType;
  late DifficultyLevel _selectedDifficulty;

  late TextEditingController _questionDescriptionController;
  late TextEditingController _marksController;

  final List<TextEditingController> _optionControllers = [];
  final List<String> _optionIds = [];
  final Set<int> _correctOptionIndexes = {};

  bool? _trueFalseAnswer;

  late TextEditingController _referenceAnswerController;
  late AssessmentType _selectedAssessmentType;

  final List<String> _criterionIds = [];
  final List<TextEditingController> _criterionControllers = [];
  final List<TextEditingController> _criterionMarkControllers = [];

  @override
  void initState() {
    super.initState();

    _selectedProgramId = widget.question.programId;
    _selectedSubjectId = widget.question.subjectId;
    _selectedTopicId = widget.question.topicId;

    _selectedQuestionType = widget.question.questionType;

    _selectedDifficulty = widget.question.difficulty;

    _questionDescriptionController = TextEditingController(
      text: widget.question.questionDescription,
    );

    _marksController = TextEditingController(
      text: widget.question.marks.toString(),
    );

    if (_selectedQuestionType == QuestionType.multiple) {
      for (int i = 0; i < widget.question.options.length; i++) {
        final option = widget.question.options[i];

        _optionIds.add(option.optionId);

        _optionControllers.add(TextEditingController(text: option.optionText));

        if (widget.question.correctAnswers.contains(option.optionId)) {
          _correctOptionIndexes.add(i);
        }
      }
    }

    if (_selectedQuestionType == QuestionType.trueFalse) {
      if (widget.question.correctAnswers.contains('true')) {
        _trueFalseAnswer = true;
      } else if (widget.question.correctAnswers.contains('false')) {
        _trueFalseAnswer = false;
      }
    }

    if (_selectedQuestionType == QuestionType.written) {
      final assessment = widget.question.writtenAssessment;

      _referenceAnswerController = TextEditingController(
        text: assessment?.referenceAnswer ?? '',
      );

      _selectedAssessmentType =
          assessment?.assessmentType ?? AssessmentType.manual;

      if (assessment != null) {
        for (final criterion in assessment.criteria) {
          _criterionIds.add(criterion.criterionId);

          _criterionControllers.add(
            TextEditingController(text: criterion.criterion),
          );

          _criterionMarkControllers.add(
            TextEditingController(text: criterion.marks.toString()),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _questionDescriptionController.dispose();
    _marksController.dispose();

    for (final controller in _optionControllers) {
      controller.dispose();
    }

    if (_selectedQuestionType == QuestionType.written) {
      _referenceAnswerController.dispose();

      for (final controller in _criterionControllers) {
        controller.dispose();
      }

      for (final controller in _criterionMarkControllers) {
        controller.dispose();
      }
    }

    super.dispose();
  }

  List<Subject> get _filteredSubjects {
    return widget.subjects
        .where(
          (subject) =>
              subject.programId == _selectedProgramId && subject.isActive,
        )
        .toList();
  }

  List<Topic> get _filteredTopics {
    return widget.topics
        .where(
          (topic) => topic.subjectId == _selectedSubjectId && topic.isActive,
        )
        .toList();
  }

  String _generateId() {
    return DateTime.now().microsecondsSinceEpoch.toString();
  }

  String _getQuestionTypeLabel(QuestionType type) {
    switch (type) {
      case QuestionType.multiple:
        return 'Multiple Choice';

      case QuestionType.trueFalse:
        return 'True / False';

      case QuestionType.written:
        return 'Written';
    }
  }

  String _getDifficultyLabel(DifficultyLevel difficulty) {
    switch (difficulty) {
      case DifficultyLevel.easy:
        return 'Easy';

      case DifficultyLevel.medium:
        return 'Medium';

      case DifficultyLevel.hard:
        return 'Hard';
    }
  }

  String _getAssessmentTypeLabel(AssessmentType type) {
    switch (type) {
      case AssessmentType.automatic:
        return 'Automatic';

      case AssessmentType.manual:
        return 'Manual';

      case AssessmentType.hybrid:
        return 'Hybrid';
    }
  }

  void _addOption() {
    if (_optionControllers.length >= 6) {
      return;
    }

    setState(() {
      final optionId = _generateId();

      _optionIds.add(optionId);

      _optionControllers.add(TextEditingController());
    });
  }

  void _removeOption(int index) {
    if (_optionControllers.length <= 2) {
      return;
    }

    setState(() {
      _optionControllers[index].dispose();

      _optionControllers.removeAt(index);
      _optionIds.removeAt(index);

      final updatedCorrectIndexes = <int>{};

      for (final correctIndex in _correctOptionIndexes) {
        if (correctIndex == index) {
          continue;
        }

        if (correctIndex > index) {
          updatedCorrectIndexes.add(correctIndex - 1);
        } else {
          updatedCorrectIndexes.add(correctIndex);
        }
      }

      _correctOptionIndexes
        ..clear()
        ..addAll(updatedCorrectIndexes);
    });
  }

  void _addCriterion() {
    setState(() {
      _criterionIds.add(_generateId());

      _criterionControllers.add(TextEditingController());

      _criterionMarkControllers.add(TextEditingController());
    });
  }

  void _removeCriterion(int index) {
    if (_criterionControllers.length <= 1) {
      return;
    }

    setState(() {
      _criterionControllers[index].dispose();
      _criterionMarkControllers[index].dispose();

      _criterionControllers.removeAt(index);
      _criterionMarkControllers.removeAt(index);
      _criterionIds.removeAt(index);
    });
  }

  Widget _buildMultipleChoiceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),

        const Text(
          'Options',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 8),

        ...List.generate(_optionControllers.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Checkbox(
                  value: _correctOptionIndexes.contains(index),
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _correctOptionIndexes.add(index);
                      } else {
                        _correctOptionIndexes.remove(index);
                      }
                    });
                  },
                ),

                Expanded(
                  child: TextFormField(
                    controller: _optionControllers[index],
                    decoration: InputDecoration(
                      labelText: 'Option ${index + 1}',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),

                IconButton(
                  tooltip: 'Remove option',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: _optionControllers.length > 2
                      ? () {
                          _removeOption(index);
                        }
                      : null,
                ),
              ],
            ),
          );
        }),

        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _optionControllers.length < 6 ? _addOption : null,
            icon: const Icon(Icons.add),
            label: const Text('Add Option'),
          ),
        ),
      ],
    );
  }

  Widget _buildTrueFalseSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),

        const Text(
          'Correct Answer',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),

        RadioListTile<bool>(
          title: const Text('True'),
          value: true,
          groupValue: _trueFalseAnswer,
          onChanged: (value) {
            setState(() {
              _trueFalseAnswer = value;
            });
          },
        ),

        RadioListTile<bool>(
          title: const Text('False'),
          value: false,
          groupValue: _trueFalseAnswer,
          onChanged: (value) {
            setState(() {
              _trueFalseAnswer = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildWrittenSection() {
    final showCriteria =
        _selectedAssessmentType == AssessmentType.manual ||
        _selectedAssessmentType == AssessmentType.hybrid;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),

        TextFormField(
          controller: _referenceAnswerController,
          decoration: const InputDecoration(
            labelText: 'Reference Answer',
            hintText: 'Enter the reference answer...',
            border: OutlineInputBorder(),
          ),
          maxLines: 8,
        ),

        const SizedBox(height: 16),

        DropdownButtonFormField<AssessmentType>(
          value: _selectedAssessmentType,
          decoration: const InputDecoration(
            labelText: 'Assessment Type',
            border: OutlineInputBorder(),
          ),
          items: AssessmentType.values
              .map(
                (type) => DropdownMenuItem<AssessmentType>(
                  value: type,
                  child: Text(_getAssessmentTypeLabel(type)),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) {
              return;
            }

            setState(() {
              _selectedAssessmentType = value;
            });
          },
        ),

        if (showCriteria) ...[
          const SizedBox(height: 16),

          const Text(
            'Assessment Criteria',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          ...List.generate(_criterionControllers.length, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _criterionControllers[index],
                      decoration: InputDecoration(
                        labelText: 'Criterion ${index + 1}',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  SizedBox(
                    width: 100,
                    child: TextFormField(
                      controller: _criterionMarkControllers[index],
                      decoration: const InputDecoration(
                        labelText: 'Marks',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),

                  IconButton(
                    tooltip: 'Remove criterion',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: _criterionControllers.length > 1
                        ? () {
                            _removeCriterion(index);
                          }
                        : null,
                  ),
                ],
              ),
            );
          }),

          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _addCriterion,
              icon: const Icon(Icons.add),
              label: const Text('Add Criterion'),
            ),
          ),
        ],
      ],
    );
  }

  bool _validateMultipleChoice() {
    for (final controller in _optionControllers) {
      if (controller.text.trim().isEmpty) {
        return false;
      }
    }

    if (_correctOptionIndexes.isEmpty) {
      return false;
    }

    return true;
  }

  bool _validateTrueFalse() {
    return _trueFalseAnswer != null;
  }

  bool _validateWrittenQuestion() {
    if (_referenceAnswerController.text.trim().isEmpty) {
      return false;
    }

    if (_selectedAssessmentType == AssessmentType.manual ||
        _selectedAssessmentType == AssessmentType.hybrid) {
      if (_criterionControllers.isEmpty) {
        return false;
      }

      for (int i = 0; i < _criterionControllers.length; i++) {
        if (_criterionControllers[i].text.trim().isEmpty) {
          return false;
        }

        final criterionMarks = double.tryParse(
          _criterionMarkControllers[i].text.trim(),
        );

        if (criterionMarks == null || criterionMarks <= 0) {
          return false;
        }
      }

      final questionMarks = double.tryParse(_marksController.text.trim());

      if (questionMarks == null) {
        return false;
      }

      final totalCriterionMarks = _criterionMarkControllers.fold<double>(0, (
        total,
        controller,
      ) {
        return total + (double.tryParse(controller.text.trim()) ?? 0);
      });

      if (totalCriterionMarks != questionMarks) {
        return false;
      }
    }

    return true;
  }

  Question _buildUpdatedQuestion() {
    final options = <QuestionOption>[];
    final correctAnswers = <String>[];

    if (_selectedQuestionType == QuestionType.multiple) {
      for (int i = 0; i < _optionControllers.length; i++) {
        final optionId = _optionIds[i];

        options.add(
          QuestionOption(
            optionId: optionId,
            optionText: _optionControllers[i].text.trim(),
          ),
        );

        if (_correctOptionIndexes.contains(i)) {
          correctAnswers.add(optionId);
        }
      }
    }

    if (_selectedQuestionType == QuestionType.trueFalse) {
      const trueOptionId = 'true';
      const falseOptionId = 'false';

      options.add(
        const QuestionOption(optionId: trueOptionId, optionText: 'True'),
      );

      options.add(
        const QuestionOption(optionId: falseOptionId, optionText: 'False'),
      );

      correctAnswers.add(
        _trueFalseAnswer == true ? trueOptionId : falseOptionId,
      );
    }

    WrittenAssessment? writtenAssessment;

    if (_selectedQuestionType == QuestionType.written) {
      final criteria = <AssessmentCriterion>[];

      if (_selectedAssessmentType == AssessmentType.manual ||
          _selectedAssessmentType == AssessmentType.hybrid) {
        for (int i = 0; i < _criterionControllers.length; i++) {
          criteria.add(
            AssessmentCriterion(
              criterionId: _criterionIds[i],
              criterion: _criterionControllers[i].text.trim(),
              marks: double.parse(_criterionMarkControllers[i].text.trim()),
            ),
          );
        }
      }

      writtenAssessment = WrittenAssessment(
        assessmentType: _selectedAssessmentType,
        referenceAnswer: _referenceAnswerController.text.trim(),
        criteria: criteria,
      );
    }

    return Question(
      questionId: widget.question.questionId,
      questionDescription: _questionDescriptionController.text.trim(),
      programId: _selectedProgramId,
      subjectId: _selectedSubjectId!,
      topicId: _selectedTopicId!,
      questionType: _selectedQuestionType,
      difficulty: _selectedDifficulty,
      options: options,
      correctAnswers: correctAnswers,
      writtenAssessment: writtenAssessment,
      marks: double.parse(_marksController.text.trim()),
      createdBy: widget.question.createdBy,
      status: widget.question.status,
      approvedBy: widget.question.approvedBy,
      approvedAt: widget.question.approvedAt,
      createdAt: widget.question.createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedQuestionType == QuestionType.written &&
        !_validateWrittenQuestion()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please complete the written assessment correctly. '
            'Criterion marks must equal question marks.',
          ),
        ),
      );
      return;
    }

    if (_selectedQuestionType == QuestionType.multiple &&
        !_validateMultipleChoice()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter all options and select at least one correct answer.',
          ),
        ),
      );
      return;
    }

    if (_selectedQuestionType == QuestionType.trueFalse &&
        !_validateTrueFalse()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select True or False as the correct answer.'),
        ),
      );
      return;
    }

    final updatedQuestion = _buildUpdatedQuestion();

    try {
      final questionService = QuestionService();

      await questionService.updateQuestion(updatedQuestion);

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update question: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Question'),

      content: SizedBox(
        width: 600,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedProgramId,
                  decoration: const InputDecoration(
                    labelText: 'Program',
                    border: OutlineInputBorder(),
                  ),
                  items: widget.programs
                      .where((program) => program.isActive)
                      .map(
                        (program) => DropdownMenuItem<String>(
                          value: program.programId,
                          child: Text(program.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }

                    setState(() {
                      _selectedProgramId = value;

                      final subjectStillValid = widget.subjects.any(
                        (subject) =>
                            subject.programId == value &&
                            subject.subjectId == _selectedSubjectId &&
                            subject.isActive,
                      );

                      if (!subjectStillValid) {
                        _selectedSubjectId = widget.subjects
                            .where(
                              (subject) =>
                                  subject.programId == value &&
                                  subject.isActive,
                            )
                            .firstOrNull
                            ?.subjectId;
                      }

                      final topicStillValid = widget.topics.any(
                        (topic) =>
                            topic.subjectId == _selectedSubjectId &&
                            topic.topicId == _selectedTopicId &&
                            topic.isActive,
                      );

                      if (!topicStillValid) {
                        _selectedTopicId = widget.topics
                            .where(
                              (topic) =>
                                  topic.subjectId == _selectedSubjectId &&
                                  topic.isActive,
                            )
                            .firstOrNull
                            ?.topicId;
                      }
                    });
                  },
                ),

                const SizedBox(height: 8),

                DropdownButtonFormField<String>(
                  value: _selectedSubjectId,
                  decoration: const InputDecoration(
                    labelText: 'Subject',
                    border: OutlineInputBorder(),
                  ),
                  items: _filteredSubjects
                      .map(
                        (subject) => DropdownMenuItem<String>(
                          value: subject.subjectId,
                          child: Text(subject.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedSubjectId = value;

                      final topicStillValid = widget.topics.any(
                        (topic) =>
                            topic.subjectId == value &&
                            topic.topicId == _selectedTopicId &&
                            topic.isActive,
                      );

                      if (!topicStillValid) {
                        _selectedTopicId = widget.topics
                            .where(
                              (topic) =>
                                  topic.subjectId == value && topic.isActive,
                            )
                            .firstOrNull
                            ?.topicId;
                      }
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a subject.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 8),

                DropdownButtonFormField<String>(
                  value: _selectedTopicId,
                  decoration: const InputDecoration(
                    labelText: 'Topic',
                    border: OutlineInputBorder(),
                  ),
                  items: _filteredTopics
                      .map(
                        (topic) => DropdownMenuItem<String>(
                          value: topic.topicId,
                          child: Text(topic.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedTopicId = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a topic.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 8),

                DropdownButtonFormField<QuestionType>(
                  value: _selectedQuestionType,
                  decoration: const InputDecoration(
                    labelText: 'Question Type',
                    border: OutlineInputBorder(),
                  ),
                  items: QuestionType.values
                      .map(
                        (type) => DropdownMenuItem<QuestionType>(
                          value: type,
                          child: Text(_getQuestionTypeLabel(type)),
                        ),
                      )
                      .toList(),

                  // Question type cannot be
                  // changed while editing.
                  onChanged: null,
                ),

                const SizedBox(height: 8),

                DropdownButtonFormField<DifficultyLevel>(
                  value: _selectedDifficulty,
                  decoration: const InputDecoration(
                    labelText: 'Difficulty',
                    border: OutlineInputBorder(),
                  ),
                  items: DifficultyLevel.values
                      .map(
                        (difficulty) => DropdownMenuItem<DifficultyLevel>(
                          value: difficulty,
                          child: Text(_getDifficultyLabel(difficulty)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }

                    setState(() {
                      _selectedDifficulty = value;
                    });
                  },
                ),

                const SizedBox(height: 8),

                TextFormField(
                  controller: _questionDescriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Question',
                    hintText: 'Enter the question...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 5,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Question description can't be left empty.";
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 8),

                TextFormField(
                  controller: _marksController,
                  decoration: const InputDecoration(
                    labelText: 'Marks',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Marks can't be left empty.";
                    }

                    final marks = double.tryParse(value.trim());

                    if (marks == null) {
                      return "Please enter a valid number.";
                    }

                    if (marks <= 0) {
                      return "Marks should be more than 0.";
                    }

                    return null;
                  },
                ),

                if (_selectedQuestionType == QuestionType.multiple)
                  _buildMultipleChoiceSection(),

                if (_selectedQuestionType == QuestionType.trueFalse)
                  _buildTrueFalseSection(),

                if (_selectedQuestionType == QuestionType.written)
                  _buildWrittenSection(),
              ],
            ),
          ),
        ),
      ),

      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(false);
          },
          child: const Text('Cancel'),
        ),

        ElevatedButton(
          onPressed: _saveChanges,
          child: const Text('Save Changes'),
        ),
      ],
    );
  }
}
