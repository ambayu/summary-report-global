import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/models/enums.dart';
import '../../shared/widgets/access_denied_state.dart';

class ManageRolesPage extends ConsumerWidget {
  const ManageRolesPage({super.key});

  Future<void> _openRoleEditor(
    BuildContext context,
    WidgetRef ref, {
    RoleDefinition? role,
  }) async {
    final settingsRepository = ref.read(settingsRepositoryProvider);
    final settings = settingsRepository.settings;
    final result = await Navigator.of(context).push<RoleDefinition>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _RoleEditorPage(role: role, roles: settings.roles),
      ),
    );
    if (result == null || !context.mounted) return;

    final nextRoles = AppRole.sortDefinitions([
      for (final item in settings.roles)
        if (item.key != result.key) item,
      result,
    ]);
    await settingsRepository.save(settings.copyWith(roles: nextRoles));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Role ${result.label} berhasil disimpan')),
    );
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
            appBar: AppBar(title: const Text('Manajemen Role')),
            body: const AccessDeniedState(
              message: 'Role Anda belum memiliki akses ke manajemen role.',
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Manajemen Role')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              _SectionHeader(
                title: 'Daftar Role',
                description:
                    'Role baru bisa ditambah dari sini, lalu permission menu dipilih saat membuat atau mengedit role.',
                action: FilledButton.icon(
                  onPressed: () => _openRoleEditor(context, ref),
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah Role'),
                ),
              ),
              const SizedBox(height: 12),
              ...settings.roles.map(
                (role) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _RoleCard(
                    role: role,
                    onEdit: AppRole.isOwner(role.key)
                        ? null
                        : () => _openRoleEditor(context, ref, role: role),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({required this.role, required this.onEdit});

  final RoleDefinition role;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final roleLabel = role.label.trim().isEmpty
        ? AppRole.labelForKey(role.key)
        : role.label;
    final permissions = role.permissions
        .where(roleConfigurablePermissions.contains)
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 420;
                final info = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      roleLabel,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      role.key,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                );
                final actions = Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (role.isSystem) const Chip(label: Text('System')),
                    if (onEdit != null)
                      OutlinedButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Edit'),
                      ),
                  ],
                );

                if (isCompact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      info,
                      const SizedBox(height: 10),
                      actions,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: info),
                    const SizedBox(width: 12),
                    actions,
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            if (permissions.isEmpty)
              Text(
                'Belum ada permission menu dipilih untuk role ini.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: permissions
                    .map((permission) => Chip(label: Text(permission.label)))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class _RoleEditorPage extends StatefulWidget {
  const _RoleEditorPage({required this.role, required this.roles});

  final RoleDefinition? role;
  final List<RoleDefinition> roles;

  @override
  State<_RoleEditorPage> createState() => _RoleEditorPageState();
}

class _RoleEditorPageState extends State<_RoleEditorPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _labelController;
  late Set<AppPermission> _permissions;

  bool get _isEditing => widget.role != null;
  bool get _isSystem => widget.role?.isSystem ?? false;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.role?.label ?? '');
    _permissions = (widget.role?.permissions ?? const <AppPermission>[])
        .where(roleConfigurablePermissions.contains)
        .toSet();
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final trimmedLabel = _labelController.text.trim();
    final roleKey = _isEditing
        ? widget.role!.key
        : AppRole.normalizeKey(trimmedLabel);

    if (roleKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama role belum valid')),
      );
      return;
    }

    final exists = widget.roles.any(
      (item) => item.key == roleKey && item.key != widget.role?.key,
    );
    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama role sudah digunakan')),
      );
      return;
    }

    Navigator.of(context).pop(
      RoleDefinition(
        key: roleKey,
        label: trimmedLabel,
        permissions: _permissions.toList(),
        isSystem: _isSystem,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Role' : 'Tambah Role')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _labelController,
              decoration: const InputDecoration(
                labelText: 'Nama Role',
                prefixIcon: Icon(Icons.badge_outlined),
                helperText:
                    'Nama role bisa diubah. Key internal role tetap aman dan tidak ikut berubah.',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nama role wajib diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Permission Menu',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            const Text(
              'Pilih menu apa saja yang boleh dilihat oleh role ini.',
            ),
            const SizedBox(height: 12),
            ...roleConfigurablePermissions.map(
              (permission) => CheckboxListTile(
                value: _permissions.contains(permission),
                contentPadding: EdgeInsets.zero,
                title: Text(permission.label),
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _permissions.add(permission);
                    } else {
                      _permissions.remove(permission);
                    }
                  });
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Simpan Role'),
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
    return LayoutBuilder(
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
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
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
    );
  }
}
