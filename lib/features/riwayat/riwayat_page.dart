import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/models/enums.dart';
import '../../core/utils/currency.dart';
import '../../core/utils/date_time.dart';
import '../../shared/widgets/status_badge.dart';

class RiwayatPage extends ConsumerStatefulWidget {
  const RiwayatPage({super.key});

  @override
  ConsumerState<RiwayatPage> createState() => _RiwayatPageState();
}

class _RiwayatPageState extends ConsumerState<RiwayatPage> {
  TransactionStatus? _status;

  @override
  Widget build(BuildContext context) {
    final repository = ref.read(transactionRepositoryProvider);

    return ValueListenableBuilder(
      valueListenable: repository.listenable,
      builder: (context, box, child) {
        final all = repository.getAll();
        final list = _status == null
            ? all
            : all.where((tx) => tx.status == _status).toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Semua'),
                  selected: _status == null,
                  onSelected: (_) => setState(() => _status = null),
                ),
                ...TransactionStatus.values.map(
                  (status) => ChoiceChip(
                    label: Text(status.label),
                    selected: _status == status,
                    onSelected: (_) => setState(() => _status = status),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (list.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('Belum ada riwayat transaksi.'),
                ),
              )
            else
              ...list.map(
                (tx) => Card(
                  child: ListTile(
                    onTap: () => context.push('/riwayat/${tx.id}'),
                    leading: const Icon(Icons.receipt_long_outlined),
                    title: Text(tx.orderNo),
                    subtitle: Text(
                      '${formatDateTime(tx.createdAt)}\n${tx.paymentMethod.label}',
                    ),
                    isThreeLine: true,
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        StatusBadge(status: tx.status),
                        const SizedBox(height: 6),
                        Text(
                          formatCurrency(tx.grandTotal),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
