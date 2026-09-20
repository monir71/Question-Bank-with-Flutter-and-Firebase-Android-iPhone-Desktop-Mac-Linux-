import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../services/user_service.dart';
import 'edit_user_dialog.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {

  final UserService _userService = UserService();

  List<AppUser> _users = [];
  bool _isLoading = true;
  String? _errorMessage;

  final TextEditingController _searchController =
  TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  UserRole? _selectedRole;
  bool? _selectedStatus;

  List<AppUser> get _filteredUsers {
    final searchText = _searchController.text.trim().toLowerCase();

    return _users.where((user) {
      final matchesSearch =
          searchText.isEmpty ||
              user.username.toLowerCase().contains(searchText) ||
              user.displayName.toLowerCase().contains(searchText) ||
              user.email.toLowerCase().contains(searchText);

      final matchesRole =
          _selectedRole == null || user.role == _selectedRole;

      final matchesStatus =
          _selectedStatus == null || user.isActive == _selectedStatus;

      return matchesSearch && matchesRole && matchesStatus;
    }).toList();
  }

  Future<void> _loadUsers() async {
    try {
      final users = await _userService.getAllUsers();

      if (!mounted) {
        return;
      }

      setState(() {
        _users = users;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Widget _buildUserContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Text(
          _errorMessage!,
          style: const TextStyle(
            color: Colors.red,
            fontSize: 16,
          ),
        ),
      );
    }

    if (_users.isEmpty) {
      return const Center(
        child: Text(
          'No users found.',
          style: TextStyle(
            fontSize: 18,
          ),
        ),
      );
    }

    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 900;

            if (isNarrow) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search users...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: _buildRoleDropdown(),
                        ),

                        const SizedBox(width: 16),

                        Expanded(
                          child: _buildStatusDropdown(),
                        ),

                      ],
                    ),
                  ],
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search users...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                  ),

                  const SizedBox(width: 16),

                  SizedBox(
                    width: 180,
                    child: _buildRoleDropdown(),
                  ),

                  const SizedBox(width: 16),

                  SizedBox(
                    width: 180,
                    child: _buildStatusDropdown(),
                  ),
                ],
              ),
            );
          },
        ),

        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Showing ${_filteredUsers.length} '
                  '${_filteredUsers.length == 1 ? 'user' : 'users'}',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ),
        ),

        _buildUserHeader(),

        const Divider(height: 1),

        Expanded(
          child: ListView.builder(
            itemCount: _filteredUsers.length,
            itemBuilder: (context, index) {
              final user = _filteredUsers[index];

              return _buildUserRow(user);
            },
          ),
        ),
      ],
    );
  }

  Future<void> _editUser(AppUser user) async {
    final updated = await showDialog<bool>(
      context: context,
      builder: (context) {
        return EditUserDialog(
          user: user,
          userService: _userService,
        );
      },
    );

    if (updated != true) {
      return;
    }

    await _loadUsers();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('User updated successfully.'),
      ),
    );
  }

  Widget _buildRoleDropdown() {
    return DropdownButtonFormField<UserRole?>(
      initialValue: _selectedRole,
      decoration: InputDecoration(
        labelText: 'Role',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      items: [
        const DropdownMenuItem<UserRole?>(
          value: null,
          child: Text('All Roles'),
        ),
        ...UserRole.values.map(
              (role) {
            return DropdownMenuItem<UserRole?>(
              value: role,
              child: Text(
                role.name[0].toUpperCase() +
                    role.name.substring(1),
              ),
            );
          },
        ),
      ],
      onChanged: (value) {
        setState(() {
          _selectedRole = value;
        });
      },
    );
  }

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<bool?>(
      initialValue: _selectedStatus,
      decoration: InputDecoration(
        labelText: 'Status',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      items: const [
        DropdownMenuItem<bool?>(
          value: null,
          child: Text('All Status'),
        ),
        DropdownMenuItem<bool?>(
          value: true,
          child: Text('Active'),
        ),
        DropdownMenuItem<bool?>(
          value: false,
          child: Text('Inactive'),
        ),
      ],
      onChanged: (value) {
        setState(() {
          _selectedStatus = value;
        });
      },
    );
  }

  Widget _buildUserRow(AppUser user) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 20,
                  child: Icon(Icons.person),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    user.displayName,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            flex: 2,
            child: Text(
              user.email,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          Expanded(
            child: _buildRoleBadge(user.role),
          ),

          Expanded(
            child: _buildStatusBadge(user.isActive),
          ),

          Expanded(
            child: IconButton(
              tooltip: 'Edit user',
              icon: const Icon(
                Icons.edit_outlined,
              ),
              onPressed: () {
                _editUser(user);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              'User',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Email',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Role',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Status',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Actions',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.green.shade50
            : Colors.red.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isActive
              ? Colors.green.shade700
              : Colors.red.shade700,
        ),
      ),
    );
  }

  Widget _buildRoleBadge(UserRole role) {
    String label;

    switch (role) {
      case UserRole.admin:
        label = 'Admin';
        break;

      case UserRole.examiner:
        label = 'Examiner';
        break;

      case UserRole.examinee:
        label = 'Examinee';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.blue.shade700,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Users',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Manage Question Bank users',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),

          const SizedBox(height: 30),

          Expanded(
            child: Card(
              elevation: 2,
                child: _buildUserContent(),
            ),
          ),
        ],
      ),
    );
  }
}