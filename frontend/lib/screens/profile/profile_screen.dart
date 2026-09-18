import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/account_provider.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    await context.read<AuthProvider>().logout();
    context.read<AccountProvider>().clear();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      user?.initials ?? '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    user?.fullName ?? 'Unknown user',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? '',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Card(
              child: Column(
                children: [
                  _ProfileRow(label: 'Role', value: user?.role ?? '-'),
                  const Divider(height: 1),
                  _ProfileRow(label: 'Status', value: user?.status ?? '-'),
                  // These three are nullable on the model - older accounts
                  // created before phone/dateOfBirth/gender existed will
                  // have null here, so the row is simply omitted rather
                  // than showing "null" or crashing.
                  if (user?.phone != null) ...[
                    const Divider(height: 1),
                    _ProfileRow(label: 'Phone', value: user!.phone!),
                  ],
                  if (user?.gender != null) ...[
                    const Divider(height: 1),
                    _ProfileRow(label: 'Gender', value: user!.gender!),
                  ],
                  if (user?.dateOfBirth != null) ...[
                    const Divider(height: 1),
                    _ProfileRow(
                      label: 'Date of birth',
                      value: '${user!.dateOfBirth!.year}-'
                          '${user.dateOfBirth!.month.toString().padLeft(2, '0')}-'
                          '${user.dateOfBirth!.day.toString().padLeft(2, '0')}',
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 30),
            OutlinedButton.icon(
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Log out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.danger),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final String label;
  final String value;
  const _ProfileRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Text(
            value.isEmpty ? value : value[0].toUpperCase() + value.substring(1),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
