import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

import '../../app/providers.dart';
import '../../core/models/enums.dart';
import '../../core/utils/currency.dart';
import '../../core/utils/export_file_helper.dart';
import '../../shared/widgets/access_denied_state.dart';
import '../../shared/widgets/kpi_card.dart';

class LaporanPage extends ConsumerStatefulWidget {
  const LaporanPage({super.key});

  @override
  ConsumerState<LaporanPage> createState() => _LaporanPageState();
}

class _LaporanPageState extends ConsumerState<LaporanPage> {
  String _period = 'hari';
  int? _selectedYear;
  DateTimeRange? _dateRange;
  bool _busy = false;
  Timer? _importHoldTimer;
  bool _skipNextExportTap = false;

  @override
  Widget build(BuildContext context) {
    final session = ref.read(authRepositoryProvider).currentSession;
    if (!(session?.role.hasPermission(AppPermission.laporan) ?? false)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Laporan')),
        body: const AccessDeniedState(
          message: 'Role Anda belum memiliki akses ke halaman laporan.',
        ),
      );
    }

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
              return _matchesReportFilter(item.createdAt, now);
            }).toList();

            final ex = expenseRepo.getAll().where((item) {
              return _matchesReportFilter(item.createdAt, now);
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
            final years = {
              now.year,
              ...txRepo.getAll().map((item) => item.createdAt.year),
            }.toList()..sort((a, b) => b.compareTo(a));

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                DropdownButtonFormField<int?>(
                  initialValue: _selectedYear,
                  decoration: const InputDecoration(
                    labelText: 'Tahun Data',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Semua Tahun'),
                    ),
                    ...years.map(
                      (year) => DropdownMenuItem<int?>(
                        value: year,
                        child: Text(year.toString()),
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(() => _selectedYear = value),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _busy ? null : _pickDateRange,
                        icon: const Icon(Icons.date_range_outlined),
                        label: Text(
                          _dateRange == null
                              ? 'Rentang Tanggal'
                              : '${_fmtDate(_dateRange!.start)} - ${_fmtDate(_dateRange!.end)}',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Reset rentang tanggal',
                      onPressed: _dateRange == null
                          ? null
                          : () => setState(() => _dateRange = null),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SegmentedButton<String>(
                  style: ButtonStyle(
                    foregroundColor: WidgetStateProperty.resolveWith<Color>((
                      states,
                    ) {
                      if (states.contains(WidgetState.selected)) {
                        return Colors.white;
                      }
                      return Theme.of(context).colorScheme.onSurface;
                    }),
                    backgroundColor: WidgetStateProperty.resolveWith<Color>((
                      states,
                    ) {
                      if (states.contains(WidgetState.selected)) {
                        return Theme.of(context).colorScheme.primary;
                      }
                      return Theme.of(context).colorScheme.surface;
                    }),
                  ),
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
                const SizedBox(height: 12),
                Card(
                  child: Column(
                    children: [
                      Listener(
                        onPointerDown: _busy ? null : (_) => _startImportHold(),
                        onPointerUp: _busy
                            ? null
                            : (_) {
                                _cancelImportHold();
                              },
                        onPointerCancel: _busy
                            ? null
                            : (_) {
                                _cancelImportHold();
                              },
                        child: ListTile(
                          leading: const Icon(Icons.file_download_outlined),
                          title: const Text('Export XLSX'),
                          subtitle: const Text(
                            'Pilih rentang tanggal saat export',
                          ),
                          trailing: _busy
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.chevron_right),
                          onTap: _busy
                              ? null
                              : () async {
                                  if (_skipNextExportTap) {
                                    _skipNextExportTap = false;
                                    return;
                                  }
                                  await _onExportXlsx();
                                },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
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

  bool _matchesReportFilter(DateTime date, DateTime now) {
    if (_selectedYear != null && date.year != _selectedYear) {
      return false;
    }
    if (!_isWithinRange(date, _dateRange)) return false;

    final hasExplicitFilter = _selectedYear != null || _dateRange != null;
    if (hasExplicitFilter) return true;

    if (_period == 'hari') {
      return date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    }

    if (_period == 'minggu') {
      final startOfToday = DateTime(now.year, now.month, now.day);
      final startOfDate = DateTime(date.year, date.month, date.day);
      final diff = startOfToday.difference(startOfDate).inDays;
      return diff >= 0 && diff <= 7;
    }

    return date.year == now.year && date.month == now.month;
  }

  String _fmtDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }

  @override
  void dispose() {
    _importHoldTimer?.cancel();
    super.dispose();
  }

  void _startImportHold() {
    _importHoldTimer?.cancel();
    _importHoldTimer = Timer(const Duration(seconds: 2), () async {
      if (!mounted || _busy) return;
      _skipNextExportTap = true;
      await _onImportXlsx();
    });
  }

  void _cancelImportHold() {
    _importHoldTimer?.cancel();
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

  Future<void> _onImportXlsx() async {
    setState(() => _busy = true);
    try {
      final file = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        withData: true,
      );
      if (file == null) return;

      final picked = file.files.single;
      final bytes =
          picked.bytes ??
          (picked.path == null ? null : await File(picked.path!).readAsBytes());
      if (bytes == null) return;

      final imported = await ref
          .read(transactionRepositoryProvider)
          .importFromXlsx(bytes);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$imported baris berhasil di-import dari XLSX')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Import XLSX gagal. Periksa format file.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _onExportXlsx() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 5, 12, 31),
      initialDateRange: DateTimeRange(
        start: DateTime(now.year, now.month, 1),
        end: now,
      ),
    );

    if (range == null) return;

    setState(() => _busy = true);
    try {
      final bytes = ref
          .read(transactionRepositoryProvider)
          .exportReportToXlsx(
            year: _selectedYear,
            startDate: range.start,
            endDate: range.end,
          );
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final defaultName = _selectedYear == null
          ? 'laporan_$timestamp.xlsx'
          : 'laporan_${_selectedYear}_$timestamp.xlsx';

      final savePath = await ExportFileHelper.saveBytes(
        dialogTitle: 'Simpan XLSX Laporan',
        fileName: defaultName,
        allowedExtensions: const ['xlsx'],
        bytes: bytes,
      );

      if (savePath == null) return;
      if (!mounted) return;
      await ExportFileHelper.promptOpenFile(
        context,
        filePath: savePath,
        successMessage: 'File XLSX laporan berhasil disimpan di:\n$savePath',
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Export XLSX gagal. Coba ulangi lagi.')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
