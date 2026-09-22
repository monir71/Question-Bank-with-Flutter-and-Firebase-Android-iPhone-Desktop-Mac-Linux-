import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:questionbank/models/program.dart';
import 'package:questionbank/models/subject.dart';
import 'package:questionbank/models/topic.dart';

import '../../models/question.dart';
import '../../services/question_service.dart';

class AddQuestionDialog extends StatefulWidget {
  final List<Program> programs;
  final List<Subject> subjects;
  final List<Topic> topics;

  const AddQuestionDialog({
    super.key,
    required this.programs,
    required this.subjects,
    required this.topics,
  });

  @override
  State<AddQuestionDialog> createState() =>
      _AddQuestionDialogState();
}

class _AddQuestionDialogState
    extends State<AddQuestionDialog> {
  String? _selectedProgramId;
  String? _selectedSubjectId;
  String? _selectedTopicId;

  QuestionType _selectedQuestionType =
      QuestionType.multiple;

  DifficultyLevel _selectedDifficulty =
      DifficultyLevel.medium;

  final TextEditingController _marksController =
  TextEditingController();
  final TextEditingController _questionDescriptionController =
  TextEditingController();

  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];

  final Set<int> _correctOptionIndexes = {};

  bool? _trueFalseAnswer;

  final TextEditingController _referenceAnswerController =
  TextEditingController();
  AssessmentType _selectedAssessmentType =
      AssessmentType.manual;

  final List<TextEditingController> _criterionControllers = [];
  final List<TextEditingController> _criterionMarkControllers = [];

  final _formKey = GlobalKey<FormState>();

  final QuestionService _questionService =
  QuestionService();

  @override
  void dispose() {
    _marksController.dispose();
    _questionDescriptionController.dispose();
    _referenceAnswerController.dispose();

    for (final controller in _optionControllers) {
      controller.dispose();
    }

    for (final controller in _criterionControllers) {
      controller.dispose();
    }

    for (final controller in _criterionMarkControllers) {
      controller.dispose();
    }

    super.dispose();
  }

  void _addCriterion() {
    setState(() {
      _criterionControllers.add(
        TextEditingController(),
      );

      _criterionMarkControllers.add(
        TextEditingController(),
      );
    });
  }

  void _removeCriterion(int index) {
    if (_criterionControllers.isEmpty) {
      return;
    }

    setState(() {
      _criterionControllers[index].dispose();
      _criterionMarkControllers[index].dispose();

      _criterionControllers.removeAt(index);
      _criterionMarkControllers.removeAt(index);
    });
  }

  String _getAssessmentTypeLabel(
      AssessmentType type,
      ) {
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
      _optionControllers.add(
        TextEditingController(),
      );
    });
  }

  void _removeOption(int index) {
    if (_optionControllers.length <= 2) {
      return;
    }

    setState(() {
      _optionControllers[index].dispose();
      _optionControllers.removeAt(index);

      final updatedCorrectIndexes =
      <int>{};

      for (final correctIndex
      in _correctOptionIndexes) {
        if (correctIndex == index) {
          continue;
        }

        if (correctIndex > index) {
          updatedCorrectIndexes.add(
            correctIndex - 1,
          );
        } else {
          updatedCorrectIndexes.add(
            correctIndex,
          );
        }
      }

      _correctOptionIndexes
        ..clear()
        ..addAll(
          updatedCorrectIndexes,
        );
    });
  }

  List<Subject> get _filteredSubjects {
    if (_selectedProgramId == null) {
      return [];
    }

    return widget.subjects
        .where(
          (subject) =>
      subject.programId ==
          _selectedProgramId &&
          subject.isActive,
    )
        .toList();
  }

  List<Topic> get _filteredTopics {
    if (_selectedSubjectId == null) {
      return [];
    }

    return widget.topics
        .where(
          (topic) =>
      topic.subjectId ==
          _selectedSubjectId &&
          topic.isActive,
    )
        .toList();
  }

  String _getQuestionTypeLabel(
      QuestionType type,
      ) {
    switch (type) {
      case QuestionType.multiple:
        return 'Multiple Choice';

      case QuestionType.trueFalse:
        return 'True / False';

      case QuestionType.written:
        return 'Written';
    }
  }

  String _getDifficultyLabel(
      DifficultyLevel difficulty,
      ) {
    switch (difficulty) {
      case DifficultyLevel.easy:
        return 'Easy';

      case DifficultyLevel.medium:
        return 'Medium';

      case DifficultyLevel.hard:
        return 'Hard';
    }
  }

  bool _validateTrueFalse() {
    return _trueFalseAnswer != null;
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

      final questionMarks = double.tryParse(
        _marksController.text.trim(),
      );

      if (questionMarks == null) {
        return false;
      }

      final totalCriterionMarks =
      _criterionMarkControllers.fold<double>(
        0,
            (total, controller) {
          return total +
              (double.tryParse(controller.text.trim()) ?? 0);
        },
      );

      if (totalCriterionMarks != questionMarks) {
        return false;
      }
    }

    return true;
  }

  Question _buildQuestion() {
    final questionId = FirebaseFirestore.instance
        .collection('questions')
        .doc()
        .id;

    final options = <QuestionOption>[];
    final correctAnswers = <String>[];

    if (_selectedQuestionType == QuestionType.multiple) {
      for (int i = 0; i < _optionControllers.length; i++) {
        final optionId = FirebaseFirestore.instance
            .collection('questions')
            .doc()
            .id;

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
        const QuestionOption(
          optionId: trueOptionId,
          optionText: 'True',
        ),
      );

      options.add(
        const QuestionOption(
          optionId: falseOptionId,
          optionText: 'False',
        ),
      );

      correctAnswers.add(
        _trueFalseAnswer == true
            ? trueOptionId
            : falseOptionId,
      );
    }

    WrittenAssessment? writtenAssessment;

    if (_selectedQuestionType == QuestionType.written) {
      final criteria = <AssessmentCriterion>[];

      for (int i = 0; i < _criterionControllers.length; i++) {
        final criterionId = FirebaseFirestore.instance
            .collection('questions')
            .doc()
            .id;

        criteria.add(
          AssessmentCriterion(
            criterionId: criterionId,
            criterion: _criterionControllers[i].text.trim(),
            marks: double.parse(
              _criterionMarkControllers[i].text.trim(),
            ),
          ),
        );
      }

      writtenAssessment = WrittenAssessment(
        assessmentType: _selectedAssessmentType,
        referenceAnswer:
        _referenceAnswerController.text.trim(),
        criteria: criteria,
      );
    }

    return Question(
      questionId: questionId,
      questionDescription:
      _questionDescriptionController.text.trim(),
      programId: _selectedProgramId!,
      subjectId: _selectedSubjectId!,
      topicId: _selectedTopicId!,
      questionType: _selectedQuestionType,
      difficulty: _selectedDifficulty,
      options: options,
      correctAnswers: correctAnswers,
      writtenAssessment: writtenAssessment,
      marks: double.parse(
        _marksController.text.trim(),
      ),
      createdBy: FirebaseAuth.instance.currentUser!.uid,
      status: QuestionStatus.approved,
      approvedBy: null,
      approvedAt: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Add Question',
      ),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a program.';
                    }

                    return null;
                  },
                  decoration: const InputDecoration(
                    labelText: 'Program',
                    border: OutlineInputBorder(),
                  ),
                  items: widget.programs
                      .where(
                        (program) => program.isActive,
                  )
                      .map(
                        (program) =>
                        DropdownMenuItem<String>(
                          value: program.programId,
                          child: Text(
                            program.name,
                          ),
                        ),
                  )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedProgramId = value;
                      _selectedSubjectId = null;
                      _selectedTopicId = null;
                    });
                  },
                ),
            
                const SizedBox(height: 16),
            
                DropdownButtonFormField<String>(
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a subject.';
                    }

                    return null;
                  },
                  decoration: const InputDecoration(
                    labelText: 'Subject',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedSubjectId,
                  items: _filteredSubjects
                      .map(
                        (subject) =>
                        DropdownMenuItem<String>(
                          value: subject.subjectId,
                          child: Text(
                            subject.name,
                          ),
                        ),
                  )
                      .toList(),
                  onChanged:
                  _selectedProgramId == null
                      ? null
                      : (value) {
                    setState(() {
                      _selectedSubjectId =
                          value;
                      _selectedTopicId =
                      null;
                    });
                  },
                ),
            
                const SizedBox(height: 16),
            
                DropdownButtonFormField<String>(
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a topic.';
                    }

                    return null;
                  },
                  decoration: const InputDecoration(
                    labelText: 'Topic',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedTopicId,
                  items: _filteredTopics
                      .map(
                        (topic) =>
                        DropdownMenuItem<String>(
                          value: topic.topicId,
                          child: Text(
                            topic.name,
                          ),
                        ),
                  )
                      .toList(),
                  onChanged:
                  _selectedSubjectId == null
                      ? null
                      : (value) {
                    setState(() {
                      _selectedTopicId =
                          value;
                    });
                  },
                ),
            
                const SizedBox(height: 16),
            
                TextFormField(
                  controller: _questionDescriptionController,
                  maxLines: 5,
                  validator: (value) {
                    if(value == null || value.trim().isEmpty) {
                      return "Question description can't be left empty.";
                    }
                    return null;
                  },
                  decoration: const InputDecoration(
                    labelText: 'Question',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                    hintText: 'Enter the question...',
                  ),
                ),
            
                const SizedBox(height: 16),
            
                DropdownButtonFormField<QuestionType>(
                  decoration: const InputDecoration(
                    labelText: 'Question Type',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedQuestionType,
                  items: QuestionType.values.map(
                        (type) {
                      return DropdownMenuItem<QuestionType>(
                        value: type,
                        child: Text(
                          _getQuestionTypeLabel(type),
                        ),
                      );
                    },
                  ).toList(),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
            
                    setState(() {
                      _selectedQuestionType = value;
            
                      _trueFalseAnswer = null;
                      _correctOptionIndexes.clear();
                    });
                  },
                ),
            
                const SizedBox(height: 16),
            
                DropdownButtonFormField<DifficultyLevel>(
                  decoration: const InputDecoration(
                    labelText: 'Difficulty',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedDifficulty,
                  items: DifficultyLevel.values.map(
                        (difficulty) {
                      return DropdownMenuItem<DifficultyLevel>(
                        value: difficulty,
                        child: Text(
                          _getDifficultyLabel(difficulty),
                        ),
                      );
                    },
                  ).toList(),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
            
                    setState(() {
                      _selectedDifficulty = value;
                    });
                  },
                ),
            
                const SizedBox(height: 16),
            
                TextFormField(
                  controller: _marksController,
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
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Marks',
                    border: OutlineInputBorder(),
                  ),
                ),
            
                if (_selectedQuestionType ==
                    QuestionType.multiple) ...[
                  const SizedBox(height: 20),
            
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Options',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium,
                    ),
                  ),
            
                  const SizedBox(height: 12),
            
                  ...List.generate(
                    _optionControllers.length,
                        (index) {
                      return Padding(
                        padding: const EdgeInsets.only(
                          bottom: 12,
                        ),
                        child: Row(
                          children: [
                            Checkbox(
                              value: _correctOptionIndexes
                                  .contains(index),
                              onChanged: (value) {
                                setState(() {
                                  if (value == true) {
                                    _correctOptionIndexes
                                        .add(index);
                                  } else {
                                    _correctOptionIndexes
                                        .remove(index);
                                  }
                                });
                              },
                            ),
            
                            Expanded(
                              child: TextFormField(
                                controller:
                                _optionControllers[index],
                                decoration: InputDecoration(
                                  labelText:
                                  'Option ${String.fromCharCode(65 + index)}',
                                  border:
                                  const OutlineInputBorder(),
                                ),
                              ),
                            ),
            
                            IconButton(
                              tooltip: 'Remove option',
                              icon: const Icon(
                                Icons.delete_outline,
                              ),
                              onPressed:
                              _optionControllers.length <= 2
                                  ? null
                                  : () {
                                _removeOption(index);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
            
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed:
                      _optionControllers.length >= 6
                          ? null
                          : _addOption,
                      icon: const Icon(
                        Icons.add,
                      ),
                      label: const Text(
                        'Add Option',
                      ),
                    ),
                  ),
                ],
            
                if (_selectedQuestionType ==
                    QuestionType.trueFalse) ...[
                  const SizedBox(height: 20),
            
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Correct Answer',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium,
                    ),
                  ),
            
                  const SizedBox(height: 8),
            
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
            
                if (_selectedQuestionType ==
                    QuestionType.written) ...[
                  const SizedBox(height: 20),
            
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Reference Answer',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium,
                    ),
                  ),
            
                  const SizedBox(height: 8),
            
                  TextFormField(
                    controller: _referenceAnswerController,
                    maxLines: 8,
                    decoration: const InputDecoration(
                      labelText: 'Reference Answer',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                      hintText:
                      'Enter the reference or model answer...',
                    ),
                  ),
                ],
            
                const SizedBox(height: 16),
            
                DropdownButtonFormField<AssessmentType>(
                  decoration: const InputDecoration(
                    labelText: 'Assessment Type',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedAssessmentType,
                  items: AssessmentType.values.map(
                        (type) {
                      return DropdownMenuItem<AssessmentType>(
                        value: type,
                        child: Text(
                          _getAssessmentTypeLabel(type),
                        ),
                      );
                    },
                  ).toList(),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
            
                    setState(() {
                      _selectedAssessmentType = value;
                    });
                  },
                ),
            
                const SizedBox(height: 20),
            
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Assessment Criteria',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium,
                  ),
                ),
            
                const SizedBox(height: 8),
            
                ...List.generate(
                  _criterionControllers.length,
                      (index) {
                    return Padding(
                      padding: const EdgeInsets.only(
                        bottom: 12,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller:
                              _criterionControllers[index],
                              decoration: const InputDecoration(
                                labelText: 'Criterion',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
            
                          const SizedBox(width: 12),
            
                          SizedBox(
                            width: 100,
                            child: TextFormField(
                              controller:
                              _criterionMarkControllers[index],
                              keyboardType:
                              const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              decoration:
                              const InputDecoration(
                                labelText: 'Marks',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
            
                          IconButton(
                            tooltip: 'Remove criterion',
                            icon: const Icon(
                              Icons.delete_outline,
                            ),
                            onPressed: () {
                              _removeCriterion(index);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
            
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _addCriterion,
                    icon: const Icon(
                      Icons.add,
                    ),
                    label: const Text(
                      'Add Criterion',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: () async {
            if (!_formKey.currentState!.validate()) {
              return;
            }

            if (_selectedQuestionType == QuestionType.multiple) {
              final isValid = _validateMultipleChoice();

              if (!isValid) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Please enter all options and select at least one correct answer.',
                    ),
                  ),
                );

                return;
              }
            }

            if (_selectedQuestionType == QuestionType.trueFalse) {
              final isValid = _validateTrueFalse();

              if (!isValid) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Please select True or False.',
                    ),
                  ),
                );

                return;
              }
            }

            if (_selectedQuestionType == QuestionType.written) {
              final isValid = _validateWrittenQuestion();

              if (!isValid) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Please complete the written assessment details correctly.',
                    ),
                  ),
                );

                return;
              }
            }

            final question = _buildQuestion();

            try {
              await _questionService.createAdminQuestion(
                question,
              );

              if (!mounted) {
                return;
              }

              Navigator.of(context).pop(true);
            } catch (e) {
              if (!mounted) {
                return;
              }

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Failed to save question: $e',
                  ),
                ),
              );
            }
          },
          icon: const Icon(Icons.save),
          label: const Text('Save Question'),
        ),
      ],
    );
  }
}