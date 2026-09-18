import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../models/account.dart';
import '../providers/account_provider.dart';
import '../screens/account/create_account_screen.dart';
import '../screens/account/personal_detail_screen.dart';
import '../screens/banking/my_qr_screen.dart';
import '../screens/banking/transactions_screen.dart';
import '../screens/banking/transfer_screen.dart';
import '../screens/banking/withdraw_screen.dart';
import '../screens/payment/payment_screen.dart';

/// One tile in the dashboard's feature grid ("My Accounts", "Send Money",
/// etc). Shared between DashboardScreen (small inline grid) and MoreScreen
/// (the full "More" tab), so both always show the same set of actions.
class DashMenuItem {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  DashMenuItem(this.label, this.icon, this.color, this.onTap);
}

Future<void> _open(BuildContext context, Widget screen) async {
  await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  if (context.mounted) context.read<AccountProvider>().loadAccount();
}

void _soon(BuildContext context, String name) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('$name is coming soon')),
  );
}

void _needAccount(BuildContext context, BankAccount? account, VoidCallback go) {
  if (account == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Open an account first')),
    );
    return;
  }
  go();
}

/// The full set of dashboard actions. Call this from build() so it always
/// reflects the current account/user.
List<DashMenuItem> buildDashboardMenuItems(
  BuildContext context, {
  required BankAccount? account,
  required String? userName,
}) {
  return [
    DashMenuItem('My Accounts', Icons.account_balance_wallet_rounded,
        const Color(0xFF1AAE6F), () {
      if (account == null) {
        _open(context, const CreateAccountScreen());
      } else {
        _open(context,
            PersonalDetailScreen(account: account, accountName: userName));
      }
    }),
    DashMenuItem('Cards', Icons.credit_card_rounded, const Color(0xFF1AAE6F),
        () {
      _needAccount(
        context,
        account,
        () => _open(
          context,
          PersonalDetailScreen(account: account!, accountName: userName),
        ),
      );
    }),
    DashMenuItem('Statement', Icons.description_outlined, AppColors.primary,
        () {
      _needAccount(context, account,
          () => _open(context, TransactionsScreen(account: account!)));
    }),
    DashMenuItem('Digital Services', Icons.grid_view_rounded, AppColors.primary,
        () => _soon(context, 'Digital Services')),
    DashMenuItem('My QR', Icons.qr_code_2_rounded, const Color(0xFF1AAE6F), () {
      _needAccount(
        context,
        account,
        () => _open(context,
            MyQrScreen(account: account!, accountHolderName: userName)),
      );
    }),
    DashMenuItem('Payments', Icons.payments_outlined, const Color(0xFF1AAE6F),
        () {
      _needAccount(context, account,
          () => _open(context, PaymentScreen(account: account!)));
    }),
    DashMenuItem('Load Wallet', Icons.add_box_outlined, const Color(0xFF1AAE6F),
        () {
      _needAccount(
        context,
        account,
        () => _open(
          context,
          PaymentScreen(
            account: account!,
            title: 'Load Wallet',
            ctaLabel: 'Continue to load wallet',
          ),
        ),
      );
    }),
    DashMenuItem('Mobile Topup', Icons.phone_android_rounded, AppColors.primary,
        () => _soon(context, 'Mobile Topup')),
    DashMenuItem(
        'Cardless Withdrawal', Icons.atm_rounded, const Color(0xFFE0473F), () {
      _needAccount(context, account,
          () => _open(context, WithdrawScreen(account: account!)));
    }),
    DashMenuItem('Send Money', Icons.send_rounded, const Color(0xFF1AAE6F), () {
      _needAccount(context, account,
          () => _open(context, TransferScreen(account: account!)));
    }),
    DashMenuItem('Fixed Deposit', Icons.savings_outlined, AppColors.primary,
        () => _soon(context, 'Fixed Deposit')),
    DashMenuItem('Virtual Dollar', Icons.account_balance_rounded,
        AppColors.primary, () => _soon(context, 'Virtual Dollar Card')),
    DashMenuItem('Book Appointment', Icons.event_available_rounded,
        const Color(0xFF1AAE6F), () => _soon(context, 'Book an Appointment')),
  ];
}

/// The 4-column icon grid used to show a list of [DashMenuItem]s.
class DashboardMenuGrid extends StatelessWidget {
  final List<DashMenuItem> items;
  final int columns;

  const DashboardMenuGrid({super.key, required this.items, this.columns = 4});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = 8.0;
        final tileW = (constraints.maxWidth - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: 16,
          children: [
            for (final item in items)
              SizedBox(width: tileW, child: _MenuTile(item: item)),
          ],
        );
      },
    );
  }
}

class _MenuTile extends StatelessWidget {
  final DashMenuItem item;
  const _MenuTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFF7F9FC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Icon(item.icon, color: item.color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            item.label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
