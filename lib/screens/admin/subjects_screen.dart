import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:questionbank/models/program.dart';
import 'package:questionbank/models/subject.dart';
import 'package:questionbank/services/program_service.dart';
import 'package:questionbank/services/subject_service.dart';

import 'add_subject_dialog.dart';
import 'edit_subject_dialog.dart';

class SubjectsScreen extends StatefulWidget {
  const SubjectsScreen({super.key});

  @override
  State<SubjectsScreen> createState() =>
      _SubjectsScreenState();
}

class _SubjectsScreenState
    extends State<SubjectsScreen> {
  final SubjectService _subjectService =
  SubjectService();

  final ProgramService _programService =
  ProgramService();

  List<Subject> _subjects = [];
  List<Program> _programs = [];

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

      final subjects =
      results[0] as List<Subject>;

      final programs =
      results[1] as List<Program>;

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

  String _getProgramName(
      String programId,
      ) {
    final program = _programs.firstWhere(
          (program) =>
      program.programId == programId,
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

  Future<void> _showAddSubjectDialog() async {
    final result =
    await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return AddSubjectDialog(
          programs: _programs,
        );
      },
    );

    if (result == null) {
      return;
    }

    final subjectId = FirebaseFirestore
        .instance
        .collection('subjects')
        .doc()
        .id;

    final subject = Subject(
      subjectId: subjectId,
      programId:
      result['programId'] as String,
      name:
      result['name'] as String,
      isActive: true,
      sortOrder:
      result['sortOrder'] as int,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await _subjectService.createSubject(
        subject,
      );

      await _loadSubjects();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Subject created successfully.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Failed to create subject: $e',
          ),
        ),
      );
    }
  }

  Future<void> _showEditSubjectDialog(
      Subject subject,
      ) async {
    final result =
    await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return EditSubjectDialog(
          subject: subject,
          programs: _programs,
        );
      },
    );

    if (result == null) {
      return;
    }

    final updatedSubject = Subject(
      subjectId: subject.subjectId,
      programId:
      result['programId'] as String,
      name:
      result['name'] as String,
      isActive: subject.isActive,
      sortOrder:
      result['sortOrder'] as int,
      createdAt: subject.createdAt,
      updatedAt: DateTime.now(),
    );

    try {
      await _subjectService.updateSubject(
        updatedSubject,
      );

      await _loadSubjects();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Subject updated successfully.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update subject: $e',
          ),
        ),
      );
    }
  }

  Future<void> _toggleSubjectStatus(
      Subject subject,
      ) async {
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

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
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

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update subject status: $e',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Subjects',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              ElevatedButton.icon(
                onPressed: _showAddSubjectDialog,
                icon: const Icon(Icons.add),
                label: const Text(
                  'Add Subject',
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Text(
          'Failed to load subjects:\n$_errorMessage',
          textAlign: TextAlign.center,
        ),
      );
    }

    if (_subjects.isEmpty) {
      return const Center(
        child: Text(
          'No subjects found.',
        ),
      );
    }

    return _buildSubjectsList();
  }

  Widget _buildSubjectsList() {
    return Column(
      children: [
        _buildHeader(),

        const Divider(height: 1),

        Expanded(
          child: ListView.builder(
            itemCount: _subjects.length,
            itemBuilder: (context, index) {
              final subject =
              _subjects[index];

              return _buildSubjectRow(
                subject,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Expanded(
          flex: 3,
          child: Text(
            'Subject',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        const Expanded(
          flex: 3,
          child: Text(
            'Program',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        const Expanded(
          flex: 2,
          child: Text(
            'Order',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        const Expanded(
          flex: 2,
          child: Text(
            'Status',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        const Expanded(
          flex: 1,
          child: Text(
            'Action',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectRow(
      Subject subject,
      ) {
    return Padding(
      padding:
      const EdgeInsets.symmetric(
        vertical: 12,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              subject.name,
            ),
          ),

          Expanded(
            flex: 3,
            child: Text(
              _getProgramName(
                subject.programId,
              ),
            ),
          ),

          Expanded(
            flex: 2,
            child: Text(
              subject.sortOrder.toString(),
            ),
          ),

          Expanded(
            flex: 2,
            child: Row(
              children: [
                Icon(
                  subject.isActive
                      ? Icons.check_circle_outline
                      : Icons.cancel_outlined,
                  size: 18,
                  color: subject.isActive
                      ? Colors.green
                      : Colors.red,
                ),

                const SizedBox(width: 6),

                Text(
                  subject.isActive
                      ? 'Active'
                      : 'Inactive',
                ),
              ],
            ),
          ),

          Expanded(
            flex: 1,
            child: Row(
              children: [
                IconButton(
                  tooltip: subject.isActive
                      ? 'Deactivate'
                      : 'Activate',
                  icon: Icon(
                    subject.isActive
                        ? Icons.toggle_on
                        : Icons.toggle_off,
                    color: subject.isActive
                        ? Colors.green
                        : Colors.grey,
                  ),
                  onPressed: () {
                    _toggleSubjectStatus(subject);
                  },
                ),

                IconButton(
                  tooltip: 'Edit',
                  icon: const Icon(
                    Icons.edit,
                  ),
                  onPressed: () {
                    _showEditSubjectDialog(subject);
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