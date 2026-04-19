import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/models/enums.dart';
import '../../core/models/transaction_item.dart';
import '../../core/utils/currency.dart';

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

    final selectedProducts = products
        .where((product) => (_qtyMap[product.id] ?? 0) > 0)
        .toList();

    final subtotal = selectedProducts.fold<double>(
      0,
      (sum, product) => sum + product.sellPrice * (_qtyMap[product.id] ?? 0),
    );
    final discountPercent = double.tryParse(_discountController.text) ?? 0;
    final discountAmount = subtotal * (discountPercent / 100);
    final taxAmount = (subtotal - discountAmount) * (settings.taxPercent / 100);
    final serviceAmount =
        (subtotal - discountAmount) * (settings.servicePercent / 100);
    final grandTotal = subtotal - discountAmount + taxAmount + serviceAmount;

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
      final created = await txRepo.create(
        tableNo: _tableController.text,
        customerId: selectedCustomer?.id,
        customerName: selectedCustomer?.name,
        items: items,
        discountPercent: discountPercent,
        taxPercent: settings.taxPercent,
        servicePercent: settings.servicePercent,
        paymentMethod: _paymentMethod,
        status: _status,
        cashier: session,
      );
      if (!context.mounted) return;
      setState(() => _saving = false);
      context.push('/transaksi/${created.id}');
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Transaksi Baru')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
          const SizedBox(height: 12),
          TextField(
            controller: _discountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Diskon (%)',
              prefixIcon: Icon(Icons.percent),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<PaymentMethod>(
            initialValue: _paymentMethod,
            decoration: const InputDecoration(
              labelText: 'Metode pembayaran',
              prefixIcon: Icon(Icons.payments_outlined),
            ),
            items: settings.activePayments
                .map(
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
          const SizedBox(height: 16),
          Text('Pilih Menu', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (products.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text('Belum ada produk tersedia.'),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: () => context.push('/produk'),
                      child: const Text('Tambah produk'),
                    ),
                  ],
                ),
              ),
            )
          else
            ...products.map((product) {
              final qty = _qtyMap[product.id] ?? 0;
              return Card(
                child: ListTile(
                  title: Text(product.name),
                  subtitle: Text(
                    '${product.category} • ${formatCurrency(product.sellPrice)}',
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
            }),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _line('Subtotal', formatCurrency(subtotal)),
                  _line('Pelanggan', selectedCustomer?.name ?? 'Pelanggan Umum'),
                  _line('Diskon', '- ${formatCurrency(discountAmount)}'),
                  _line(
                    'Pajak (${settings.taxPercent.toStringAsFixed(0)}%)',
                    formatCurrency(taxAmount),
                  ),
                  _line(
                    'Service (${settings.servicePercent.toStringAsFixed(0)}%)',
                    formatCurrency(serviceAmount),
                  ),
                  const Divider(),
                  _line('Total Bayar', formatCurrency(grandTotal), bold: true),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _saving ? null : submit,
            icon: const Icon(Icons.save_outlined),
            label: Text(_saving ? 'Menyimpan...' : 'Simpan Transaksi'),
          ),
          const SizedBox(height: 16),
        ],
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
