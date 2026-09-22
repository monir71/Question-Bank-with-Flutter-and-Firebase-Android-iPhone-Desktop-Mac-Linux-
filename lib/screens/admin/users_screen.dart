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
  final TextEditingController _searchController = TextEditingController();

  List<AppUser> _users = [];

  bool _isLoading = true;
  String? _errorMessage;

  UserRole? _selectedRole;
  bool? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AppUser> get _filteredUsers {
    final searchText = _searchController.text.trim().toLowerCase();

    return _users.where((user) {
      final matchesSearch =
          searchText.isEmpty ||
          user.username.toLowerCase().contains(searchText) ||
          user.displayName.toLowerCase().contains(searchText) ||
          user.email.toLowerCase().contains(searchText);

      final matchesRole = _selectedRole == null || user.role == _selectedRole;

      final matchesStatus =
          _selectedStatus == null || user.isActive == _selectedStatus;

      return matchesSearch && matchesRole && matchesStatus;
    }).toList();
  }

  Future<void> _loadUsers() async {
    try {
      final users = await _userService.getAllUsers();

      if (!mounted) return;

      setState(() {
        _users = users;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _editUser(AppUser user) async {
    final updated = await showDialog<bool>(
      context: context,
      builder: (context) {
        return EditUserDialog(user: user, userService: _userService);
      },
    );

    if (updated != true) return;

    await _loadUsers();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('User updated successfully.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _roleLabel(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.examiner:
        return 'Examiner';
      case UserRole.examinee:
        return 'Examinee';
    }
  }

  IconData _roleIcon(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Icons.admin_panel_settings_outlined;
      case UserRole.examiner:
        return Icons.fact_check_outlined;
      case UserRole.examinee:
        return Icons.person_outline;
    }
  }

  Widget _buildRoleDropdown() {
    return DropdownButtonFormField<UserRole?>(
      initialValue: _selectedRole,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Role',
        prefixIcon: const Icon(Icons.badge_outlined, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
      items: [
        const DropdownMenuItem<UserRole?>(
          value: null,
          child: Text('All Roles'),
        ),
        ...UserRole.values.map(
          (role) => DropdownMenuItem<UserRole?>(
            value: role,
            child: Text(_roleLabel(role)),
          ),
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
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Status',
        prefixIcon: const Icon(Icons.toggle_on_outlined, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
      items: const [
        DropdownMenuItem<bool?>(value: null, child: Text('All Status')),
        DropdownMenuItem<bool?>(value: true, child: Text('Active')),
        DropdownMenuItem<bool?>(value: false, child: Text('Inactive')),
      ],
      onChanged: (value) {
        setState(() {
          _selectedStatus = value;
        });
      },
    );
  }

  Widget _buildSearchAndFilters() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 850;

        if (isNarrow) {
          return Column(
            children: [
              _buildSearchField(),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(child: _buildRoleDropdown()),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatusDropdown()),
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: _buildSearchField()),

            const SizedBox(width: 12),

            SizedBox(width: 180, child: _buildRoleDropdown()),

            const SizedBox(width: 12),

            SizedBox(width: 180, child: _buildStatusDropdown()),
          ],
        );
      },
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (_) {
        setState(() {});
      },
      decoration: InputDecoration(
        hintText: 'Search by name, username or email...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                tooltip: 'Clear search',
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  setState(() {});
                },
              )
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 12,
        ),
      ),
    );
  }

  Widget _buildUserCount() {
    final count = _filteredUsers.length;

    return Row(
      children: [
        Icon(Icons.people_outline, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 7),
        Text(
          'Showing $count ${count == 1 ? 'user' : 'users'}',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildUserTable() {
    final users = _filteredUsers;

    if (users.isEmpty) {
      return _buildNoMatchingUsers();
    }

    return Column(
      children: [
        _buildUserHeader(),
        Divider(height: 1, color: Colors.grey.shade200),
        Expanded(
          child: ListView.separated(
            itemCount: users.length,
            separatorBuilder: (_, _) =>
                Divider(height: 1, color: Colors.grey.shade100),
            itemBuilder: (context, index) {
              return _buildUserRow(users[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUserHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      color: Colors.grey.shade50,
      child: const Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              'USER',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'EMAIL',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'ROLE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'STATUS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          SizedBox(
            width: 60,
            child: Text(
              'ACTION',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserRow(AppUser user) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                _buildUserAvatar(user),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        '@${user.username}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            flex: 3,
            child: Text(
              user.email,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
          ),

          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildRoleBadge(user.role),
            ),
          ),

          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildStatusBadge(user.isActive),
            ),
          ),

          SizedBox(
            width: 60,
            child: IconButton(
              tooltip: 'Edit user',
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: () => _editUser(user),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserAvatar(AppUser user) {
    if (user.photoUrl != null && user.photoUrl!.trim().isNotEmpty) {
      return CircleAvatar(
        radius: 21,
        backgroundImage: NetworkImage(user.photoUrl!),
      );
    }

    return CircleAvatar(
      radius: 21,
      backgroundColor: Colors.blue.shade50,
      child: Icon(Icons.person_outline, color: Colors.blue.shade700, size: 23),
    );
  }

  Widget _buildRoleBadge(UserRole role) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_roleIcon(role), size: 15, color: Colors.blue.shade700),

          const SizedBox(width: 5),

          Flexible(
            child: Text(
              _roleLabel(role),
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    final color = isActive ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.check_circle_outline : Icons.cancel_outlined,
            size: 15,
            color: color.shade700,
          ),

          const SizedBox(width: 5),

          Text(
            isActive ? 'Active' : 'Inactive',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoMatchingUsers() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_search_outlined,
                size: 34,
                color: Colors.blue.shade700,
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              'No matching users',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 6),

            Text(
              'Try changing your search or filters.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),

            const SizedBox(height: 12),

            const Text(
              'Unable to load users',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 8),

            Text(
              _errorMessage ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),

            const SizedBox(height: 16),

            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });

                _loadUsers();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return _buildLoading();
    }

    if (_errorMessage != null) {
      return _buildError();
    }

    if (_users.isEmpty) {
      return _buildNoMatchingUsers();
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(18),
          child: _buildSearchAndFilters(),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: _buildUserCount(),
          ),
        ),

        Expanded(child: _buildUserTable()),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --------------------------------------------------
          // Page Header
          // --------------------------------------------------
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.people_outline,
                  color: Colors.blue.shade800,
                  size: 27,
                ),
              ),

              const SizedBox(width: 14),

              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Users',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),

                    SizedBox(height: 4),

                    Text(
                      'Manage Question Bank users',
                      style: TextStyle(fontSize: 15, color: Colors.grey),
                    ),
                  ],
                ),
              ),

              if (!_isLoading && _users.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_users.length} Total',
                    style: TextStyle(
                      color: Colors.blue.shade800,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 24),

          // --------------------------------------------------
          // Main User Card
          // --------------------------------------------------
          Expanded(
            child: Card(
              elevation: 2,
              shadowColor: Colors.black.withValues(alpha: 0.08),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              clipBehavior: Clip.antiAlias,
              child: _buildContent(),
            ),
          ),
        ],
      ),
    );
  }
}
