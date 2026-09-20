import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:questionbank/models/learning_area.dart';
import 'package:questionbank/services/learning_area_service.dart';

import 'add_learning_area_dialog.dart';
import 'edit_learning_area_dialog.dart';

class LearningAreasScreen extends StatefulWidget {
  const LearningAreasScreen({super.key});

  @override
  State<LearningAreasScreen> createState() =>
      _LearningAreasScreenState();
}

class _LearningAreasScreenState
    extends State<LearningAreasScreen> {

  final LearningAreaService _learningAreaService =
  LearningAreaService();

  List<LearningArea> _learningAreas = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _loadLearningAreas();
  }

  Future<void> _loadLearningAreas() async {
    try {
      final learningAreas =
      await _learningAreaService
          .getAllLearningAreas();

      if (!mounted) {
        return;
      }

      setState(() {
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

  Future<void> _showAddLearningAreaDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return const AddLearningAreaDialog();
      },
    );

    if (result == null) {
      return;
    }

    final name = result['name'] as String;
    final sortOrder = result['sortOrder'] as int;

    final learningAreaId = FirebaseFirestore.instance
        .collection('learningAreas')
        .doc()
        .id;

    final learningArea = LearningArea(
      learningAreaId: learningAreaId,
      name: name,
      isActive: true,
      sortOrder: sortOrder,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await _learningAreaService.createLearningArea(
        learningArea,
      );

      await _loadLearningAreas();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Learning area added successfully.',
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
            'Failed to add learning area: $e',
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Learning Areas',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),

              ElevatedButton.icon(
                onPressed: _showAddLearningAreaDialog,
                icon: const Icon(Icons.add),
                label: const Text('Add Learning Area'),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            'Manage the major learning categories '
                'in Question Bank',
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

    if (_learningAreas.isEmpty) {
      return const Center(
        child: Text(
          'No learning areas found.',
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
              itemCount: _learningAreas.length,
              itemBuilder: (context, index) {
                final learningArea =
                _learningAreas[index];

                return _buildLearningAreaRow(
                  learningArea,
                );
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
            flex: 4,
            child: Text(
              'Learning Area',
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

  Widget _buildLearningAreaRow(
      LearningArea learningArea,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              learningArea.name,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          Expanded(
            flex: 1,
            child: Text(
              learningArea.sortOrder.toString(),
            ),
          ),

          Expanded(
            flex: 2,
            child: Row(
              children: [
                Icon(
                  learningArea.isActive
                      ? Icons.check_circle_outline
                      : Icons.cancel_outlined,
                  size: 18,
                  color: learningArea.isActive
                      ? Colors.green
                      : Colors.red,
                ),

                const SizedBox(width: 6),

                Text(
                  learningArea.isActive
                      ? 'Active'
                      : 'Inactive',
                ),

                const SizedBox(width: 12),

                Switch(
                  value: learningArea.isActive,
                  onChanged: (value) {
                    _toggleLearningAreaStatus(
                      learningArea,
                      value,
                    );
                  },
                ),
              ],
            ),
          ),

          SizedBox(
            width: 80,
            child: IconButton(
              tooltip: 'Edit',
              onPressed: () {
                _showEditLearningAreaDialog(
                  learningArea,
                );
              },
              icon: const Icon(
                Icons.edit_outlined,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditLearningAreaDialog(
      LearningArea learningArea,
      ) async {
    final result =
    await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return EditLearningAreaDialog(
          learningArea: learningArea,
        );
      },
    );

    if (result == null) {
      return;
    }

    final updatedLearningArea = LearningArea(
      learningAreaId: learningArea.learningAreaId,
      name: result['name'] as String,
      isActive: learningArea.isActive,
      sortOrder: result['sortOrder'] as int,
      createdAt: learningArea.createdAt,
      updatedAt: DateTime.now(),
    );

    try {
      await _learningAreaService.updateLearningArea(
        updatedLearningArea,
      );

      await _loadLearningAreas();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Learning area updated successfully.',
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
            'Failed to update learning area: $e',
          ),
        ),
      );
    }
  }

  Future<void> _toggleLearningAreaStatus(
      LearningArea learningArea,
      bool isActive,
      ) async {
    try {
      await _learningAreaService.updateLearningAreaStatus(
        learningAreaId: learningArea.learningAreaId,
        isActive: isActive,
      );

      await _loadLearningAreas();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isActive
                ? 'Learning area activated.'
                : 'Learning area deactivated.',
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
            'Failed to update status: $e',
          ),
        ),
      );
    }
  }
}