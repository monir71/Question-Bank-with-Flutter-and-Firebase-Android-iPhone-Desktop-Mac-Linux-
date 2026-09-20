import 'package:flutter/material.dart';
import 'package:questionbank/models/learning_area.dart';
import 'package:questionbank/models/program.dart';

class AddProgramDialog extends StatefulWidget {
  final List<LearningArea> learningAreas;
  final List<Program> programs;

  const AddProgramDialog({
    super.key,
    required this.learningAreas,
    required this.programs,
  });

  @override
  State<AddProgramDialog> createState() =>
      _AddProgramDialogState();
}

class _AddProgramDialogState
    extends State<AddProgramDialog> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _sortOrderController = TextEditingController(
    text: '1',
  );

  String? _selectedLearningAreaId;
  String? _selectedParentProgramId;

  @override
  void dispose() {
    _nameController.dispose();
    _sortOrderController.dispose();

    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.pop(
      context,
      {
        'learningAreaId': _selectedLearningAreaId,
        'name': _nameController.text.trim(),
        'parentProgramId': _selectedParentProgramId,
        'sortOrder':
        int.parse(_sortOrderController.text.trim()),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Program'),

      content: SizedBox(
        width: 450,

        child: Form(
          key: _formKey,

          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _selectedLearningAreaId,

                  decoration: const InputDecoration(
                    labelText: 'Learning Area',
                    border: OutlineInputBorder(),
                  ),

                  items: widget.learningAreas
                      .where(
                        (area) => area.isActive,
                  )
                      .map(
                        (area) =>
                        DropdownMenuItem<String>(
                          value: area.learningAreaId,
                          child: Text(area.name),
                        ),
                  )
                      .toList(),

                  onChanged: (value) {
                    setState(() {
                      _selectedLearningAreaId = value;
                      _selectedParentProgramId = null;
                    });
                  },

                  validator: (value) {
                    if (value == null ||
                        value.isEmpty) {
                      return 'Please select a learning area.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _nameController,

                  decoration: const InputDecoration(
                    labelText: 'Program Name',
                    hintText: 'e.g. Class 9 - Science',
                    border: OutlineInputBorder(),
                  ),

                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Please enter a program name.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                DropdownButtonFormField<String?>(
                  initialValue: _selectedParentProgramId,

                  decoration: const InputDecoration(
                    labelText: 'Parent Program (Optional)',
                    border: OutlineInputBorder(),
                  ),

                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('None'),
                    ),

                    ...widget.programs
                        .where(
                          (program) =>
                      program.learningAreaId ==
                          _selectedLearningAreaId &&
                          program.isActive,
                    )
                        .map(
                          (program) =>
                          DropdownMenuItem<String?>(
                            value: program.programId,
                            child: Text(program.name),
                          ),
                    ),
                  ],

                  onChanged: _selectedLearningAreaId == null
                      ? null
                      : (value) {
                    setState(() {
                      _selectedParentProgramId =
                          value;
                    });
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _sortOrderController,

                  keyboardType: TextInputType.number,

                  decoration: const InputDecoration(
                    labelText: 'Sort Order',
                    hintText: 'e.g. 1',
                    border: OutlineInputBorder(),
                  ),

                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Please enter a sort order.';
                    }

                    final number =
                    int.tryParse(value.trim());

                    if (number == null) {
                      return 'Please enter a valid number.';
                    }

                    if (number < 0) {
                      return 'Sort order cannot be negative.';
                    }

                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),

      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),

        ElevatedButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}