import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/auth_api.dart';
import '../core/api_exceptions.dart';
import '../core/breakpoints.dart';
import '../models/app_user.dart';
import '../widgets/list_load_body.dart';

/// Экран администратора: пользователи и роли (только admin на сервере).
class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  bool _loading = true;
  String? _error;
  List<AppUser> _users = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final users = await context.read<AuthApi>().listUsers();
      if (!mounted) return;
      setState(() {
        _users = users;
        _loading = false;
      });
    } on ForbiddenException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('403: ${e.message}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Пользователи и роли'),
        actions: [
          IconButton(
            onPressed: _load,
            tooltip: 'Обновить',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? ConnectionProblem(message: _error, onRetry: _load)
              : _users.isEmpty
              ? const Center(child: Text('Пользователей нет'))
              : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _users.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final u = _users[i];
                  final phone =
                      MediaQuery.sizeOf(context).width < Breakpoints.phone;
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(u.role.label.characters.first),
                    ),
                    title: Text(
                      u.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      phone
                          ? '${u.username}\n${u.role.label}'
                          : '${u.username} · ${u.email}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    isThreeLine: phone,
                    trailing:
                        phone
                            ? null
                            : Chip(
                              label: Text(
                                u.role.label,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                  );
                },
              ),
    );
  }
}
