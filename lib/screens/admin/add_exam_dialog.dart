import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:questionbank/models/exam.dart';
import 'package:questionbank/models/program.dart';
import 'package:questionbank/models/subject.dart';
import 'package:questionbank/services/exam_service.dart';

class AddExamDialog extends StatefulWidget {
  final List<Program> programs;
  final List<Subject> subjects;

  /// Null = Add Exam
  /// Non-null = Edit Exam
  final Exam? exam;

  const AddExamDialog({
    super.key,
    required this.programs,
    required this.subjects,
    this.exam,
  });

  @override
  State<AddExamDialog> createState() => _AddExamDialogState();
}

class _AddExamDialogState extends State<AddExamDialog> {
  final _formKey = GlobalKey<FormState>();

  final ExamService _examService = ExamService();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  final TextEditingController _durationController = TextEditingController(
    text: '30',
  );

  final TextEditingController _passPercentageController = TextEditingController(
    text: '40',
  );

  String? _selectedProgramId;

  /// IDs of subjects selected for this exam.
  final Set<String> _selectedSubjectIds = <String>{};

  ExamQuestionSelectionMode _questionSelectionMode =
      ExamQuestionSelectionMode.manual;

  bool _randomizeQuestions = false;
  bool _randomizeOptions = false;

  bool _isSaving = false;

  bool get _isEditing => widget.exam != null;

  String get _dialogTitle => _isEditing ? 'Edit Exam' : 'Add Exam';

  String get _saveButtonText => _isEditing ? 'Update Exam' : 'Create Exam';

  @override
  void initState() {
    super.initState();

    _loadExistingExam();
  }

  // ---------------------------------------------------------------------------
  // Load existing exam when editing
  // ---------------------------------------------------------------------------

