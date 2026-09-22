import 'package:flutter/material.dart';
import 'package:questionbank/models/exam.dart';
import 'package:questionbank/models/program.dart';
import 'package:questionbank/models/subject.dart';
import 'package:questionbank/services/exam_service.dart';
import 'package:questionbank/services/program_service.dart';
import 'package:questionbank/services/subject_service.dart';

import 'examinee_exam_details_screen.dart';

class ExamineeDashboardScreen extends StatefulWidget {
  const ExamineeDashboardScreen({super.key});

  @override
  State<ExamineeDashboardScreen> createState() =>
      _ExamineeDashboardScreenState();
}

class _ExamineeDashboardScreenState extends State<ExamineeDashboardScreen> {
  final ExamService _examService = ExamService();
  final ProgramService _programService = ProgramService();
  final SubjectService _subjectService = SubjectService();

  bool _isLoading = true;
  String? _errorMessage;

  List<Exam> _exams = [];
  List<Program> _programs = [];
  List<Subject> _subjects = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _examService.getActiveExams(),
        _programService.getAllPrograms(),
        _subjectService.getAllSubjects(),
      ]);

      if (!mounted) return;

      setState(() {
        _exams = results[0] as List<Exam>;
        _programs = results[1] as List<Program>;
        _subjects = results[2] as List<Subject>;
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

  Program? _getProgram(String? programId) {
    if (programId == null || programId.isEmpty) {
      return null;
    }

    for (final program in _programs) {
      if (program.programId == programId) {
        return program;
      }
    }

    return null;
  }

  List<Subject> _getSubjects(Exam exam) {
    return _subjects
        .where((subject) => exam.subjectIds.contains(subject.subjectId))
        .toList();
  }

  String _formatSubjects(Exam exam) {
    final subjects = _getSubjects(exam);

    if (subjects.isEmpty) {
      return 'All subjects';
    }

    return subjects.map((subject) => subject.name).join(', ');
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) {
      return '$minutes min';
    }

    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;

    if (remainingMinutes == 0) {
      return '$hours hr';
    }

    return '$hours hr $remainingMinutes min';
  }

  void _openExamDetails(Exam exam) {
    final program = _getProgram(exam.programId);
    final subjects = _getSubjects(exam);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return ExamineeExamDetailsScreen(
            exam: exam,
            program: program,
            subjects: subjects,
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
      decoration: BoxDecoration(
        color: Colors.indigo.shade700,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.school_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Examinee Dashboard',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Choose an available exam and start your assessment.',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.indigo.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.indigo),
          ),
          const SizedBox(width: 13),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExamCard(Exam exam) {
    final program = _getProgram(exam.programId);
    final subjects = _getSubjects(exam);

    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.indigo.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.assignment_rounded,
                    color: Colors.indigo,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exam.examName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (program != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          program.name,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 15,
                        color: Colors.green,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'Active',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (exam.description.trim().isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                exam.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade700, height: 1.45),
              ),
            ],

            const SizedBox(height: 18),
            Divider(color: Colors.grey.shade200, height: 1),
            const SizedBox(height: 16),

            Wrap(
              spacing: 18,
              runSpacing: 12,
              children: [
                _buildExamInfo(
                  icon: Icons.quiz_outlined,
                  label: 'Questions',
                  value: '${exam.questionCount}',
                ),
                _buildExamInfo(
                  icon: Icons.star_outline_rounded,
                  label: 'Marks',
                  value: _formatMarks(exam.totalMarks),
                ),
                _buildExamInfo(
                  icon: Icons.timer_outlined,
                  label: 'Duration',
                  value: _formatDuration(exam.durationMinutes),
                ),
                _buildExamInfo(
                  icon: Icons.flag_outlined,
                  label: 'Pass',
                  value: '${_formatNumber(exam.passPercentage)}%',
                ),
              ],
            ),

            const SizedBox(height: 15),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.menu_book_outlined,
                  size: 17,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    subjects.isEmpty ? 'All subjects' : _formatSubjects(exam),
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _openExamDetails(exam),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Start Exam'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExamInfo({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17, color: Colors.indigo),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  String _formatMarks(double marks) {
    if (marks == marks.roundToDouble()) {
      return marks.toInt().toString();
    }

    return marks.toStringAsFixed(1);
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(1);
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
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
              'Unable to load available exams.',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'An unexpected error occurred.',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 55),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(
            Icons.assignment_late_outlined,
            size: 58,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          const Text(
            'No exams are currently available',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 7),
          Text(
            'Please check again later for available examinations.',
            style: TextStyle(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 20),

        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 700;

            if (isWide) {
              return Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      icon: Icons.assignment_rounded,
                      value: '${_exams.length}',
                      label: 'Available Exams',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSummaryCard(
                      icon: Icons.school_outlined,
                      value: '${_programs.length}',
                      label: 'Programs',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSummaryCard(
                      icon: Icons.menu_book_outlined,
                      value: '${_subjects.length}',
                      label: 'Subjects',
                    ),
                  ),
                ],
              );
            }

            return Column(
              children: [
                _buildSummaryCard(
                  icon: Icons.assignment_rounded,
                  value: '${_exams.length}',
                  label: 'Available Exams',
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        icon: Icons.school_outlined,
                        value: '${_programs.length}',
                        label: 'Programs',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryCard(
                        icon: Icons.menu_book_outlined,
                        value: '${_subjects.length}',
                        label: 'Subjects',
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 28),

        Row(
          children: [
            const Icon(Icons.assignment_outlined, color: Colors.indigo),
            const SizedBox(width: 9),
            const Text(
              'Available Exams',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.indigo.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_exams.length}',
                style: const TextStyle(
                  color: Colors.indigo,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        if (_exams.isEmpty)
          _buildEmptyState()
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 850;

              if (!isWide) {
                return Column(
                  children: _exams
                      .map(
                        (exam) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildExamCard(exam),
                        ),
                      )
                      .toList(),
                );
              }

              final cardWidth = (constraints.maxWidth - 16) / 2;

              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: _exams
                    .map(
                      (exam) => SizedBox(
                        width: cardWidth,
                        child: _buildExamCard(exam),
                      ),
                    )
                    .toList(),
              );
            },
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: _buildContent(),
          ),
        ),
      ),
    );
  }
}
