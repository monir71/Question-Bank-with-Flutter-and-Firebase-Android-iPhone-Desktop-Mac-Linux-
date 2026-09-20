import 'package:flutter/material.dart';
import 'package:questionbank/models/learning_area.dart';

class EditLearningAreaDialog extends StatefulWidget {
  final LearningArea learningArea;

  const EditLearningAreaDialog({
    super.key,
    required this.learningArea,
  });

  @override
  State<EditLearningAreaDialog> createState() =>
      _EditLearningAreaDialogState();
}

class _EditLearningAreaDialogState
    extends State<EditLearningAreaDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _sortOrderController;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(
      text: widget.learningArea.name,
    );

    _sortOrderController = TextEditingController(
      text: widget.learningArea.sortOrder.toString(),
    );
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
        'name': _nameController.text.trim(),
        'sortOrder':
        int.parse(_sortOrderController.text.trim()),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Learning Area'),

      content: SizedBox(
        width: 400,

        child: Form(
          key: _formKey,

          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,

                decoration: const InputDecoration(
                  labelText: 'Learning Area Name',
                  border: OutlineInputBorder(),
                ),

                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'Please enter a learning area name.';
                  }

                  return null;
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