  void _loadExistingExam() {
    final exam = widget.exam;

    if (exam == null) {
      return;
    }

    _nameController.text = exam.examName;
    _descriptionController.text = exam.description;

    _durationController.text = exam.durationMinutes.toString();

    _passPercentageController.text = exam.passPercentage.toString();

    _selectedProgramId = exam.programId;

    _selectedSubjectIds.addAll(exam.subjectIds);

    _questionSelectionMode = exam.questionSelectionMode;

    _randomizeQuestions = exam.randomizeQuestions;
    _randomizeOptions = exam.randomizeOptions;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    _passPercentageController.dispose();

    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Available subjects
  // ---------------------------------------------------------------------------

  List<Subject> get _availableSubjects {
    if (_selectedProgramId == null) {
      return [];
    }

    final subjects = widget.subjects
        .where((subject) => subject.programId == _selectedProgramId)
        .toList();

    subjects.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return subjects;
  }

  // ---------------------------------------------------------------------------
  // All subjects selected?
  // ---------------------------------------------------------------------------

  bool get _allSubjectsSelected {
    if (_availableSubjects.isEmpty) {
      return false;
    }

    return _availableSubjects.every(
      (subject) => _selectedSubjectIds.contains(subject.subjectId),
    );
  }

  // ---------------------------------------------------------------------------
  // Select / deselect all subjects
  // ---------------------------------------------------------------------------

  void _toggleAllSubjects() {
    if (_availableSubjects.isEmpty) {
      return;
    }

    setState(() {
      if (_allSubjectsSelected) {
        _selectedSubjectIds.clear();
      } else {
        _selectedSubjectIds
          ..clear()
          ..addAll(_availableSubjects.map((subject) => subject.subjectId));
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Toggle individual subject
  // ---------------------------------------------------------------------------

  void _toggleSubject(String subjectId) {
    setState(() {
      if (_selectedSubjectIds.contains(subjectId)) {
        _selectedSubjectIds.remove(subjectId);
      } else {
        _selectedSubjectIds.add(subjectId);
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Save
  // ---------------------------------------------------------------------------

  Future<void> _saveExam() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedSubjectIds.isEmpty) {
      _showMessage('Please select at least one subject.', isError: true);
      return;
    }

    final duration = int.tryParse(_durationController.text.trim());

    final passPercentage = double.tryParse(
      _passPercentageController.text.trim(),
    );

    if (duration == null || duration <= 0) {
      _showMessage('Please enter a valid duration.', isError: true);
      return;
    }

    if (passPercentage == null || passPercentage < 0 || passPercentage > 100) {
      _showMessage('Pass percentage must be between 0 and 100.', isError: true);
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // -----------------------------------------------------------------------
      // EDIT EXISTING EXAM
      // -----------------------------------------------------------------------

      if (_isEditing) {
        final existingExam = widget.exam!;

        final updatedExam = existingExam.copyWith(
          examName: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          programId: _selectedProgramId,
          subjectIds: _selectedSubjectIds.toList(),
          questionSelectionMode: _questionSelectionMode,
          durationMinutes: duration,
          passPercentage: passPercentage,
          randomizeQuestions: _randomizeQuestions,
          randomizeOptions: _randomizeOptions,
          updatedAt: DateTime.now(),
        );

        await _examService.updateExam(updatedExam);

        if (!mounted) {
          return;
        }

        Navigator.of(context).pop(true);
        return;
      }

      // -----------------------------------------------------------------------
      // CREATE NEW EXAM
      // -----------------------------------------------------------------------

      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        setState(() {
          _isSaving = false;
        });

        _showMessage('You must be logged in to create an exam.', isError: true);
        return;
      }

      final examId = 'exam_${DateTime.now().millisecondsSinceEpoch}';

      final now = DateTime.now();

      final exam = Exam(
        examId: examId,
        examName: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        programId: _selectedProgramId,
        subjectIds: _selectedSubjectIds.toList(),
        questionSelectionMode: _questionSelectionMode,
        durationMinutes: duration,
        totalMarks: 0,
        passPercentage: passPercentage,
        questionCount: 0,
        randomizeQuestions: _randomizeQuestions,
        randomizeOptions: _randomizeOptions,
        isActive: true,
        createdBy: currentUser.uid,
        createdAt: now,
        updatedAt: now,
        questions: const [],
      );

      await _examService.createExam(exam);

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });

      _showMessage(
        _isEditing ? 'Failed to update exam.' : 'Failed to create exam.',
        isError: true,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Message
  // ---------------------------------------------------------------------------

  void _showMessage(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  // ---------------------------------------------------------------------------
  // Question summary
  // ---------------------------------------------------------------------------

  Widget _buildQuestionSummary() {
    final questionCount = widget.exam?.questionCount ?? 0;
    final totalMarks = widget.exam?.totalMarks ?? 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryItem(
              icon: Icons.quiz_outlined,
              label: 'Questions',
              value: '$questionCount',
            ),
          ),
          Container(width: 1, height: 42, color: Colors.grey.shade300),
          Expanded(
            child: _buildSummaryItem(
              icon: Icons.stars_outlined,
              label: 'Total Marks',
              value: '$totalMarks',
            ),
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
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 24, color: Colors.indigo),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 8),
      contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 18),
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.indigo.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(Icons.assignment_outlined, color: Colors.indigo),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _dialogTitle,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 620,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Exam Information', Icons.info_outline),
                const SizedBox(height: 12),

                // -------------------------------------------------------------
                // Exam name
                // -------------------------------------------------------------
                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Exam Name',
                    hintText: 'e.g. Class 9 Physics - Motion Test',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.assignment_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter exam name.';
                    }

                    if (value.trim().length < 3) {
                      return 'Exam name is too short.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 14),

                // -------------------------------------------------------------
                // Description
                // -------------------------------------------------------------
                TextFormField(
                  controller: _descriptionController,
                  minLines: 2,
                  maxLines: 4,
                  textInputAction: TextInputAction.newline,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Optional exam description',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.notes_outlined),
                    alignLabelWithHint: true,
                  ),
                ),

                const SizedBox(height: 24),

                // -------------------------------------------------------------
                // Exam scope
                // -------------------------------------------------------------
                _buildSectionTitle('Exam Scope', Icons.account_tree_outlined),
                const SizedBox(height: 12),

                // -------------------------------------------------------------
                // Program
                // -------------------------------------------------------------
                DropdownButtonFormField<String>(
                  value: _selectedProgramId,
                  decoration: const InputDecoration(
                    labelText: 'Program',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.account_tree_outlined),
                  ),
                  items: widget.programs.map((program) {
                    return DropdownMenuItem<String>(
                      value: program.programId,
                      child: Text(program.name),
                    );
                  }).toList(),
                  onChanged: _isSaving
                      ? null
                      : (value) {
                          setState(() {
                            _selectedProgramId = value;
                            _selectedSubjectIds.clear();
                          });
                        },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a program.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // -------------------------------------------------------------
                // Subjects
                // -------------------------------------------------------------
                _buildSubjectSelector(),

                const SizedBox(height: 24),

                // -------------------------------------------------------------
                // Question summary
                // -------------------------------------------------------------
                _buildSectionTitle('Question Summary', Icons.quiz_outlined),
                const SizedBox(height: 12),

                _buildQuestionSummary(),

                const SizedBox(height: 24),

                // -------------------------------------------------------------
                // Exam settings
                // -------------------------------------------------------------
                _buildSectionTitle('Exam Settings', Icons.settings_outlined),
                const SizedBox(height: 12),

                // -------------------------------------------------------------
                // Question selection mode
                // -------------------------------------------------------------
                _buildQuestionSelectionMode(),

                const SizedBox(height: 16),

                // -------------------------------------------------------------
                // Duration and pass percentage
                // -------------------------------------------------------------
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _durationController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Duration',
                          suffixText: 'minutes',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.timer_outlined),
                        ),
                        validator: (value) {
                          final number = int.tryParse(value?.trim() ?? '');

                          if (number == null || number <= 0) {
                            return 'Enter valid duration.';
                          }

                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextFormField(
                        controller: _passPercentageController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Pass Percentage',
                          suffixText: '%',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.percent_outlined),
                        ),
                        validator: (value) {
                          final number = double.tryParse(value?.trim() ?? '');

                          if (number == null || number < 0 || number > 100) {
                            return 'Enter 0–100.';
                          }

                          return null;
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // -------------------------------------------------------------
                // Randomize questions
                // -------------------------------------------------------------
                _buildSettingTile(
                  title: 'Randomize Questions',
                  subtitle:
                      'Show exam questions in a different order for each attempt.',
                  value: _randomizeQuestions,
                  onChanged: _isSaving
                      ? null
                      : (value) {
                          setState(() {
                            _randomizeQuestions = value;
                          });
                        },
                ),

                const SizedBox(height: 8),

                // -------------------------------------------------------------
                // Randomize options
                // -------------------------------------------------------------
                _buildSettingTile(
                  title: 'Randomize Options',
                  subtitle: 'Randomize answer options where applicable.',
                  value: _randomizeOptions,
                  onChanged: _isSaving
                      ? null
                      : (value) {
                          setState(() {
                            _randomizeOptions = value;
                          });
                        },
                ),

                const SizedBox(height: 8),

                // -------------------------------------------------------------
                // Information note
                // -------------------------------------------------------------
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.blue.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 19,
                        color: Colors.blue.shade700,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _isEditing
                              ? 'Existing questions attached to this exam will be preserved. '
                                    'You can manage the questions separately.'
                              : 'Questions will be added after the exam is created. '
                                    'Question count and total marks will then be calculated automatically.',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Colors.blue.shade800,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: _isSaving ? null : _saveExam,
          icon: _isSaving
              ? const SizedBox(
                  width: 17,
                  height: 17,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_outlined),
          label: Text(_isSaving ? 'Saving...' : _saveButtonText),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(9),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Question selection mode
  // ---------------------------------------------------------------------------

  Widget _buildQuestionSelectionMode() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Question Selection',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Choose how questions will be added to this exam.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 10),
      IgnorePointer(
        ignoring: _isSaving,
        child: RadioGroup<ExamQuestionSelectionMode>(
          groupValue: _questionSelectionMode,
          onChanged: (value) {
            if (value == null) {
              return;
            }

            setState(() {
              _questionSelectionMode = value;
            });
          },
          child: Column(
              children: [
                RadioListTile<ExamQuestionSelectionMode>(
                  value: ExamQuestionSelectionMode.manual,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: const Text(
                    'Manual Selection',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Admin selects the questions individually.',
                    style: TextStyle(fontSize: 12),
                  ),
                  secondary: const Icon(
                    Icons.checklist_outlined,
                    color: Colors.indigo,
                  ),
                ),
                RadioListTile<ExamQuestionSelectionMode>(
                  value: ExamQuestionSelectionMode.automatic,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: const Text(
                    'Automatic / Random Selection',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'The system selects questions according to configured rules.',
                    style: TextStyle(fontSize: 12),
                  ),
                  secondary: const Icon(
                    Icons.shuffle_outlined,
                    color: Colors.indigo,
                  ),
                ),
              ],
            ),
          ),
        ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Subject selector
  // ---------------------------------------------------------------------------

  Widget _buildSubjectSelector() {
    final subjects = _availableSubjects;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                const Icon(Icons.menu_book_outlined, size: 21),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Subjects',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                if (_selectedProgramId != null && subjects.isNotEmpty)
                  Text(
                    '${_selectedSubjectIds.length}/${subjects.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.indigo.shade700,
                    ),
                  ),
              ],
            ),
          ),
          if (_selectedProgramId == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Text(
                'Select a program first.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            )
          else if (subjects.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Text(
                'No subjects are available for this program.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            )
          else ...[
            const Divider(height: 1),

            // ---------------------------------------------------------------
            // All Subjects
            // ---------------------------------------------------------------
            CheckboxListTile(
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
              value: _allSubjectsSelected,
              tristate: true,
              onChanged: _isSaving ? null : (_) => _toggleAllSubjects(),
              title: const Text(
                'All Subjects',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Include all subjects of this program',
                style: TextStyle(fontSize: 12),
              ),
              secondary: const Icon(Icons.select_all_outlined),
            ),

            const Divider(height: 1),

            // ---------------------------------------------------------------
            // Individual subjects
            // ---------------------------------------------------------------
            ...subjects.map((subject) {
              final selected = _selectedSubjectIds.contains(subject.subjectId);

              return CheckboxListTile(
                dense: true,
                controlAffinity: ListTileControlAffinity.leading,
                value: selected,
                onChanged: _isSaving
                    ? null
                    : (_) => _toggleSubject(subject.subjectId),
                title: Text(subject.name),
                secondary: Icon(
                  selected
                      ? Icons.check_circle_outline
                      : Icons.menu_book_outlined,
                  color: selected ? Colors.indigo : Colors.grey.shade500,
                ),
              );
            }),

            if (_selectedSubjectIds.isNotEmpty) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _availableSubjects
                      .where(
                        (subject) =>
                            _selectedSubjectIds.contains(subject.subjectId),
                      )
                      .map(
                        (subject) => Chip(
                          label: Text(
                            subject.name,
                            style: const TextStyle(fontSize: 12),
                          ),
                          deleteIcon: const Icon(Icons.close, size: 16),
                          onDeleted: _isSaving
                              ? null
                              : () => _toggleSubject(subject.subjectId),
                          visualDensity: VisualDensity.compact,
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Section title
  // ---------------------------------------------------------------------------

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 19, color: Colors.indigo),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Setting tile
  // ---------------------------------------------------------------------------

  Widget _buildSettingTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
