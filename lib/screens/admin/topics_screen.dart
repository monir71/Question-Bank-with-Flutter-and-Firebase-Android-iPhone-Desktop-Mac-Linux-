import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:questionbank/models/program.dart';
import 'package:questionbank/models/subject.dart';
import 'package:questionbank/models/topic.dart';
import 'package:questionbank/services/program_service.dart';
import 'package:questionbank/services/subject_service.dart';
import 'package:questionbank/services/topic_service.dart';

import 'add_topic_dialog.dart';
import 'edit_topic_dialog.dart';

enum _TopicSortOption { programOrder, subjectOrder, topicOrder }

class TopicsScreen extends StatefulWidget {
  const TopicsScreen({super.key});

  @override
  State<TopicsScreen> createState() => _TopicsScreenState();
}

class _TopicsScreenState extends State<TopicsScreen> {
  final TopicService _topicService = TopicService();
  final SubjectService _subjectService = SubjectService();
  final ProgramService _programService = ProgramService();

  List<Topic> _topics = [];
  List<Subject> _subjects = [];
  List<Program> _programs = [];

  bool _isLoading = true;
  String? _errorMessage;

  String? _selectedProgramId;
  String? _selectedSubjectId;

  _TopicSortOption _sortOption = _TopicSortOption.programOrder;

  @override
  void initState() {
    super.initState();
    _loadTopics();
  }

  // ============================================================
  // LOAD DATA
  // ============================================================

