import 'package:flutter/material.dart';
import 'package:questionbank/models/question.dart';
import 'package:questionbank/models/program.dart';
import 'package:questionbank/models/subject.dart';
import 'package:questionbank/models/topic.dart';
import 'package:questionbank/services/question_service.dart';
import 'package:questionbank/services/program_service.dart';
import 'package:questionbank/services/subject_service.dart';
import 'package:questionbank/services/topic_service.dart';

import 'add_question_dialog.dart';
import 'edit_question_dialog.dart';

enum _QuestionSortOption {
  programOrder,
  subjectOrder,
  topicOrder,
  questionOrder,
}

class QuestionsScreen extends StatefulWidget {
  const QuestionsScreen({super.key});

  @override
  State<QuestionsScreen> createState() => _QuestionsScreenState();
}

class _QuestionsScreenState extends State<QuestionsScreen> {
  final QuestionService _questionService = QuestionService();
  final ProgramService _programService = ProgramService();
  final SubjectService _subjectService = SubjectService();
  final TopicService _topicService = TopicService();

  List<Question> _questions = [];
  List<Program> _programs = [];
  List<Subject> _subjects = [];
  List<Topic> _topics = [];

  bool _isLoading = true;
  String? _errorMessage;

  String? _selectedProgramId;
  String? _selectedSubjectId;
  String? _selectedTopicId;

  _QuestionSortOption _sortOption = _QuestionSortOption.programOrder;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  // ============================================================
  // LOAD DATA
  // ============================================================

