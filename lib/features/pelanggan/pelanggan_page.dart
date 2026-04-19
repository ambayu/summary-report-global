import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/utils/currency.dart';

class PelangganPage extends ConsumerStatefulWidget {
  const PelangganPage({super.key});

  @override
  ConsumerState<PelangganPage> createState() => _PelangganPageState();
}

class _PelangganPageState extends ConsumerState<PelangganPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repository = ref.read(customerRepositoryProvider);

    Future<void> showCustomerDialog({
      String? id,
      String? name,
      String? phone,
    }) async {
      final formKey = GlobalKey<FormState>();
      final nameController = TextEditingController(text: name ?? '');
      final phoneController = TextEditingController(text: phone ?? '');
      final isEdit = id != null;

      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(isEdit ? 'Edit Pelanggan' : 'Tambah Pelanggan'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nama'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nama pelanggan wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'No. HP'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'No. HP wajib diisi';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                if (isEdit) {
                  await repository.update(
                    id: id,
                    name: nameController.text,
                    phone: phoneController.text,
                  );
                } else {
                  await repository.create(
                    name: nameController.text,
                    phone: phoneController.text,
                  );
                }

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              },
              child: Text(isEdit ? 'Update' : 'Simpan'),
            ),
          ],
        ),
      );

      nameController.dispose();
      phoneController.dispose();
    }

    Future<void> confirmDelete({
      required String id,
      required String name,
    }) async {
      final shouldDelete = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Hapus pelanggan?'),
          content: Text('Data pelanggan "$name" akan dihapus.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Hapus'),
            ),
          ],
        ),
      );

      if (shouldDelete == true) {
        await repository.delete(id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pelanggan berhasil dihapus')),
          );
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pelanggan'),
        actions: [
          IconButton(
            onPressed: showCustomerDialog,
            icon: const Icon(Icons.person_add_alt_1_outlined),
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: repository.listenable,
        builder: (context, box, child) {
          final query = _searchQuery.trim().toLowerCase();
          final list = repository.getAll().where((customer) {
            if (query.isEmpty) return true;
            return customer.name.toLowerCase().contains(query) ||
                customer.phone.toLowerCase().contains(query);
          }).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Cari pelanggan',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                          icon: const Icon(Icons.close),
                        ),
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
              const SizedBox(height: 12),
              if (list.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      query.isEmpty
                          ? 'Belum ada data pelanggan.'
                          : 'Pelanggan tidak ditemukan.',
                    ),
                  ),
                )
              else
                ...list.map(
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
                        '${customer.phone}\nTotal: ${formatCurrency(customer.totalPurchase)} | Point: ${customer.points}',
                      ),
                      isThreeLine: true,
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') {
                            showCustomerDialog(
                              id: customer.id,
                              name: customer.name,
                              phone: customer.phone,
                            );
                            return;
                          }
                          if (value == 'delete') {
                            confirmDelete(id: customer.id, name: customer.name);
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: 'edit',
                            child: Text('Edit'),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text('Hapus'),
                          ),
                        ],
                        icon: customer.isFavorite
                            ? const Icon(Icons.star, color: Colors.amber)
                            : const Icon(Icons.more_vert),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: showCustomerDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
