import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/models/enums.dart';
import '../../core/models/product.dart';
import '../../core/models/transaction_item.dart';
import '../../core/utils/currency.dart';
import '../../shared/widgets/product_thumbnail.dart';

class NewTransactionPage extends ConsumerStatefulWidget {
  const NewTransactionPage({super.key});

  @override
  ConsumerState<NewTransactionPage> createState() => _NewTransactionPageState();
}

class _NewTransactionPageState extends ConsumerState<NewTransactionPage> {
  final _tableController = TextEditingController();
  final _discountController = TextEditingController(text: '0');
  final Map<String, int> _qtyMap = {};

  String? _selectedCustomerId;
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  TransactionStatus _status = TransactionStatus.lunas;
  String _selectedCategory = 'Semua';
  String _searchQuery = '';
  String _menuMode = 'visual';
  String _discountMode = 'percent';
  bool _fullDiscount = false;
  bool _saving = false;

  @override
  void dispose() {
    _tableController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productRepo = ref.read(productRepositoryProvider);
    final customerRepo = ref.read(customerRepositoryProvider);
    final txRepo = ref.read(transactionRepositoryProvider);
    final authRepo = ref.read(authRepositoryProvider);
    final settingsRepo = ref.read(settingsRepositoryProvider);

    final settings = settingsRepo.settings;
    final products = productRepo.getAvailable();
    final customers = customerRepo.getAll();
    final selectedCustomer = _selectedCustomerId == null
        ? null
        : customers.where((item) => item.id == _selectedCustomerId).firstOrNull;
    final categories =
        {
          'Semua',
          ...products.map(
            (product) =>
                product.category.trim().isEmpty ? 'Umum' : product.category,
          ),
        }.toList()..sort((a, b) {
          if (a == 'Semua') return -1;
          if (b == 'Semua') return 1;
          return a.compareTo(b);
        });

    final filteredProducts = products.where((product) {
      final matchesCategory =
          _selectedCategory == 'Semua' || product.category == _selectedCategory;
      final query = _searchQuery.trim().toLowerCase();
      final matchesQuery =
          query.isEmpty ||
          product.name.toLowerCase().contains(query) ||
          product.category.toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();

    final selectedProducts = products
        .where((product) => (_qtyMap[product.id] ?? 0) > 0)
        .toList();

    final subtotal = selectedProducts.fold<double>(
      0,
      (sum, product) => sum + product.sellPrice * (_qtyMap[product.id] ?? 0),
    );
    final rawDiscountValue = _parseDiscountInput();
    final discountAmount = _fullDiscount
        ? subtotal
        : _discountMode == 'nominal'
        ? rawDiscountValue.clamp(0, subtotal).toDouble()
        : subtotal * (rawDiscountValue.clamp(0, 100).toDouble() / 100);
    final discountPercent = subtotal <= 0
        ? 0.0
        : (discountAmount / subtotal) * 100;
    final taxAmount = (subtotal - discountAmount) * (settings.taxPercent / 100);
    final grandTotal = subtotal - discountAmount + taxAmount;
    final screenSize = MediaQuery.sizeOf(context);
    final isWideScreen =
        screenSize.width >= 960 ||
        (screenSize.width >= 760 && screenSize.width > screenSize.height);

    Future<void> submit() async {
      if (selectedProducts.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Pilih minimal 1 produk')));
        return;
      }

      final session = authRepo.currentSession;
      if (session == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sesi login tidak ditemukan')),
        );
        return;
      }

      final items = selectedProducts
          .map(
            (product) => TransactionItem(
              productId: product.id,
              productName: product.name,
              qty: _qtyMap[product.id] ?? 1,
              unitPrice: product.sellPrice,
              note: '',
            ),
          )
          .toList();

      setState(() => _saving = true);
      try {
        final created = await txRepo.create(
          tableNo: _tableController.text,
          customerId: selectedCustomer?.id,
          customerName: selectedCustomer?.name,
          items: items,
          discountPercent: discountPercent,
          taxPercent: settings.taxPercent,
          servicePercent: 0,
          paymentMethod: _paymentMethod,
          status: _status,
          cashier: session,
        );
        if (!context.mounted) return;
        context.push('/transaksi/${created.id}');
      } catch (_) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menyimpan transaksi')),
        );
      } finally {
        if (mounted) {
          setState(() => _saving = false);
        }
      }
    }

