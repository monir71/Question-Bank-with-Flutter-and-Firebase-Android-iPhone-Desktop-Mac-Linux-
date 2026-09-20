import 'package:flutter/material.dart';
import 'package:questionbank/models/subject.dart';

class AddTopicDialog extends StatefulWidget {
  final List<Subject> subjects;

  const AddTopicDialog({
    super.key,
    required this.subjects,
  });

  @override
  State<AddTopicDialog> createState() =>
      _AddTopicDialogState();
}

class _AddTopicDialogState
    extends State<AddTopicDialog> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController =
  TextEditingController();

  final TextEditingController _sortOrderController =
  TextEditingController(
    text: '0',
  );

  String? _selectedSubjectId;

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
        'subjectId': _selectedSubjectId,
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
    final activeSubjects = widget.subjects
        .where(
          (subject) => subject.isActive,
    )
        .toList();

    return AlertDialog(
      title: const Text(
        'Add Topic',
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
                  _selectedSubjectId,
                  decoration:
                  const InputDecoration(
                    labelText: 'Subject',
                    border:
                    OutlineInputBorder(),
                  ),
                  items: activeSubjects
                      .map(
                        (subject) =>
                        DropdownMenuItem<
                            String>(
                          value:
                          subject.subjectId,
                          child:
                          Text(subject.name),
                        ),
                  )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedSubjectId =
                          value;
                    });
                  },
                  validator: (value) {
                    if (value == null ||
                        value.isEmpty) {
                      return 'Please select a subject.';
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
                    labelText: 'Topic Name',
                    border:
                    OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Please enter a topic name.';
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