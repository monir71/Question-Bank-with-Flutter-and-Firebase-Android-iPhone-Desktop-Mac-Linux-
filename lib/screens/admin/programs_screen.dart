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
      final learningAreas = results[1] as List<LearningArea>;

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

  String _getParentProgramName(Program program) {
    if (program.parentProgramId == null) {
      return '—';
    }

    final parentProgram = _programs.where(
          (item) => item.programId == program.parentProgramId,
    );

    if (parentProgram.isEmpty) {
      return '—';
    }

    return parentProgram.first.name;
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

    final result = await showDialog<Map<String, dynamic>>(
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
      learningAreaId: result['learningAreaId'] as String,
      name: result['name'] as String,
      parentProgramId: result['parentProgramId'] as String?,
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
          behavior: SnackBarBehavior.floating,
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
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Failed to add program: $e',
          ),
        ),
      );
    }
  }

  Future<void> _showEditProgramDialog(
      Program program,
      ) async {
    final result = await showDialog<Map<String, dynamic>>(
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
      learningAreaId: result['learningAreaId'] as String,
      name: result['name'] as String,
      parentProgramId: result['parentProgramId'] as String?,
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
          behavior: SnackBarBehavior.floating,
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
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Failed to update program: $e',
          ),
        ),
      );
    }
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
          behavior: SnackBarBehavior.floating,
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
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Failed to update program status: $e',
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
          _buildPageHeader(),

          const SizedBox(height: 24),

          Expanded(
            child: _buildContent(),
          ),
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
            Icons.account_tree_outlined,
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
                'Programs',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                'Manage programs and their hierarchy '
                    'under each learning area',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 16),

        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${_programs.length} Programs',
            style: TextStyle(
              color: Colors.blue.shade900,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        const SizedBox(width: 12),

        ElevatedButton.icon(
          onPressed: _showAddProgramDialog,
          icon: const Icon(Icons.add),
          label: const Text('Add Program'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 14,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_programs.isEmpty) {
      return _buildEmptyState();
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
                itemCount: _programs.length,
                separatorBuilder: (context, index) {
                  return const Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                  );
                },
                itemBuilder: (context, index) {
                  return _buildProgramRow(
                    _programs[index],
                  );
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
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      color: Colors.grey.shade50,
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: _headerText('Program'),
          ),
          Expanded(
            flex: 2,
            child: _headerText('Learning Area'),
          ),
          Expanded(
            flex: 2,
            child: _headerText('Parent Program'),
          ),
          Expanded(
            flex: 1,
            child: _headerText('Order'),
          ),
          Expanded(
            flex: 2,
            child: _headerText('Status'),
          ),
          SizedBox(
            width: 100,
            child: _headerText('Action'),
          ),
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

  Widget _buildProgramRow(Program program) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 13,
      ),
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
                    Icons.account_tree_outlined,
                    size: 20,
                    color: Colors.blue.shade900,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Text(
                    program.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            flex: 2,
            child: Text(
              _getLearningAreaName(
                program.learningAreaId,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          Expanded(
            flex: 2,
            child: Text(
              _getParentProgramName(program),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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
            child: _buildStatusCell(
              program.isActive,
            ),
          ),

          SizedBox(
            width: 100,
            child: Row(
              children: [
                IconButton(
                  tooltip: program.isActive
                      ? 'Deactivate'
                      : 'Activate',
                  onPressed: () {
                    _toggleProgramStatus(program);
                  },
                  icon: Icon(
                    program.isActive
                        ? Icons.toggle_on
                        : Icons.toggle_off,
                    color: program.isActive
                        ? Colors.green
                        : Colors.grey,
                    size: 28,
                  ),
                ),

                IconButton(
                  tooltip: 'Edit',
                  onPressed: () {
                    _showEditProgramDialog(program);
                  },
                  icon: const Icon(
                    Icons.edit_outlined,
                  ),
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
          isActive
              ? Icons.check_circle_outline
              : Icons.cancel_outlined,
          size: 18,
          color: isActive
              ? Colors.green
              : Colors.red,
        ),

        const SizedBox(width: 6),

        Text(
          isActive ? 'Active' : 'Inactive',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: isActive
                ? Colors.green.shade700
                : Colors.red.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
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
              Icons.account_tree_outlined,
              size: 36,
              color: Colors.blue.shade900,
            ),
          ),

          const SizedBox(height: 18),

          const Text(
            'No programs found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Create your first program to start building '
                'the learning hierarchy.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 15,
            ),
          ),

          const SizedBox(height: 20),

          ElevatedButton.icon(
            onPressed: _showAddProgramDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add Program'),
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
          Icon(
            Icons.error_outline,
            size: 56,
            color: Colors.red.shade400,
          ),

          const SizedBox(height: 16),

          const Text(
            'Unable to load programs',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
            ),
            child: Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
          ),

          const SizedBox(height: 20),

          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _isLoading = true;
                _errorMessage = null;
              });

              _loadPrograms();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}