import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/providers.dart';
import '../../app/theme/app_colors.dart';
import '../../core/models/app_transaction.dart';
import '../../core/models/enums.dart';
import '../../core/utils/currency.dart';
import '../../core/utils/date_time.dart';
import '../../shared/widgets/kpi_card.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionRepo = ref.read(transactionRepositoryProvider);
    final productRepo = ref.read(productRepositoryProvider);
    final settingsRepo = ref.read(settingsRepositoryProvider);

    return ValueListenableBuilder(
      valueListenable: settingsRepo.listenable,
      builder: (context, box0, child0) {
        final brandName = settingsRepo.settings.cafeName;

        return ValueListenableBuilder(
          valueListenable: transactionRepo.listenable,
          builder: (context, box1, child1) {
            return ValueListenableBuilder(
              valueListenable: productRepo.listenable,
              builder: (context, box2, child2) {
                final transactions = transactionRepo.getAll();
                final products = productRepo.getAll();
                final now = DateTime.now();

                final todayTx = transactions.where((tx) {
                  return tx.createdAt.year == now.year &&
                      tx.createdAt.month == now.month &&
                      tx.createdAt.day == now.day;
                }).toList();

                final incomeToday = todayTx.fold<double>(
                  0,
                  (sum, tx) =>
                      sum +
                      (tx.status == TransactionStatus.pending
                          ? 0
                          : tx.grandTotal),
                );

                final pendingCount = todayTx
                    .where((tx) => tx.status == TransactionStatus.pending)
                    .length;

                final paymentFreq = <PaymentMethod, int>{};
                for (final tx in todayTx) {
                  paymentFreq[tx.paymentMethod] =
                      (paymentFreq[tx.paymentMethod] ?? 0) + 1;
                }
                final topPayment = paymentFreq.entries.isEmpty
                    ? '-'
                    : (paymentFreq.entries.toList()
                            ..sort((a, b) => b.value.compareTo(a.value)))
                          .first
                          .key
                          .label;

                final productCount = <String, int>{};
                for (final tx in todayTx) {
                  for (final item in tx.items) {
                    productCount[item.productName] =
                        (productCount[item.productName] ?? 0) + item.qty;
                  }
                }

                final topProduct = productCount.entries.isEmpty
                    ? '-'
                    : (productCount.entries.toList()
                            ..sort((a, b) => b.value.compareTo(a.value)))
                          .first
                          .key;

                final lowStock = products
                    .where(
                      (product) => !product.available || product.stock <= 10,
                    )
                    .toList();

                final daily = _last7DaysIncome(transactions);

                return RefreshIndicator(
                  onRefresh: () async {},
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text(_brandInitial(brandName)),
                          ),
                          title: Text(brandName),
                          subtitle: const Text('Dashboard Brand Aplikasi'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Ringkasan Hari Ini',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        childAspectRatio: 1.45,
                        children: [
                          KpiCard(
                            title: 'Pemasukan Hari Ini',
                            value: formatCurrency(incomeToday),
                            icon: Icons.payments_outlined,
                            highlight: true,
                          ),
                          KpiCard(
                            title: 'Jumlah Transaksi',
                            value: todayTx.length.toString(),
                            icon: Icons.receipt_long_outlined,
                          ),
                          KpiCard(
                            title: 'Pending',
                            value: pendingCount.toString(),
                            icon: Icons.pending_actions_outlined,
                          ),
                          KpiCard(
                            title: 'Top Payment',
                            value: topPayment,
                            icon: Icons.qr_code_2_outlined,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Produk Terlaris',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 6),
                              Text(topProduct),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tren 7 Hari',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 140,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: daily
                                      .map(
                                        (entry) => Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 4,
                                            ),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                Container(
                                                  height:
                                                      (entry['value'] as double)
                                                          .clamp(0, 120)
                                                          .toDouble() +
                                                      8,
                                                  decoration: BoxDecoration(
                                                    color: AppColors.primaryRed
                                                        .withValues(
                                                          alpha: 0.75,
                                                        ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  entry['label'] as String,
                                                  style: Theme.of(
                                                    context,
                                                  ).textTheme.bodySmall,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Peringatan Stok',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              if (lowStock.isEmpty)
                                const Text('Semua stok aman.')
                              else
                                ...lowStock
                                    .take(5)
                                    .map(
                                      (item) => ListTile(
                                        dense: true,
                                        contentPadding: EdgeInsets.zero,
                                        leading: const Icon(
                                          Icons.warning_amber_rounded,
                                          color: AppColors.warning,
                                        ),
                                        title: Text(item.name),
                                        subtitle: Text('Stok: ${item.stock}'),
                                        trailing: TextButton(
                                          onPressed: () =>
                                              context.push('/produk'),
                                          child: const Text('Kelola'),
                                        ),
                                      ),
                                    ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Update: ${formatDateTime(DateTime.now())}',
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 12,
                          color: AppColors.mutedGray,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  String _brandInitial(String brandName) {
    final text = brandName.trim();
    if (text.isEmpty) return 'SC';
    final parts = text.split(RegExp(r'\s+')).where((item) => item.isNotEmpty);
    if (parts.isEmpty) return 'SC';
    if (parts.length == 1) {
      final word = parts.first;
      return word.length >= 2
          ? word.substring(0, 2).toUpperCase()
          : word.toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  List<Map<String, Object>> _last7DaysIncome(
    List<AppTransaction> transactions,
  ) {
    final now = DateTime.now();
    final output = <Map<String, Object>>[];

    for (int index = 6; index >= 0; index--) {
      final day = now.subtract(Duration(days: index));

      double total = 0;
      for (final tx in transactions) {
        if (tx.createdAt.year == day.year &&
            tx.createdAt.month == day.month &&
            tx.createdAt.day == day.day) {
          total += tx.grandTotal;
        }
      }

      output.add({'label': formatShortDate(day), 'value': total / 10000});
    }

    return output;
  }
}
