import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:questionbank/models/program.dart';
import 'package:questionbank/models/subject.dart';
import 'package:questionbank/services/program_service.dart';
import 'package:questionbank/services/subject_service.dart';

import 'add_subject_dialog.dart';
import 'edit_subject_dialog.dart';

enum _SubjectSortOption { programOrder, subjectOrder }

class SubjectsScreen extends StatefulWidget {
  const SubjectsScreen({super.key});

  @override
  State<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends State<SubjectsScreen> {
  final SubjectService _subjectService = SubjectService();
  final ProgramService _programService = ProgramService();

  List<Subject> _subjects = [];
  List<Program> _programs = [];

  String? _selectedProgramId;

  _SubjectSortOption _sortOption = _SubjectSortOption.programOrder;

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    try {
      final results = await Future.wait([
        _subjectService.getAllSubjects(),
        _programService.getAllPrograms(),
      ]);

      final subjects = results[0] as List<Subject>;
      final programs = results[1] as List<Program>;

      if (!mounted) {
        return;
      }

      setState(() {
        _subjects = subjects;
        _programs = programs;
        _isLoading = false;
        _errorMessage = null;
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

  String _getProgramName(String programId) {
    final program = _programs.firstWhere(
      (item) => item.programId == programId,
      orElse: () => Program(
        programId: '',
        learningAreaId: '',
        name: 'Unknown',
        parentProgramId: null,
        isActive: false,
        sortOrder: 0,
        createdAt: DateTime(2000),
        updatedAt: DateTime(2000),
      ),
    );

    return program.name;
  }

  int _getProgramSortOrder(String programId) {
    final program = _programs.firstWhere(
      (item) => item.programId == programId,
      orElse: () => Program(
        programId: '',
        learningAreaId: '',
        name: 'Unknown',
        parentProgramId: null,
        isActive: false,
        sortOrder: 999999,
        createdAt: DateTime(2000),
        updatedAt: DateTime(2000),
      ),
    );

    return program.sortOrder;
  }

  List<Subject> _getFilteredAndSortedSubjects() {
    final filteredSubjects = _subjects.where((subject) {
      if (_selectedProgramId == null) {
        return true;
      }

      return subject.programId == _selectedProgramId;
    }).toList();

    filteredSubjects.sort((a, b) {
      if (_sortOption == _SubjectSortOption.programOrder) {
        final programOrderComparison = _getProgramSortOrder(
          a.programId,
        ).compareTo(_getProgramSortOrder(b.programId));

        if (programOrderComparison != 0) {
          return programOrderComparison;
        }
      }

      final subjectOrderComparison = a.sortOrder.compareTo(b.sortOrder);

      if (subjectOrderComparison != 0) {
        return subjectOrderComparison;
      }

      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return filteredSubjects;
  }

  String _getSortLabel() {
    switch (_sortOption) {
      case _SubjectSortOption.programOrder:
        return 'Program Order';

      case _SubjectSortOption.subjectOrder:
        return 'Subject Order';
    }
  }

  String _getSelectedProgramLabel() {
    if (_selectedProgramId == null) {
      return 'All Programs';
    }

    return _getProgramName(_selectedProgramId!);
  }

  void _changeSortOption(_SubjectSortOption option) {
    setState(() {
      _sortOption = option;
    });
  }

  void _changeProgramFilter(String? programId) {
    setState(() {
      _selectedProgramId = programId;
    });
  }

  Future<void> _showAddSubjectDialog() async {
    if (_programs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Please create a program first.'),
        ),
      );

      return;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return AddSubjectDialog(programs: _programs);
      },
    );

    if (result == null) {
      return;
    }

    final subjectId = FirebaseFirestore.instance
        .collection('subjects')
        .doc()
        .id;

    final subject = Subject(
      subjectId: subjectId,
      programId: result['programId'] as String,
      name: result['name'] as String,
      isActive: true,
      sortOrder: result['sortOrder'] as int,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await _subjectService.createSubject(subject);

      await _loadSubjects();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Subject created successfully.'),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Failed to create subject: $e'),
        ),
      );
    }
  }

