import 'package:flutter/material.dart';
import 'package:questionbank/models/exam.dart';
import 'package:questionbank/models/program.dart';
import 'package:questionbank/models/subject.dart';
import 'package:questionbank/services/exam_service.dart';
import 'package:questionbank/services/program_service.dart';
import 'package:questionbank/services/subject_service.dart';

import 'add_exam_dialog.dart';
import 'manage_exam_questions_dialog.dart';

enum _ExamSortOption { programOrder, subjectOrder, examOrder }

class ExamsScreen extends StatefulWidget {
  const ExamsScreen({super.key});

  @override
  State<ExamsScreen> createState() => _ExamsScreenState();
}

class _ExamsScreenState extends State<ExamsScreen> {
  final ExamService _examService = ExamService();
  final ProgramService _programService = ProgramService();
  final SubjectService _subjectService = SubjectService();

  List<Exam> _exams = [];
  List<Program> _programs = [];
  List<Subject> _subjects = [];

  bool _isLoading = true;
  String? _errorMessage;

  String? _selectedProgramId;

  _ExamSortOption _sortOption = _ExamSortOption.programOrder;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ---------------------------------------------------------------------------
  // Data loading
  // ---------------------------------------------------------------------------

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _examService.getAllExams(),
        _programService.getAllPrograms(),
        _subjectService.getAllSubjects(),
      ]);

      final exams = results[0] as List<Exam>;
      final programs = results[1] as List<Program>;
      final subjects = results[2] as List<Subject>;

      programs.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      subjects.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      if (!mounted) return;

      setState(() {
        _exams = exams;
        _programs = programs;
        _subjects = subjects;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load exams.';
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Lookup helpers
  // ---------------------------------------------------------------------------

  Program? _getProgram(String? programId) {
    if (programId == null) return null;

    for (final program in _programs) {
      if (program.programId == programId) {
        return program;
      }
    }

    return null;
  }

  Subject? _getSubject(String subjectId) {
    for (final subject in _subjects) {
      if (subject.subjectId == subjectId) {
        return subject;
      }
    }

    return null;
  }

  List<Subject> _getExamSubjects(Exam exam) {
    final subjects = <Subject>[];

    for (final subjectId in exam.subjectIds) {
      final subject = _getSubject(subjectId);

      if (subject != null) {
        subjects.add(subject);
      }
    }

    subjects.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return subjects;
  }

  // ---------------------------------------------------------------------------
  // Filtering
  // ---------------------------------------------------------------------------

  List<Exam> _getFilteredExams() {
    return _exams.where((exam) {
      if (_selectedProgramId != null && exam.programId != _selectedProgramId) {
        return false;
      }

      return true;
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // Sorting
  // ---------------------------------------------------------------------------

  List<Exam> _getFilteredAndSortedExams() {
    final exams = _getFilteredExams();

    exams.sort((a, b) {
      final programA = _getProgram(a.programId);
      final programB = _getProgram(b.programId);

      if (_sortOption == _ExamSortOption.programOrder) {
        final programOrderA = programA?.sortOrder ?? 999999;

        final programOrderB = programB?.sortOrder ?? 999999;

        final programComparison = programOrderA.compareTo(programOrderB);

        if (programComparison != 0) {
          return programComparison;
        }
      }

      if (_sortOption == _ExamSortOption.programOrder ||
          _sortOption == _ExamSortOption.subjectOrder) {
        final subjectsA = _getExamSubjects(a);
        final subjectsB = _getExamSubjects(b);

        final subjectOrderA = subjectsA.isEmpty
            ? 999999
            : subjectsA.first.sortOrder;

        final subjectOrderB = subjectsB.isEmpty
            ? 999999
            : subjectsB.first.sortOrder;

        final subjectComparison = subjectOrderA.compareTo(subjectOrderB);

        if (subjectComparison != 0) {
          return subjectComparison;
        }
      }

      return a.examName.toLowerCase().compareTo(b.examName.toLowerCase());
    });

    return exams;
  }

  // ---------------------------------------------------------------------------
  // Filter / sort actions
  // ---------------------------------------------------------------------------

  void _changeProgramFilter(String value) {
    setState(() {
      _selectedProgramId = value.isEmpty ? null : value;
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedProgramId = null;
    });
  }

  // ---------------------------------------------------------------------------
  // Add Exam
  // ---------------------------------------------------------------------------

  Future<void> _showAddExamDialog() async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AddExamDialog(
          programs: _programs,
          subjects: _subjects,
        );
      },
    );

    if (saved == true && mounted) {
      await _loadData();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Exam created successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Edit Exam
  // ---------------------------------------------------------------------------

  Future<void> _showEditExamDialog(Exam exam) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AddExamDialog(
          programs: _programs,
          subjects: _subjects,
          exam: exam,
        );
      },
    );

    if (saved == true && mounted) {
      await _loadData();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Exam updated successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final displayedExams = _getFilteredAndSortedExams();

    return Scaffold(
      backgroundColor: const Color(0xfff5f7fa),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(displayedExams.length),

              const SizedBox(height: 20),

              _buildFilterBar(),

              const SizedBox(height: 16),

              Expanded(child: _buildContent(displayedExams)),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Header
  // ---------------------------------------------------------------------------

  Widget _buildHeader(int count) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.indigo.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.assignment_outlined,
            color: Colors.indigo,
            size: 26,
          ),
        ),

        const SizedBox(width: 14),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Exams',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 3),
              Text(
                'Create and manage examinations',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
            ],
          ),
        ),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.indigo.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count ${count == 1 ? 'Exam' : 'Exams'}',
            style: const TextStyle(
              color: Colors.indigo,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),

        const SizedBox(width: 12),

        ElevatedButton.icon(
          onPressed: _showAddExamDialog,
          icon: const Icon(Icons.add),
          label: const Text('Add Exam'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Filter bar
  // ---------------------------------------------------------------------------

  Widget _buildFilterBar() {
    final selectedProgram = _getProgram(_selectedProgramId);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.filter_alt_outlined, size: 20, color: Colors.indigo),

          const SizedBox(width: 10),

          const Text('Filter:', style: TextStyle(fontWeight: FontWeight.w600)),

          const SizedBox(width: 12),

          PopupMenuButton<String>(
            tooltip: 'Filter by program',
            onSelected: _changeProgramFilter,
            itemBuilder: (context) {
              return [
                const PopupMenuItem<String>(
                  value: '',
                  child: Text('All Programs'),
                ),
                ..._programs.map(
                  (program) => PopupMenuItem<String>(
                    value: program.programId,
                    child: Text(program.name),
                  ),
                ),
              ];
            },
            child: _buildFilterButton(
              icon: Icons.account_tree_outlined,
              label: selectedProgram?.name ?? 'All Programs',
            ),
          ),

          const Spacer(),

          PopupMenuButton<_ExamSortOption>(
            tooltip: 'Sort exams',
            onSelected: (value) {
              setState(() {
                _sortOption = value;
              });
            },
            itemBuilder: (context) {
              return const [
                PopupMenuItem(
                  value: _ExamSortOption.programOrder,
                  child: Text('Program → Subject → Exam'),
                ),
                PopupMenuItem(
                  value: _ExamSortOption.subjectOrder,
                  child: Text('Subject → Exam'),
                ),
                PopupMenuItem(
                  value: _ExamSortOption.examOrder,
                  child: Text('Exam Name'),
                ),
              ];
            },
            child: _buildFilterButton(icon: Icons.sort, label: _sortLabel),
          ),

          if (_selectedProgramId != null) ...[
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Clear filters',
              onPressed: _clearFilters,
              icon: const Icon(Icons.clear),
            ),
          ],

          const SizedBox(width: 4),

          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }

  String get _sortLabel {
    switch (_sortOption) {
      case _ExamSortOption.programOrder:
        return 'Program → Subject → Exam';

      case _ExamSortOption.subjectOrder:
        return 'Subject → Exam';

      case _ExamSortOption.examOrder:
        return 'Exam Name';
    }
  }

  Widget _buildFilterButton({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.indigo),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(width: 4),
          const Icon(Icons.arrow_drop_down, size: 20),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Main content
  // ---------------------------------------------------------------------------

  Widget _buildContent(List<Exam> exams) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (exams.isEmpty) {
      return _buildEmptyState();
    }

    return _buildExamTable(exams);
  }

  // ---------------------------------------------------------------------------
  // Error state
  // ---------------------------------------------------------------------------

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 52, color: Colors.red.shade300),
          const SizedBox(height: 12),
          const Text(
            'Unable to load exams',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            _errorMessage ?? 'Something went wrong.',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Empty state
  // ---------------------------------------------------------------------------

  Widget _buildEmptyState() {
    final hasFilter = _selectedProgramId != null;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            hasFilter ? 'No exams found for this program' : 'No exams found',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 7),
          Text(
            hasFilter
                ? 'Try another program or clear the filter.'
                : 'Create your first exam to get started.',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 18),
          if (hasFilter)
            OutlinedButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(Icons.clear),
              label: const Text('Clear Filter'),
            )
          else
            ElevatedButton.icon(
              onPressed: _showAddExamDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Exam'),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Exam table
  // ---------------------------------------------------------------------------

  Widget _buildExamTable(List<Exam> exams) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Scrollbar(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: DataTable(
                headingRowHeight: 48,
                dataRowMinHeight: 62,
                dataRowMaxHeight: 76,
                horizontalMargin: 20,
                columnSpacing: 28,
                headingRowColor: WidgetStateProperty.all(
                  const Color(0xfff1f3f6),
                ),
                columns: const [
                  DataColumn(
                    label: Text(
                      'EXAM',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'PROGRAM',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'SUBJECTS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'QUESTIONS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'MARKS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'DURATION',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'PASS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'STATUS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'ACTION',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                rows: exams.map(_buildExamRow).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Exam row
  // ---------------------------------------------------------------------------

  Future<void> _showManageQuestionsDialog(Exam exam) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return ManageExamQuestionsDialog(
          exam: exam,
        );
      },
    );
  }

  DataRow _buildExamRow(Exam exam) {
    final program = _getProgram(exam.programId);

    final subjects = _getExamSubjects(exam);

    return DataRow(
      cells: [
        DataCell(
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 240),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.indigo.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    Icons.assignment_outlined,
                    size: 19,
                    color: Colors.indigo,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    exam.examName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Program
        DataCell(Text(program?.name ?? '—')),

        // Subjects
        DataCell(
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: subjects.isEmpty
                ? const Text('—')
                : Wrap(
                    spacing: 5,
                    runSpacing: 4,
                    children: subjects
                        .map(
                          (subject) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.indigo.withValues(alpha: 0.07),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              subject.name,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
        ),

        // Questions
        DataCell(
          Text(
            '${exam.questionCount}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),

        // Marks
        DataCell(Text('${exam.totalMarks}')),

        // Duration
        DataCell(Text('${exam.durationMinutes} min')),

        // Pass percentage
        DataCell(Text('${exam.passPercentage.toStringAsFixed(0)}%')),

        // Status
        DataCell(_buildStatus(exam.isActive)),

        // Actions
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Edit',
                onPressed: () => _showEditExamDialog(exam),
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 20,
                ),
              ),
              IconButton(
                tooltip: 'Manage Questions',
                onPressed: () => _showManageQuestionsDialog(exam),
                icon: const Icon(
                  Icons.playlist_add_check_outlined,
                  size: 20,
                ),
              ),
              IconButton(
                tooltip: exam.isActive ? 'Deactivate' : 'Activate',
                onPressed: () => _toggleExamStatus(exam),
                icon: Icon(
                  exam.isActive
                      ? Icons.toggle_on_outlined
                      : Icons.toggle_off_outlined,
                  size: 25,
                  color: exam.isActive ? Colors.green : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Status
  // ---------------------------------------------------------------------------

  Widget _buildStatus(bool isActive) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isActive ? Icons.check_circle_outline : Icons.cancel_outlined,
          size: 18,
          color: isActive ? Colors.green : Colors.grey,
        ),
        const SizedBox(width: 6),
        Text(
          isActive ? 'Active' : 'Inactive',
          style: TextStyle(
            color: isActive ? Colors.green.shade700 : Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Status toggle
  // ---------------------------------------------------------------------------

  Future<void> _toggleExamStatus(Exam exam) async {
    try {
      await _examService.updateExamStatus(
        examId: exam.examId,
        isActive: !exam.isActive,
      );

      if (!mounted) return;

      setState(() {
        final index = _exams.indexWhere((item) => item.examId == exam.examId);

        if (index != -1) {
          _exams[index] = exam.copyWith(isActive: !exam.isActive);
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            exam.isActive ? 'Exam deactivated.' : 'Exam activated.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update exam status.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
