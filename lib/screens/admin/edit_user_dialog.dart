import 'package:flutter/material.dart';
import 'package:questionbank/models/app_user.dart';
import 'package:questionbank/services/user_service.dart';

class EditUserDialog extends StatefulWidget {
  final AppUser user;
  final UserService userService;

  const EditUserDialog({
    super.key,
    required this.user,
    required this.userService,
  });

  @override
  State<EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<EditUserDialog> {
  late final TextEditingController _usernameController;
  late final TextEditingController _displayNameController;
  late final TextEditingController _mobileController;

  late UserRole _selectedRole;
  late bool _selectedStatus;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    _usernameController = TextEditingController(
      text: widget.user.username,
    );

    _displayNameController = TextEditingController(
      text: widget.user.displayName,
    );

    _mobileController = TextEditingController(
      text: widget.user.mobileNumber ?? '',
    );

    _selectedRole = widget.user.role;
    _selectedStatus = widget.user.isActive;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _displayNameController.dispose();
    _mobileController.dispose();

    super.dispose();
  }

  String? _validateFields() {
    final username = _usernameController.text.trim();
    final displayName = _displayNameController.text.trim();
    final mobile = _mobileController.text.trim();

    if (username.isEmpty) {
      return 'Username is required.';
    }

    if (displayName.isEmpty) {
      return 'Display name is required.';
    }

    if (mobile.isNotEmpty) {
      if (!RegExp(r'^01\d{9}$').hasMatch(mobile)) {
        return 'Mobile number must be 11 digits and start with 01.';
      }
    }

    return null;
  }

  Future<void> _saveUser() async {
    final validationMessage = _validateFields();

    if (validationMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validationMessage),
        ),
      );

      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.userService.updateUser(
        userId: widget.user.userId,
        username: _usernameController.text.trim(),
        displayName: _displayNameController.text.trim(),
        mobileNumber: _mobileController.text.trim().isEmpty
            ? null
            : _mobileController.text.trim(),
        role: _selectedRole,
        isActive: _selectedStatus,
      );

      if (!mounted) {
        return;
      }

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update user: $e',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit User'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _displayNameController,
              decoration: const InputDecoration(
                labelText: 'Display Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _mobileController,
              decoration: const InputDecoration(
                labelText: 'Mobile Number',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<UserRole>(
              initialValue: _selectedRole,
              decoration: const InputDecoration(
                labelText: 'Role',
                border: OutlineInputBorder(),
              ),
              items: UserRole.values.map((role) {
                return DropdownMenuItem<UserRole>(
                  value: role,
                  child: Text(
                    role.name[0].toUpperCase() +
                        role.name.substring(1),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedRole = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<bool>(
              initialValue: _selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem<bool>(
                  value: true,
                  child: Text('Active'),
                ),
                DropdownMenuItem<bool>(
                  value: false,
                  child: Text('Inactive'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedStatus = value;
                  });
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving
              ? null
              : () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveUser,
          child: _isSaving
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          )
              : const Text('Save'),
        ),
      ],
    );
  }
}