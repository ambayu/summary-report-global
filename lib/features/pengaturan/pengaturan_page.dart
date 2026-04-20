import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/models/app_settings.dart';
import '../../core/models/enums.dart';
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
    _activePayments = settings.activePayments.toSet();
    _logoBase64 = settings.logoBase64;
  }

  @override
  void dispose() {
    _cafeController.dispose();
    _taxController.dispose();
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

  @override
  Widget build(BuildContext context) {
    final settingsRepository = ref.read(settingsRepositoryProvider);
    final authRepository = ref.read(authRepositoryProvider);
    final session = authRepository.currentSession;
    final currentSettings = settingsRepository.settings;

    if (!currentSettings.hasPermission(
      session?.roleKey,
      AppPermission.pengaturan,
    )) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pengaturan')),
        body: const AccessDeniedState(
          message: 'Role Anda belum memiliki akses ke halaman pengaturan ini.',
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
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
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
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: FilledButton.icon(
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;

                  final next = AppSettings(
                    cafeName: _cafeController.text.trim(),
                    logoBase64: _logoBase64,
                    taxPercent: double.tryParse(_taxController.text) ?? 0,
                    activePayments: _activePayments.toList(),
                    roles: currentSettings.roles,
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
            ),
          ],
        ),
      ),
    );
  }
}