  Future<void> _showEditSubjectDialog(Subject subject) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return EditSubjectDialog(subject: subject, programs: _programs);
      },
    );

    if (result == null) {
      return;
    }

    final updatedSubject = Subject(
      subjectId: subject.subjectId,
      programId: result['programId'] as String,
      name: result['name'] as String,
      isActive: subject.isActive,
      sortOrder: result['sortOrder'] as int,
      createdAt: subject.createdAt,
      updatedAt: DateTime.now(),
    );

    try {
      await _subjectService.updateSubject(updatedSubject);

      await _loadSubjects();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Subject updated successfully.'),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Failed to update subject: $e'),
        ),
      );
    }
  }

  Future<void> _toggleSubjectStatus(Subject subject) async {
    final newStatus = !subject.isActive;

    try {
      await _subjectService.updateSubjectStatus(
        subjectId: subject.subjectId,
        isActive: newStatus,
      );

      await _loadSubjects();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            newStatus
                ? 'Subject activated successfully.'
                : 'Subject deactivated successfully.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Failed to update subject status: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPageHeader(),

          const SizedBox(height: 24),

          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildPageHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            Icons.menu_book_outlined,
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
                'Subjects',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 4),

              Text(
                'Manage subjects under each program',
                style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),

        const SizedBox(width: 16),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${_getFilteredAndSortedSubjects().length} Subjects',
            style: TextStyle(
              color: Colors.blue.shade900,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        const SizedBox(width: 12),

        _buildProgramFilter(),

        const SizedBox(width: 12),

        _buildSortButton(),

        const SizedBox(width: 12),

        ElevatedButton.icon(
          onPressed: _showAddSubjectDialog,
          icon: const Icon(Icons.add),
          label: const Text('Add Subject'),
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

  Widget _buildProgramFilter() {
    return PopupMenuButton<String?>(
      tooltip: 'Filter by program',
      onSelected: _changeProgramFilter,
      itemBuilder: (context) {
        return [
          PopupMenuItem<String?>(
            value: null,
            child: Row(
              children: [
                Icon(
                  Icons.all_inclusive,
                  size: 20,
                  color: Colors.blue.shade900,
                ),
                const SizedBox(width: 10),
                const Text('All Programs'),
              ],
            ),
          ),

          ..._programs.map((program) {
            return PopupMenuItem<String?>(
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
                    child: Text(program.name, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            );
          }),
        ];
      },
      child: Container(
        constraints: const BoxConstraints(maxWidth: 190),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.filter_list, size: 20, color: Colors.blue.shade900),

            const SizedBox(width: 8),

            Flexible(
              child: Text(
                _getSelectedProgramLabel(),
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),

            const SizedBox(width: 4),

            const Icon(Icons.arrow_drop_down, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildSortButton() {
    return PopupMenuButton<_SubjectSortOption>(
      tooltip: 'Sort subjects',
      onSelected: _changeSortOption,
      itemBuilder: (context) {
        return [
          PopupMenuItem(
            value: _SubjectSortOption.programOrder,
            child: Row(
              children: [
                Icon(
                  Icons.account_tree_outlined,
                  size: 20,
                  color: Colors.blue.shade900,
                ),
                const SizedBox(width: 10),
                const Text('Program Order'),
              ],
            ),
          ),

          PopupMenuItem(
            value: _SubjectSortOption.subjectOrder,
            child: Row(
              children: [
                Icon(Icons.sort, size: 20, color: Colors.blue.shade900),
                const SizedBox(width: 10),
                const Text('Subject Order'),
              ],
            ),
          ),
        ];
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sort, size: 20, color: Colors.blue.shade900),

            const SizedBox(width: 8),

            Text(
              _getSortLabel(),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),

            const SizedBox(width: 4),

            const Icon(Icons.arrow_drop_down, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    final subjects = _getFilteredAndSortedSubjects();

    if (subjects.isEmpty) {
      return _buildEmptyFilteredState();
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            _buildTableHeader(),

            const Divider(height: 1),

            Expanded(
              child: ListView.separated(
                itemCount: subjects.length,
                separatorBuilder: (context, index) {
                  return const Divider(height: 1, indent: 16, endIndent: 16);
                },
                itemBuilder: (context, index) {
                  return _buildSubjectRow(subjects[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      color: Colors.grey.shade50,
      child: Row(
        children: [
          Expanded(flex: 3, child: _headerText('Subject')),

          Expanded(flex: 3, child: _headerText('Program')),

          Expanded(flex: 2, child: _headerText('Order')),

          Expanded(flex: 2, child: _headerText('Status')),

          SizedBox(width: 100, child: _headerText('Action')),
        ],
      ),
    );
  }

  Widget _headerText(String text) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade700,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildSubjectRow(Subject subject) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.menu_book_outlined,
                    size: 20,
                    color: Colors.blue.shade900,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Text(
                    subject.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            flex: 3,
            child: Text(
              _getProgramName(subject.programId),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          Expanded(flex: 2, child: Text(subject.sortOrder.toString())),

          Expanded(flex: 2, child: _buildStatusCell(subject.isActive)),

          SizedBox(
            width: 100,
            child: Row(
              children: [
                IconButton(
                  tooltip: subject.isActive ? 'Deactivate' : 'Activate',
                  onPressed: () {
                    _toggleSubjectStatus(subject);
                  },
                  icon: Icon(
                    subject.isActive ? Icons.toggle_on : Icons.toggle_off,
                    color: subject.isActive ? Colors.green : Colors.grey,
                    size: 28,
                  ),
                ),

                IconButton(
                  tooltip: 'Edit',
                  onPressed: () {
                    _showEditSubjectDialog(subject);
                  },
                  icon: const Icon(Icons.edit_outlined),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCell(bool isActive) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isActive ? Icons.check_circle_outline : Icons.cancel_outlined,
          size: 18,
          color: isActive ? Colors.green : Colors.red,
        ),

        const SizedBox(width: 6),

        Text(
          isActive ? 'Active' : 'Inactive',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: isActive ? Colors.green.shade700 : Colors.red.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyFilteredState() {
    final hasFilter = _selectedProgramId != null;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasFilter
                  ? Icons.filter_alt_off_outlined
                  : Icons.menu_book_outlined,
              size: 36,
              color: Colors.blue.shade900,
            ),
          ),

          const SizedBox(height: 18),

          Text(
            hasFilter
                ? 'No subjects found for this program'
                : 'No subjects found',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          Text(
            hasFilter
                ? 'There are no subjects assigned to '
                      '${_getSelectedProgramLabel()}.'
                : 'Create your first subject to continue '
                      'building the question bank hierarchy.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
          ),

          const SizedBox(height: 20),

          if (hasFilter)
            OutlinedButton.icon(
              onPressed: () {
                _changeProgramFilter(null);
              },
              icon: const Icon(Icons.clear),
              label: const Text('Clear Program Filter'),
            )
          else
            ElevatedButton.icon(
              onPressed: _showAddSubjectDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Subject'),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 56, color: Colors.red.shade400),

          const SizedBox(height: 16),

          const Text(
            'Unable to load subjects',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),

          const SizedBox(height: 20),

          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _isLoading = true;
                _errorMessage = null;
              });

              _loadSubjects();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
