import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/account.dart';
import '../../providers/auth_provider.dart';
import '../../providers/balance_visibility_provider.dart';

/// Shows everything about the signed-in person and their account in one
/// place: name, contact details, and the account/card info (account
/// number, type, status, balance). Reached by tapping "My Accounts",
/// "Cards", or the balance card itself.
class PersonalDetailScreen extends StatelessWidget {
  final BankAccount account;
  final String? accountName;

  const PersonalDetailScreen({
    super.key,
    required this.account,
    this.accountName,
  });

  String _currencySymbol(String currency) {
    if (currency.toUpperCase() == 'NPR') return 'Rs ';
    return '$currency ';
  }

  String _formatAccountNumber(String number) {
    final buffer = StringBuffer();
    for (var i = 0; i < number.length; i++) {
      buffer.write(number[i]);
      if ((i + 1) % 4 == 0 && i + 1 != number.length) buffer.write('  ');
    }
    return buffer.toString();
  }

  String _maskedAccountNumber(String number) {
    if (number.length <= 4) return _formatAccountNumber(number);
    final visible = number.substring(number.length - 4);
    final masked = '•' * (number.length - 4) + visible;
    return _formatAccountNumber(masked);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final obscured = context.watch<BalanceVisibilityProvider>().obscured;
    final displayName = (accountName ?? user?.fullName ?? '').trim();
    final format = NumberFormat.currency(
      symbol: _currencySymbol(account.currency),
      decimalDigits: 2,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Personal Details')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            // --- Card preview, matches the BalanceCard styling ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
              decoration: BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.account_balance_rounded,
                            color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'IMAGE BANK',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          account.status.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  if (displayName.isNotEmpty)
                    Text(
                      displayName.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        letterSpacing: 0.6,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    obscured
                        ? _maskedAccountNumber(account.accountNumber)
                        : _formatAccountNumber(account.accountNumber),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // --- Personal information ---
            const _SectionLabel('Personal Information'),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  _DetailRow(label: 'Full name', value: user?.fullName ?? '-'),
                  const Divider(height: 1),
                  _DetailRow(label: 'Email', value: user?.email ?? '-'),
                  if (user?.phone != null) ...[
                    const Divider(height: 1),
                    _DetailRow(label: 'Phone', value: user!.phone!),
                  ],
                  if (user?.gender != null) ...[
                    const Divider(height: 1),
                    _DetailRow(label: 'Gender', value: user!.gender!),
                  ],
                  if (user?.dateOfBirth != null) ...[
                    const Divider(height: 1),
                    _DetailRow(
                      label: 'Date of birth',
                      value: '${user!.dateOfBirth!.year}-'
                          '${user.dateOfBirth!.month.toString().padLeft(2, '0')}-'
                          '${user.dateOfBirth!.day.toString().padLeft(2, '0')}',
                    ),
                  ],
                  const Divider(height: 1),
                  _DetailRow(label: 'Role', value: user?.role ?? '-'),
                  const Divider(height: 1),
                  _DetailRow(
                      label: 'Account status', value: user?.status ?? '-'),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // --- Account / card information ---
            const _SectionLabel('Account Details'),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  _DetailRow(
                    label: 'Account number',
                    value: obscured
                        ? _maskedAccountNumber(account.accountNumber)
                        : _formatAccountNumber(account.accountNumber),
                    trailing: IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: Icon(
                        obscured
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () =>
                          context.read<BalanceVisibilityProvider>().toggle(),
                    ),
                  ),
                  const Divider(height: 1),
                  _DetailRow(
                    label: 'Account type',
                    value: account.accountTypeLabel,
                  ),
                  const Divider(height: 1),
                  _DetailRow(label: 'Currency', value: account.currency),
                  const Divider(height: 1),
                  _DetailRow(label: 'Status', value: account.status),
                  const Divider(height: 1),
                  _DetailRow(
                    label: 'Balance',
                    value: obscured
                        ? '${_currencySymbol(account.currency)}•••••••'
                        : format.format(account.balance),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 15,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Widget? trailing;

  const _DetailRow({required this.label, required this.value, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(width: 12),
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    value.isEmpty
                        ? value
                        : value[0].toUpperCase() + value.substring(1),
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
