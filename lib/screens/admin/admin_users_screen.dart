import 'package:flutter/material.dart';
import '../../services/service_locator.dart';
import '../../utils/helpers.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/error_widget.dart';
import '../../widgets/common/empty_widget.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List<dynamic> _users = [];
  bool _isLoading = true;
  String? _error;
  final _searchCtrl = TextEditingController();

  final _roleLabels = {1: 'Admin', 2: 'Staff', 3: 'Customer', 4: 'Shipper'};
  final _roleColors = {1: Colors.purple, 2: Colors.blue, 3: Colors.teal, 4: Colors.orange};

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUsers({String? search}) async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final res = await sl.adminService.getUsers(pageSize: 50, search: search);
      if (res.success && res.data != null) {
        final data = res.data;
        if (data is List) {
          setState(() => _users = data);
        } else if (data is Map && data['items'] is List) {
          setState(() => _users = data['items'] as List);
        } else {
          setState(() => _users = []);
        }
      }
    } catch (e) {
      setState(() => _error = e.toString());
    }
    setState(() => _isLoading = false);
  }

  Future<void> _changeStatus(int userId, bool currentlyActive) async {
    try {
      final res = await sl.adminService.changeUserStatus(userId, !currentlyActive);
      if (res.success) {
        Helpers.showSnackBar(context, currentlyActive ? 'Đã vô hiệu hóa tài khoản' : 'Đã kích hoạt tài khoản');
        _loadUsers();
      } else {
        Helpers.showSnackBar(context, res.message ?? 'Thất bại', isError: true);
      }
    } catch (_) {
      Helpers.showSnackBar(context, 'Có lỗi xảy ra', isError: true);
    }
  }

  Future<void> _changeRole(int userId, int currentRole) async {
    final selected = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Đổi vai trò'),
        children: [
          for (final entry in _roleLabels.entries)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, entry.key),
              child: Row(children: [
                Icon(Icons.circle, size: 8, color: _roleColors[entry.key]),
                const SizedBox(width: 8),
                Text(entry.value, style: TextStyle(fontWeight: entry.key == currentRole ? FontWeight.bold : FontWeight.normal)),
              ]),
            ),
        ],
      ),
    );
    if (selected == null || selected == currentRole) return;
    try {
      final res = await sl.adminService.changeUserRole(userId, selected);
      if (res.success) {
        Helpers.showSnackBar(context, 'Đã cập nhật vai trò → ${_roleLabels[selected]}');
        _loadUsers();
      } else {
        Helpers.showSnackBar(context, res.message ?? 'Thất bại', isError: true);
      }
    } catch (_) {
      Helpers.showSnackBar(context, 'Có lỗi xảy ra', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý người dùng'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm theo tên, email...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchCtrl.clear(); _loadUsers(); })
                    : null,
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onSubmitted: (v) => _loadUsers(search: v),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const LoadingWidget()
          : _error != null
              ? AppErrorWidget(message: _error!, onRetry: _loadUsers)
              : _users.isEmpty
                  ? const EmptyWidget(icon: Icons.people_outline, message: 'Không có người dùng')
                  : RefreshIndicator(
                      onRefresh: _loadUsers,
                      child: ListView.builder(
                        itemCount: _users.length,
                        itemBuilder: (_, i) => _buildUserTile(_users[i] as Map<String, dynamic>),
                      ),
                    ),
    );
  }

  Widget _buildUserTile(Map<String, dynamic> user) {
    final userId = (user['userId'] ?? user['id'] ?? 0) as int;
    final name = user['fullName'] ?? user['username'] ?? 'Unknown';
    final email = user['email'] ?? '';
    final role = (user['role'] ?? 3) as int;
    final isActive = user['isActive'] ?? user['status'] == 'ACTIVE';
    final avatarUrl = user['avatarUrl'];

    return ListTile(
      leading: CircleAvatar(
        radius: 22,
        backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl as String) : null,
        backgroundColor: Colors.grey.shade200,
        child: avatarUrl == null ? const Icon(Icons.person, color: Colors.grey) : null,
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(email, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        GestureDetector(
          onTap: () => _changeRole(userId, role),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: (_roleColors[role] ?? Colors.grey).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(_roleLabels[role] ?? 'User',
              style: TextStyle(color: _roleColors[role] ?? Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 8),
        Switch(
          value: isActive as bool,
          onChanged: (_) => _changeStatus(userId, isActive as bool),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ]),
    );
  }
}
