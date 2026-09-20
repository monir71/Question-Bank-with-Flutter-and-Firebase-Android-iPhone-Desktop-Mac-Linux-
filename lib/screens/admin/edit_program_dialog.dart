import 'package:flutter/material.dart';
import 'package:questionbank/models/learning_area.dart';
import 'package:questionbank/models/program.dart';

class EditProgramDialog extends StatefulWidget {
  final Program program;
  final List<LearningArea> learningAreas;
  final List<Program> programs;

  const EditProgramDialog({
    super.key,
    required this.program,
    required this.learningAreas,
    required this.programs,
  });

  @override
  State<EditProgramDialog> createState() =>
      _EditProgramDialogState();
}

class _EditProgramDialogState
    extends State<EditProgramDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _sortOrderController;

  late String _selectedLearningAreaId;
  String? _selectedParentProgramId;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(
      text: widget.program.name,
    );

    _sortOrderController = TextEditingController(
      text: widget.program.sortOrder.toString(),
    );

    _selectedLearningAreaId =
        widget.program.learningAreaId;

    _selectedParentProgramId =
        widget.program.parentProgramId;
  }

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
    final availableParentPrograms =
    widget.programs.where(
          (program) =>
      program.learningAreaId ==
          _selectedLearningAreaId &&
          program.isActive &&
          program.programId !=
              widget.program.programId,
    );

    return AlertDialog(
      title: const Text('Edit Program'),

      content: SizedBox(
        width: 450,

        child: Form(
          key: _formKey,

          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue:
                  _selectedLearningAreaId,

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
                    if (value == null) {
                      return;
                    }

                    setState(() {
                      _selectedLearningAreaId =
                          value;
                      _selectedParentProgramId =
                      null;
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
                  initialValue:
                  _selectedParentProgramId,

                  decoration: const InputDecoration(
                    labelText:
                    'Parent Program (Optional)',
                    border: OutlineInputBorder(),
                  ),

                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('None'),
                    ),

                    ...availableParentPrograms.map(
                          (program) =>
                          DropdownMenuItem<String?>(
                            value: program.programId,
                            child: Text(program.name),
                          ),
                    ),
                  ],

                  onChanged: (value) {
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
          child: const Text('Save Changes'),
        ),
      ],
    );
  }
}