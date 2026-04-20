import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/models/enums.dart';
import '../../core/utils/currency.dart';
import '../../core/utils/date_time.dart';
import '../../shared/widgets/access_denied_state.dart';

class PengeluaranPage extends ConsumerWidget {
  const PengeluaranPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.read(authRepositoryProvider).currentSession;
    final settings = ref.read(settingsRepositoryProvider).settings;
    if (!settings.hasPermission(session?.roleKey, AppPermission.pengeluaran)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pengeluaran')),
        body: const AccessDeniedState(
          message: 'Role Anda belum memiliki akses ke menu pengeluaran.',
        ),
      );
    }

    final repository = ref.read(expenseRepositoryProvider);

    Future<void> showAddDialog() async {
      final categoryController = TextEditingController(text: 'Operasional');
      final titleController = TextEditingController();
      final amountController = TextEditingController();
      final noteController = TextEditingController();

      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Input Pengeluaran'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: categoryController,
                  decoration: const InputDecoration(labelText: 'Kategori'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Judul'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(labelText: 'Nominal'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(labelText: 'Catatan'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () async {
                await repository.create(
                  category: categoryController.text,
                  title: titleController.text,
                  amount: double.tryParse(amountController.text) ?? 0,
                  note: noteController.text,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengeluaran'),
        actions: [
          IconButton(
            onPressed: showAddDialog,
            icon: const Icon(Icons.add_card_outlined),
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: repository.listenable,
        builder: (context, box, child) {
          final list = repository.getAll();
          final total = list.fold<double>(0, (sum, item) => sum + item.amount);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: ListTile(
                  title: const Text('Total Pengeluaran'),
                  subtitle: Text(formatCurrency(total)),
                ),
              ),
              const SizedBox(height: 8),
              if (list.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('Belum ada pengeluaran.'),
                  ),
                )
              else
                ...list.map(
                  (expense) => Card(
                    child: ListTile(
                      title: Text(expense.title),
                      subtitle: Text(
                        '${expense.category} • ${formatDateTime(expense.createdAt)}\n${expense.note}',
                      ),
                      isThreeLine: true,
                      trailing: Text(
                        formatCurrency(expense.amount),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: showAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
