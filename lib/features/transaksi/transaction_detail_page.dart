import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/models/enums.dart';
import '../../core/utils/currency.dart';
import '../../core/utils/date_time.dart';
import '../../shared/widgets/status_badge.dart';

class TransactionDetailPage extends ConsumerWidget {
  const TransactionDetailPage({super.key, required this.transactionId});

  final String transactionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.read(transactionRepositoryProvider);

    return ValueListenableBuilder(
      valueListenable: repository.listenable,
      builder: (context, box, child) {
        final tx = repository.findById(transactionId);
        if (tx == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Detail Transaksi')),
            body: const Center(child: Text('Transaksi tidak ditemukan.')),
          );
        }

        return Scaffold(
          appBar: AppBar(title: Text(tx.orderNo)),
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
                onPressed: () async {
                  await repository.updateStatus(
                    id: tx.id,
                    status: TransactionStatus.batal,
                    paidAmount: 0,
                  );
                },
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Batalkan Transaksi'),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () async {
                  await repository.delete(tx.id);
                  if (context.mounted) {
                    Navigator.of(context).pop();
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