  Future<void> _loadQuestions() async {
    try {
      final results = await Future.wait([
        _questionService.getAllQuestions(),
        _programService.getAllPrograms(),
        _subjectService.getAllSubjects(),
        _topicService.getAllTopics(),
      ]);

      final questions = results[0] as List<Question>;
      final programs = results[1] as List<Program>;
      final subjects = results[2] as List<Subject>;
      final topics = results[3] as List<Topic>;

      // Keep hierarchy in configured order.
      programs.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      subjects.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      topics.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      if (!mounted) {
        return;
      }

      setState(() {
        _questions = questions;
        _programs = programs;
        _subjects = subjects;
        _topics = topics;
        _isLoading = false;
        _errorMessage = null;

        // Make sure selected program still exists.
        if (_selectedProgramId != null &&
            !_programs.any(
              (program) => program.programId == _selectedProgramId,
            )) {
          _selectedProgramId = null;
          _selectedSubjectId = null;
          _selectedTopicId = null;
        }

        // Make sure selected subject is still available
        // under the selected program.
        if (_selectedSubjectId != null &&
            !_getAvailableSubjects().any(
              (subject) => subject.subjectId == _selectedSubjectId,
            )) {
          _selectedSubjectId = null;
          _selectedTopicId = null;
        }

        // Make sure selected topic is still available
        // under the selected subject.
        if (_selectedTopicId != null &&
            !_getAvailableTopics().any(
              (topic) => topic.topicId == _selectedTopicId,
            )) {
          _selectedTopicId = null;
        }
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  // ============================================================
  // LOOKUPS
  // ============================================================

  Program? _getProgram(String programId) {
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

  Topic? _getTopic(String topicId) {
    for (final topic in _topics) {
      if (topic.topicId == topicId) {
        return topic;
      }
    }

    return null;
  }

  String _getProgramName(String programId) {
    return _getProgram(programId)?.name ?? 'Unknown';
  }

  String _getSubjectName(String subjectId) {
    return _getSubject(subjectId)?.name ?? 'Unknown';
  }

  String _getTopicName(String topicId) {
    return _getTopic(topicId)?.name ?? 'Unknown';
  }

  // ============================================================
  // AVAILABLE SUBJECTS
  // ============================================================

  List<Subject> _getAvailableSubjects() {
    final subjects = _selectedProgramId == null
        ? List<Subject>.from(_subjects)
        : _subjects
              .where((subject) => subject.programId == _selectedProgramId)
              .toList();

    subjects.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return subjects;
  }

  // ============================================================
  // AVAILABLE TOPICS
  // ============================================================

  List<Topic> _getAvailableTopics() {
    List<Topic> topics;

    if (_selectedSubjectId != null) {
      // If a subject is selected, show only its topics.
      topics = _topics
          .where((topic) => topic.subjectId == _selectedSubjectId)
          .toList();
    } else if (_selectedProgramId != null) {
      // If only a program is selected, show topics belonging
      // to subjects under that program.
      final subjectIds = _subjects
          .where((subject) => subject.programId == _selectedProgramId)
          .map((subject) => subject.subjectId)
          .toSet();

      topics = _topics
          .where((topic) => subjectIds.contains(topic.subjectId))
          .toList();
    } else {
      // No program or subject selected.
      topics = List<Topic>.from(_topics);
    }

    topics.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return topics;
  }

  // ============================================================
  // FILTERING
  // ============================================================

  List<Question> _getFilteredQuestions() {
    return _questions.where((question) {
      // ----------------------------------------------------------
      // PROGRAM FILTER
      // ----------------------------------------------------------

      if (_selectedProgramId != null &&
          question.programId != _selectedProgramId) {
        return false;
      }

      // ----------------------------------------------------------
      // SUBJECT FILTER
      // ----------------------------------------------------------

      if (_selectedSubjectId != null &&
          question.subjectId != _selectedSubjectId) {
        return false;
      }

      // ----------------------------------------------------------
      // TOPIC FILTER
      // ----------------------------------------------------------

      if (_selectedTopicId != null && question.topicId != _selectedTopicId) {
        return false;
      }

      return true;
    }).toList();
  }

  // ============================================================
  // SORTING
  // ============================================================

  List<Question> _getFilteredAndSortedQuestions() {
    final questions = _getFilteredQuestions();

    questions.sort((a, b) {
      final programA = _getProgram(a.programId);
      final programB = _getProgram(b.programId);

      final subjectA = _getSubject(a.subjectId);
      final subjectB = _getSubject(b.subjectId);

      final topicA = _getTopic(a.topicId);
      final topicB = _getTopic(b.topicId);

      // ----------------------------------------------------------
      // PROGRAM ORDER
      // Program → Subject → Topic → Question
      // ----------------------------------------------------------

      if (_sortOption == _QuestionSortOption.programOrder) {
        final programOrderA = programA?.sortOrder ?? 999999;
        final programOrderB = programB?.sortOrder ?? 999999;

        final programComparison = programOrderA.compareTo(programOrderB);

        if (programComparison != 0) {
          return programComparison;
        }
      }

      // ----------------------------------------------------------
      // SUBJECT ORDER
      //
      // Program → Subject → Topic → Question
      //
      // OR
      //
      // Subject → Topic → Question
      // ----------------------------------------------------------

      if (_sortOption == _QuestionSortOption.programOrder ||
          _sortOption == _QuestionSortOption.subjectOrder) {
        final subjectOrderA = subjectA?.sortOrder ?? 999999;
        final subjectOrderB = subjectB?.sortOrder ?? 999999;

        final subjectComparison = subjectOrderA.compareTo(subjectOrderB);

        if (subjectComparison != 0) {
          return subjectComparison;
        }
      }

      // ----------------------------------------------------------
      // TOPIC ORDER
      //
      // Program → Subject → Topic → Question
      //
      // OR
      //
      // Subject → Topic → Question
      //
      // OR
      //
      // Topic → Question
      // ----------------------------------------------------------

      if (_sortOption == _QuestionSortOption.programOrder ||
          _sortOption == _QuestionSortOption.subjectOrder ||
          _sortOption == _QuestionSortOption.topicOrder) {
        final topicOrderA = topicA?.sortOrder ?? 999999;
        final topicOrderB = topicB?.sortOrder ?? 999999;

        final topicComparison = topicOrderA.compareTo(topicOrderB);

        if (topicComparison != 0) {
          return topicComparison;
        }
      }

      // ----------------------------------------------------------
      // QUESTION ORDER
      // ----------------------------------------------------------

      return a.questionDescription.toLowerCase().compareTo(
        b.questionDescription.toLowerCase(),
      );
    });

    return questions;
  }

  // ============================================================
  // FILTER LABELS
  // ============================================================

  String _getSelectedProgramLabel() {
    if (_selectedProgramId == null) {
      return 'All Programs';
    }

    return _getProgramName(_selectedProgramId!);
  }

  String _getSelectedSubjectLabel() {
    if (_selectedSubjectId == null) {
      return 'All Subjects';
    }

    return _getSubjectName(_selectedSubjectId!);
  }

  String _getSelectedTopicLabel() {
    if (_selectedTopicId == null) {
      return 'All Topics';
    }

    return _getTopicName(_selectedTopicId!);
  }

  String _getSortLabel() {
    switch (_sortOption) {
      case _QuestionSortOption.programOrder:
        return 'Program → Subject → Topic';

      case _QuestionSortOption.subjectOrder:
        return 'Subject → Topic';

      case _QuestionSortOption.topicOrder:
        return 'Topic → Question';

      case _QuestionSortOption.questionOrder:
        return 'Question';
    }
  }

  // ============================================================
  // FILTER ACTIONS
  // ============================================================

  void _changeProgramFilter(String value) {
    setState(() {
      _selectedProgramId = value.isEmpty ? null : value;

      // Program changed → reset dependent filters.
      _selectedSubjectId = null;
      _selectedTopicId = null;
    });
  }

  void _changeSubjectFilter(String value) {
    setState(() {
      _selectedSubjectId = value.isEmpty ? null : value;

      // Subject changed → reset topic filter.
      _selectedTopicId = null;
    });
  }

  void _changeTopicFilter(String value) {
    setState(() {
      _selectedTopicId = value.isEmpty ? null : value;
    });
  }

  void _changeSortOption(_QuestionSortOption option) {
    setState(() {
      _sortOption = option;
    });
  }

  // ============================================================
  // ADD QUESTION
  // ============================================================

  Future<void> _showAddQuestionDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AddQuestionDialog(
          programs: _programs,
          subjects: _subjects,
          topics: _topics,
        );
      },
    );

    if (result == true) {
      await _loadQuestions();
    }
  }

  // ============================================================
  // EDIT QUESTION
  // ============================================================

  Future<void> _showEditQuestionDialog(Question question) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return EditQuestionDialog(
          question: question,
          programs: _programs,
          subjects: _subjects,
          topics: _topics,
        );
      },
    );

