import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/utils/currency.dart';

class PelangganPage extends ConsumerWidget {
  const PelangganPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.read(customerRepositoryProvider);

    Future<void> showAddDialog() async {
      final nameController = TextEditingController();
      final phoneController = TextEditingController();

      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Tambah Pelanggan'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nama'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'No. HP'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () async {
                await repository.create(
                  name: nameController.text,
                  phone: phoneController.text,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pelanggan'),
        actions: [
          IconButton(
            onPressed: showAddDialog,
            icon: const Icon(Icons.person_add_alt_1_outlined),
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: repository.listenable,
        builder: (context, box, child) {
          final list = repository.getAll();
          if (list.isEmpty) {
            return const Center(child: Text('Belum ada data pelanggan.'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: list
                .map(
                  (customer) => Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          customer.name.isEmpty
                              ? '?'
                              : customer.name[0].toUpperCase(),
                        ),
                      ),
                      title: Text(customer.name),
                      subtitle: Text(
                        '${customer.phone}\nTotal: ${formatCurrency(customer.totalPurchase)} • Point: ${customer.points}',
                      ),
                      isThreeLine: true,
                      trailing: customer.isFavorite
                          ? const Icon(Icons.star, color: Colors.amber)
                          : null,
                    ),
                  ),
                )
                .toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: showAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
