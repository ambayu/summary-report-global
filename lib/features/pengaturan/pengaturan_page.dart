import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/models/app_settings.dart';
import '../../core/models/app_user.dart';
import '../../core/models/enums.dart';
import '../../core/utils/export_file_helper.dart';
import '../../shared/widgets/access_denied_state.dart';
import '../../shared/widgets/brand_avatar.dart';

class PengaturanPage extends ConsumerStatefulWidget {
  const PengaturanPage({super.key});

  @override
  ConsumerState<PengaturanPage> createState() => _PengaturanPageState();
}

class _PengaturanPageState extends ConsumerState<PengaturanPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _cafeController;
  late TextEditingController _taxController;
  late TextEditingController _serviceController;
  late Set<PaymentMethod> _activePayments;
  String? _logoBase64;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsRepositoryProvider).settings;
    _cafeController = TextEditingController(text: settings.cafeName);
    _taxController = TextEditingController(
      text: settings.taxPercent.toStringAsFixed(0),
    );
    _serviceController = TextEditingController(
      text: settings.servicePercent.toStringAsFixed(0),
    );
    _activePayments = settings.activePayments.toSet();
    _logoBase64 = settings.logoBase64;
  }

  @override
  void dispose() {
    _cafeController.dispose();
    _taxController.dispose();
    _serviceController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final file = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    if (file == null) return;

    final picked = file.files.single;
    final bytes =
        picked.bytes ??
        (picked.path == null ? null : await File(picked.path!).readAsBytes());
    if (bytes == null || bytes.isEmpty) return;

    setState(() => _logoBase64 = base64Encode(bytes));
  }

  Future<void> _exportLogoAsAppIconCandidate() async {
    if (_logoBase64 == null || _logoBase64!.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upload logo dulu sebelum export icon')),
      );
      return;
    }

    final bytes = BrandAvatar.tryDecodeLogo(_logoBase64);
    if (bytes == null || bytes.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logo tidak valid untuk dijadikan icon')),
      );
      return;
    }

    final savePath = await ExportFileHelper.saveBytes(
      dialogTitle: 'Simpan Calon App Icon',
      fileName: 'app_icon_candidate.png',
      allowedExtensions: const ['png'],
      bytes: bytes,
    );

    if (savePath == null || !mounted) return;

    await ExportFileHelper.promptOpenFile(
      context,
      filePath: savePath,
      successMessage:
          'Calon app icon berhasil disimpan di:\n$savePath\n\nGunakan file ini untuk mengganti asset icon build lalu jalankan generator app icon.',
    );
  }

  Future<void> _showAddUserDialog() async {
    final authRepository = ref.read(authRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    final formKey = GlobalKey<FormState>();
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    var role = UserRole.kasir;
    var saving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Tambah User'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        prefixIcon: Icon(Icons.person_add_alt_1_outlined),
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
                      controller: passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().length < 4) {
                          return 'Password minimal 4 karakter';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<UserRole>(
                      initialValue: role,
                      decoration: const InputDecoration(
                        labelText: 'Role',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      items: UserRole.values
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(item.label),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() => role = value);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Batal'),
                ),
                FilledButton(
                  onPressed: saving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setDialogState(() => saving = true);
                          try {
                            await authRepository.createUser(
                              username: usernameController.text,
                              password: passwordController.text,
                              role: role,
                            );
                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop();
                            }
                            if (mounted) {
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('User berhasil ditambahkan'),
                                ),
                              );
                            }
                          } catch (error) {
                            if (!mounted) return;
                            messenger.showSnackBar(
                              SnackBar(content: Text(error.toString())),
                            );
                          } finally {
                            if (dialogContext.mounted) {
                              setDialogState(() => saving = false);
                            }
                          }
                        },
                  child: Text(saving ? 'Menyimpan...' : 'Tambah User'),
                ),
              ],
            );
          },
        );
      },
    );

    usernameController.dispose();
    passwordController.dispose();
  }

  Future<void> _confirmDeleteUser(AppUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Hapus user?'),
          content: Text(
            'User "${user.username}" dengan role ${user.role.label} akan dihapus.',
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
    if (confirmed != true) return;

    try {
      await ref.read(authRepositoryProvider).deleteUser(user.username);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User ${user.username} berhasil dihapus')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsRepository = ref.read(settingsRepositoryProvider);
    final authRepository = ref.read(authRepositoryProvider);
    final session = authRepository.currentSession;

    if (session?.role != UserRole.owner) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pengaturan')),
        body: const AccessDeniedState(
          message:
              'Halaman pengaturan hanya dapat dibuka oleh owner. Admin dan kasir tetap bisa bekerja sesuai menu yang diizinkan.',
        ),
      );
    }

    final previewBrandName = _cafeController.text.trim().isEmpty
        ? 'Summary Cafe'
        : _cafeController.text.trim();

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Brand Cafe',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        BrandAvatar(
                          brandName: previewBrandName,
                          logoBase64: _logoBase64,
                          radius: 32,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            _logoBase64 == null
                                ? 'Belum ada logo. Upload logo agar tampil di login dan identitas brand aplikasi.'
                                : 'Logo brand aktif dan akan dipakai di login serta header aplikasi.',
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
                          onPressed: _pickLogo,
                          icon: const Icon(Icons.upload_file_outlined),
                          label: const Text('Upload Logo'),
                        ),
                        if (_logoBase64 != null)
                          OutlinedButton.icon(
                            onPressed: () => setState(() => _logoBase64 = null),
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Hapus Logo'),
                          ),
                        if (_logoBase64 != null)
                          OutlinedButton.icon(
                            onPressed: _exportLogoAsAppIconCandidate,
                            icon: const Icon(Icons.app_shortcut_outlined),
                            label: const Text('Calon App Icon Build'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _cafeController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Cafe',
                        prefixIcon: Icon(Icons.store_outlined),
                      ),
                      onChanged: (_) => setState(() {}),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nama cafe wajib diisi';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _taxController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Pajak (%)',
                        prefixIcon: Icon(Icons.percent),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _serviceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Service Charge (%)',
                        prefixIcon: Icon(Icons.room_service_outlined),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Metode Pembayaran Aktif',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ...PaymentMethod.values.map(
                      (method) => CheckboxListTile(
                        value: _activePayments.contains(method),
                        title: Text(method.label),
                        contentPadding: EdgeInsets.zero,
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              _activePayments.add(method);
                            } else {
                              _activePayments.remove(method);
                            }
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hak Akses per Role',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Ringkasan ini membantu owner melihat menu apa saja yang tersedia untuk owner, admin, dan kasir.',
                    ),
                    const SizedBox(height: 12),
                    ...UserRole.values.map((role) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                role.label,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: role.permissions
                                    .map(
                                      (permission) => Chip(
                                        label: Text(permission.label),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Manajemen User',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Owner bisa menambah akun baru untuk admin atau kasir langsung dari sini.',
                              ),
                            ],
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: _showAddUserDialog,
                          icon: const Icon(Icons.person_add_alt_1),
                          label: const Text('Tambah User'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ValueListenableBuilder(
                      valueListenable: authRepository.usersListenable,
                      builder: (context, box, child) {
                        final users = authRepository.getAllUsers();
                        if (users.isEmpty) {
                          return const Text('Belum ada user terdaftar.');
                        }

                        return Column(
                          children: users.map((user) {
                            final isCurrentUser = user.username == session!.name;
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                leading: CircleAvatar(
                                  child: Text(user.role.label[0]),
                                ),
                                title: Text(user.username),
                                subtitle: Text(
                                  '${user.role.label}\nDibuat ${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}',
                                ),
                                isThreeLine: true,
                                trailing: isCurrentUser || user.role == UserRole.owner
                                    ? Chip(
                                        label: Text(
                                          isCurrentUser ? 'Login aktif' : 'Owner',
                                        ),
                                      )
                                    : IconButton(
                                        tooltip: 'Hapus user',
                                        onPressed: () => _confirmDeleteUser(user),
                                        icon: const Icon(Icons.delete_outline),
                                      ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () async {
                if (!_formKey.currentState!.validate()) return;

                final next = AppSettings(
                  cafeName: _cafeController.text.trim(),
                  logoBase64: _logoBase64,
                  taxPercent: double.tryParse(_taxController.text) ?? 0,
                  servicePercent: double.tryParse(_serviceController.text) ?? 0,
                  activePayments: _activePayments.toList(),
                );

                await settingsRepository.save(next);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Pengaturan berhasil disimpan'),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.save_outlined),
              label: const Text('Simpan Pengaturan'),
            ),
          ],
        ),
      ),
    );
  }
}
