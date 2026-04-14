import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/models/enums.dart';
import '../../core/utils/currency.dart';
import '../../core/utils/date_time.dart';

class RiwayatDetailPage extends ConsumerWidget {
  const RiwayatDetailPage({super.key, required this.transactionId});

  final String transactionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tx = ref.read(transactionRepositoryProvider).findById(transactionId);
    if (tx == null) {
      return const Scaffold(
        body: Center(child: Text('Riwayat tidak ditemukan')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Riwayat')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(tx.orderNo, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('Tanggal: ${formatDateTime(tx.createdAt)}'),
          Text('Kasir: ${tx.cashierName}'),
          Text('Metode: ${tx.paymentMethod.label}'),
          const SizedBox(height: 12),
          ...tx.items.map(
            (item) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(item.productName),
              subtitle: Text('${item.qty} x ${formatCurrency(item.unitPrice)}'),
              trailing: Text(formatCurrency(item.total)),
            ),
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total'),
              Text(
                formatCurrency(tx.grandTotal),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
