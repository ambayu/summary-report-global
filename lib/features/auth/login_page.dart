import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/router/route_names.dart';
import '../../core/models/enums.dart';
import '../../shared/widgets/brand_avatar.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'owner');
  final _passwordController = TextEditingController(text: '123456');
  String _roleKey = AppRole.owner;
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final settings = ref.read(settingsRepositoryProvider).settings;
    final selectedRole = settings.roleByKey(_roleKey);
    if (selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Role login tidak ditemukan')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .login(
            name: _nameController.text,
            password: _passwordController.text,
            roleKey: selectedRole.key,
          );
      if (mounted) {
        context.go(RouteNames.dashboard);
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsRepo = ref.read(settingsRepositoryProvider);

    return ValueListenableBuilder(
      valueListenable: settingsRepo.listenable,
      builder: (context, box, child) {
        final settings = settingsRepo.settings;
        final brandName = settings.cafeName;
        final roles = settings.roles;
        final effectiveRoleKey = settings.roleByKey(_roleKey)?.key ??
            (roles.isEmpty ? AppRole.owner : roles.first.key);

        return Scaffold(
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                BrandAvatar(
                                  brandName: brandName,
                                  logoBase64: settings.logoBase64,
                                  radius: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    brandName,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.headlineMedium,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Masuk ke aplikasi $brandName untuk mulai transaksi dan laporan.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Nama user',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Nama user wajib diisi';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: 'Password',
                                prefixIcon: Icon(Icons.lock_outline),
                              ),
                              validator: (value) {
                                if (value == null || value.length < 4) {
                                  return 'Minimal 4 karakter';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              initialValue: effectiveRoleKey,
                              decoration: const InputDecoration(
                                labelText: 'Role',
                                prefixIcon: Icon(Icons.badge_outlined),
                              ),
                              items: roles
                                  .map(
                                    (role) => DropdownMenuItem(
                                      value: role.key,
                                      child: Text(role.label),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() => _roleKey = value);
                              },
                            ),
                            const SizedBox(height: 18),
                            ElevatedButton.icon(
                              onPressed: _loading ? null : _submit,
                              icon: _loading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.login),
                              label: Text(_loading ? 'Memproses...' : 'Login'),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () =>
                                  context.push(RouteNames.forgotPassword),
                              child: const Text('Lupa password'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
