import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/models/enums.dart';
import '../../core/utils/currency.dart';

class LaporanDetailPage extends ConsumerWidget {
  const LaporanDetailPage({super.key, required this.reportType});

  final String reportType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txs = ref.read(transactionRepositoryProvider).getAll();
    final total = txs.fold<double>(0, (sum, tx) => sum + tx.grandTotal);

    return Scaffold(
      appBar: AppBar(title: Text('Detail Laporan: $reportType')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              title: const Text('Total Ringkasan'),
              subtitle: Text(formatCurrency(total)),
            ),
          ),
          const SizedBox(height: 8),
          ...txs
              .take(20)
              .map(
                (tx) => Card(
                  child: ListTile(
                    title: Text(tx.orderNo),
                    subtitle: Text(tx.paymentMethod.label),
                    trailing: Text(formatCurrency(tx.grandTotal)),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
