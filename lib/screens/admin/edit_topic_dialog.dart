import 'package:flutter/material.dart';
import 'package:questionbank/models/subject.dart';
import 'package:questionbank/models/topic.dart';

class EditTopicDialog extends StatefulWidget {
  final Topic topic;
  final List<Subject> subjects;

  const EditTopicDialog({
    super.key,
    required this.topic,
    required this.subjects,
  });

  @override
  State<EditTopicDialog> createState() =>
      _EditTopicDialogState();
}

class _EditTopicDialogState
    extends State<EditTopicDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _sortOrderController;

  late String _selectedSubjectId;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(
      text: widget.topic.name,
    );

    _sortOrderController = TextEditingController(
      text: widget.topic.sortOrder.toString(),
    );

    _selectedSubjectId =
        widget.topic.subjectId;
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
          (subject) =>
      subject.isActive ||
          subject.subjectId ==
              widget.topic.subjectId,
    )
        .toList();

    return AlertDialog(
      title: const Text(
        'Edit Topic',
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
                    if (value == null) {
                      return;
                    }

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
            'Save Changes',
          ),
        ),
      ],
    );
  }
}