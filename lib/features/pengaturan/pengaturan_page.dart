import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/models/app_settings.dart';
import '../../core/models/enums.dart';

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
  }

  @override
  void dispose() {
    _cafeController.dispose();
    _taxController.dispose();
    _serviceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repository = ref.read(settingsRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _cafeController,
              decoration: const InputDecoration(
                labelText: 'Nama Cafe',
                prefixIcon: Icon(Icons.store_outlined),
              ),
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
            const SizedBox(height: 16),
            Text(
              'Metode Pembayaran Aktif',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...PaymentMethod.values.map(
              (method) => CheckboxListTile(
                value: _activePayments.contains(method),
                title: Text(method.label),
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
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () async {
                if (!_formKey.currentState!.validate()) return;

                final next = AppSettings(
                  cafeName: _cafeController.text.trim(),
                  taxPercent: double.tryParse(_taxController.text) ?? 0,
                  servicePercent: double.tryParse(_serviceController.text) ?? 0,
                  activePayments: _activePayments.toList(),
                );

                await repository.save(next);
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
