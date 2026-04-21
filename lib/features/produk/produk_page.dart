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
  bool _importing = false;

  @override
  Widget build(BuildContext context) {
    final session = ref.read(authRepositoryProvider).currentSession;
    final settings = ref.read(settingsRepositoryProvider).settings;
    if (!settings.hasPermission(session?.roleKey, AppPermission.produk)) {
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
            tooltip: 'Import Excel',
            onPressed: _importing ? null : () => _importExcel(repository),
            icon: _importing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.upload_file_outlined),
          ),
          IconButton(
            onPressed: () => _openProductEditor(context, repository),
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
                              _openProductEditor(context, repository),
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
                    onEdit: () => _openProductEditor(
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
        onPressed: () => _openProductEditor(context, repository),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _openProductEditor(
    BuildContext context,
    dynamic repository, {
    Product? existing,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            _ProductEditorPage(repository: repository, existing: existing),
        fullscreenDialog: true,
      ),
    );
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

  Future<void> _importExcel(dynamic repository) async {
    setState(() => _importing = true);
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        withData: true,
      );
      if (picked == null || picked.files.isEmpty) return;

      final file = picked.files.single;
      final bytes =
          file.bytes ??
          (file.path == null ? null : await File(file.path!).readAsBytes());
      if (bytes == null || bytes.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File Excel tidak bisa dibaca.')),
        );
        return;
      }

      final imported = await repository.importFromXlsx(bytes);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            imported == 0
                ? 'Tidak ada data menu yang berhasil diimport.'
                : '$imported menu berhasil diimport dari Excel.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Import Excel gagal. Cek format file.')),
      );
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }
}

class _ProductEditorPage extends StatefulWidget {
  const _ProductEditorPage({required this.repository, this.existing});

  final dynamic repository;
  final Product? existing;

  @override
  State<_ProductEditorPage> createState() => _ProductEditorPageState();
}

class _ProductEditorPageState extends State<_ProductEditorPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _categoryController;
  late final TextEditingController _priceController;
  late final TextEditingController _costController;
  late final TextEditingController _stockController;

  String? _imageBase64;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _categoryController = TextEditingController(text: existing?.category ?? '');
    _priceController = TextEditingController(
      text: existing == null ? '' : existing.sellPrice.toStringAsFixed(0),
    );
    _costController = TextEditingController(
      text: existing == null ? '0' : existing.costPrice.toStringAsFixed(0),
    );
    _stockController = TextEditingController(
      text: existing == null ? '0' : existing.stock.toString(),
    );
    _imageBase64 = existing?.imageBase64;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _priceController.dispose();
    _costController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Produk' : 'Tambah Produk')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: ProductThumbnail(
                      name: _nameController.text.isEmpty
                          ? 'Menu Baru'
                          : _nameController.text,
                      imageBase64: _imageBase64,
                      width: 120,
                      height: 120,
                      radius: 26,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _saving ? null : _pickImage,
                        icon: const Icon(Icons.image_outlined),
                        label: const Text('Upload Gambar'),
                      ),
                      if (_imageBase64 != null)
                        OutlinedButton.icon(
                          onPressed: _saving
                              ? null
                              : () => setState(() => _imageBase64 = null),
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Hapus Gambar'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Nama produk'),
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _categoryController,
                    decoration: const InputDecoration(labelText: 'Kategori'),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _priceController,
                    decoration: const InputDecoration(labelText: 'Harga jual'),
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _costController,
                    decoration: const InputDecoration(labelText: 'Harga modal'),
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _stockController,
                    decoration: const InputDecoration(labelText: 'Stok'),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _saving
                    ? null
                    : () => Navigator.of(context).maybePop(),
                child: const Text('Batal'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Menyimpan...' : 'Simpan Produk'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final file = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: false,
      );
      if (file == null || !mounted) return;

      final picked = file.files.single;
      final bytes =
          picked.bytes ??
          (picked.path == null ? null : await File(picked.path!).readAsBytes());
      if (bytes == null || bytes.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gambar tidak bisa dibaca. Coba pilih file lain.'),
          ),
        );
        return;
      }

      if (!mounted) return;
      setState(() => _imageBase64 = base64Encode(bytes));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upload gambar gagal. Coba ulangi lagi.')),
      );
    }
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Nama produk wajib diisi')));
      return;
    }

    setState(() => _saving = true);
    try {
      if (_isEdit) {
        await widget.repository.update(
          widget.existing!.copyWith(
            name: _nameController.text.trim(),
            category: _categoryController.text.trim().isEmpty
                ? 'Umum'
                : _categoryController.text.trim(),
            imageBase64: _imageBase64,
            sellPrice: double.tryParse(_priceController.text) ?? 0,
            costPrice: double.tryParse(_costController.text) ?? 0,
            stock: int.tryParse(_stockController.text) ?? 0,
          ),
        );
      } else {
        await widget.repository.create(
          name: _nameController.text.trim(),
          category: _categoryController.text.trim(),
          imageBase64: _imageBase64,
          sellPrice: double.tryParse(_priceController.text) ?? 0,
          costPrice: double.tryParse(_costController.text) ?? 0,
          stock: int.tryParse(_stockController.text) ?? 0,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Produk gagal disimpan. Coba ulangi lagi.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
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
                        'Harga: ${formatCurrency(product.sellPrice)}',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.primary,
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
