import 'package:flutter/material.dart';

class LaporanFilterPage extends StatelessWidget {
  const LaporanFilterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Filter Laporan')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Card(
            child: ListTile(
              title: Text('Tanggal'),
              subtitle: Text('Pilih rentang tanggal laporan'),
              trailing: Icon(Icons.date_range_outlined),
            ),
          ),
          Card(
            child: ListTile(
              title: Text('Kasir'),
              subtitle: Text('Filter berdasarkan user kasir'),
              trailing: Icon(Icons.person_outline),
            ),
          ),
          Card(
            child: ListTile(
              title: Text('Metode Pembayaran'),
              subtitle: Text('Cash, QRIS, Debit/Kredit, E-wallet, Transfer'),
              trailing: Icon(Icons.payments_outlined),
            ),
          ),
        ],
      ),
    );
  }
}