    if (result == true) {
      await _loadQuestions();
    }
  }

  // ============================================================
  // QUESTION TYPE
  // ============================================================

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

  // ============================================================
  // DIFFICULTY
  // ============================================================

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

  // ============================================================
  // STATUS
  // ============================================================

  Widget _buildStatusCell(QuestionStatus status) {
    switch (status) {
      case QuestionStatus.approved:
        return const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, size: 18, color: Colors.green),
            SizedBox(width: 6),
            Text('Approved'),
          ],
        );

      case QuestionStatus.pending:
        return const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.pending_outlined, size: 18, color: Colors.orange),
            SizedBox(width: 6),
            Text('Pending'),
          ],
        );

      case QuestionStatus.rejected:
        return const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cancel_outlined, size: 18, color: Colors.red),
            SizedBox(width: 6),
            Text('Rejected'),
          ],
        );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Text(
          'Failed to load questions.\n$_errorMessage',
          textAlign: TextAlign.center,
        ),
      );
    }

    final questions = _getFilteredAndSortedQuestions();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ------------------------------------------------------
          // HEADER
          // ------------------------------------------------------
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.help_outline,
                  color: Colors.blue.shade900,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Questions',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Manage questions by program, subject and topic',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${questions.length} Questions',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _showAddQuestionDialog,
                icon: const Icon(Icons.add),
                label: const Text('Add Question'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ------------------------------------------------------
          // FILTER BAR
          // ------------------------------------------------------
          _buildFilterBar(),

          const SizedBox(height: 16),

          // ------------------------------------------------------
          // QUESTION TABLE
          // ------------------------------------------------------
          Expanded(
            child: Container(
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
                child: questions.isEmpty
                    ? _buildEmptyState()
                    : _buildQuestionsTable(questions),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FILTER BAR
  // ============================================================

  Widget _buildFilterBar() {
    final availableSubjects = _getAvailableSubjects();

    final availableTopics = _getAvailableTopics();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.filter_alt_outlined, color: Colors.blue.shade900),
          const SizedBox(width: 10),
          Text(
            'Filters & Sorting',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(width: 18),

          // ------------------------------------------------------
          // PROGRAM
          // ------------------------------------------------------
          PopupMenuButton<String>(
            tooltip: 'Filter by program',
            onSelected: _changeProgramFilter,
            itemBuilder: (context) {
              return [
                const PopupMenuItem<String>(
                  value: '',
                  child: Row(
                    children: [
                      Icon(Icons.all_inclusive, size: 20),
                      SizedBox(width: 10),
                      Text('All Programs'),
                    ],
                  ),
                ),
                ..._programs.map((program) {
                  return PopupMenuItem<String>(
                    value: program.programId,
                    child: Row(
                      children: [
                        Icon(
                          Icons.account_tree_outlined,
                          size: 20,
                          color: Colors.blue.shade900,
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            program.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ];
            },
            child: _buildFilterButton(
              Icons.account_tree_outlined,
              _getSelectedProgramLabel(),
            ),
          ),

          const SizedBox(width: 10),

          // ------------------------------------------------------
          // SUBJECT
          // ------------------------------------------------------
          PopupMenuButton<String>(
            tooltip: 'Filter by subject',
            onSelected: _changeSubjectFilter,
            itemBuilder: (context) {
              return [
                const PopupMenuItem<String>(
                  value: '',
                  child: Row(
                    children: [
                      Icon(Icons.all_inclusive, size: 20),
                      SizedBox(width: 10),
                      Text('All Subjects'),
                    ],
                  ),
                ),
                ...availableSubjects.map((subject) {
                  return PopupMenuItem<String>(
                    value: subject.subjectId,
                    child: Row(
                      children: [
                        Icon(
                          Icons.menu_book_outlined,
                          size: 20,
                          color: Colors.blue.shade900,
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            subject.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ];
            },
            child: _buildFilterButton(
              Icons.menu_book_outlined,
              _getSelectedSubjectLabel(),
            ),
          ),

          const SizedBox(width: 10),

          // ------------------------------------------------------
          // TOPIC
          // ------------------------------------------------------
          PopupMenuButton<String>(
            tooltip: 'Filter by topic',
            onSelected: _changeTopicFilter,
            itemBuilder: (context) {
              return [
                const PopupMenuItem<String>(
                  value: '',
                  child: Row(
                    children: [
                      Icon(Icons.all_inclusive, size: 20),
                      SizedBox(width: 10),
                      Text('All Topics'),
                    ],
                  ),
                ),
                ...availableTopics.map((topic) {
                  return PopupMenuItem<String>(
                    value: topic.topicId,
                    child: Row(
                      children: [
                        Icon(
                          Icons.topic_outlined,
                          size: 20,
                          color: Colors.blue.shade900,
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            topic.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ];
            },
            child: _buildFilterButton(
              Icons.topic_outlined,
              _getSelectedTopicLabel(),
            ),
          ),

          const Spacer(),

          // ------------------------------------------------------
          // SORT
          // ------------------------------------------------------
          PopupMenuButton<_QuestionSortOption>(
            tooltip: 'Sort questions',
            onSelected: _changeSortOption,
            itemBuilder: (context) {
              return [
                PopupMenuItem(
                  value: _QuestionSortOption.programOrder,
                  child: const Row(
                    children: [
                      Icon(Icons.account_tree_outlined, size: 20),
                      SizedBox(width: 10),
                      Text('Program → Subject → Topic'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: _QuestionSortOption.subjectOrder,
                  child: const Row(
                    children: [
                      Icon(Icons.menu_book_outlined, size: 20),
                      SizedBox(width: 10),
                      Text('Subject → Topic'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: _QuestionSortOption.topicOrder,
                  child: const Row(
                    children: [
                      Icon(Icons.topic_outlined, size: 20),
                      SizedBox(width: 10),
                      Text('Topic → Question'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: _QuestionSortOption.questionOrder,
                  child: const Row(
                    children: [
                      Icon(Icons.sort, size: 20),
                      SizedBox(width: 10),
                      Text('Question'),
                    ],
                  ),
                ),
              ];
            },
            child: _buildFilterButton(Icons.sort, _getSortLabel()),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FILTER BUTTON
  // ============================================================

  Widget _buildFilterButton(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.blue.shade900),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 210),
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.arrow_drop_down, size: 20),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    final hasFilter =
        _selectedProgramId != null ||
        _selectedSubjectId != null ||
        _selectedTopicId != null;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasFilter ? Icons.filter_alt_off_outlined : Icons.help_outline,
            size: 52,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            hasFilter
                ? 'No questions found for the selected filter.'
                : 'No questions found.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          if (hasFilter) ...[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _selectedProgramId = null;
                  _selectedSubjectId = null;
                  _selectedTopicId = null;
                });
              },
              icon: const Icon(Icons.clear),
              label: const Text('Clear Filters'),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // QUESTION TABLE
  // ============================================================

  Widget _buildQuestionsTable(List<Question> questions) {
    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStatePropertyAll(Colors.grey.shade50),
          columns: const [
            DataColumn(label: Text('Question')),
            DataColumn(label: Text('Program')),
            DataColumn(label: Text('Subject')),
            DataColumn(label: Text('Topic')),
            DataColumn(label: Text('Type')),
            DataColumn(label: Text('Difficulty')),
            DataColumn(label: Text('Marks')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Action')),
          ],
          rows: questions.map((question) {
            return DataRow(
              cells: [
                DataCell(
                  SizedBox(
                    width: 300,
                    child: Text(
                      question.questionDescription,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(Text(_getProgramName(question.programId))),
                DataCell(Text(_getSubjectName(question.subjectId))),
                DataCell(Text(_getTopicName(question.topicId))),
                DataCell(Text(_getQuestionTypeLabel(question.questionType))),
                DataCell(Text(_getDifficultyLabel(question.difficulty))),
                DataCell(Text(question.marks.toString())),
                DataCell(_buildStatusCell(question.status)),
                DataCell(
                  IconButton(
                    tooltip: 'Edit',
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () {
                      _showEditQuestionDialog(question);
                    },
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
