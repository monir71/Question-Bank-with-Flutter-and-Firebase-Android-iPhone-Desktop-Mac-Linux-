import 'package:flutter/material.dart';

class AddLearningAreaDialog extends StatefulWidget {
  const AddLearningAreaDialog({super.key});

  @override
  State<AddLearningAreaDialog> createState() =>
      _AddLearningAreaDialogState();
}

class _AddLearningAreaDialogState
    extends State<AddLearningAreaDialog> {

  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _sortOrderController = TextEditingController(
    text: '1',
  );

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

    final name = _nameController.text.trim();
    final sortOrder =
    int.parse(_sortOrderController.text.trim());

    Navigator.pop(
      context,
      {
        'name': name,
        'sortOrder': sortOrder,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Learning Area'),

      content: SizedBox(
        width: 400,

        child: Form(
          key: _formKey,

          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              TextFormField(
                controller: _nameController,
                autofocus: true,

                decoration: const InputDecoration(
                  labelText: 'Learning Area Name',
                  hintText: 'e.g. Academic',
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