    final submitAction = _saving ? null : () => submit();

    return Scaffold(
      appBar: AppBar(title: const Text('Transaksi Baru')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isSplitLayout =
              constraints.maxWidth >= 960 ||
              (constraints.maxWidth >= 760 &&
                  constraints.maxWidth > constraints.maxHeight);
          final sidePanelWidth = constraints.maxWidth >= 1280 ? 400.0 : 360.0;
          final menuPanelWidth = isSplitLayout
              ? constraints.maxWidth - sidePanelWidth - 48
              : constraints.maxWidth - 32;
          final orderSections = [
            _buildOrderDetailsCard(customers),
            const SizedBox(height: 12),
            _buildDiscountCard(subtotal),
            const SizedBox(height: 12),
            _buildPaymentCard(settings),
            const SizedBox(height: 12),
            _buildSummaryCard(
              selectedCustomerName: selectedCustomer?.name,
              subtotal: subtotal,
              discountAmount: discountAmount,
              discountPercent: discountPercent,
              taxPercent: settings.taxPercent,
              taxAmount: taxAmount,
              grandTotal: grandTotal,
            ),
            if (isSplitLayout) ...[
              const SizedBox(height: 12),
              _buildCheckoutPanel(
                grandTotal: grandTotal,
                menuCount: selectedProducts.length,
                onSubmit: submitAction,
              ),
            ],
          ];
          final menuSections = [
            _buildMenuCard(
              categories: categories,
              filteredProducts: filteredProducts,
              selectedCount: selectedProducts.length,
              availableWidth: menuPanelWidth,
            ),
          ];

          if (isSplitLayout) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: sidePanelWidth,
                    child: ListView(children: orderSections),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: ListView(children: menuSections)),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            children: [
              ...orderSections,
              const SizedBox(height: 18),
              ...menuSections,
            ],
          );
        },
      ),
      bottomNavigationBar: isWideScreen
          ? null
          : SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: _buildCheckoutPanel(
                grandTotal: grandTotal,
                menuCount: selectedProducts.length,
                onSubmit: submitAction,
              ),
            ),
    );
  }

  double _parseDiscountInput() {
    return double.tryParse(_discountController.text.replaceAll(',', '.')) ?? 0;
  }

  String _formatNumberInput(double value) {
    if (value <= 0) return '0';
    final rounded = value.roundToDouble();
    if ((value - rounded).abs() < 0.001) {
      return rounded.toInt().toString();
    }
    return value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
  }

  void _changeDiscountMode(String nextMode, double subtotal) {
    if (nextMode == _discountMode) return;

    final currentInput = _parseDiscountInput();
    final currentAmount = _fullDiscount
        ? subtotal
        : _discountMode == 'nominal'
        ? currentInput.clamp(0, subtotal).toDouble()
        : subtotal * (currentInput.clamp(0, 100).toDouble() / 100);
    final currentPercent = subtotal <= 0
        ? 0.0
        : (currentAmount / subtotal) * 100;

    setState(() {
      _discountMode = nextMode;
      _discountController.text = nextMode == 'nominal'
          ? _formatNumberInput(currentAmount)
          : _formatNumberInput(currentPercent);
    });
  }

  Widget _buildOrderDetailsCard(List<dynamic> customers) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Info Pesanan',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _tableController,
              decoration: const InputDecoration(
                labelText: 'Nomor meja / order',
                prefixIcon: Icon(Icons.table_restaurant_outlined),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: _selectedCustomerId,
              decoration: const InputDecoration(
                labelText: 'Pelanggan',
                prefixIcon: Icon(Icons.groups_outlined),
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Pelanggan Umum'),
                ),
                ...customers.map(
                  (customer) => DropdownMenuItem<String?>(
                    value: customer.id,
                    child: Text('${customer.name} - ${customer.phone}'),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() => _selectedCustomerId = value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscountCard(double subtotal) {
    final helperText = _fullDiscount
        ? 'Diskon penuh aktif. Total item akan gratis semua.'
        : _discountMode == 'nominal'
        ? 'Isi potongan langsung dalam rupiah.'
        : 'Isi potongan dalam persen 0 sampai 100.';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Diskon', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'percent',
                  icon: Icon(Icons.percent),
                  label: Text('Persen'),
                ),
                ButtonSegment(
                  value: 'nominal',
                  icon: Icon(Icons.payments_outlined),
                  label: Text('Nominal'),
                ),
              ],
              selected: {_discountMode},
              onSelectionChanged: (selection) {
                _changeDiscountMode(selection.first, subtotal);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _discountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              enabled: !_fullDiscount,
              decoration: InputDecoration(
                labelText: _discountMode == 'nominal'
                    ? 'Diskon Nominal'
                    : 'Diskon (%)',
                prefixIcon: Icon(
                  _discountMode == 'nominal'
                      ? Icons.sell_outlined
                      : Icons.percent,
                ),
                suffixText: _discountMode == 'percent' ? '%' : null,
                helperText: helperText,
              ),
              onChanged: (_) => setState(() {}),
            ),
            CheckboxListTile(
              value: _fullDiscount,
              contentPadding: EdgeInsets.zero,
              title: const Text('Diskon penuh'),
              subtitle: const Text(
                'Aktifkan untuk menggratiskan transaksi ini dengan sekali tap.',
              ),
              onChanged: (value) {
                final checked = value ?? false;
                setState(() {
                  _fullDiscount = checked;
                  _discountController.text = checked
                      ? _formatNumberInput(
                          _discountMode == 'nominal' ? subtotal : 100,
                        )
                      : '0';
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard(dynamic settings) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pembayaran', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            DropdownButtonFormField<PaymentMethod>(
              initialValue: _paymentMethod,
              decoration: const InputDecoration(
                labelText: 'Metode pembayaran',
                prefixIcon: Icon(Icons.payments_outlined),
              ),
              items: settings.activePayments
                  .map<DropdownMenuItem<PaymentMethod>>(
                    (payment) => DropdownMenuItem(
                      value: payment,
                      child: Text(payment.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _paymentMethod = value);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<TransactionStatus>(
              initialValue: _status,
              decoration: const InputDecoration(
                labelText: 'Status bayar',
                prefixIcon: Icon(Icons.task_alt_outlined),
              ),
              items:
                  [
                        TransactionStatus.lunas,
                        TransactionStatus.pending,
                        TransactionStatus.splitBill,
                      ]
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(status.label),
                        ),
                      )
                      .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _status = value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required List<String> categories,
    required List<Product> filteredProducts,
    required int selectedCount,
    required double availableWidth,
  }) {
    final gridCount = availableWidth >= 1200
        ? 4
        : availableWidth >= 840
        ? 3
        : 2;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pilih Menu',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$selectedCount menu dipilih',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'visual',
                      icon: Icon(Icons.grid_view_rounded),
                      label: Text('Gambar'),
                    ),
                    ButtonSegment(
                      value: 'text',
                      icon: Icon(Icons.view_list_rounded),
                      label: Text('Teks'),
                    ),
                  ],
                  selected: {_menuMode},
                  onSelectionChanged: (selection) {
                    setState(() => _menuMode = selection.first);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Cari menu',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final isSelected = _selectedCategory == category;
                  return ChoiceChip(
                    label: Text(category),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : null,
                      fontWeight: isSelected ? FontWeight.w700 : null,
                    ),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() => _selectedCategory = category);
                    },
                  );
                },
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemCount: categories.length,
              ),
            ),
            const SizedBox(height: 14),
            if (filteredProducts.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                child: const Column(
                  children: [
                    Icon(Icons.search_off_outlined, size: 32),
                    SizedBox(height: 8),
                    Text('Menu tidak ditemukan untuk filter ini.'),
                  ],
                ),
              )
            else if (_menuMode == 'visual')
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredProducts.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: gridCount,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: availableWidth >= 840 ? 0.9 : 0.78,
                ),
                itemBuilder: (context, index) {
                  final product = filteredProducts[index];
                  return _VisualProductCard(
                    product: product,
                    qty: _qtyMap[product.id] ?? 0,
                    onAdd: () {
                      setState(
                        () => _qtyMap[product.id] =
                            (_qtyMap[product.id] ?? 0) + 1,
                      );
                    },
                    onRemove: () {
                      final currentQty = _qtyMap[product.id] ?? 0;
                      if (currentQty == 0) return;
                      setState(() => _qtyMap[product.id] = currentQty - 1);
                    },
                  );
                },
              )
            else
              Column(
                children: filteredProducts.map((product) {
                  final qty = _qtyMap[product.id] ?? 0;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      leading: ProductThumbnail(
                        name: product.name,
                        imageBase64: product.imageBase64,
                      ),
                      title: Text(product.name),
                      subtitle: Text(
                        '${product.category} - ${formatCurrency(product.sellPrice)}',
                      ),
                      trailing: SizedBox(
                        width: 120,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              onPressed: () {
                                if (qty == 0) return;
                                setState(() => _qtyMap[product.id] = qty - 1);
                              },
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                            Text('$qty'),
                            IconButton(
                              onPressed: () {
                                setState(() => _qtyMap[product.id] = qty + 1);
                              },
                              icon: const Icon(Icons.add_circle_outline),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String? selectedCustomerName,
    required double subtotal,
    required double discountAmount,
    required double discountPercent,
    required double taxPercent,
    required double taxAmount,
    required double grandTotal,
  }) {
    final discountLabel = _fullDiscount
        ? 'Diskon Penuh'
        : _discountMode == 'nominal'
        ? 'Diskon Nominal'
        : 'Diskon (${_formatNumberInput(discountPercent)}%)';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ringkasan', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _line('Subtotal', formatCurrency(subtotal)),
            _line('Pelanggan', selectedCustomerName ?? 'Pelanggan Umum'),
            _line(discountLabel, '- ${formatCurrency(discountAmount)}'),
            _line(
              'Pajak (${taxPercent.toStringAsFixed(0)}%)',
              formatCurrency(taxAmount),
            ),
            const Divider(),
            _line('Total Bayar', formatCurrency(grandTotal), bold: true),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckoutPanel({
    required double grandTotal,
    required int menuCount,
    required VoidCallback? onSubmit,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Belanja',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formatCurrency(grandTotal),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$menuCount menu',
                    style: TextStyle(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onSubmit,
                icon: const Icon(Icons.add_shopping_cart_outlined),
                label: Text(_saving ? 'Menyimpan...' : 'Transaksi Baru'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _line(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _VisualProductCard extends StatelessWidget {
  const _VisualProductCard({
    required this.product,
    required this.qty,
    required this.onAdd,
    required this.onRemove,
  });

  final Product product;
  final int qty;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: ProductThumbnail(
                    name: product.name,
                    imageBase64: product.imageBase64,
                    width: double.infinity,
                    height: double.infinity,
                    radius: 0,
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      product.category,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  formatCurrency(product.sellPrice),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    IconButton(
                      onPressed: qty == 0 ? null : onRemove,
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          '$qty',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: onAdd,
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