  Future<void> _loadTopics() async {
    try {
      final results = await Future.wait([
        _topicService.getAllTopics(),
        _subjectService.getAllSubjects(),
        _programService.getAllPrograms(),
      ]);

      final topics = results[0] as List<Topic>;
      final subjects = results[1] as List<Subject>;
      final programs = results[2] as List<Program>;

      // Keep programs in their configured order.
      programs.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      // Keep subjects in their configured order.
      subjects.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      if (!mounted) {
        return;
      }

      setState(() {
        _topics = topics;
        _subjects = subjects;
        _programs = programs;
        _isLoading = false;
        _errorMessage = null;

        // Make sure the selected program still exists.
        if (_selectedProgramId != null &&
            !_programs.any(
              (program) => program.programId == _selectedProgramId,
            )) {
          _selectedProgramId = null;
          _selectedSubjectId = null;
        }

        // Make sure the selected subject still belongs
        // to the selected program.
        if (_selectedSubjectId != null &&
            !_getAvailableSubjects().any(
              (subject) => subject.subjectId == _selectedSubjectId,
            )) {
          _selectedSubjectId = null;
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

  Subject? _getSubject(String subjectId) {
    for (final subject in _subjects) {
      if (subject.subjectId == subjectId) {
        return subject;
      }
    }

    return null;
  }

  Program? _getProgram(String programId) {
    for (final program in _programs) {
      if (program.programId == programId) {
        return program;
      }
    }

    return null;
  }

  // IMPORTANT:
  // Topic -> Subject -> Program
  //
  // Topic does not directly contain programId.
  Program? _getProgramForTopic(Topic topic) {
    final subject = _getSubject(topic.subjectId);

    if (subject == null) {
      return null;
    }

    return _getProgram(subject.programId);
  }

  String _getProgramName(String programId) {
    return _getProgram(programId)?.name ?? 'Unknown';
  }

  String _getSubjectName(String subjectId) {
    return _getSubject(subjectId)?.name ?? 'Unknown';
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
  // FILTERING + SORTING
  // ============================================================

  List<Topic> _getFilteredAndSortedTopics() {
    final filteredTopics = _topics.where((topic) {
      final subject = _getSubject(topic.subjectId);

      // A topic without a valid subject cannot be displayed
      // correctly in the hierarchy.
      if (subject == null) {
        return false;
      }

      // ----------------------------------------------------------
      // PROGRAM FILTER
      // ----------------------------------------------------------

      if (_selectedProgramId != null &&
          subject.programId != _selectedProgramId) {
        return false;
      }

      // ----------------------------------------------------------
      // SUBJECT FILTER
      // ----------------------------------------------------------

      if (_selectedSubjectId != null && topic.subjectId != _selectedSubjectId) {
        return false;
      }

      return true;
    }).toList();

    filteredTopics.sort((a, b) {
      final subjectA = _getSubject(a.subjectId);
      final subjectB = _getSubject(b.subjectId);

      // ----------------------------------------------------------
      // PROGRAM ORDER
      // Program → Subject → Topic
      // ----------------------------------------------------------

      if (_sortOption == _TopicSortOption.programOrder) {
        final programA = subjectA == null
            ? null
            : _getProgram(subjectA.programId);

        final programB = subjectB == null
            ? null
            : _getProgram(subjectB.programId);

        final programOrderA = programA?.sortOrder ?? 999999;
        final programOrderB = programB?.sortOrder ?? 999999;

        final programComparison = programOrderA.compareTo(programOrderB);

        if (programComparison != 0) {
          return programComparison;
        }
      }

      // ----------------------------------------------------------
      // SUBJECT ORDER
      // Program → Subject → Topic
      //
      // OR
      //
      // Subject → Topic
      // ----------------------------------------------------------

      if (_sortOption == _TopicSortOption.programOrder ||
          _sortOption == _TopicSortOption.subjectOrder) {
        final subjectOrderA = subjectA?.sortOrder ?? 999999;
        final subjectOrderB = subjectB?.sortOrder ?? 999999;

        final subjectComparison = subjectOrderA.compareTo(subjectOrderB);

        if (subjectComparison != 0) {
          return subjectComparison;
        }
      }

      // ----------------------------------------------------------
      // TOPIC ORDER
      // ----------------------------------------------------------

      final topicOrderComparison = a.sortOrder.compareTo(b.sortOrder);

      if (topicOrderComparison != 0) {
        return topicOrderComparison;
      }

      // Final alphabetical fallback.
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return filteredTopics;
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

  String _getSortLabel() {
    switch (_sortOption) {
      case _TopicSortOption.programOrder:
        return 'Program → Subject → Topic';

      case _TopicSortOption.subjectOrder:
        return 'Subject → Topic';

      case _TopicSortOption.topicOrder:
        return 'Topic Order';
    }
  }

  // ============================================================
  // FILTER ACTIONS
  // ============================================================

  void _changeProgramFilter(String value) {
    setState(() {
      _selectedProgramId = value.isEmpty ? null : value;

      // Selecting another program resets the subject filter.
      _selectedSubjectId = null;
    });
  }

  void _changeSubjectFilter(String value) {
    setState(() {
      _selectedSubjectId = value.isEmpty ? null : value;
    });
  }

  void _changeSortOption(_TopicSortOption option) {
    setState(() {
      _sortOption = option;
    });
  }

  // ============================================================
  // ADD TOPIC
  // ============================================================

  Future<void> _showAddTopicDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return AddTopicDialog(subjects: _subjects);
      },
    );

    if (result == null) {
      return;
    }

    final topicId = FirebaseFirestore.instance.collection('topics').doc().id;

    final topic = Topic(
      topicId: topicId,
      subjectId: result['subjectId'] as String,
      name: result['name'] as String,
      isActive: true,
      sortOrder: result['sortOrder'] as int,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await _topicService.createTopic(topic);

      await _loadTopics();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Topic created successfully.')),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to create topic: $e')));
    }
  }

  // ============================================================
  // EDIT TOPIC
  // ============================================================

  Future<void> _showEditTopicDialog(Topic topic) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return EditTopicDialog(topic: topic, subjects: _subjects);
      },
    );

    if (result == null) {
      return;
    }

    final updatedTopic = Topic(
      topicId: topic.topicId,
      subjectId: result['subjectId'] as String,
      name: result['name'] as String,
      isActive: topic.isActive,
      sortOrder: result['sortOrder'] as int,
      createdAt: topic.createdAt,
      updatedAt: DateTime.now(),
    );

    try {
      await _topicService.updateTopic(updatedTopic);

      await _loadTopics();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Topic updated successfully.')),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update topic: $e')));
    }
  }

  // ============================================================
  // TOGGLE STATUS
  // ============================================================

  Future<void> _toggleTopicStatus(Topic topic) async {
    final newStatus = !topic.isActive;

    try {
      await _topicService.updateTopicStatus(
        topicId: topic.topicId,
        isActive: newStatus,
      );

      await _loadTopics();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus
                ? 'Topic activated successfully.'
                : 'Topic deactivated successfully.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update topic status: $e')),
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final filteredTopics = _getFilteredAndSortedTopics();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.topic_outlined,
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
                      'Topics',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Manage topics under subjects',
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
                  '${filteredTopics.length} Topics',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _showAddTopicDialog,
                icon: const Icon(Icons.add),
                label: const Text('Add Topic'),
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
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  // ============================================================
  // CONTENT
  // ============================================================

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    return _buildTopicsList();
  }

  // ============================================================
  // ERROR STATE
  // ============================================================

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
          const SizedBox(height: 12),
          const Text(
            'Failed to load topics.',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            _errorMessage ?? '',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _loadTopics,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TOPICS LIST
  // ============================================================

  Widget _buildTopicsList() {
    final filteredTopics = _getFilteredAndSortedTopics();

    return Column(
      children: [
        _buildFilterBar(),
        const SizedBox(height: 16),
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
              child: Column(
                children: [
                  _buildHeader(),
                  const Divider(height: 1),
                  Expanded(
                    child: filteredTopics.isEmpty
                        ? _buildEmptyFilteredState()
                        : ListView.separated(
                            itemCount: filteredTopics.length,
                            separatorBuilder: (context, index) =>
                                Divider(height: 1, color: Colors.grey.shade200),
                            itemBuilder: (context, index) {
                              return _buildTopicRow(filteredTopics[index]);
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // FILTER BAR
  // ============================================================

  Widget _buildFilterBar() {
    final availableSubjects = _getAvailableSubjects();

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
          // PROGRAM FILTER
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
          // SUBJECT FILTER
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

          const Spacer(),

          // ------------------------------------------------------
          // SORT
          // ------------------------------------------------------
          PopupMenuButton<_TopicSortOption>(
            tooltip: 'Sort topics',
            onSelected: _changeSortOption,
            itemBuilder: (context) {
              return [
                PopupMenuItem(
                  value: _TopicSortOption.programOrder,
                  child: const Row(
                    children: [
                      Icon(Icons.account_tree_outlined, size: 20),
                      SizedBox(width: 10),
                      Text('Program → Subject → Topic'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: _TopicSortOption.subjectOrder,
                  child: const Row(
                    children: [
                      Icon(Icons.menu_book_outlined, size: 20),
                      SizedBox(width: 10),
                      Text('Subject → Topic'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: _TopicSortOption.topicOrder,
                  child: const Row(
                    children: [
                      Icon(Icons.sort, size: 20),
                      SizedBox(width: 10),
                      Text('Topic Order'),
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
            constraints: const BoxConstraints(maxWidth: 220),
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

  Widget _buildEmptyFilteredState() {
    final hasFilter = _selectedProgramId != null || _selectedSubjectId != null;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasFilter ? Icons.filter_alt_off_outlined : Icons.topic_outlined,
            size: 52,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            hasFilter
                ? 'No topics found for the selected filter.'
                : 'No topics found.',
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
  // TABLE HEADER
  // ============================================================

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      color: Colors.grey.shade50,
      child: const Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              'Topic',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'Program',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'Subject',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'Order',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Status',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Action',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TOPIC ROW
  // ============================================================

  Widget _buildTopicRow(Topic topic) {
    final subject = _getSubject(topic.subjectId);

    // Resolve Program through:
    //
    // Topic → Subject → Program
    final program = _getProgramForTopic(topic);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
      child: Row(
        children: [
          // ------------------------------------------------------
          // TOPIC
          // ------------------------------------------------------
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(
                    Icons.topic_outlined,
                    size: 18,
                    color: Colors.blue.shade900,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    topic.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),

          // ------------------------------------------------------
          // PROGRAM
          // ------------------------------------------------------
          Expanded(
            flex: 3,
            child: Text(
              program?.name ?? 'Unknown',
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // ------------------------------------------------------
          // SUBJECT
          // ------------------------------------------------------
          Expanded(
            flex: 3,
            child: Text(
              subject?.name ?? 'Unknown',
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // ------------------------------------------------------
          // ORDER
          // ------------------------------------------------------
          Expanded(flex: 1, child: Text(topic.sortOrder.toString())),

          // ------------------------------------------------------
          // STATUS
          // ------------------------------------------------------
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Icon(
                  topic.isActive
                      ? Icons.check_circle_outline
                      : Icons.cancel_outlined,
                  size: 18,
                  color: topic.isActive ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 6),
                Text(topic.isActive ? 'Active' : 'Inactive'),
              ],
            ),
          ),

          // ------------------------------------------------------
          // ACTION
          // ------------------------------------------------------
          Expanded(
            flex: 2,
            child: Row(
              children: [
                IconButton(
                  tooltip: topic.isActive ? 'Deactivate' : 'Activate',
                  icon: Icon(
                    topic.isActive ? Icons.toggle_on : Icons.toggle_off,
                    color: topic.isActive ? Colors.green : Colors.grey,
                    size: 28,
                  ),
                  onPressed: () {
                    _toggleTopicStatus(topic);
                  },
                ),
                IconButton(
                  tooltip: 'Edit',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () {
                    _showEditTopicDialog(topic);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
