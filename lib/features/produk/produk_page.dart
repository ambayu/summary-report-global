import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/models/enums.dart';
import '../../core/models/product.dart';
import '../../core/utils/currency.dart';
import '../../shared/widgets/access_denied_state.dart';
import '../../shared/widgets/product_thumbnail.dart';

class ProdukPage extends ConsumerStatefulWidget {
  const ProdukPage({super.key});

  @override
  ConsumerState<ProdukPage> createState() => _ProdukPageState();
}

class _ProdukPageState extends ConsumerState<ProdukPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final session = ref.read(authRepositoryProvider).currentSession;
    if (!(session?.role.hasPermission(AppPermission.produk) ?? false)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Menu Produk')),
        body: const AccessDeniedState(
          message: 'Role Anda belum memiliki akses ke menu produk.',
        ),
      );
    }

    final repository = ref.read(productRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu Produk'),
        actions: [
          IconButton(
            onPressed: () => _showProductDialog(context, repository),
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: repository.listenable,
        builder: (context, box, child) {
          final all = repository.getAll();
          final list = all.where((product) {
            if (_query.trim().isEmpty) return true;
            final q = _query.trim().toLowerCase();
            return product.name.toLowerCase().contains(q) ||
                product.category.toLowerCase().contains(q);
          }).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Cari menu atau kategori',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: 12),
              if (list.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Icon(Icons.local_cafe_outlined, size: 40),
                        const SizedBox(height: 8),
                        Text(
                          all.isEmpty
                              ? 'Belum ada menu produk.'
                              : 'Tidak ada menu yang cocok dengan pencarian.',
                        ),
                        const SizedBox(height: 10),
                        FilledButton.icon(
                          onPressed: () =>
                              _showProductDialog(context, repository),
                          icon: const Icon(Icons.add),
                          label: const Text('Tambah Menu'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...list.map(
                  (product) => _ProductItem(
                    product: product,
                    onToggleAvailability: () async {
                      await repository.update(
                        product.copyWith(available: !product.available),
                      );
                    },
                    onEdit: () => _showProductDialog(
                      context,
                      repository,
                      existing: product,
                    ),
                    onDelete: () =>
                        _confirmDelete(context, repository, product),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showProductDialog(context, repository),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showProductDialog(
    BuildContext context,
    dynamic repository, {
    Product? existing,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final isEdit = existing != null;
    final nameController = TextEditingController(text: existing?.name ?? '');
    final categoryController = TextEditingController(
      text: existing?.category ?? '',
    );
    final priceController = TextEditingController(
      text: existing == null ? '' : existing.sellPrice.toStringAsFixed(0),
    );
    final costController = TextEditingController(
      text: existing == null ? '0' : existing.costPrice.toStringAsFixed(0),
    );
    final stockController = TextEditingController(
      text: existing == null ? '0' : existing.stock.toString(),
    );
    var imageBase64 = existing?.imageBase64;
    var saving = false;
    var dialogClosed = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEdit ? 'Edit Produk' : 'Tambah Produk'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ProductThumbnail(
                      name: nameController.text.isEmpty
                          ? 'Menu Baru'
                          : nameController.text,
                      imageBase64: imageBase64,
                      width: 96,
                      height: 96,
                      radius: 20,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: saving
                              ? null
                              : () async {
                                  try {
                                    final file = await FilePicker.platform
                                        .pickFiles(
                                          type: FileType.image,
                                          allowMultiple: false,
                                          withData: false,
                                        );
                                    if (file == null ||
                                        !dialogContext.mounted) {
                                      return;
                                    }

                                    final picked = file.files.single;
                                    final bytes =
                                        picked.bytes ??
                                        (picked.path == null
                                            ? null
                                            : await File(
                                                picked.path!,
                                              ).readAsBytes());
                                    if (bytes == null || bytes.isEmpty) {
                                      messenger.showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Gambar tidak bisa dibaca. Coba pilih file lain.',
                                          ),
                                        ),
                                      );
                                      return;
                                    }

                                    if (!dialogContext.mounted) return;
                                    setDialogState(
                                      () => imageBase64 = base64Encode(bytes),
                                    );
                                  } catch (_) {
                                    if (!dialogContext.mounted) return;
                                    messenger.showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Upload gambar gagal. Coba ulangi lagi.',
                                        ),
                                      ),
                                    );
                                  }
                                },
                          icon: const Icon(Icons.image_outlined),
                          label: const Text('Upload Gambar'),
                        ),
                        if (imageBase64 != null)
                          OutlinedButton.icon(
                            onPressed: saving
                                ? null
                                : () =>
                                      setDialogState(() => imageBase64 = null),
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Hapus Gambar'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama produk',
                      ),
                      onChanged: (_) => setDialogState(() {}),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: categoryController,
                      decoration: const InputDecoration(labelText: 'Kategori'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: priceController,
                      decoration: const InputDecoration(
                        labelText: 'Harga jual',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: costController,
                      decoration: const InputDecoration(
                        labelText: 'Harga modal',
                      ),
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
                  onPressed: saving
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Batal'),
                ),
                FilledButton(
                  onPressed: saving
                      ? null
                      : () async {
                          if (nameController.text.trim().isEmpty) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Nama produk wajib diisi'),
                              ),
                            );
                            return;
                          }

                          setDialogState(() => saving = true);
                          try {
                            if (existing == null) {
                              await repository.create(
                                name: nameController.text,
                                category: categoryController.text,
                                imageBase64: imageBase64,
                                sellPrice:
                                    double.tryParse(priceController.text) ?? 0,
                                costPrice:
                                    double.tryParse(costController.text) ?? 0,
                                stock: int.tryParse(stockController.text) ?? 0,
                              );
                            } else {
                              await repository.update(
                                existing.copyWith(
                                  name: nameController.text.trim(),
                                  category:
                                      categoryController.text.trim().isEmpty
                                      ? 'Umum'
                                      : categoryController.text.trim(),
                                  imageBase64: imageBase64,
                                  sellPrice:
                                      double.tryParse(priceController.text) ??
                                      0,
                                  costPrice:
                                      double.tryParse(costController.text) ?? 0,
                                  stock:
                                      int.tryParse(stockController.text) ?? 0,
                                ),
                              );
                            }
                            if (dialogContext.mounted) {
                              dialogClosed = true;
                              Navigator.of(dialogContext).pop();
                            }
                          } catch (_) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Produk gagal disimpan. Coba ulangi lagi.',
                                ),
                              ),
                            );
                          } finally {
                            if (dialogContext.mounted && !dialogClosed) {
                              setDialogState(() => saving = false);
                            }
                          }
                        },
                  child: Text(saving ? 'Menyimpan...' : 'Simpan'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    categoryController.dispose();
    priceController.dispose();
    costController.dispose();
    stockController.dispose();
  }

  Future<void> _confirmDelete(
    BuildContext context,
    dynamic repository,
    Product product,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Hapus produk?'),
          content: Text(
            'Produk "${product.name}" akan dihapus dari daftar menu.',
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

    await repository.remove(product.id);
  }
}

class _ProductItem extends StatelessWidget {
  const _ProductItem({
    required this.product,
    required this.onToggleAvailability,
    required this.onEdit,
    required this.onDelete,
  });

  final Product product;
  final Future<void> Function() onToggleAvailability;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                ProductThumbnail(
                  name: product.name,
                  imageBase64: product.imageBase64,
                  width: 72,
                  height: 72,
                  radius: 18,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.category,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        formatCurrency(product.sellPrice),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('Stok: ${product.stock}'),
                    ],
                  ),
                ),
                Switch(
                  value: product.available,
                  onChanged: (_) => onToggleAvailability(),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Hapus'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
