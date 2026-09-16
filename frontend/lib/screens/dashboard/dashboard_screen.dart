import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/account_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/balance_card.dart';
import '../../widgets/quick_action_button.dart';
import '../../widgets/transaction_tile.dart';
import '../account/create_account_screen.dart';
import '../auth/login_screen.dart';
import '../banking/deposit_screen.dart';
import '../banking/transactions_screen.dart';
import '../banking/transfer_screen.dart';
import '../banking/withdraw_screen.dart';
import '../payment/payment_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AccountProvider>().loadAccount();
    });
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
    context.read<AccountProvider>().clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _openThenRefresh(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    if (mounted) context.read<AccountProvider>().loadAccount();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final accountProvider = context.watch<AccountProvider>();
    final account = accountProvider.account;
    final firstName = auth.user?.fullName.split(' ').first ?? 'there';

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => context.read<AccountProvider>().loadAccount(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Welcome back',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        firstName,
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 21,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          auth.user?.initials ?? '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout_rounded),
                        color: AppColors.textSecondary,
                        tooltip: 'Log out',
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (accountProvider.isLoading && account == null)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (account == null)
                _NoAccountCard(
                  onCreate: () => _openThenRefresh(const CreateAccountScreen()),
                )
              else ...[
                BalanceCard(account: account),
                const SizedBox(height: 22),
                _QuickActionsRow(
                  onDeposit: () => _openThenRefresh(DepositScreen(account: account)),
                  onWithdraw: () => _openThenRefresh(WithdrawScreen(account: account)),
                  onTransfer: () => _openThenRefresh(TransferScreen(account: account)),
                  onPay: () => _openThenRefresh(PaymentScreen(account: account)),
                ),
                const SizedBox(height: 26),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent activity',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => TransactionsScreen(account: account),
                        ),
                      ),
                      child: const Text('See all'),
                    ),
                  ],
                ),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    child: accountProvider.recentTransactions.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: Text(
                                'No transactions yet',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          )
                        : Column(
                            children: [
                              for (final tx in accountProvider.recentTransactions)
                                Column(
                                  children: [
                                    TransactionTile(
                                      transaction: tx,
                                      currency: account.currency,
                                    ),
                                    if (tx != accountProvider.recentTransactions.last)
                                      const Divider(height: 1),
                                  ],
                                ),
                            ],
                          ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _NoAccountCard extends StatelessWidget {
  final VoidCallback onCreate;
  const _NoAccountCard({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.skyTint,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.account_balance_rounded,
            color: AppColors.primary,
            size: 40,
          ),
          const SizedBox(height: 14),
          Text(
            'Open your first account',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          const Text(
            "You don't have a bank account yet - set one up to deposit, "
            'transfer and pay.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 18),
          ElevatedButton(onPressed: onCreate, child: const Text('Open Account')),
        ],
      ),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  final VoidCallback onDeposit;
  final VoidCallback onWithdraw;
  final VoidCallback onTransfer;
  final VoidCallback onPay;

  const _QuickActionsRow({
    required this.onDeposit,
    required this.onWithdraw,
    required this.onTransfer,
    required this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        QuickActionButton(
          icon: Icons.add_rounded,
          label: 'Deposit',
          onTap: onDeposit,
        ),
        QuickActionButton(
          icon: Icons.remove_rounded,
          label: 'Withdraw',
          onTap: onWithdraw,
          color: AppColors.warning,
        ),
        QuickActionButton(
          icon: Icons.swap_horiz_rounded,
          label: 'Transfer',
          onTap: onTransfer,
        ),
        QuickActionButton(
          icon: Icons.qr_code_scanner_rounded,
          label: 'Pay',
          onTap: onPay,
          color: AppColors.success,
        ),
      ],
    );
  }
}
