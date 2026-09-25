import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:questionbank/models/learning_area.dart';
import 'package:questionbank/models/program.dart';
import 'package:questionbank/models/question.dart';
import 'package:questionbank/models/subject.dart';
import 'package:questionbank/models/topic.dart';
import 'package:questionbank/services/learning_area_service.dart';
import 'package:questionbank/services/program_service.dart';
import 'package:questionbank/services/question_service.dart';
import 'package:questionbank/services/subject_service.dart';
import 'package:questionbank/services/topic_service.dart';

class ExamineeEditQuestionScreen extends StatefulWidget {
  final Question question;

  const ExamineeEditQuestionScreen({
    super.key,
    required this.question,
  });

  @override
  State<ExamineeEditQuestionScreen> createState() =>
      _ExamineeEditQuestionScreenState();
}

class _ExamineeEditQuestionScreenState
    extends State<ExamineeEditQuestionScreen> {
  final LearningAreaService _learningAreaService =
  LearningAreaService();

  final ProgramService _programService =
  ProgramService();

  final SubjectService _subjectService =
  SubjectService();

  final TopicService _topicService =
  TopicService();

  final QuestionService _questionService =
  QuestionService();

  final TextEditingController _questionController =
  TextEditingController();

  final TextEditingController _marksController =
  TextEditingController();

  final TextEditingController _referenceAnswerController =
  TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  String? _errorMessage;

  List<LearningArea> _learningAreas = [];
  List<Program> _programs = [];
  List<Subject> _subjects = [];
  List<Topic> _topics = [];

  LearningArea? _selectedLearningArea;
  Program? _selectedProgram;
  Subject? _selectedSubject;
  Topic? _selectedTopic;

  QuestionType _questionType =
      QuestionType.multiple;

  DifficultyLevel _difficulty =
      DifficultyLevel.medium;

  final List<TextEditingController>
  _optionControllers = [];

  final Set<int> _correctOptionIndexes = {};

  AssessmentType _assessmentType =
      AssessmentType.manual;

  final List<_CriterionInput> _criteria = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _questionController.dispose();
    _marksController.dispose();
    _referenceAnswerController.dispose();

    for (final controller in _optionControllers) {
      controller.dispose();
    }

    for (final criterion in _criteria) {
      criterion.dispose();
    }

    super.dispose();
  }

  // ===========================================================================
  // INITIAL DATA
  // ===========================================================================

  Future<void> _loadData() async {
    if (widget.question.status != QuestionStatus.pending) {
      setState(() {
        _isLoading = false;
        _errorMessage =
        'Only pending questions can be edited.';
      });
      return;
    }

    try {
      final areas =
      await _learningAreaService.getAllLearningAreas();

      if (!mounted) return;

      final activeAreas = areas
          .where((area) => area.isActive)
          .toList()
        ..sort(
              (a, b) {
            final comparison =
            a.sortOrder.compareTo(b.sortOrder);

            if (comparison != 0) {
              return comparison;
            }

            return a.name
                .toLowerCase()
                .compareTo(
              b.name.toLowerCase(),
            );
          },
        );

      setState(() {
        _learningAreas = activeAreas;
      });

      final selectedArea = activeAreas
          .where(
            (area) =>
        area.learningAreaId ==
            widget.question.programId,
      )
          .firstOrNull;

      _questionController.text =
          widget.question.questionDescription;

      _marksController.text =
          widget.question.marks.toString();

      _questionType =
          widget.question.questionType;

      _difficulty =
          widget.question.difficulty;

      _loadQuestionSpecificData();

      // The question model stores programId rather than
      // learningAreaId, so find the learning area through
      // the program hierarchy.
      await _loadProgramHierarchy();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage =
        'Unable to load question data: $e';
      });
    }
  }

  Future<void> _loadProgramHierarchy() async {
    try {
      final allPrograms =
      await _programService.getAllPrograms();

      final matchingProgram = allPrograms
          .where(
            (program) =>
        program.programId ==
            widget.question.programId,
      )
          .firstOrNull;

      if (matchingProgram == null) {
        throw Exception(
          'The original program could not be found.',
        );
      }

      final matchingArea = _learningAreas
          .where(
            (area) =>
        area.learningAreaId ==
            matchingProgram.learningAreaId,
      )
          .firstOrNull;

      if (matchingArea == null) {
        throw Exception(
          'The original learning area could not be found.',
        );
      }

      final programs =
      await _programService
          .getProgramsByLearningArea(
        matchingArea.learningAreaId,
      );

      final activePrograms = programs
          .where((program) => program.isActive)
          .toList()
        ..sort(
              (a, b) {
            final comparison =
            a.sortOrder.compareTo(b.sortOrder);

            if (comparison != 0) {
              return comparison;
            }

            return a.name
                .toLowerCase()
                .compareTo(
              b.name.toLowerCase(),
            );
          },
        );

      if (!mounted) return;

      setState(() {
        _selectedLearningArea = matchingArea;
        _programs = activePrograms;
        _selectedProgram = activePrograms
            .where(
              (program) =>
          program.programId ==
              widget.question.programId,
        )
            .firstOrNull;
      });

      if (_selectedProgram == null) {
        throw Exception(
          'The original program is no longer available.',
        );
      }

      await _loadSubjects(
        _selectedProgram!.programId,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage =
        'Unable to load question hierarchy: $e';
      });
    }
  }

  Future<void> _loadSubjects(
      String programId,
      ) async {
    final subjects =
    await _subjectService.getSubjectsByProgram(
      programId,
    );

    final activeSubjects = subjects
        .where((subject) => subject.isActive)
        .toList()
      ..sort(
            (a, b) {
          final comparison =
          a.sortOrder.compareTo(b.sortOrder);

          if (comparison != 0) {
            return comparison;
          }

          return a.name
              .toLowerCase()
              .compareTo(
            b.name.toLowerCase(),
          );
        },
      );

    if (!mounted) return;

    setState(() {
      _subjects = activeSubjects;

      _selectedSubject = activeSubjects
          .where(
            (subject) =>
        subject.subjectId ==
            widget.question.subjectId,
      )
          .firstOrNull;
    });

    if (_selectedSubject == null) {
      throw Exception(
        'The original subject is no longer available.',
      );
    }

    await _loadTopics(
      _selectedSubject!.subjectId,
    );
  }

  Future<void> _loadTopics(
      String subjectId,
      ) async {
    final topics =
    await _topicService.getTopicsBySubject(
      subjectId,
    );

    final activeTopics = topics
        .where((topic) => topic.isActive)
        .toList()
      ..sort(
            (a, b) {
          final comparison =
          a.sortOrder.compareTo(b.sortOrder);

          if (comparison != 0) {
            return comparison;
          }

          return a.name
              .toLowerCase()
              .compareTo(
            b.name.toLowerCase(),
          );
        },
      );

    if (!mounted) return;

    setState(() {
      _topics = activeTopics;

      _selectedTopic = activeTopics
          .where(
            (topic) =>
        topic.topicId ==
            widget.question.topicId,
      )
          .firstOrNull;

      _isLoading = false;
    });

    if (_selectedTopic == null) {
      throw Exception(
        'The original topic is no longer available.',
      );
    }
  }

  void _loadQuestionSpecificData() {
    _optionControllers.clear();
    _correctOptionIndexes.clear();

    if (_questionType ==
        QuestionType.multiple) {
      for (var i = 0;
      i < widget.question.options.length;
      i++) {
        final option =
        widget.question.options[i];

        _optionControllers.add(
          TextEditingController(
            text: option.optionText,
          ),
        );

        if (widget.question.correctAnswers
            .contains(option.optionId)) {
          _correctOptionIndexes.add(i);
        }
      }

      while (_optionControllers.length < 2) {
        _optionControllers.add(
          TextEditingController(),
        );
      }
    }

    if (_questionType ==
        QuestionType.trueFalse) {
      _correctOptionIndexes.clear();

      final correctAnswer =
          widget.question.correctAnswers
              .firstOrNull;

      if (correctAnswer == 'true') {
        _correctOptionIndexes.add(0);
      } else if (correctAnswer == 'false') {
        _correctOptionIndexes.add(1);
      }
    }

    final writtenAssessment =
        widget.question.writtenAssessment;

    if (writtenAssessment != null) {
      _referenceAnswerController.text =
          writtenAssessment.referenceAnswer;

      _assessmentType =
          writtenAssessment.assessmentType;

      for (final criterion
      in writtenAssessment.criteria) {
        _criteria.add(
          _CriterionInput(
            criterion: criterion.criterion,
            marks: criterion.marks.toString(),
          ),
        );
      }
    }
  }

  // ===========================================================================
  // CASCADING DROPDOWNS
  // ===========================================================================

  Future<void> _onLearningAreaChanged(
      LearningArea? area,
      ) async {
    if (area == null) return;

    setState(() {
      _selectedLearningArea = area;
      _selectedProgram = null;
      _selectedSubject = null;
      _selectedTopic = null;
      _programs = [];
      _subjects = [];
      _topics = [];
    });

    try {
      final programs =
      await _programService
          .getProgramsByLearningArea(
        area.learningAreaId,
      );

      if (!mounted) return;

      final activePrograms = programs
          .where((program) => program.isActive)
          .toList()
        ..sort(
              (a, b) =>
              a.sortOrder.compareTo(b.sortOrder),
        );

      setState(() {
        _programs = activePrograms;
      });
    } catch (e) {
      if (!mounted) return;
      _showError('Unable to load programs: $e');
    }
  }

  Future<void> _onProgramChanged(
      Program? program,
      ) async {
    if (program == null) return;

    setState(() {
      _selectedProgram = program;
      _selectedSubject = null;
      _selectedTopic = null;
      _subjects = [];
      _topics = [];
    });

    try {
      final subjects =
      await _subjectService
          .getSubjectsByProgram(
        program.programId,
      );

      if (!mounted) return;

      final activeSubjects = subjects
          .where((subject) => subject.isActive)
          .toList()
        ..sort(
              (a, b) =>
              a.sortOrder.compareTo(b.sortOrder),
        );

      setState(() {
        _subjects = activeSubjects;
      });
    } catch (e) {
      if (!mounted) return;
      _showError('Unable to load subjects: $e');
    }
  }

  Future<void> _onSubjectChanged(
      Subject? subject,
      ) async {
    if (subject == null) return;

    setState(() {
      _selectedSubject = subject;
      _selectedTopic = null;
      _topics = [];
    });

    try {
      final topics =
      await _topicService.getTopicsBySubject(
        subject.subjectId,
      );

      if (!mounted) return;

      final activeTopics = topics
          .where((topic) => topic.isActive)
          .toList()
        ..sort(
              (a, b) =>
              a.sortOrder.compareTo(b.sortOrder),
        );

      setState(() {
        _topics = activeTopics;
      });
    } catch (e) {
      if (!mounted) return;
      _showError('Unable to load topics: $e');
    }
  }

  // ===========================================================================
  // OPTIONS
  // ===========================================================================

  void _addOption() {
    if (_optionControllers.length >= 6) {
      _showError(
        'A multiple-choice question can have at most 6 options.',
      );
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
      _showError(
        'A multiple-choice question must have at least 2 options.',
      );
      return;
    }

    final controller =
    _optionControllers[index];

    setState(() {
      _optionControllers.removeAt(index);

      final updated = <int>{};

      for (final correct
      in _correctOptionIndexes) {
        if (correct == index) continue;

        if (correct > index) {
          updated.add(correct - 1);
        } else {
          updated.add(correct);
        }
      }

      _correctOptionIndexes
        ..clear()
        ..addAll(updated);
    });

    controller.dispose();
  }

  void _toggleCorrectOption(int index) {
    setState(() {
      if (_correctOptionIndexes.contains(index)) {
        _correctOptionIndexes.remove(index);
      } else {
        _correctOptionIndexes.add(index);
      }
    });
  }

  // ===========================================================================
  // CRITERIA
  // ===========================================================================

  void _addCriterion() {
    setState(() {
      _criteria.add(
        _CriterionInput(),
      );
    });
  }

  void _removeCriterion(int index) {
    final criterion = _criteria[index];

    setState(() {
      _criteria.removeAt(index);
    });

    criterion.dispose();
  }

  // ===========================================================================
  // VALIDATION
  // ===========================================================================

  String? _validateForm() {
    if (_selectedLearningArea == null) {
      return 'Please select a learning area.';
    }

    if (_selectedProgram == null) {
      return 'Please select a program.';
    }

    if (_selectedSubject == null) {
      return 'Please select a subject.';
    }

    if (_selectedTopic == null) {
      return 'Please select a topic.';
    }

    if (_questionController.text.trim().isEmpty) {
      return 'Please enter the question.';
    }

    final marks =
    double.tryParse(
      _marksController.text.trim(),
    );

    if (marks == null || marks <= 0) {
      return 'Marks must be greater than 0.';
    }

    if (_questionType ==
        QuestionType.multiple) {
      if (_optionControllers.length < 2) {
        return 'Please provide at least 2 options.';
      }

      for (var i = 0;
      i < _optionControllers.length;
      i++) {
        if (_optionControllers[i]
            .text
            .trim()
            .isEmpty) {
          return 'Please enter text for option ${_optionLetter(i)}.';
        }
      }

      if (_correctOptionIndexes.isEmpty) {
        return 'Please select at least one correct answer.';
      }
    }

    if (_questionType ==
        QuestionType.trueFalse) {
      if (_correctOptionIndexes.isEmpty) {
        return 'Please select True or False.';
      }
    }

    if (_questionType ==
        QuestionType.written) {
      if (_referenceAnswerController
          .text
          .trim()
          .isEmpty) {
        return 'Please enter a reference answer.';
      }

      if (_assessmentType ==
          AssessmentType.manual ||
          _assessmentType ==
              AssessmentType.hybrid) {
        if (_criteria.isEmpty) {
          return 'Please add at least one assessment criterion.';
        }

        double totalMarks = 0;

        for (final criterion in _criteria) {
          if (criterion
              .criterionController
              .text
              .trim()
              .isEmpty) {
            return 'Please enter all assessment criteria.';
          }

          final criterionMarks =
          double.tryParse(
            criterion
                .marksController
                .text
                .trim(),
          );

          if (criterionMarks == null ||
              criterionMarks <= 0) {
            return 'Each assessment criterion must have valid marks.';
          }

          totalMarks += criterionMarks;
        }

        if (totalMarks > marks) {
          return 'Assessment criteria marks cannot exceed the question marks.';
        }
      }
    }

    return null;
  }

  // ===========================================================================
  // SAVE
  // ===========================================================================

  Future<void> _saveQuestion() async {
    FocusScope.of(context).unfocus();

    final validationError =
    _validateForm();

    if (validationError != null) {
      _showError(validationError);
      return;
    }

    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showError('You are not logged in.');
      return;
    }

    // Extra protection: the editor is only for
    // the original creator.
    if (widget.question.createdBy != user.uid) {
      _showError(
        'You are not allowed to edit this question.',
      );
      return;
    }

    if (widget.question.status !=
        QuestionStatus.pending) {
      _showError(
        'Only pending questions can be edited.',
      );
      return;
    }

    final marks =
    double.parse(
      _marksController.text.trim(),
    );

    final options = <QuestionOption>[];
    final correctAnswers = <String>[];

    if (_questionType ==
        QuestionType.multiple) {
      for (var i = 0;
      i < _optionControllers.length;
      i++) {
        final optionId =
            'option_${i + 1}';

        options.add(
          QuestionOption(
            optionId: optionId,
            optionText:
            _optionControllers[i]
                .text
                .trim(),
          ),
        );

        if (_correctOptionIndexes
            .contains(i)) {
          correctAnswers.add(optionId);
        }
      }
    }

    if (_questionType ==
        QuestionType.trueFalse) {
      options.add(
        const QuestionOption(
          optionId: 'true',
          optionText: 'True',
        ),
      );

      options.add(
        const QuestionOption(
          optionId: 'false',
          optionText: 'False',
        ),
      );

      if (_correctOptionIndexes
          .contains(0)) {
        correctAnswers.add('true');
      } else if (_correctOptionIndexes
          .contains(1)) {
        correctAnswers.add('false');
      }
    }

    WrittenAssessment?
    writtenAssessment;

    if (_questionType ==
        QuestionType.written) {
      final criteria =
      <AssessmentCriterion>[];

      for (var i = 0;
      i < _criteria.length;
      i++) {
        final criterion = _criteria[i];

        criteria.add(
          AssessmentCriterion(
            criterionId:
            'criterion_${i + 1}',
            criterion:
            criterion
                .criterionController
                .text
                .trim(),
            marks: double.parse(
              criterion
                  .marksController
                  .text
                  .trim(),
            ),
          ),
        );
      }

      writtenAssessment =
          WrittenAssessment(
            assessmentType:
            _assessmentType,
            referenceAnswer:
            _referenceAnswerController
                .text
                .trim(),
            criteria: criteria,
          );
    }

    final updatedQuestion =
    Question(
      questionId:
      widget.question.questionId,
      questionDescription:
      _questionController.text.trim(),
      programId:
      _selectedProgram!.programId,
      subjectId:
      _selectedSubject!.subjectId,
      topicId:
      _selectedTopic!.topicId,
      questionType:
      _questionType,
      difficulty:
      _difficulty,
      options: options,
      correctAnswers:
      correctAnswers,
      writtenAssessment:
      writtenAssessment,
      marks: marks,

      // Preserve creator.
      createdBy:
      widget.question.createdBy,

      // A modified question must remain pending.
      status:
      QuestionStatus.pending,

      // A pending question has no approval data.
      approvedBy: null,
      approvedAt: null,

      // Preserve original creation date.
      createdAt:
      widget.question.createdAt,

      updatedAt: DateTime.now(),
    );

    setState(() {
      _isSaving = true;
    });

    try {
      await _questionService.updateQuestion(
        updatedQuestion,
      );

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius:
              BorderRadius.circular(20),
            ),
            icon: Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: Colors.green
                    .withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Colors.green,
                size: 40,
              ),
            ),
            title: const Text(
              'Question Updated',
              textAlign: TextAlign.center,
            ),
            content: const Text(
              'Your question has been updated successfully and remains pending for review.',
              textAlign: TextAlign.center,
            ),
            actionsAlignment:
            MainAxisAlignment.center,
            actions: [
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                icon: const Icon(
                  Icons.check_rounded,
                ),
                label: const Text('Done'),
              ),
            ],
          );
        },
      );

      if (!mounted) return;

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      _showError(
        'Unable to update question: $e',
      );
    }
  }

  // ===========================================================================
  // UI HELPERS
  // ===========================================================================

  String _optionLetter(int index) {
    const letters = [
      'A',
      'B',
      'C',
      'D',
      'E',
      'F',
    ];

    return index >= 0 &&
        index < letters.length
        ? letters[index]
        : '?';
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        behavior:
        SnackBarBehavior.floating,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: colorScheme.primary
          .withValues(alpha: 0.035),
      border: OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(14),
        borderSide: BorderSide(
          color: Colors.grey.shade300,
        ),
      ),
      enabledBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(14),
        borderSide: BorderSide(
          color: Colors.grey.shade300,
        ),
      ),
      focusedBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(14),
        borderSide: BorderSide(
          color: colorScheme.primary,
          width: 1.5,
        ),
      ),
    );
  }

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colorScheme
                      .primary
                      .withValues(alpha: 0.09),
                  borderRadius:
                  BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color:
                  colorScheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style:
                      const TextStyle(
                        fontSize: 17,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors
                            .grey
                            .shade600,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _dropdown<T>({
    required String label,
    required IconData icon,
    required T? value,
    required List<
        DropdownMenuItem<T>>
    items,
    required ValueChanged<T?>?
    onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: true,
      decoration: _inputDecoration(
        label: label,
        icon: icon,
      ),
      items: items,
      onChanged: onChanged,
    );
  }

  // ===========================================================================
  // HIERARCHY
  // ===========================================================================

  Widget _buildHierarchy() {
    return _sectionCard(
      icon: Icons.account_tree_rounded,
      title: 'Question Category',
      subtitle:
      'Select where this question belongs.',
      child: Column(
        children: [
          _dropdown<LearningArea>(
            label: 'Learning Area',
            icon:
            Icons.auto_stories_rounded,
            value:
            _selectedLearningArea,
            items: _learningAreas
                .map(
                  (area) =>
                  DropdownMenuItem<
                      LearningArea>(
                    value: area,
                    child: Text(
                      area.name,
                      overflow:
                      TextOverflow
                          .ellipsis,
                    ),
                  ),
            )
                .toList(),
            onChanged:
            _onLearningAreaChanged,
          ),
          const SizedBox(height: 14),
          _dropdown<Program>(
            label: 'Program',
            icon:
            Icons.account_tree_rounded,
            value: _selectedProgram,
            items: _programs
                .map(
                  (program) =>
                  DropdownMenuItem<
                      Program>(
                    value: program,
                    child: Text(
                      program.name,
                      overflow:
                      TextOverflow
                          .ellipsis,
                    ),
                  ),
            )
                .toList(),
            onChanged:
            _selectedLearningArea ==
                null
                ? null
                : _onProgramChanged,
          ),
          const SizedBox(height: 14),
          _dropdown<Subject>(
            label: 'Subject',
            icon:
            Icons.menu_book_rounded,
            value: _selectedSubject,
            items: _subjects
                .map(
                  (subject) =>
                  DropdownMenuItem<
                      Subject>(
                    value: subject,
                    child: Text(
                      subject.name,
                      overflow:
                      TextOverflow
                          .ellipsis,
                    ),
                  ),
            )
                .toList(),
            onChanged:
            _selectedProgram ==
                null
                ? null
                : _onSubjectChanged,
          ),
          const SizedBox(height: 14),
          _dropdown<Topic>(
            label: 'Topic',
            icon:
            Icons.topic_rounded,
            value: _selectedTopic,
            items: _topics
                .map(
                  (topic) =>
                  DropdownMenuItem<Topic>(
                    value: topic,
                    child: Text(
                      topic.name,
                      overflow:
                      TextOverflow
                          .ellipsis,
                    ),
                  ),
            )
                .toList(),
            onChanged:
            _selectedSubject ==
                null
                ? null
                : (value) {
              setState(() {
                _selectedTopic =
                    value;
              });
            },
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SETTINGS
  // ===========================================================================

  Widget _buildSettings() {
    return _sectionCard(
      icon: Icons.tune_rounded,
      title: 'Question Settings',
      subtitle:
      'Choose the question type, difficulty and marks.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide =
              constraints.maxWidth >= 650;

          final type = _dropdown<
              QuestionType>(
            label: 'Question Type',
            icon: Icons.quiz_rounded,
            value: _questionType,
            items: const [
              DropdownMenuItem(
                value:
                QuestionType.multiple,
                child: Text(
                  'Multiple Choice',
                ),
              ),
              DropdownMenuItem(
                value:
                QuestionType.trueFalse,
                child: Text(
                  'True / False',
                ),
              ),
              DropdownMenuItem(
                value:
                QuestionType.written,
                child: Text(
                  'Written',
                ),
              ),
            ],
            onChanged: (value) {
              if (value == null) return;

              setState(() {
                _questionType = value;
                _correctOptionIndexes
                    .clear();
              });
            },
          );

          final difficulty =
          _dropdown<
              DifficultyLevel>(
            label: 'Difficulty',
            icon: Icons.speed_rounded,
            value: _difficulty,
            items: const [
              DropdownMenuItem(
                value:
                DifficultyLevel.easy,
                child: Text('Easy'),
              ),
              DropdownMenuItem(
                value:
                DifficultyLevel.medium,
                child: Text('Medium'),
              ),
              DropdownMenuItem(
                value:
                DifficultyLevel.hard,
                child: Text('Hard'),
              ),
            ],
            onChanged: (value) {
              if (value == null) return;

              setState(() {
                _difficulty = value;
              });
            },
          );

          final marks =
          TextFormField(
            controller:
            _marksController,
            keyboardType:
            const TextInputType
                .numberWithOptions(
              decimal: true,
            ),
            decoration:
            _inputDecoration(
              label: 'Marks',
              icon: Icons
                  .star_outline_rounded,
            ),
          );

          if (wide) {
            return Row(
              children: [
                Expanded(
                  child: type,
                ),
                const SizedBox(
                  width: 12,
                ),
                Expanded(
                  child: difficulty,
                ),
                const SizedBox(
                  width: 12,
                ),
                SizedBox(
                  width: 150,
                  child: marks,
                ),
              ],
            );
          }

          return Column(
            children: [
              type,
              const SizedBox(height: 14),
              difficulty,
              const SizedBox(height: 14),
              marks,
            ],
          );
        },
      ),
    );
  }

  // ===========================================================================
  // QUESTION
  // ===========================================================================

  Widget _buildQuestion() {
    return _sectionCard(
      icon: Icons.edit_note_rounded,
      title: 'Question',
      subtitle:
      'Edit your question text.',
      child: TextFormField(
        controller:
        _questionController,
        maxLines: 6,
        minLines: 4,
        decoration:
        _inputDecoration(
          label: 'Question text',
          icon:
          Icons.help_outline_rounded,
          hint:
          'Enter your question here...',
        ),
      ),
    );
  }

  // ===========================================================================
  // MULTIPLE CHOICE
  // ===========================================================================

  Widget _buildMultipleChoice() {
    return _sectionCard(
      icon: Icons.checklist_rounded,
      title: 'Answer Options',
      subtitle:
      'Edit the options and correct answers.',
      child: Column(
        children: [
          ...List.generate(
            _optionControllers.length,
                (index) =>
                _buildOptionRow(index),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed:
                _optionControllers
                    .length >=
                    6
                    ? null
                    : _addOption,
                icon: const Icon(
                  Icons.add_rounded,
                ),
                label:
                const Text(
                  'Add Option',
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${_optionControllers.length}/6 options',
                style: TextStyle(
                  color:
                  Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOptionRow(int index) {
    final colorScheme =
        Theme.of(context)
            .colorScheme;

    final isCorrect =
    _correctOptionIndexes
        .contains(index);

    return Container(
      margin:
      const EdgeInsets.only(
        bottom: 12,
      ),
      decoration: BoxDecoration(
        color: isCorrect
            ? colorScheme.primary
            .withValues(
            alpha: 0.055)
            : Colors.grey.shade50,
        borderRadius:
        BorderRadius.circular(
          15,
        ),
        border: Border.all(
          color: isCorrect
              ? colorScheme.primary
              .withValues(
              alpha: 0.35)
              : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Checkbox(
            value: isCorrect,
            onChanged: (_) =>
                _toggleCorrectOption(
                  index,
                ),
          ),
          Container(
            width: 34,
            height: 34,
            alignment:
            Alignment.center,
            decoration:
            BoxDecoration(
              color: isCorrect
                  ? colorScheme
                  .primary
                  : Colors.grey.shade200,
              borderRadius:
              BorderRadius.circular(
                10,
              ),
            ),
            child: Text(
              _optionLetter(index),
              style: TextStyle(
                color: isCorrect
                    ? Colors.white
                    : Colors.grey.shade700,
                fontWeight:
                FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller:
              _optionControllers[
              index],
              decoration:
              const InputDecoration(
                hintText:
                'Enter option text',
                border:
                InputBorder.none,
              ),
            ),
          ),
          IconButton(
            tooltip:
            'Remove option',
            onPressed:
            _optionControllers
                .length <=
                2
                ? null
                : () =>
                _removeOption(
                  index,
                ),
            icon: const Icon(
              Icons.close_rounded,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TRUE / FALSE
  // ===========================================================================

  Widget _buildTrueFalse() {
    return _sectionCard(
      icon: Icons.rule_rounded,
      title: 'Correct Answer',
      subtitle:
      'Select the correct answer.',
      child: Row(
        children: [
          Expanded(
            child:
            _trueFalseChoice(
              value: 0,
              label: 'True',
              icon: Icons
                  .check_circle_outline_rounded,
              color: Colors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child:
            _trueFalseChoice(
              value: 1,
              label: 'False',
              icon: Icons
                  .cancel_outlined,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _trueFalseChoice({
    required int value,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final selected =
    _correctOptionIndexes
        .contains(value);

    return InkWell(
      borderRadius:
      BorderRadius.circular(
        15,
      ),
      onTap: () {
        setState(() {
          _correctOptionIndexes
            ..clear()
            ..add(value);
        });
      },
      child: Container(
        padding:
        const EdgeInsets.all(
          14,
        ),
        decoration:
        BoxDecoration(
          color: selected
              ? color.withValues(
              alpha: 0.08)
              : Colors.grey.shade50,
          borderRadius:
          BorderRadius.circular(
            15,
          ),
          border: Border.all(
            color: selected
                ? color.withValues(
                alpha: 0.45)
                : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Radio<int>(
              value: value,
              groupValue:
              _correctOptionIndexes
                  .isEmpty
                  ? null
                  : _correctOptionIndexes
                  .first,
              onChanged: (_) {
                setState(() {
                  _correctOptionIndexes
                    ..clear()
                    ..add(value);
                });
              },
            ),
            Icon(
              icon,
              color: color,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style:
              const TextStyle(
                fontWeight:
                FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // WRITTEN
  // ===========================================================================

  Widget _buildWritten() {
    return _sectionCard(
      icon: Icons.draw_rounded,
      title: 'Written Assessment',
      subtitle:
      'Edit the reference answer and assessment method.',
      child: Column(
        children: [
          TextFormField(
            controller:
            _referenceAnswerController,
            maxLines: 6,
            minLines: 4,
            decoration:
            _inputDecoration(
              label:
              'Reference Answer',
              icon: Icons
                  .menu_book_outlined,
            ),
          ),
          const SizedBox(height: 18),
          _dropdown<AssessmentType>(
            label:
            'Assessment Type',
            icon:
            Icons.fact_check_outlined,
            value:
            _assessmentType,
            items: const [
              DropdownMenuItem(
                value:
                AssessmentType.automatic,
                child:
                Text('Automatic'),
              ),
              DropdownMenuItem(
                value:
                AssessmentType.manual,
                child:
                Text('Manual'),
              ),
              DropdownMenuItem(
                value:
                AssessmentType.hybrid,
                child:
                Text('Hybrid'),
              ),
            ],
            onChanged: (value) {
              if (value == null) return;

              setState(() {
                _assessmentType =
                    value;
              });
            },
          ),
          if (_assessmentType !=
              AssessmentType.automatic) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Assessment Criteria',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed:
                  _addCriterion,
                  icon: const Icon(
                    Icons.add_rounded,
                  ),
                  label: const Text(
                    'Add Criterion',
                  ),
                ),
              ],
            ),
            ...List.generate(
              _criteria.length,
                  (index) =>
                  _buildCriterionRow(
                    index,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCriterionRow(
      int index,
      ) {
    final criterion =
    _criteria[index];

    return Container(
      margin:
      const EdgeInsets.only(
        top: 10,
      ),
      padding:
      const EdgeInsets.all(13),
      decoration:
      BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius:
        BorderRadius.circular(
          15,
        ),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: LayoutBuilder(
        builder:
            (context, constraints) {
          final wide =
              constraints.maxWidth >=
                  600;

          final criterionField =
          TextField(
            controller: criterion
                .criterionController,
            maxLines: 2,
            decoration:
            _inputDecoration(
              label:
              'Criterion ${index + 1}',
              icon: Icons
                  .checklist_outlined,
            ),
          );

          final marksField =
          TextField(
            controller:
            criterion
                .marksController,
            keyboardType:
            const TextInputType
                .numberWithOptions(
              decimal: true,
            ),
            decoration:
            _inputDecoration(
              label: 'Marks',
              icon: Icons
                  .star_outline_rounded,
            ),
          );

          final remove =
          IconButton(
            onPressed: () =>
                _removeCriterion(
                  index,
                ),
            icon: const Icon(
              Icons
                  .delete_outline_rounded,
            ),
          );

          if (wide) {
            return Row(
              children: [
                Expanded(
                  child:
                  criterionField,
                ),
                const SizedBox(
                  width: 12,
                ),
                SizedBox(
                  width: 150,
                  child: marksField,
                ),
                remove,
              ],
            );
          }

          return Column(
            children: [
              criterionField,
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child:
                    marksField,
                  ),
                  remove,
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor:
        Colors.white,
        surfaceTintColor:
        Colors.transparent,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () =>
              Navigator.of(context)
                  .pop(),
          icon: const Icon(
            Icons.arrow_back_rounded,
          ),
        ),
        title: const Text(
          'Edit Pending Question',
        ),
      ),
      body: _isLoading
          ? const Center(
        child:
        CircularProgressIndicator(),
      )
          : _errorMessage != null
          ? Center(
        child: Padding(
          padding:
          const EdgeInsets.all(
            30,
          ),
          child: Column(
            mainAxisSize:
            MainAxisSize.min,
            children: [
              Icon(
                Icons
                    .error_outline_rounded,
                size: 55,
                color: Colors
                    .red
                    .shade300,
              ),
              const SizedBox(
                height: 15,
              ),
              Text(
                _errorMessage!,
                textAlign:
                TextAlign.center,
                style:
                const TextStyle(
                  fontSize: 16,
                ),
              ),
              const SizedBox(
                height: 18,
              ),
              FilledButton.icon(
                onPressed: () =>
                    Navigator.of(
                      context,
                    ).pop(),
                icon: const Icon(
                  Icons
                      .arrow_back_rounded,
                ),
                label:
                const Text(
                  'Go Back',
                ),
              ),
            ],
          ),
        ),
      )
          : SafeArea(
        child:
        SingleChildScrollView(
          padding:
          const EdgeInsets
              .fromLTRB(
            20,
            20,
            20,
            35,
          ),
          child: Center(
            child:
            ConstrainedBox(
              constraints:
              const BoxConstraints(
                maxWidth: 1000,
              ),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment
                    .start,
                children: [
                  Container(
                    width: double
                        .infinity,
                    padding:
                    const EdgeInsets
                        .all(
                      20,
                    ),
                    decoration:
                    BoxDecoration(
                      color: Colors
                          .orange
                          .withValues(
                        alpha: 0.07,
                      ),
                      borderRadius:
                      BorderRadius
                          .circular(
                        18,
                      ),
                      border:
                      Border.all(
                        color: Colors
                            .orange
                            .withValues(
                          alpha: 0.20,
                        ),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                      children: [
                        Icon(
                          Icons
                              .info_outline_rounded,
                          color: Colors
                              .orange
                              .shade800,
                        ),
                        const SizedBox(
                          width: 12,
                        ),
                        const Expanded(
                          child: Text(
                            'This question is currently pending review. '
                                'After editing, it will remain pending and will need to be reviewed again.',
                            style:
                            TextStyle(
                              fontSize:
                              13,
                              height:
                              1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(
                    height: 18,
                  ),

                  _buildHierarchy(),

                  const SizedBox(
                    height: 18,
                  ),

                  _buildSettings(),

                  const SizedBox(
                    height: 18,
                  ),

                  _buildQuestion(),

                  const SizedBox(
                    height: 18,
                  ),

                  if (_questionType ==
                      QuestionType
                          .multiple)
                    _buildMultipleChoice(),

                  if (_questionType ==
                      QuestionType
                          .trueFalse)
                    _buildTrueFalse(),

                  if (_questionType ==
                      QuestionType
                          .written)
                    _buildWritten(),

                  const SizedBox(
                    height: 24,
                  ),

                  SizedBox(
                    width: double
                        .infinity,
                    height: 52,
                    child:
                    FilledButton
                        .icon(
                      onPressed:
                      _isSaving
                          ? null
                          : _saveQuestion,
                      icon: _isSaving
                          ? const SizedBox(
                        width:
                        20,
                        height:
                        20,
                        child:
                        CircularProgressIndicator(
                          strokeWidth:
                          2.2,
                          color:
                          Colors.white,
                        ),
                      )
                          : const Icon(
                        Icons
                            .save_rounded,
                      ),
                      label: Text(
                        _isSaving
                            ? 'Saving...'
                            : 'Save Changes',
                        style:
                        const TextStyle(
                          fontSize:
                          15,
                          fontWeight:
                          FontWeight.w600,
                        ),
                      ),
                      style: FilledButton
                          .styleFrom(
                        shape:
                        RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius
                              .circular(
                            15,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// CRITERION INPUT
// =============================================================================

class _CriterionInput {
  final TextEditingController
  criterionController;

  final TextEditingController
  marksController;

  _CriterionInput({
    String criterion = '',
    String marks = '1',
  })  : criterionController =
  TextEditingController(
    text: criterion,
  ),
        marksController =
        TextEditingController(
          text: marks,
        );

  void dispose() {
    criterionController.dispose();
    marksController.dispose();
  }
}