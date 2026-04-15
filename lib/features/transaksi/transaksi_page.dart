import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';

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
  DateTimeRange? _dateRange;
  bool _exporting = false;
  bool _deletingMonth = false;

  @override
  Widget build(BuildContext context) {
    final repository = ref.read(transactionRepositoryProvider);

    return ValueListenableBuilder(
      valueListenable: repository.listenable,
      builder: (context, box, child) {
        final all = repository.getAll();
        final list = all.where((tx) {
          if (_filter != null && tx.status != _filter) {
            return false;
          }
          return _isWithinRange(tx.createdAt, _dateRange);
        }).toList();

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
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDateRange,
                    icon: const Icon(Icons.date_range_outlined),
                    label: Text(
                      _dateRange == null
                          ? 'Filter Tanggal'
                          : '${formatShortDate(_dateRange!.start)} - ${formatShortDate(_dateRange!.end)}',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Reset tanggal',
                  onPressed: _dateRange == null
                      ? null
                      : () => setState(() => _dateRange = null),
                  icon: const Icon(Icons.close),
                ),
                const SizedBox(width: 6),
                IconButton.filledTonal(
                  tooltip: 'Hapus transaksi sesuai rentang tanggal',
                  onPressed: _deletingMonth ? null : _deleteByRange,
                  icon: _deletingMonth
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.delete_sweep_outlined),
                ),
                const SizedBox(width: 6),
                IconButton.filled(
                  tooltip: 'Export transaksi sesuai filter',
                  onPressed: _exporting ? null : _exportFilteredCsv,
                  icon: _exporting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.file_download_outlined),
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

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 5, 12, 31),
      initialDateRange: _dateRange,
    );

    if (picked == null) return;
    setState(() => _dateRange = picked);
  }

  Future<void> _exportFilteredCsv() async {
    setState(() => _exporting = true);
    try {
      final repository = ref.read(transactionRepositoryProvider);
      final csv = repository.exportFilteredToCsv(
        status: _filter,
        startDate: _dateRange?.start,
        endDate: _dateRange?.end,
      );

      final now = DateTime.now().millisecondsSinceEpoch;
      final savePath = await FilePicker.platform.saveFile(
        dialogTitle: 'Simpan Export Transaksi',
        fileName: 'transaksi_filter_$now.csv',
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (savePath == null) return;
      await File(savePath).writeAsString(csv);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Export berhasil: $savePath')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Export gagal. Coba ulangi lagi.')),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _deleteByRange() async {
    if (_dateRange == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih rentang tanggal dulu')),
      );
      return;
    }
    final repository = ref.read(transactionRepositoryProvider);
    final count = repository.getAll().where((tx) {
      return _isWithinRange(tx.createdAt, _dateRange);
    }).length;

    if (count == 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada transaksi di bulan tersebut')),
      );
      return;
    }
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Hapus transaksi sesuai rentang?'),
          content: Text(
            'Data transaksi pada rentang tanggal terpilih akan dihapus sebanyak $count transaksi.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() => _deletingMonth = true);
    try {
      final deleted = await repository.deleteByDateRange(
        startDate: _dateRange!.start,
        endDate: _dateRange!.end,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$deleted transaksi berhasil dihapus')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menghapus transaksi per bulan')),
      );
    } finally {
      if (mounted) setState(() => _deletingMonth = false);
    }
  }

  bool _isWithinRange(DateTime date, DateTimeRange? range) {
    if (range == null) return true;
    final start = DateTime(
      range.start.year,
      range.start.month,
      range.start.day,
    );
    final end = DateTime(
      range.end.year,
      range.end.month,
      range.end.day,
      23,
      59,
      59,
      999,
    );
    if (date.isBefore(start)) return false;
    if (date.isAfter(end)) return false;
    return true;
  }
}
