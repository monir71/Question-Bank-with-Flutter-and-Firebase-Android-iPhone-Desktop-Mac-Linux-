import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:questionbank/models/program.dart';
import 'package:questionbank/services/program_service.dart';

import '../../models/learning_area.dart';
import '../../services/learning_area_service.dart';
import 'add_program_dialog.dart';
import 'edit_program_dialog.dart';

class ProgramsScreen extends StatefulWidget {
  const ProgramsScreen({super.key});

  @override
  State<ProgramsScreen> createState() => _ProgramsScreenState();
}

class _ProgramsScreenState extends State<ProgramsScreen> {
  final ProgramService _programService = ProgramService();
  final LearningAreaService _learningAreaService =
  LearningAreaService();

  List<Program> _programs = [];
  List<LearningArea> _learningAreas = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _loadPrograms();
  }

  Future<void> _loadPrograms() async {
    try {
      final results = await Future.wait([
        _programService.getAllPrograms(),
        _learningAreaService.getAllLearningAreas(),
      ]);

      final programs = results[0] as List<Program>;
      final learningAreas =
      results[1] as List<LearningArea>;

      if (!mounted) {
        return;
      }

      setState(() {
        _programs = programs;
        _learningAreas = learningAreas;
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

  String _getLearningAreaName(String learningAreaId) {
    final learningArea = _learningAreas.firstWhere(
          (area) => area.learningAreaId == learningAreaId,
      orElse: () => LearningArea(
        learningAreaId: '',
        name: 'Unknown',
        isActive: false,
        sortOrder: 0,
        createdAt: DateTime(2000),
        updatedAt: DateTime(2000),
      ),
    );

    return learningArea.name;
  }

  Future<void> _showAddProgramDialog() async {
    if (_learningAreas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please create a learning area first.',
          ),
        ),
      );

      return;
    }

    final result =
    await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return AddProgramDialog(
          learningAreas: _learningAreas,
          programs: _programs,
        );
      },
    );

    if (result == null) {
      return;
    }

    final programId = FirebaseFirestore.instance
        .collection('programs')
        .doc()
        .id;

    final program = Program(
      programId: programId,
      learningAreaId:
      result['learningAreaId'] as String,
      name: result['name'] as String,
      parentProgramId:
      result['parentProgramId'] as String?,
      isActive: true,
      sortOrder: result['sortOrder'] as int,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await _programService.createProgram(program);

      await _loadPrograms();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Program added successfully.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to add program: $e',
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Programs',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),

              ElevatedButton.icon(
                onPressed: _showAddProgramDialog,
                icon: const Icon(Icons.add),
                label: const Text('Add Program'),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            'Manage programs under each learning area',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),

          const SizedBox(height: 30),

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
          _errorMessage!,
          style: const TextStyle(
            color: Colors.red,
          ),
        ),
      );
    }

    if (_programs.isEmpty) {
      return const Center(
        child: Text(
          'No programs found.',
          style: TextStyle(
            fontSize: 18,
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      child: Column(
        children: [
          _buildHeader(),

          const Divider(height: 1),

          Expanded(
            child: ListView.builder(
              itemCount: _programs.length,
              itemBuilder: (context, index) {
                final program = _programs[index];

                return _buildProgramRow(program);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              'Program',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          Expanded(
            flex: 2,
            child: Text(
              'Learning Area',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          Expanded(
            flex: 2,
            child: Text(
              'Parent Program',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          Expanded(
            flex: 1,
            child: Text(
              'Order',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          Expanded(
            flex: 2,
            child: Text(
              'Status',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          SizedBox(
            width: 80,
            child: Text(
              'Action',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgramRow(Program program) {
    String parentProgramName = '—';

    if (program.parentProgramId != null) {
      final parentProgram = _programs.where(
            (item) =>
        item.programId ==
            program.parentProgramId,
      );

      if (parentProgram.isNotEmpty) {
        parentProgramName =
            parentProgram.first.name;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              program.name,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          Expanded(
            flex: 2,
            child: Text(
              _getLearningAreaName(
                program.learningAreaId,
              ),
            ),
          ),

          Expanded(
            flex: 2,
            child: Text(
              parentProgramName,
            ),
          ),

          Expanded(
            flex: 1,
            child: Text(
              program.sortOrder.toString(),
            ),
          ),

          Expanded(
            flex: 2,
            child: Row(
              children: [
                Icon(
                  program.isActive
                      ? Icons.check_circle_outline
                      : Icons.cancel_outlined,
                  size: 18,
                  color: program.isActive
                      ? Colors.green
                      : Colors.red,
                ),

                const SizedBox(width: 6),

                Text(
                  program.isActive
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
                  tooltip: program.isActive
                      ? 'Deactivate'
                      : 'Activate',
                  icon: Icon(
                    program.isActive
                        ? Icons.toggle_on
                        : Icons.toggle_off,
                    color: program.isActive
                        ? Colors.green
                        : Colors.grey,
                  ),
                  onPressed: () {
                    _toggleProgramStatus(program);
                  },
                ),

                IconButton(
                  tooltip: 'Edit',
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    _showEditProgramDialog(program);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleProgramStatus(
      Program program,
      ) async {
    final newStatus = !program.isActive;

    try {
      await _programService.updateProgramStatus(
        programId: program.programId,
        isActive: newStatus,
      );

      await _loadPrograms();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus
                ? 'Program activated successfully.'
                : 'Program deactivated successfully.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update program status: $e',
          ),
        ),
      );
    }
  }

  Future<void> _showEditProgramDialog(
      Program program,
      ) async {
    final result =
    await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return EditProgramDialog(
          program: program,
          learningAreas: _learningAreas,
          programs: _programs,
        );
      },
    );

    if (result == null) {
      return;
    }

    final updatedProgram = Program(
      programId: program.programId,
      learningAreaId:
      result['learningAreaId'] as String,
      name: result['name'] as String,
      parentProgramId:
      result['parentProgramId'] as String?,
      isActive: program.isActive,
      sortOrder: result['sortOrder'] as int,
      createdAt: program.createdAt,
      updatedAt: DateTime.now(),
    );

    try {
      await _programService.updateProgram(
        updatedProgram,
      );

      await _loadPrograms();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Program updated successfully.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update program: $e',
          ),
        ),
      );
    }
  }
}