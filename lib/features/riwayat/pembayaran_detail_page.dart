import 'package:flutter/material.dart';

class PembayaranDetailPage extends StatelessWidget {
  const PembayaranDetailPage({super.key, required this.paymentId});

  final String paymentId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Pembayaran')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Text('Detail pembayaran ID: $paymentId'),
      ),
    );
  }
}
