import 'package:flutter/material.dart';
import 'package:questionbank/models/program.dart';

class AddSubjectDialog extends StatefulWidget {
  final List<Program> programs;

  const AddSubjectDialog({
    super.key,
    required this.programs,
  });

  @override
  State<AddSubjectDialog> createState() =>
      _AddSubjectDialogState();
}

class _AddSubjectDialogState
    extends State<AddSubjectDialog> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController =
  TextEditingController();

  final TextEditingController _sortOrderController =
  TextEditingController(
    text: '0',
  );

  String? _selectedProgramId;

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
        'programId': _selectedProgramId,
        'name': _nameController.text.trim(),
        'sortOrder':
        int.parse(
          _sortOrderController.text.trim(),
        ),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final activePrograms = widget.programs
        .where(
          (program) => program.isActive,
    )
        .toList();

    return AlertDialog(
      title: const Text(
        'Add Subject',
      ),
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
                  _selectedProgramId,
                  decoration:
                  const InputDecoration(
                    labelText: 'Program',
                    border:
                    OutlineInputBorder(),
                  ),
                  items: activePrograms
                      .map(
                        (program) =>
                        DropdownMenuItem<
                            String>(
                          value:
                          program.programId,
                          child:
                          Text(program.name),
                        ),
                  )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedProgramId =
                          value;
                    });
                  },
                  validator: (value) {
                    if (value == null ||
                        value.isEmpty) {
                      return 'Please select a program.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller:
                  _nameController,
                  decoration:
                  const InputDecoration(
                    labelText: 'Subject Name',
                    border:
                    OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Please enter a subject name.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller:
                  _sortOrderController,
                  keyboardType:
                  TextInputType.number,
                  decoration:
                  const InputDecoration(
                    labelText: 'Sort Order',
                    border:
                    OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Please enter a sort order.';
                    }

                    final number =
                    int.tryParse(
                      value.trim(),
                    );

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
          child: const Text(
            'Cancel',
          ),
        ),

        ElevatedButton(
          onPressed: _save,
          child: const Text(
            'Save',
          ),
        ),
      ],
    );
  }
}