import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/models/product.dart';
import '../../core/utils/currency.dart';

class ProdukPage extends ConsumerWidget {
  const ProdukPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.read(productRepositoryProvider);

    Future<void> showAddDialog() async {
      final nameController = TextEditingController();
      final categoryController = TextEditingController();
      final priceController = TextEditingController();
      final costController = TextEditingController(text: '0');
      final stockController = TextEditingController(text: '0');

      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Tambah Produk'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Nama produk'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: categoryController,
                    decoration: const InputDecoration(labelText: 'Kategori'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: priceController,
                    decoration: const InputDecoration(labelText: 'Harga jual'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: costController,
                    decoration: const InputDecoration(labelText: 'Harga modal'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: stockController,
                    decoration: const InputDecoration(labelText: 'Stok'),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
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
                    category: categoryController.text,
                    sellPrice: double.tryParse(priceController.text) ?? 0,
                    costPrice: double.tryParse(costController.text) ?? 0,
                    stock: int.tryParse(stockController.text) ?? 0,
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
                child: const Text('Simpan'),
              ),
            ],
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu Produk'),
        actions: [
          IconButton(
            onPressed: showAddDialog,
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: repository.listenable,
        builder: (context, box, child) {
          final list = repository.getAll();
          if (list.isEmpty) {
            return Center(
              child: FilledButton.icon(
                onPressed: showAddDialog,
                icon: const Icon(Icons.add),
                label: const Text('Tambah Menu'),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final product = list[index];
              return _ProductItem(
                product: product,
                onChanged: repository.update,
              );
            },
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

class _ProductItem extends StatelessWidget {
  const _ProductItem({required this.product, required this.onChanged});

  final Product product;
  final Future<void> Function(Product product) onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(product.name),
        subtitle: Text(
          '${product.category} • ${formatCurrency(product.sellPrice)}\nStok: ${product.stock}',
        ),
        isThreeLine: true,
        trailing: Switch(
          value: product.available,
          onChanged: (value) {
            onChanged(product.copyWith(available: value));
          },
        ),
      ),
    );
  }
}
