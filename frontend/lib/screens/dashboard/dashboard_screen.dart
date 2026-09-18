import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/account_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/account_flow_chart.dart';
import '../../widgets/balance_card.dart';
import '../../widgets/dashboard_menu.dart';
import '../../widgets/transaction_tile.dart';
import '../account/create_account_screen.dart';
import '../account/personal_detail_screen.dart';
import '../auth/login_screen.dart';
import '../banking/my_qr_screen.dart';
import '../banking/transactions_screen.dart';

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
      if (mounted) context.read<AccountProvider>().loadAccount();
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

  Future<void> _open(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    if (mounted) context.read<AccountProvider>().loadAccount();
  }

  void _soon(String name) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$name is coming soon')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accountProvider = context.watch<AccountProvider>();
    final account = accountProvider.account;
    final userName = context.watch<AuthProvider>().user?.fullName;
    final items =
        buildDashboardMenuItems(context, account: account, userName: userName);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => context.read<AccountProvider>().loadAccount(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
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
                          userName?.split(' ').first ?? 'there',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      context.watch<AuthProvider>().user?.initials ?? '?',
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
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (accountProvider.isLoading && account == null)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (account == null)
                _NoAccount(onCreate: () => _open(const CreateAccountScreen()))
              else
                BalanceCard(
                  key: ValueKey('balance-card-${account.id}'),
                  account: account,
                  accountName: userName,
                  onTap: () => _open(
                    PersonalDetailScreen(
                        account: account, accountName: userName),
                  ),
                  onQrTap: () => _open(
                    MyQrScreen(account: account, accountHolderName: userName),
                  ),
                ),
              if (account != null) ...[
                const SizedBox(height: 18),
                AccountFlowChart(
                  transactions: accountProvider.flowTransactions,
                ),
              ],
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    DashboardMenuGrid(items: items),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => _soon('Edit Menu'),
                        icon: const Icon(Icons.edit_outlined, size: 15),
                        label: const Text('Edit Menu'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (account != null) ...[
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent activity',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    TextButton(
                      onPressed: () =>
                          _open(TransactionsScreen(account: account)),
                      child: const Text('See all'),
                    ),
                  ],
                ),
                Card(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    child: accountProvider.recentTransactions.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 22),
                            child: Center(
                              child: Text(
                                'No transactions yet',
                                style:
                                    TextStyle(color: AppColors.textSecondary),
                              ),
                            ),
                          )
                        : Column(
                            children: [
                              for (final tx
                                  in accountProvider.recentTransactions)
                                Column(
                                  children: [
                                    TransactionTile(
                                      transaction: tx,
                                      currency: account.currency,
                                    ),
                                    if (tx !=
                                        accountProvider.recentTransactions.last)
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

class _NoAccount extends StatelessWidget {
  final VoidCallback onCreate;
  const _NoAccount({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.skyTint,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.account_balance_rounded,
              color: AppColors.primary, size: 36),
          const SizedBox(height: 12),
          Text(
            'Open your first account',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          const Text(
            "You don't have a bank account yet.",
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
              onPressed: onCreate, child: const Text('Open Account')),
        ],
      ),
    );
  }
}
