import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:questionbank/models/learning_area.dart';
import 'package:questionbank/services/learning_area_service.dart';

import 'add_learning_area_dialog.dart';
import 'edit_learning_area_dialog.dart';

class LearningAreasScreen extends StatefulWidget {
  const LearningAreasScreen({super.key});

  @override
  State<LearningAreasScreen> createState() => _LearningAreasScreenState();
}

class _LearningAreasScreenState extends State<LearningAreasScreen> {
  final LearningAreaService _learningAreaService = LearningAreaService();

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
      final learningAreas = await _learningAreaService.getAllLearningAreas();

      if (!mounted) return;

      setState(() {
        _learningAreas = learningAreas;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;

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

    if (result == null) return;

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
      await _learningAreaService.createLearningArea(learningArea);

      await _loadLearningAreas();

      if (!mounted) return;

      _showMessage('Learning area added successfully.');
    } catch (e) {
      if (!mounted) return;

      _showMessage('Failed to add learning area: $e', isError: true);
    }
  }

  Future<void> _showEditLearningAreaDialog(LearningArea learningArea) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return EditLearningAreaDialog(learningArea: learningArea);
      },
    );

    if (result == null) return;

    final updatedLearningArea = LearningArea(
      learningAreaId: learningArea.learningAreaId,
      name: result['name'] as String,
      isActive: learningArea.isActive,
      sortOrder: result['sortOrder'] as int,
      createdAt: learningArea.createdAt,
      updatedAt: DateTime.now(),
    );

    try {
      await _learningAreaService.updateLearningArea(updatedLearningArea);

      await _loadLearningAreas();

      if (!mounted) return;

      _showMessage('Learning area updated successfully.');
    } catch (e) {
      if (!mounted) return;

      _showMessage('Failed to update learning area: $e', isError: true);
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

      if (!mounted) return;

      _showMessage(
        isActive ? 'Learning area activated.' : 'Learning area deactivated.',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage('Failed to update status: $e', isError: true);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Colors.red.shade700 : null,
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.account_tree_outlined,
            color: Colors.blue.shade800,
            size: 27,
          ),
        ),

        const SizedBox(width: 14),

        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Learning Areas',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),

              SizedBox(height: 4),

              Text(
                'Manage the major learning categories '
                'in Question Bank',
                style: TextStyle(fontSize: 15, color: Colors.grey),
              ),
            ],
          ),
        ),

        if (_learningAreas.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_learningAreas.length} Total',
              style: TextStyle(
                color: Colors.blue.shade800,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),

        const SizedBox(width: 12),

        ElevatedButton.icon(
          onPressed: _showAddLearningAreaDialog,
          icon: const Icon(Icons.add),
          label: const Text('Add Learning Area'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
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
      return _buildLoading();
    }

    if (_errorMessage != null) {
      return _buildError();
    }

    if (_learningAreas.isEmpty) {
      return _buildEmptyState();
    }

    return _buildTable();
  }

  Widget _buildLoading() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),

            const SizedBox(height: 12),

            const Text(
              'Unable to load learning areas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 8),

            Text(
              _errorMessage ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),

            const SizedBox(height: 16),

            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });

                _loadLearningAreas();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
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
                color: Colors.blue.shade700,
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              'No learning areas yet',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 6),

            Text(
              'Add your first learning area to get started.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),

            const SizedBox(height: 18),

            ElevatedButton.icon(
              onPressed: _showAddLearningAreaDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Learning Area'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTable() {
    return Column(
      children: [
        _buildTableHeader(),

        Divider(height: 1, color: Colors.grey.shade200),

        Expanded(
          child: ListView.separated(
            itemCount: _learningAreas.length,
            separatorBuilder: (_, _) =>
                Divider(height: 1, color: Colors.grey.shade100),
            itemBuilder: (context, index) {
              return _buildLearningAreaRow(_learningAreas[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      color: Colors.grey.shade50,
      child: const Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              'LEARNING AREA',
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
              'ORDER',
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
              'STATUS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),

          SizedBox(
            width: 70,
            child: Text(
              'ACTION',
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

  Widget _buildLearningAreaRow(LearningArea learningArea) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
      child: Row(
        children: [
          Expanded(
            flex: 4,
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
                    color: Colors.blue.shade700,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Text(
                    learningArea.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            flex: 1,
            child: Text(
              learningArea.sortOrder.toString(),
              style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
            ),
          ),

          Expanded(
            flex: 2,
            child: Row(
              children: [
                _buildStatusBadge(learningArea.isActive),

                const SizedBox(width: 8),

                Switch(
                  value: learningArea.isActive,
                  onChanged: (value) {
                    _toggleLearningAreaStatus(learningArea, value);
                  },
                ),
              ],
            ),
          ),

          SizedBox(
            width: 70,
            child: IconButton(
              tooltip: 'Edit learning area',
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: () {
                _showEditLearningAreaDialog(learningArea);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.check_circle_outline : Icons.cancel_outlined,
            size: 15,
            color: isActive ? Colors.green.shade700 : Colors.red.shade700,
          ),

          const SizedBox(width: 5),

          Text(
            isActive ? 'Active' : 'Inactive',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.green.shade700 : Colors.red.shade700,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),

          const SizedBox(height: 24),

          Expanded(
            child: Card(
              elevation: 2,
              shadowColor: Colors.black.withValues(alpha: 0.08),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              clipBehavior: Clip.antiAlias,
              child: _buildContent(),
            ),
          ),
        ],
      ),
    );
  }
}
