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

class ExamineeAddQuestionScreen extends StatefulWidget {
  const ExamineeAddQuestionScreen({super.key});

  @override
  State<ExamineeAddQuestionScreen> createState() =>
      _ExamineeAddQuestionScreenState();
}

class _ExamineeAddQuestionScreenState
    extends State<ExamineeAddQuestionScreen> {
  final LearningAreaService _learningAreaService = LearningAreaService();
  final ProgramService _programService = ProgramService();
  final SubjectService _subjectService = SubjectService();
  final TopicService _topicService = TopicService();
  final QuestionService _questionService = QuestionService();

  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _marksController =
  TextEditingController(text: '1');

  final TextEditingController _referenceAnswerController =
  TextEditingController();

  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  List<LearningArea> _learningAreas = [];
  List<Program> _programs = [];
  List<Subject> _subjects = [];
  List<Topic> _topics = [];

  LearningArea? _selectedLearningArea;
  Program? _selectedProgram;
  Subject? _selectedSubject;
  Topic? _selectedTopic;

  QuestionType _questionType = QuestionType.multiple;
  DifficultyLevel _difficulty = DifficultyLevel.medium;

  // Multiple-choice options.
  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];

  final Set<int> _correctOptionIndexes = {};

  // Written assessment.
  AssessmentType _assessmentType = AssessmentType.manual;

  final List<_CriterionInput> _criteria = [];

  @override
  void initState() {
    super.initState();
    _loadLearningAreas();
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

  // ---------------------------------------------------------------------------
  // DATA LOADING
  // ---------------------------------------------------------------------------

  Future<void> _loadLearningAreas() async {
    try {
      final areas = await _learningAreaService.getAllLearningAreas();

      if (!mounted) return;

      final activeAreas = areas
          .where((area) => area.isActive)
          .toList()
        ..sort((a, b) {
          final sortComparison =
          a.sortOrder.compareTo(b.sortOrder);

          if (sortComparison != 0) {
            return sortComparison;
          }

          return a.name
              .toLowerCase()
              .compareTo(b.name.toLowerCase());
        });

      setState(() {
        _learningAreas = activeAreas;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load learning areas: $e';
      });
    }
  }

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
      await _programService.getProgramsByLearningArea(
        area.learningAreaId,
      );

      if (!mounted) return;

      final activePrograms = programs
          .where((program) => program.isActive)
          .toList()
        ..sort((a, b) {
          final sortComparison =
          a.sortOrder.compareTo(b.sortOrder);

          if (sortComparison != 0) {
            return sortComparison;
          }

          return a.name
              .toLowerCase()
              .compareTo(b.name.toLowerCase());
        });

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
      await _subjectService.getSubjectsByProgram(
        program.programId,
      );

      if (!mounted) return;

      final activeSubjects = subjects
          .where((subject) => subject.isActive)
          .toList()
        ..sort((a, b) {
          final sortComparison =
          a.sortOrder.compareTo(b.sortOrder);

          if (sortComparison != 0) {
            return sortComparison;
          }

          return a.name
              .toLowerCase()
              .compareTo(b.name.toLowerCase());
        });

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
        ..sort((a, b) {
          final sortComparison =
          a.sortOrder.compareTo(b.sortOrder);

          if (sortComparison != 0) {
            return sortComparison;
          }

          return a.name
              .toLowerCase()
              .compareTo(b.name.toLowerCase());
        });

      setState(() {
        _topics = activeTopics;
      });
    } catch (e) {
      if (!mounted) return;

      _showError('Unable to load topics: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // OPTION MANAGEMENT
  // ---------------------------------------------------------------------------

  void _addOption() {
    if (_optionControllers.length >= 6) {
      _showError('A multiple-choice question can have at most 6 options.');
      return;
    }

    setState(() {
      _optionControllers.add(TextEditingController());
    });
  }

  void _removeOption(int index) {
    if (_optionControllers.length <= 2) {
      _showError('A multiple-choice question must have at least 2 options.');
      return;
    }

    final controller = _optionControllers[index];

    setState(() {
      _optionControllers.removeAt(index);

      final updatedCorrectAnswers = <int>{};

      for (final correctIndex in _correctOptionIndexes) {
        if (correctIndex == index) {
          continue;
        }

        if (correctIndex > index) {
          updatedCorrectAnswers.add(correctIndex - 1);
        } else {
          updatedCorrectAnswers.add(correctIndex);
        }
      }

      _correctOptionIndexes
        ..clear()
        ..addAll(updatedCorrectAnswers);
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

  // ---------------------------------------------------------------------------
  // WRITTEN CRITERIA
  // ---------------------------------------------------------------------------

  void _addCriterion() {
    setState(() {
      _criteria.add(_CriterionInput());
    });
  }

  void _removeCriterion(int index) {
    final criterion = _criteria[index];

    setState(() {
      _criteria.removeAt(index);
    });

    criterion.dispose();
  }

  // ---------------------------------------------------------------------------
  // VALIDATION
  // ---------------------------------------------------------------------------

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

    final marksText = _marksController.text.trim();

    if (marksText.isEmpty) {
      return 'Please enter the marks.';
    }

    final marks = double.tryParse(marksText);

    if (marks == null || marks <= 0) {
      return 'Marks must be greater than 0.';
    }

    if (_questionType == QuestionType.multiple) {
      if (_optionControllers.length < 2) {
        return 'Please provide at least 2 options.';
      }

      for (var i = 0; i < _optionControllers.length; i++) {
        if (_optionControllers[i].text.trim().isEmpty) {
          return 'Please enter text for option ${_optionLetter(i)}.';
        }
      }

      if (_correctOptionIndexes.isEmpty) {
        return 'Please select at least one correct answer.';
      }
    }

    if (_questionType == QuestionType.written) {
      if (_referenceAnswerController.text.trim().isEmpty) {
        return 'Please enter a reference answer.';
      }

      if (_assessmentType == AssessmentType.hybrid ||
          _assessmentType == AssessmentType.manual) {
        if (_criteria.isEmpty) {
          return 'Please add at least one assessment criterion.';
        }

        double totalCriteriaMarks = 0;

        for (final criterion in _criteria) {
          final text = criterion.criterionController.text.trim();

          if (text.isEmpty) {
            return 'Please enter all assessment criteria.';
          }

          final criterionMarks =
          double.tryParse(criterion.marksController.text.trim());

          if (criterionMarks == null || criterionMarks <= 0) {
            return 'Each assessment criterion must have valid marks.';
          }

          totalCriteriaMarks += criterionMarks;
        }

        if (totalCriteriaMarks > marks) {
          return 'Assessment criteria marks cannot exceed the question marks.';
        }
      }
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // SUBMISSION
  // ---------------------------------------------------------------------------

  Future<void> _submitQuestion() async {
    FocusScope.of(context).unfocus();

    final validationError = _validateForm();

    if (validationError != null) {
      _showError(validationError);
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showError('You are not logged in.');
      return;
    }

    final marks =
    double.parse(_marksController.text.trim());

    final questionId =
        'q_${DateTime.now().millisecondsSinceEpoch}_${user.uid.substring(0, user.uid.length >= 6 ? 6 : user.uid.length)}';

    final List<QuestionOption> options = [];
    final List<String> correctAnswers = [];

    if (_questionType == QuestionType.multiple) {
      for (var i = 0; i < _optionControllers.length; i++) {
        final optionId = 'option_${i + 1}';

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

    if (_questionType == QuestionType.trueFalse) {
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

      // The answer is selected through the radio buttons below.
      if (_correctOptionIndexes.contains(0)) {
        correctAnswers.add('true');
      } else if (_correctOptionIndexes.contains(1)) {
        correctAnswers.add('false');
      }
    }

    WrittenAssessment? writtenAssessment;

    if (_questionType == QuestionType.written) {
      final criteria = <AssessmentCriterion>[];

      for (var i = 0; i < _criteria.length; i++) {
        final criterion = _criteria[i];

        criteria.add(
          AssessmentCriterion(
            criterionId: 'criterion_${i + 1}',
            criterion: criterion.criterionController.text.trim(),
            marks: double.parse(
              criterion.marksController.text.trim(),
            ),
          ),
        );
      }

      writtenAssessment = WrittenAssessment(
        assessmentType: _assessmentType,
        referenceAnswer:
        _referenceAnswerController.text.trim(),
        criteria: criteria,
      );
    }

    final question = Question(
      questionId: questionId,
      questionDescription:
      _questionController.text.trim(),
      programId: _selectedProgram!.programId,
      subjectId: _selectedSubject!.subjectId,
      topicId: _selectedTopic!.topicId,
      questionType: _questionType,
      difficulty: _difficulty,
      options: options,
      correctAnswers: correctAnswers,
      writtenAssessment: writtenAssessment,
      marks: marks,
      createdBy: user.uid,
      status: QuestionStatus.pending,
      approvedBy: null,
      approvedAt: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _questionService.submitQuestion(question);

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            icon: Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Colors.green,
                size: 40,
              ),
            ),
            title: const Text(
              'Question Submitted',
              textAlign: TextAlign.center,
            ),
            content: const Text(
              'Your question has been submitted successfully and is now waiting for review.',
              textAlign: TextAlign.center,
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.check_rounded),
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
        _isSubmitting = false;
      });

      _showError('Unable to submit question: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // UI HELPERS
  // ---------------------------------------------------------------------------

  String _optionLetter(int index) {
    const letters = ['A', 'B', 'C', 'D', 'E', 'F'];

    if (index >= 0 && index < letters.length) {
      return letters[index];
    }

    return '?';
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: colorScheme.primary.withValues(alpha: 0.035),
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

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: colorScheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade600,
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

  Widget _buildDropdown<T>({
    required String label,
    required IconData icon,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?>? onChanged,
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

  // ---------------------------------------------------------------------------
  // HIERARCHY SECTION
  // ---------------------------------------------------------------------------

  Widget _buildHierarchySection() {
    return _buildSectionCard(
      icon: Icons.account_tree_rounded,
      title: 'Question Category',
      subtitle:
      'Select where this question belongs in the question bank.',
      child: Column(
        children: [
          _buildDropdown<LearningArea>(
            label: 'Learning Area',
            icon: Icons.auto_stories_rounded,
            value: _selectedLearningArea,
            items: _learningAreas.map((area) {
              return DropdownMenuItem<LearningArea>(
                value: area,
                child: Text(
                  area.name,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: _onLearningAreaChanged,
          ),

          const SizedBox(height: 14),

          _buildDropdown<Program>(
            label: 'Program',
            icon: Icons.account_tree_rounded,
            value: _selectedProgram,
            items: _programs.map((program) {
              return DropdownMenuItem<Program>(
                value: program,
                child: Text(
                  program.name,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged:
            _selectedLearningArea == null
                ? null
                : _onProgramChanged,
          ),

          const SizedBox(height: 14),

          _buildDropdown<Subject>(
            label: 'Subject',
            icon: Icons.menu_book_rounded,
            value: _selectedSubject,
            items: _subjects.map((subject) {
              return DropdownMenuItem<Subject>(
                value: subject,
                child: Text(
                  subject.name,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged:
            _selectedProgram == null
                ? null
                : _onSubjectChanged,
          ),

          const SizedBox(height: 14),

          _buildDropdown<Topic>(
            label: 'Topic',
            icon: Icons.topic_rounded,
            value: _selectedTopic,
            items: _topics.map((topic) {
              return DropdownMenuItem<Topic>(
                value: topic,
                child: Text(
                  topic.name,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged:
            _selectedSubject == null
                ? null
                : (topic) {
              setState(() {
                _selectedTopic = topic;
              });
            },
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // QUESTION SETTINGS
  // ---------------------------------------------------------------------------

  Widget _buildQuestionSettingsSection() {
    return _buildSectionCard(
      icon: Icons.tune_rounded,
      title: 'Question Settings',
      subtitle:
      'Choose the question type, difficulty and marks.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 650;

          final typeDropdown = _buildDropdown<QuestionType>(
            label: 'Question Type',
            icon: Icons.quiz_rounded,
            value: _questionType,
            items: const [
              DropdownMenuItem(
                value: QuestionType.multiple,
                child: Text('Multiple Choice'),
              ),
              DropdownMenuItem(
                value: QuestionType.trueFalse,
                child: Text('True / False'),
              ),
              DropdownMenuItem(
                value: QuestionType.written,
                child: Text('Written'),
              ),
            ],
            onChanged: (value) {
              if (value == null) return;

              setState(() {
                _questionType = value;
                _correctOptionIndexes.clear();
              });
            },
          );

          final difficultyDropdown =
          _buildDropdown<DifficultyLevel>(
            label: 'Difficulty',
            icon: Icons.speed_rounded,
            value: _difficulty,
            items: const [
              DropdownMenuItem(
                value: DifficultyLevel.easy,
                child: Text('Easy'),
              ),
              DropdownMenuItem(
                value: DifficultyLevel.medium,
                child: Text('Medium'),
              ),
              DropdownMenuItem(
                value: DifficultyLevel.hard,
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

          final marksField = TextFormField(
            controller: _marksController,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            decoration: _inputDecoration(
              label: 'Marks',
              icon: Icons.star_outline_rounded,
              hint: 'e.g. 1 or 5',
            ),
          );

          if (isWide) {
            return Row(
              children: [
                Expanded(child: typeDropdown),
                const SizedBox(width: 12),
                Expanded(child: difficultyDropdown),
                const SizedBox(width: 12),
                SizedBox(
                  width: 150,
                  child: marksField,
                ),
              ],
            );
          }

          return Column(
            children: [
              typeDropdown,
              const SizedBox(height: 14),
              difficultyDropdown,
              const SizedBox(height: 14),
              marksField,
            ],
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // QUESTION CONTENT
  // ---------------------------------------------------------------------------

  Widget _buildQuestionSection() {
    return _buildSectionCard(
      icon: Icons.edit_note_rounded,
      title: 'Question',
      subtitle:
      'Write a clear and meaningful question.',
      child: TextFormField(
        controller: _questionController,
        maxLines: 6,
        minLines: 4,
        textInputAction: TextInputAction.newline,
        decoration: _inputDecoration(
          label: 'Question text',
          icon: Icons.help_outline_rounded,
          hint: 'Enter your question here...',
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // MULTIPLE CHOICE
  // ---------------------------------------------------------------------------

  Widget _buildMultipleChoiceSection() {
    return _buildSectionCard(
      icon: Icons.checklist_rounded,
      title: 'Answer Options',
      subtitle:
      'Add 2–6 options and select one or more correct answers.',
      child: Column(
        children: [
          ...List.generate(
            _optionControllers.length,
                (index) => _buildOptionRow(index),
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _optionControllers.length >= 6
                    ? null
                    : _addOption,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add Option'),
              ),
              const SizedBox(width: 12),
              Text(
                '${_optionControllers.length}/6 options',
                style: TextStyle(
                  color: Colors.grey.shade600,
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
    final colorScheme = Theme.of(context).colorScheme;
    final isCorrect =
    _correctOptionIndexes.contains(index);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isCorrect
            ? colorScheme.primary.withValues(alpha: 0.055)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isCorrect
              ? colorScheme.primary.withValues(alpha: 0.35)
              : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 8),

          Checkbox(
            value: isCorrect,
            onChanged: (_) => _toggleCorrectOption(index),
          ),

          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isCorrect
                  ? colorScheme.primary
                  : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _optionLetter(index),
              style: TextStyle(
                color: isCorrect
                    ? Colors.white
                    : Colors.grey.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: TextField(
              controller: _optionControllers[index],
              decoration: const InputDecoration(
                hintText: 'Enter option text',
                border: InputBorder.none,
                contentPadding:
                EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),

          IconButton(
            tooltip: 'Remove option',
            onPressed: _optionControllers.length <= 2
                ? null
                : () => _removeOption(index),
            icon: const Icon(Icons.close_rounded),
          ),

          const SizedBox(width: 4),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TRUE / FALSE
  // ---------------------------------------------------------------------------

  Widget _buildTrueFalseSection() {
    final colorScheme = Theme.of(context).colorScheme;

    return _buildSectionCard(
      icon: Icons.rule_rounded,
      title: 'Correct Answer',
      subtitle: 'Select the correct answer.',
      child: Row(
        children: [
          Expanded(
            child: _buildTrueFalseChoice(
              value: 0,
              label: 'True',
              icon: Icons.check_circle_outline_rounded,
              color: Colors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildTrueFalseChoice(
              value: 1,
              label: 'False',
              icon: Icons.cancel_outlined,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrueFalseChoice({
    required int value,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final selected =
    _correctOptionIndexes.contains(value);

    return InkWell(
      borderRadius: BorderRadius.circular(15),
      onTap: () {
        setState(() {
          _correctOptionIndexes
            ..clear()
            ..add(value);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.08)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: selected
                ? color.withValues(alpha: 0.45)
                : Colors.grey.shade200,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Radio<int>(
              value: value,
              groupValue: _correctOptionIndexes.isEmpty
                  ? null
                  : _correctOptionIndexes.first,
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
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // WRITTEN QUESTION
  // ---------------------------------------------------------------------------

  Widget _buildWrittenSection() {
    return _buildSectionCard(
      icon: Icons.draw_rounded,
      title: 'Written Assessment',
      subtitle:
      'Provide a reference answer and assessment method.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _referenceAnswerController,
            maxLines: 6,
            minLines: 4,
            decoration: _inputDecoration(
              label: 'Reference Answer',
              icon: Icons.menu_book_outlined,
              hint: 'Enter the expected/reference answer...',
            ),
          ),

          const SizedBox(height: 18),

          _buildDropdown<AssessmentType>(
            label: 'Assessment Type',
            icon: Icons.fact_check_outlined,
            value: _assessmentType,
            items: const [
              DropdownMenuItem(
                value: AssessmentType.automatic,
                child: Text('Automatic'),
              ),
              DropdownMenuItem(
                value: AssessmentType.manual,
                child: Text('Manual'),
              ),
              DropdownMenuItem(
                value: AssessmentType.hybrid,
                child: Text('Hybrid'),
              ),
            ],
            onChanged: (value) {
              if (value == null) return;

              setState(() {
                _assessmentType = value;
              });
            },
          ),

          if (_assessmentType != AssessmentType.automatic) ...[
            const SizedBox(height: 22),

            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Assessment Criteria',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _addCriterion,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Criterion'),
                ),
              ],
            ),

            const SizedBox(height: 8),

            if (_criteria.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: Colors.amber.shade800,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Add criteria describing how the written answer should be assessed.',
                        style: TextStyle(
                          color: Colors.amber.shade900,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            ...List.generate(
              _criteria.length,
                  (index) => _buildCriterionRow(index),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCriterionRow(int index) {
    final criterion = _criteria[index];

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 600;

          final criterionField = TextField(
            controller: criterion.criterionController,
            maxLines: 2,
            decoration: _inputDecoration(
              label: 'Criterion ${index + 1}',
              icon: Icons.checklist_outlined,
              hint: 'What should be assessed?',
            ),
          );

          final marksField = TextField(
            controller: criterion.marksController,
            keyboardType:
            const TextInputType.numberWithOptions(
              decimal: true,
            ),
            decoration: _inputDecoration(
              label: 'Marks',
              icon: Icons.star_outline_rounded,
            ),
          );

          final removeButton = IconButton(
            tooltip: 'Remove criterion',
            onPressed: () => _removeCriterion(index),
            icon: const Icon(Icons.delete_outline_rounded),
          );

          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: criterionField),
                const SizedBox(width: 12),
                SizedBox(
                  width: 150,
                  child: marksField,
                ),
                removeButton,
              ],
            );
          }

          return Column(
            children: [
              criterionField,
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: marksField),
                  removeButton,
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // INFORMATION CARD
  // ---------------------------------------------------------------------------

  Widget _buildSubmissionInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.indigo.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: Colors.indigo.withValues(alpha: 0.13),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: Colors.indigo.shade600,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Your question will be submitted for review. '
                  'It will remain pending until an administrator or examiner approves it.',
              style: TextStyle(
                color: Colors.indigo.shade900,
                fontSize: 12.5,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // LOADING / ERROR
  // ---------------------------------------------------------------------------

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
              'Unable to load question categories',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'An unexpected error occurred.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });

                _loadLearningAreas();
              },
              icon: const Icon(Icons.refresh_rounded),
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                Icons.add_comment_rounded,
                color: colorScheme.primary,
                size: 21,
              ),
            ),
            const SizedBox(width: 11),
            const Flexible(
              child: Text(
                'Contribute a Question',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? _buildLoading()
          : _errorMessage != null
          ? _buildError()
          : SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            20,
            20,
            20,
            35,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints:
              const BoxConstraints(maxWidth: 1000),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
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
                      borderRadius:
                      BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.indigo
                              .withValues(alpha: 0.16),
                          blurRadius: 16,
                          offset: const Offset(0, 7),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 55,
                          height: 55,
                          decoration: BoxDecoration(
                            color: Colors.white
                                .withValues(alpha: 0.14),
                            borderRadius:
                            BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.lightbulb_rounded,
                            color: Colors.white,
                            size: 29,
                          ),
                        ),
                        const SizedBox(width: 15),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Share your knowledge',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 21,
                                  fontWeight:
                                  FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                'Create a quality question for other learners. '
                                    'Every submitted question will be reviewed before approval.',
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
                  ),

                  const SizedBox(height: 18),

                  _buildHierarchySection(),

                  const SizedBox(height: 18),

                  _buildQuestionSettingsSection(),

                  const SizedBox(height: 18),

                  _buildQuestionSection(),

                  const SizedBox(height: 18),

                  if (_questionType ==
                      QuestionType.multiple)
                    _buildMultipleChoiceSection(),

                  if (_questionType ==
                      QuestionType.trueFalse)
                    _buildTrueFalseSection(),

                  if (_questionType ==
                      QuestionType.written)
                    _buildWrittenSection(),

                  const SizedBox(height: 18),

                  _buildSubmissionInfo(),

                  const SizedBox(height: 22),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed:
                      _isSubmitting
                          ? null
                          : _submitQuestion,
                      icon: _isSubmitting
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                        CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                          : const Icon(
                        Icons.send_rounded,
                      ),
                      label: Text(
                        _isSubmitting
                            ? 'Submitting...'
                            : 'Submit Question for Review',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(15),
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

// -----------------------------------------------------------------------------
// PRIVATE CRITERION INPUT MODEL
// -----------------------------------------------------------------------------

class _CriterionInput {
  final TextEditingController criterionController =
  TextEditingController();

  final TextEditingController marksController =
  TextEditingController(text: '1');

  void dispose() {
    criterionController.dispose();
    marksController.dispose();
  }
}