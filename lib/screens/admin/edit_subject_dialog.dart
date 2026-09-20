import 'package:flutter/material.dart';
import 'package:questionbank/models/program.dart';
import 'package:questionbank/models/subject.dart';

class EditSubjectDialog extends StatefulWidget {
  final Subject subject;
  final List<Program> programs;

  const EditSubjectDialog({
    super.key,
    required this.subject,
    required this.programs,
  });

  @override
  State<EditSubjectDialog> createState() =>
      _EditSubjectDialogState();
}

class _EditSubjectDialogState
    extends State<EditSubjectDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _sortOrderController;

  late String _selectedProgramId;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(
      text: widget.subject.name,
    );

    _sortOrderController = TextEditingController(
      text: widget.subject.sortOrder.toString(),
    );

    _selectedProgramId =
        widget.subject.programId;
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
          (program) =>
      program.isActive ||
          program.programId ==
              widget.subject.programId,
    )
        .toList();

    return AlertDialog(
      title: const Text(
        'Edit Subject',
      ),
      content: SizedBox(
        width: 450,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize:
              MainAxisSize.min,
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
                    if (value == null) {
                      return;
                    }

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
                    labelText:
                    'Subject Name',
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
            'Save Changes',
          ),
        ),
      ],
    );
  }
}