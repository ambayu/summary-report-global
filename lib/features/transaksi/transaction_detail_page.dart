import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/models/app_transaction.dart';
import '../../core/models/enums.dart';
import '../../core/utils/currency.dart';
import '../../core/utils/date_time.dart';
import '../../core/utils/receipt_printing.dart';
import '../../shared/widgets/status_badge.dart';

class TransactionDetailPage extends ConsumerWidget {
  const TransactionDetailPage({super.key, required this.transactionId});

  final String transactionId;

  void _handleBack(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    context.go('/transaksi');
  }

  Future<bool> _confirmAction({
    required BuildContext context,
    required String title,
    required String message,
    String confirmLabel = 'Ya',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Kembali'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Future<void> _printReceipt(
    BuildContext context,
    WidgetRef ref,
    AppTransaction tx,
  ) async {
    final settings = ref.read(settingsRepositoryProvider).settings;

    try {
      await ReceiptPrinting.printTransaction(
        transaction: tx,
        settings: settings,
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Print struk gagal dijalankan')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.read(transactionRepositoryProvider);

    return ValueListenableBuilder(
      valueListenable: repository.listenable,
      builder: (context, box, child) {
        final tx = repository.findById(transactionId);
        if (tx == null) {
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                onPressed: () => _handleBack(context),
                icon: const Icon(Icons.arrow_back),
              ),
              title: const Text('Detail Transaksi'),
            ),
            body: const Center(child: Text('Transaksi tidak ditemukan.')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              onPressed: () => _handleBack(context),
              icon: const Icon(Icons.arrow_back),
            ),
            title: Text(tx.orderNo),
            actions: [
              IconButton(
                tooltip: 'Print struk',
                onPressed: () => _printReceipt(context, ref, tx),
                icon: const Icon(Icons.print_outlined),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Meja ${tx.tableNo}'),
                          StatusBadge(status: tx.status),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Pelanggan: ${tx.customerName}'),
                      Text(
                        'Kasir: ${tx.cashierName} (${tx.cashierRole.label})',
                      ),
                      Text('Metode: ${tx.paymentMethod.label}'),
                      Text('Waktu: ${formatDateTime(tx.createdAt)}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Item Pesanan',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...tx.items.map(
                (item) => Card(
                  child: ListTile(
                    title: Text(item.productName),
                    subtitle: Text(
                      '${item.qty} x ${formatCurrency(item.unitPrice)}',
                    ),
                    trailing: Text(
                      formatCurrency(item.total),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      _line('Subtotal', formatCurrency(tx.subtotal)),
                      _line('Diskon', '- ${formatCurrency(tx.discountAmount)}'),
                      _line('Pajak', formatCurrency(tx.taxAmount)),
                      if (tx.serviceAmount > 0)
                        _line('Service', formatCurrency(tx.serviceAmount)),
                      const Divider(),
                      _line(
                        'Grand Total',
                        formatCurrency(tx.grandTotal),
                        bold: true,
                      ),
                      _line('Sudah Dibayar', formatCurrency(tx.paidAmount)),
                      _line(
                        'Sisa',
                        formatCurrency(tx.pendingAmount),
                        bold: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                onPressed: () => _printReceipt(context, ref, tx),
                icon: const Icon(Icons.print_outlined),
                label: const Text('Print Struk'),
              ),
              const SizedBox(height: 8),
              if (tx.status != TransactionStatus.lunas)
                FilledButton.icon(
                  onPressed: () async {
                    await repository.updateStatus(
                      id: tx.id,
                      status: TransactionStatus.lunas,
                      paidAmount: tx.grandTotal,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Transaksi ditandai lunas'),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Tandai Lunas'),
                ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: tx.status == TransactionStatus.batal
                    ? null
                    : () async {
                        final confirmed = await _confirmAction(
                          context: context,
                          title: 'Batalkan transaksi?',
                          message:
                              'Status transaksi akan diubah menjadi Batal dan pembayaran direset ke Rp 0.',
                          confirmLabel: 'Batalkan',
                        );
                        if (!confirmed) return;

                        await repository.updateStatus(
                          id: tx.id,
                          status: TransactionStatus.batal,
                          paidAmount: 0,
                        );

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Transaksi berhasil dibatalkan'),
                            ),
                          );
                        }
                      },
                icon: const Icon(Icons.cancel_outlined),
                label: Text(
                  tx.status == TransactionStatus.batal
                      ? 'Transaksi Sudah Batal'
                      : 'Batalkan Transaksi',
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () async {
                  final confirmed = await _confirmAction(
                    context: context,
                    title: 'Hapus transaksi ini?',
                    message:
                        'Data transaksi yang dihapus tidak bisa dikembalikan.',
                    confirmLabel: 'Hapus',
                  );
                  if (!confirmed) return;

                  await repository.delete(tx.id);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Transaksi berhasil dihapus'),
                      ),
                    );
                    context.go('/transaksi');
                  }
                },
                icon: const Icon(Icons.delete_outline),
                label: const Text('Hapus'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _line(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
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
