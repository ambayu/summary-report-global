import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/models/enums.dart';
import '../../core/utils/currency.dart';
import '../../shared/widgets/kpi_card.dart';

class LaporanPage extends ConsumerStatefulWidget {
  const LaporanPage({super.key});

  @override
  ConsumerState<LaporanPage> createState() => _LaporanPageState();
}

class _LaporanPageState extends ConsumerState<LaporanPage> {
  String _period = 'hari';

  @override
  Widget build(BuildContext context) {
    final txRepo = ref.read(transactionRepositoryProvider);
    final expenseRepo = ref.read(expenseRepositoryProvider);

    return ValueListenableBuilder(
      valueListenable: txRepo.listenable,
      builder: (context, box1, child1) {
        return ValueListenableBuilder(
          valueListenable: expenseRepo.listenable,
          builder: (context, box2, child2) {
            final now = DateTime.now();
            final tx = txRepo.getAll().where((item) {
              if (_period == 'hari') {
                return item.createdAt.year == now.year &&
                    item.createdAt.month == now.month &&
                    item.createdAt.day == now.day;
              }

              if (_period == 'minggu') {
                return now.difference(item.createdAt).inDays <= 7;
              }

              return item.createdAt.year == now.year &&
                  item.createdAt.month == now.month;
            }).toList();

            final ex = expenseRepo.getAll().where((item) {
              if (_period == 'hari') {
                return item.createdAt.year == now.year &&
                    item.createdAt.month == now.month &&
                    item.createdAt.day == now.day;
              }

              if (_period == 'minggu') {
                return now.difference(item.createdAt).inDays <= 7;
              }

              return item.createdAt.year == now.year &&
                  item.createdAt.month == now.month;
            }).toList();

            final omzet = tx.fold<double>(
              0,
              (sum, item) =>
                  sum +
                  (item.status == TransactionStatus.pending
                      ? 0
                      : item.grandTotal),
            );
            final pending = tx
                .where((item) => item.status == TransactionStatus.pending)
                .fold<double>(0, (sum, item) => sum + item.pendingAmount);
            final expense = ex.fold<double>(
              0,
              (sum, item) => sum + item.amount,
            );
            final profit = omzet - expense;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'hari', label: Text('Harian')),
                    ButtonSegment(value: 'minggu', label: Text('Mingguan')),
                    ButtonSegment(value: 'bulan', label: Text('Bulanan')),
                  ],
                  selected: {_period},
                  onSelectionChanged: (selection) {
                    setState(() => _period = selection.first);
                  },
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.45,
                  children: [
                    KpiCard(
                      title: 'Omzet',
                      value: formatCurrency(omzet),
                      icon: Icons.ssid_chart,
                      highlight: true,
                    ),
                    KpiCard(
                      title: 'Total Transaksi',
                      value: tx.length.toString(),
                      icon: Icons.receipt,
                    ),
                    KpiCard(
                      title: 'Pending',
                      value: formatCurrency(pending),
                      icon: Icons.pending,
                    ),
                    KpiCard(
                      title: 'Profit',
                      value: formatCurrency(profit),
                      icon: Icons.trending_up,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ringkasan',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        _line('Penjualan', formatCurrency(omzet)),
                        _line('Pengeluaran', formatCurrency(expense)),
                        _line('Laba Rugi', formatCurrency(profit), bold: true),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Export PDF/Excel akan ditambahkan di fase berikutnya.',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.file_download_outlined),
                  label: const Text('Export Laporan'),
                ),
              ],
            );
          },
        );
      },
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
