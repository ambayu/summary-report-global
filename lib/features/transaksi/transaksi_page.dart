import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/models/enums.dart';
import '../../core/utils/currency.dart';
import '../../core/utils/date_time.dart';
import '../../shared/widgets/status_badge.dart';

class TransaksiPage extends ConsumerStatefulWidget {
  const TransaksiPage({super.key});

  @override
  ConsumerState<TransaksiPage> createState() => _TransaksiPageState();
}

class _TransaksiPageState extends ConsumerState<TransaksiPage> {
  TransactionStatus? _filter;

  @override
  Widget build(BuildContext context) {
    final repository = ref.read(transactionRepositoryProvider);

    return ValueListenableBuilder(
      valueListenable: repository.listenable,
      builder: (context, box, child) {
        final all = repository.getAll();
        final list = _filter == null
            ? all
            : all.where((tx) => tx.status == _filter).toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<TransactionStatus?>(
                    initialValue: _filter,
                    decoration: const InputDecoration(
                      labelText: 'Filter status',
                      prefixIcon: Icon(Icons.filter_alt_outlined),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Semua status'),
                      ),
                      ...TransactionStatus.values.map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(status.label),
                        ),
                      ),
                    ],
                    onChanged: (value) => setState(() => _filter = value),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton.icon(
                  onPressed: () => context.push('/transaksi/new'),
                  icon: const Icon(Icons.add),
                  label: const Text('Baru'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (list.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Icon(Icons.receipt_long_outlined, size: 40),
                      const SizedBox(height: 8),
                      const Text('Belum ada transaksi.'),
                      const SizedBox(height: 10),
                      OutlinedButton(
                        onPressed: () => context.push('/transaksi/new'),
                        child: const Text('Buat transaksi pertama'),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...list.map(
                (tx) => Card(
                  child: ListTile(
                    onTap: () => context.push('/transaksi/${tx.id}'),
                    title: Text('${tx.orderNo} - Meja ${tx.tableNo}'),
                    subtitle: Text(
                      '${formatDateTime(tx.createdAt)}\n${tx.paymentMethod.label}',
                    ),
                    isThreeLine: true,
                    trailing: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
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
