import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:questionbank/services/user_service.dart';
import 'package:questionbank/services/program_service.dart';
import 'package:questionbank/services/subject_service.dart';
import 'package:questionbank/models/exam_result.dart';
import 'package:questionbank/models/app_user.dart';
import 'package:questionbank/models/program.dart';
import 'package:questionbank/models/subject.dart';
import 'package:questionbank/models/exam_question_result.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final UserService _userService = UserService();
  final ProgramService _programService = ProgramService();
  final SubjectService _subjectService = SubjectService();

  List<ExamResult> _results = [];
  List<AppUser> _users = [];
  List<Program> _programs = [];
  List<Subject> _subjects = [];

  // Stores programId and subjectId directly from
  // the corresponding examResults Firestore document.
  final Map<String, String> _resultProgramIds = {};
  final Map<String, String> _resultSubjectIds = {};

  bool _isLoading = true;
  String? _errorMessage;

  String _statusFilter = 'All';
  String _sortOrder = 'Newest';
  String _searchText = '';

  String _programFilter = 'All';
  String _subjectFilter = 'All';

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
      final resultsSnapshot = await _firestore
          .collection('examResults')
          .orderBy(
        'createdAt',
        descending: true,
      )
          .get();

      final users = await _userService.getAllUsers();

      final programs =
      await _programService.getAllPrograms();

      final subjects =
      await _subjectService.getAllSubjects();

      final results = resultsSnapshot.docs
          .map(
            (document) => ExamResult.fromMap(
          document.data(),
        ),
      )
          .toList();

      _resultProgramIds.clear();
      _resultSubjectIds.clear();

      for (final document in resultsSnapshot.docs) {
        final data = document.data();

        final resultId =
            data['resultId'] as String? ??
                document.id;

        final programId =
        data['programId'] as String?;

        final subjectId =
        data['subjectId'] as String?;

        if (programId != null &&
            programId.isNotEmpty) {
          _resultProgramIds[resultId] =
              programId;
        }

        if (subjectId != null &&
            subjectId.isNotEmpty) {
          _resultSubjectIds[resultId] =
              subjectId;
        }
      }

      if (!mounted) return;

      setState(() {
        _results = results;
        _users = users;
        _programs = programs;
        _subjects = subjects;
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

  AppUser? _findUser(String userId) {
    for (final user in _users) {
      if (user.userId == userId) {
        return user;
      }
    }

    return null;
  }

  Program? _findProgram(String programId) {
    for (final program in _programs) {
      if (program.programId == programId) {
        return program;
      }
    }

    return null;
  }

  Subject? _findSubject(String subjectId) {
    for (final subject in _subjects) {
      if (subject.subjectId == subjectId) {
        return subject;
      }
    }

    return null;
  }

  List<Subject> get _filteredSubjects {
    if (_programFilter == 'All') {
      return _subjects;
    }

    return _subjects
        .where(
          (subject) =>
      subject.programId == _programFilter,
    )
        .toList();
  }

  List<ExamResult> get _filteredResults {
    var results =
    List<ExamResult>.from(_results);

    // Program filter
    if (_programFilter != 'All') {
      results = results.where((result) {
        final programId =
        _resultProgramIds[result.resultId];

        return programId == _programFilter;
      }).toList();
    }

    // Subject filter
    if (_subjectFilter != 'All') {
      results = results.where((result) {
        final subjectId =
        _resultSubjectIds[result.resultId];

        return subjectId == _subjectFilter;
      }).toList();
    }

    // Status filter
    if (_statusFilter == 'Passed') {
      results = results
          .where(
            (result) => result.passed,
      )
          .toList();
    } else if (_statusFilter == 'Failed') {
      results = results
          .where(
            (result) => !result.passed,
      )
          .toList();
    }

    // Search
    final search =
    _searchText.trim().toLowerCase();

    if (search.isNotEmpty) {
      results = results.where((result) {
        final user =
        _findUser(result.userId);

        final name =
            user?.displayName.toLowerCase() ??
                '';

        final username =
            user?.username.toLowerCase() ??
                '';

        final email =
            user?.email.toLowerCase() ??
                '';

        final examId =
        result.examId.toLowerCase();

        final resultId =
        result.resultId.toLowerCase();

        return name.contains(search) ||
            username.contains(search) ||
            email.contains(search) ||
            examId.contains(search) ||
            resultId.contains(search);
      }).toList();
    }

    // Sort
    results.sort(
          (a, b) {
        if (_sortOrder == 'Newest') {
          return b.createdAt.compareTo(
            a.createdAt,
          );
        }

        return a.createdAt.compareTo(
          b.createdAt,
        );
      },
    );

    return results;
  }

  int get _passedCount {
    return _results
        .where(
          (result) => result.passed,
    )
        .length;
  }

  int get _failedCount {
    return _results
        .where(
          (result) => !result.passed,
    )
        .length;
  }

  double get _averagePercentage {
    if (_results.isEmpty) {
      return 0;
    }

    final total = _results.fold<double>(
      0,
          (sum, result) =>
      sum + result.percentage,
    );

    return total / _results.length;
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'Not available';
    }

    final day =
    date.day.toString().padLeft(2, '0');

    final month =
    date.month.toString().padLeft(2, '0');

    final year =
    date.year.toString();

    return '$day/$month/$year';
  }

  String _formatDateTime(DateTime? date) {
    if (date == null) {
      return 'Not available';
    }

    final day =
    date.day.toString().padLeft(2, '0');

    final month =
    date.month.toString().padLeft(2, '0');

    final year =
    date.year.toString();

    final hour =
    date.hour.toString().padLeft(2, '0');

    final minute =
    date.minute.toString().padLeft(2, '0');

    return '$day/$month/$year $hour:$minute';
  }

  String _submissionTypeText(dynamic value) {
    if (value == null) {
      return 'Not available';
    }

    final text =
        value.toString().split('.').last;

    switch (text) {
      case 'automatic':
        return 'Automatic';

      case 'manual':
        return 'Manual';

      case 'hybrid':
        return 'Hybrid';

      default:
        return text;
    }
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor:
              color.withOpacity(0.12),
              child: Icon(
                icon,
                color: color,
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
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding:
      const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 17,
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionResult(
      ExamQuestionResult questionResult,
      ) {
    final assessmentStatus =
        questionResult.assessmentStatus
            .toString()
            .split('.')
            .last;

    final statusText =
    assessmentStatus == 'pending'
        ? 'Pending assessment'
        : assessmentStatus == 'assessed'
        ? 'Assessed'
        : assessmentStatus;

    return Container(
      margin:
      const EdgeInsets.only(top: 8),
      padding:
      const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey.shade300,
        ),
        borderRadius:
        BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Text(
            'Question: '
                '${questionResult.questionId}',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              Text(
                'Maximum: '
                    '${questionResult.maximumMarks}',
              ),
              Text(
                'Awarded: '
                    '${questionResult.awardedMarks}',
              ),
              Text(
                questionResult.correct
                    ? 'Correct'
                    : 'Incorrect',
                style: TextStyle(
                  color:
                  questionResult.correct
                      ? Colors.green
                      : Colors.red,
                  fontWeight:
                  FontWeight.w600,
                ),
              ),
              Text(
                questionResult.answered
                    ? 'Answered'
                    : 'Unanswered',
              ),
            ],
          ),
          if (questionResult.writtenAnswer !=
              null &&
              questionResult.writtenAnswer!
                  .trim()
                  .isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text(
              'Written answer:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              questionResult.writtenAnswer!,
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'Assessment: $statusText',
            style: TextStyle(
              color: assessmentStatus ==
                  'pending'
                  ? Colors.orange
                  : Colors.green,
              fontWeight:
              FontWeight.w600,
            ),
          ),
          if (questionResult.feedback !=
              null &&
              questionResult.feedback!
                  .trim()
                  .isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Feedback: '
                  '${questionResult.feedback}',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultCard(
      ExamResult result,
      ) {
    final user =
    _findUser(result.userId);

    final programId =
    _resultProgramIds[result.resultId];

    final subjectId =
    _resultSubjectIds[result.resultId];

    final program = programId == null
        ? null
        : _findProgram(programId);

    final subject = subjectId == null
        ? null
        : _findSubject(subjectId);

    final displayName =
    user?.displayName
        .trim()
        .isNotEmpty ==
        true
        ? user!.displayName.trim()
        : user?.username
        .trim()
        .isNotEmpty ==
        true
        ? user!.username.trim()
        : 'Unknown user';

    final phone =
    user?.mobileNumber
        ?.trim()
        .isNotEmpty ==
        true
        ? user!.mobileNumber!.trim()
        : 'Not available';

    final email =
    user?.email.trim().isNotEmpty ==
        true
        ? user!.email.trim()
        : 'Not available';

    final statusColor =
    result.passed
        ? Colors.green
        : Colors.red;

    return Card(
      elevation: 2,
      margin:
      const EdgeInsets.only(bottom: 14),
      child: ExpansionTile(
        tilePadding:
        const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 6,
        ),
        childrenPadding:
        const EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16,
        ),
        title: Text(
          displayName,
          style: const TextStyle(
            fontWeight:
            FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Padding(
          padding:
          const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                'Exam ID: '
                    '${result.examId}',
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (program != null)
                    Chip(
                      avatar: const Icon(
                        Icons.school_outlined,
                        size: 16,
                      ),
                      label: Text(
                        program.name,
                      ),
                    ),
                  if (subject != null)
                    Chip(
                      avatar: const Icon(
                        Icons.menu_book_outlined,
                        size: 16,
                      ),
                      label: Text(
                        subject.name,
                      ),
                    ),
                  Container(
                    padding:
                    const EdgeInsets
                        .symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration:
                    BoxDecoration(
                      color: statusColor
                          .withOpacity(0.12),
                      borderRadius:
                      BorderRadius.circular(
                        20,
                      ),
                    ),
                    child: Text(
                      result.passed
                          ? 'Passed'
                          : 'Failed',
                      style: TextStyle(
                        color:
                        statusColor,
                        fontWeight:
                        FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Text(
                    '${result.percentage.toStringAsFixed(2)}%',
                  ),
                  Text(
                    'Score: '
                        '${result.score}',
                  ),
                ],
              ),
            ],
          ),
        ),
        trailing: Text(
          _formatDate(result.createdAt),
          style: const TextStyle(
            fontSize: 12,
          ),
        ),
        children: [
          const Divider(),

          Align(
            alignment:
            Alignment.centerLeft,
            child: Text(
              'Examinee Information',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(
                fontWeight:
                FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 10),

          _buildInfoRow(
            icon: Icons.person_outline,
            label: 'Name',
            value: displayName,
          ),

          _buildInfoRow(
            icon: Icons.phone_outlined,
            label: 'Phone',
            value: phone,
          ),

          _buildInfoRow(
            icon: Icons.email_outlined,
            label: 'Email',
            value: email,
          ),

          if (program != null)
            _buildInfoRow(
              icon:
              Icons.school_outlined,
              label: 'Program',
              value: program.name,
            ),

          if (subject != null)
            _buildInfoRow(
              icon:
              Icons.menu_book_outlined,
              label: 'Subject',
              value: subject.name,
            ),

          const SizedBox(height: 10),

          Align(
            alignment:
            Alignment.centerLeft,
            child: Text(
              'Result Information',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(
                fontWeight:
                FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 10),

          _buildInfoRow(
            icon: Icons.quiz_outlined,
            label: 'Total Questions',
            value:
            '${result.totalQuestions}',
          ),

          _buildInfoRow(
            icon: Icons.edit_outlined,
            label: 'Answered',
            value:
            '${result.answeredQuestions}',
          ),

          _buildInfoRow(
            icon:
            Icons.remove_circle_outline,
            label: 'Unanswered',
            value:
            '${result.unansweredQuestions}',
          ),

          _buildInfoRow(
            icon:
            Icons.check_circle_outline,
            label: 'Correct',
            value:
            '${result.correctAnswers}',
          ),

          _buildInfoRow(
            icon: Icons.cancel_outlined,
            label: 'Wrong',
            value:
            '${result.wrongAnswers}',
          ),

          _buildInfoRow(
            icon: Icons.score_outlined,
            label: 'Total Marks',
            value:
            '${result.totalMarks}',
          ),

          _buildInfoRow(
            icon: Icons.star_outline,
            label: 'Score',
            value:
            '${result.score}',
          ),

          _buildInfoRow(
            icon: Icons.percent,
            label: 'Percentage',
            value:
            '${result.percentage.toStringAsFixed(2)}%',
          ),

          _buildInfoRow(
            icon: Icons.rule_outlined,
            label: 'Pass Percentage',
            value:
            '${result.passPercentage}%',
          ),

          _buildInfoRow(
            icon:
            Icons.assessment_outlined,
            label: 'Submission Type',
            value:
            _submissionTypeText(
              result.submissionType,
            ),
          ),

          _buildInfoRow(
            icon:
            Icons.play_circle_outline,
            label: 'Started',
            value:
            _formatDateTime(
              result.startedAt,
            ),
          ),

          _buildInfoRow(
            icon:
            Icons.check_circle_outline,
            label: 'Completed',
            value:
            _formatDateTime(
              result.completedAt,
            ),
          ),

          const SizedBox(height: 12),

          if (result.questionResults
              .isNotEmpty) ...[
            Align(
              alignment:
              Alignment.centerLeft,
              child: Text(
                'Question Details',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 4),
            ...result.questionResults.map(
              _buildQuestionResult,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).dividerColor,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // First row: Search, Status, Sort, Refresh
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Search results',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchText = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _statusFilter,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'All',
                        child: Text('All'),
                      ),
                      DropdownMenuItem(
                        value: 'Passed',
                        child: Text('Passed'),
                      ),
                      DropdownMenuItem(
                        value: 'Failed',
                        child: Text('Failed'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;

                      setState(() {
                        _statusFilter = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _sortOrder,
                    decoration: const InputDecoration(
                      labelText: 'Sort',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Newest',
                        child: Text('Newest'),
                      ),
                      DropdownMenuItem(
                        value: 'Oldest',
                        child: Text('Oldest'),
                      ),
                      DropdownMenuItem(
                        value: 'Highest Score',
                        child: Text('Highest Score'),
                      ),
                      DropdownMenuItem(
                        value: 'Lowest Score',
                        child: Text('Lowest Score'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;

                      setState(() {
                        _sortOrder = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),

                IconButton(
                  tooltip: 'Refresh',
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadData,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Second row: Programs and Subjects
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _programFilter,
                    decoration: const InputDecoration(
                      labelText: 'Programs',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: 'All',
                        child: Text('All Programs'),
                      ),
                      ..._programs.map(
                            (program) => DropdownMenuItem<String>(
                          value: program.programId,
                          child: Text(
                            program.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;

                      setState(() {
                        _programFilter = value;

                        // Reset subject when selected subject
                        // does not belong to the selected program.
                        if (_subjectFilter != 'All') {
                          final subject = _subjects.firstWhere(
                                (item) =>
                            item.subjectId == _subjectFilter,
                            orElse: () => _subjects.first,
                          );

                          if (subject.programId != value &&
                              value != 'All') {
                            _subjectFilter = 'All';
                          }
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _subjectFilter,
                    decoration: const InputDecoration(
                      labelText: 'Subjects',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: 'All',
                        child: Text('All Subjects'),
                      ),
                      ..._filteredSubjects.map(
                            (subject) => DropdownMenuItem<String>(
                          value: subject.subjectId,
                          child: Text(
                            subject.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;

                      setState(() {
                        _subjectFilter = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final results =
        _filteredResults;

    return Scaffold(
      appBar: AppBar(
        title:
        const Text('Exam Results'),
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
            24,
          ),
          child: Column(
            mainAxisSize:
            MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red,
              ),
              const SizedBox(
                height: 12,
              ),
              Text(
                _errorMessage!,
                textAlign:
                TextAlign.center,
              ),
              const SizedBox(
                height: 16,
              ),
              FilledButton.icon(
                onPressed:
                _loadData,
                icon:
                const Icon(
                  Icons.refresh,
                ),
                label:
                const Text(
                  'Try Again',
                ),
              ),
            ],
          ),
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadData,
        child: LayoutBuilder(
          builder:
              (context, constraints) {
            final isWide =
                constraints
                    .maxWidth >=
                    900;

            return SingleChildScrollView(
              physics:
              const AlwaysScrollableScrollPhysics(),
              padding:
              const EdgeInsets.all(
                16,
              ),
              child: Center(
                child:
                ConstrainedBox(
                  constraints:
                  const BoxConstraints(
                    maxWidth: 1200,
                  ),
                  child:
                  Column(
                    crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                    children: [
                      if (isWide)
                        Row(
                          children: [
                            Expanded(
                              child:
                              _buildSummaryCard(
                                title:
                                'Total Results',
                                value:
                                '${_results.length}',
                                icon:
                                Icons.assessment_outlined,
                                color:
                                Colors.blue,
                              ),
                            ),
                            const SizedBox(
                              width: 12,
                            ),
                            Expanded(
                              child:
                              _buildSummaryCard(
                                title:
                                'Passed',
                                value:
                                '$_passedCount',
                                icon:
                                Icons.check_circle_outline,
                                color:
                                Colors.green,
                              ),
                            ),
                            const SizedBox(
                              width: 12,
                            ),
                            Expanded(
                              child:
                              _buildSummaryCard(
                                title:
                                'Failed',
                                value:
                                '$_failedCount',
                                icon:
                                Icons.cancel_outlined,
                                color:
                                Colors.red,
                              ),
                            ),
                            const SizedBox(
                              width: 12,
                            ),
                            Expanded(
                              child:
                              _buildSummaryCard(
                                title:
                                'Average',
                                value:
                                '${_averagePercentage.toStringAsFixed(2)}%',
                                icon:
                                Icons.percent,
                                color:
                                Colors.orange,
                              ),
                            ),
                          ],
                        )
                      else
                        Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child:
                                  _buildSummaryCard(
                                    title:
                                    'Total Results',
                                    value:
                                    '${_results.length}',
                                    icon:
                                    Icons.assessment_outlined,
                                    color:
                                    Colors.blue,
                                  ),
                                ),
                                const SizedBox(
                                  width: 12,
                                ),
                                Expanded(
                                  child:
                                  _buildSummaryCard(
                                    title:
                                    'Passed',
                                    value:
                                    '$_passedCount',
                                    icon:
                                    Icons.check_circle_outline,
                                    color:
                                    Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(
                              height: 12,
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child:
                                  _buildSummaryCard(
                                    title:
                                    'Failed',
                                    value:
                                    '$_failedCount',
                                    icon:
                                    Icons.cancel_outlined,
                                    color:
                                    Colors.red,
                                  ),
                                ),
                                const SizedBox(
                                  width: 12,
                                ),
                                Expanded(
                                  child:
                                  _buildSummaryCard(
                                    title:
                                    'Average',
                                    value:
                                    '${_averagePercentage.toStringAsFixed(2)}%',
                                    icon:
                                    Icons.percent,
                                    color:
                                    Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                      const SizedBox(
                        height: 20,
                      ),

                      _buildFilters(),

                      const SizedBox(
                        height: 20,
                      ),

                      if (results.isEmpty)
                        Card(
                          child:
                          Padding(
                            padding:
                            const EdgeInsets
                                .all(
                              32,
                            ),
                            child:
                            Center(
                              child:
                              Column(
                                children: [
                                  Icon(
                                    Icons
                                        .assessment_outlined,
                                    size:
                                    48,
                                    color: Colors
                                        .grey
                                        .shade500,
                                  ),
                                  const SizedBox(
                                    height:
                                    12,
                                  ),
                                  const Text(
                                    'No results found.',
                                    style:
                                    TextStyle(
                                      fontSize:
                                      16,
                                      fontWeight:
                                      FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      else
                        ...results.map(
                          _buildResultCard,
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}