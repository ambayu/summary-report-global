import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/models/app_user.dart';
import '../../core/models/enums.dart';
import '../../shared/widgets/access_denied_state.dart';

class ManageUsersPage extends ConsumerWidget {
  const ManageUsersPage({super.key});

  Future<void> _openUserEditor(
    BuildContext context,
    WidgetRef ref, {
    AppUser? user,
  }) async {
    final settings = ref.read(settingsRepositoryProvider).settings;
    final roles = settings.assignableRoles;
    if (roles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Belum ada role yang bisa dipilih')),
      );
      return;
    }

    final draft = await Navigator.of(context).push<_PendingUser>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _UserEditorPage(roles: roles, user: user),
      ),
    );
    if (draft == null || !context.mounted) return;

    final authRepository = ref.read(authRepositoryProvider);
    try {
      if (user == null) {
        await authRepository.createUser(
          username: draft.username,
          password: draft.password,
          role: draft.role,
        );
      } else {
        await authRepository.updateUser(
          currentUsername: user.username,
          newUsername: draft.username,
          newPassword: draft.password.trim().isEmpty ? null : draft.password,
          role: draft.role,
        );
      }
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            user == null
                ? 'Pengguna berhasil ditambahkan'
                : 'Pengguna berhasil diperbarui',
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _confirmDeleteUser(
    BuildContext context,
    WidgetRef ref,
    AppUser user,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Hapus pengguna?'),
          content: Text(
            'Pengguna "${user.username}" dengan role ${user.roleLabel} akan dihapus.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(authRepositoryProvider).deleteUser(user.username);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pengguna ${user.username} berhasil dihapus')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authRepository = ref.read(authRepositoryProvider);
    final session = authRepository.currentSession;
    final settingsRepository = ref.read(settingsRepositoryProvider);

    return ValueListenableBuilder(
      valueListenable: settingsRepository.listenable,
      builder: (context, box, child) {
        final settings = settingsRepository.settings;
        if (!settings.hasPermission(
          session?.roleKey,
          AppPermission.manageUsers,
        )) {
          return Scaffold(
            appBar: AppBar(title: const Text('Manajemen Pengguna')),
            body: const AccessDeniedState(
              message: 'Role Anda belum memiliki akses ke manajemen pengguna.',
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Manajemen Pengguna')),
          body: ValueListenableBuilder(
            valueListenable: authRepository.usersListenable,
            builder: (context, usersBox, child) {
              final users = authRepository.getAllUsers();
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  _SectionHeader(
                    title: 'Daftar Pengguna',
                    description:
                        'Tambah pengguna baru dan atur role-nya dari sini. Setiap pengguna juga bisa diedit kembali.',
                    action: FilledButton.icon(
                      onPressed: () => _openUserEditor(context, ref),
                      icon: const Icon(Icons.person_add_alt_1),
                      label: const Text('Tambah Pengguna'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (users.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Belum ada pengguna terdaftar.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    )
                  else
                    ...users.map(
                      (user) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _UserCard(
                          user: user,
                          isCurrentUser: user.username == session?.name,
                          isOwner: AppRole.isOwner(user.roleKey),
                          onEdit: () => _openUserEditor(
                            context,
                            ref,
                            user: user,
                          ),
                          onDelete: AppRole.isOwner(user.roleKey) ||
                                  user.username == session?.name
                              ? null
                              : () => _confirmDeleteUser(context, ref, user),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.user,
    required this.isCurrentUser,
    required this.isOwner,
    required this.onEdit,
    required this.onDelete,
  });

  final AppUser user;
  final bool isCurrentUser;
  final bool isOwner;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final roleLetter = user.roleLabel.isEmpty
        ? '?'
        : user.roleLabel[0].toUpperCase();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(child: Text(roleLetter)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.username,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.roleLabel,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Dibuat ${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit'),
                ),
                if (onDelete != null)
                  IconButton.filledTonal(
                    tooltip: 'Hapus pengguna',
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline),
                  )
                else
                  Chip(
                    label: Text(isCurrentUser ? 'Login aktif' : 'Owner'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _UserEditorPage extends StatefulWidget {
  const _UserEditorPage({required this.roles, this.user});

  final List<RoleDefinition> roles;
  final AppUser? user;

  @override
  State<_UserEditorPage> createState() => _UserEditorPageState();
}

class _UserEditorPageState extends State<_UserEditorPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late String _roleKey;

  bool get _isEditing => widget.user != null;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(
      text: widget.user?.username ?? '',
    );
    _passwordController = TextEditingController();
    _roleKey = widget.roles
            .where((role) => role.key == widget.user?.roleKey)
            .firstOrNull
            ?.key ??
        widget.roles.first.key;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final role = widget.roles.firstWhere(
      (item) => item.key == _roleKey,
      orElse: () => widget.roles.first,
    );
    Navigator.of(context).pop(
      _PendingUser(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        role: role,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Pengguna' : 'Tambah Pengguna'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Username wajib diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: _isEditing ? 'Password Baru' : 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                helperText: _isEditing
                    ? 'Kosongkan jika password tidak diubah'
                    : null,
              ),
              validator: (value) {
                if (_isEditing && (value == null || value.trim().isEmpty)) {
                  return null;
                }
                if (value == null || value.trim().length < 4) {
                  return 'Password minimal 4 karakter';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _roleKey,
              decoration: const InputDecoration(
                labelText: 'Role',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              items: widget.roles
                  .map(
                    (role) => DropdownMenuItem<String>(
                      value: role.key,
                      child: Text(role.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _roleKey = value);
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: FilledButton.icon(
          onPressed: _submit,
          icon: Icon(_isEditing ? Icons.save_outlined : Icons.person_add_alt_1),
          label: Text(_isEditing ? 'Simpan Perubahan' : 'Simpan Pengguna'),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.description,
    required this.action,
  });

  final String title;
  final String description;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 520) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(description),
                  const SizedBox(height: 12),
                  action,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(description),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                action,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PendingUser {
  const _PendingUser({
    required this.username,
    required this.password,
    required this.role,
  });

  final String username;
  final String password;
  final RoleDefinition role;
}
