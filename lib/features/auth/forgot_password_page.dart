import 'package:flutter/material.dart';

class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lupa Password')),
      body: const Padding(
        padding: EdgeInsets.all(20),
        child: Text(
          'Untuk versi local/offline ini, password bisa diubah setelah login lewat halaman Profil. Akun bawaan: owner, admin, dan kasir dengan password awal 123456.',
        ),
      ),
    );
  }
}
