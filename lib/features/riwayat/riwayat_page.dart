import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/models/enums.dart';
import '../../core/utils/currency.dart';
import '../../core/utils/date_time.dart';
import '../../core/utils/export_file_helper.dart';
import '../../shared/widgets/status_badge.dart';

class RiwayatPage extends ConsumerStatefulWidget {
  const RiwayatPage({super.key});

  @override
  ConsumerState<RiwayatPage> createState() => _RiwayatPageState();
}

class _RiwayatPageState extends ConsumerState<RiwayatPage> {
  TransactionStatus? _status;
  DateTimeRange? _dateRange;
  bool _exporting = false;

  @override
  Widget build(BuildContext context) {
    final repository = ref.read(transactionRepositoryProvider);

    return ValueListenableBuilder(
      valueListenable: repository.listenable,
      builder: (context, box, child) {
        final list = repository.getAll().where((tx) {
          if (_status != null && tx.status != _status) {
            return false;
          }
          return _isWithinRange(tx.createdAt, _dateRange);
        }).toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Semua'),
                  labelStyle: TextStyle(
                    color: _status == null ? Colors.white : null,
                    fontWeight: _status == null ? FontWeight.w700 : null,
                  ),
                  selected: _status == null,
                  onSelected: (_) => setState(() => _status = null),
                ),
                ...TransactionStatus.values.map(
                  (status) => ChoiceChip(
                    label: Text(status.label),
                    labelStyle: TextStyle(
                      color: _status == status ? Colors.white : null,
                      fontWeight: _status == status ? FontWeight.w700 : null,
                    ),
                    selected: _status == status,
                    onSelected: (_) => setState(() => _status = status),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
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
                IconButton.filled(
                  tooltip: 'Export XLSX riwayat sesuai filter',
                  onPressed: _exporting ? null : _exportFilteredXlsx,
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

  Future<void> _exportFilteredXlsx() async {
    setState(() => _exporting = true);
    try {
      final repository = ref.read(transactionRepositoryProvider);
      final bytes = repository.exportFilteredToXlsx(
        status: _status,
        startDate: _dateRange?.start,
        endDate: _dateRange?.end,
        sheetName: 'Riwayat',
      );

      final now = DateTime.now().millisecondsSinceEpoch;
      final savePath = await ExportFileHelper.saveBytes(
        dialogTitle: 'Simpan Export Riwayat XLSX',
        fileName: 'riwayat_filter_$now.xlsx',
        allowedExtensions: const ['xlsx'],
        bytes: bytes,
      );

      if (savePath == null) return;
      if (!mounted) return;
      await ExportFileHelper.promptOpenFile(
        context,
        filePath: savePath,
        successMessage: 'File XLSX riwayat berhasil disimpan di:\n$savePath',
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Export gagal. Coba ulangi lagi.')),
      );
    } finally {
      if (mounted) {
        setState(() => _exporting = false);
      }
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
