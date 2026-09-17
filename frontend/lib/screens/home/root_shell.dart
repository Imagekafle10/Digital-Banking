import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/account.dart';
import '../../models/favourite_account.dart';
import '../../providers/account_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/favourite_provider.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/balance_card.dart';
import '../banking/my_qr_screen.dart';
import '../banking/qr_scan_screen.dart';
import '../banking/transactions_screen.dart';
import '../banking/transfer_screen.dart';
import '../dashboard/dashboard_screen.dart';

enum _QrAction { myQr, scan }

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;
  final _pageController = PageController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FavouriteProvider>().load();
    });
  }

  void _goToHomeTab() => _animateToTab(0);

  void _animateToTab(int index) {
    setState(() => _index = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _onQrTap() async {
    final account = context.read<AccountProvider>().account;
    if (account == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Open an account first to send money.')),
      );
      _goToHomeTab();
      return;
    }

    // Slide up a sheet so the user picks which individual QR action they
    // want: show their own QR to receive money, or scan someone else's.
    final action = await showModalBottomSheet<_QrAction>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.qr_code_2_rounded,
                    color: AppColors.primary),
                title: const Text('My QR'),
                subtitle: const Text('Show your QR to receive money'),
                onTap: () => Navigator.of(ctx).pop(_QrAction.myQr),
              ),
              ListTile(
                leading: const Icon(Icons.qr_code_scanner_rounded,
                    color: AppColors.primary),
                title: const Text('Scan QR'),
                subtitle: const Text("Scan someone else's QR to pay"),
                onTap: () => Navigator.of(ctx).pop(_QrAction.scan),
              ),
            ],
          ),
        ),
      ),
    );

    if (action == null || !mounted) return;

    if (action == _QrAction.myQr) {
      final userName = context.read<AuthProvider>().user?.fullName;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              MyQrScreen(account: account, accountHolderName: userName),
        ),
      );
      return;
    }

    final scanned = await Navigator.of(context).push<String?>(
      MaterialPageRoute(builder: (_) => const QrScanScreen()),
    );
    if (scanned == null || !mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TransferScreen(
          account: account,
          initialToAccountNumber: scanned,
        ),
      ),
    );
    if (mounted) context.read<AccountProvider>().loadAccount();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final account = context.watch<AccountProvider>().account;

    final tabs = <Widget>[
      const DashboardScreen(),
      account == null
          ? _NeedsAccountView(
              message: 'Open an account to see your activity.',
              onOpenAccount: _goToHomeTab,
            )
          : TransactionsScreen(account: account),
      account == null
          ? _NeedsAccountView(
              message: 'Open an account to send money.',
              onOpenAccount: _goToHomeTab,
            )
          : _SendTab(account: account),
      const _ComingSoonView(
        icon: Icons.credit_card_rounded,
        title: 'Cards',
        message: 'Card management is coming soon.',
      ),
    ];

    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (i) => setState(() => _index = i),
        children: [for (final tab in tabs) _KeepAlive(child: tab)],
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _index,
        onTap: _animateToTab,
        onQrTap: _onQrTap,
      ),
    );
  }
}

class _KeepAlive extends StatefulWidget {
  final Widget child;
  const _KeepAlive({required this.child});

  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

class _SendTab extends StatelessWidget {
  final BankAccount account;
  const _SendTab({required this.account});

  Future<void> _openTransfer(
    BuildContext context, {
    String? toAccountNumber,
    String? recipientName,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TransferScreen(
          account: account,
          initialToAccountNumber: toAccountNumber,
          initialRecipientName: recipientName,
        ),
      ),
    );
    if (context.mounted) {
      context.read<AccountProvider>().loadAccount();
    }
  }

  Future<void> _showAddFavouriteSheet(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final numberCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Add favourite account',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: numberCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Account number',
                    prefixIcon: Icon(Icons.credit_card),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Enter account number'
                      : null,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    await context.read<FavouriteProvider>().add(
                          name: nameCtrl.text,
                          accountNumber: numberCtrl.text,
                        );
                    if (ctx.mounted) Navigator.of(ctx).pop();
                  },
                  child: const Text('Save favourite'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userName = context.watch<AuthProvider>().user?.fullName;
    final favourites = context.watch<FavouriteProvider>().favourites;

    return Scaffold(
      appBar: AppBar(title: const Text('Send')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            // Your account (not "favourite")
            BalanceCard(
              account: account,
              accountName: userName,
              onQrTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => MyQrScreen(
                    account: account,
                    accountHolderName: userName,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Icon(Icons.send_rounded, color: AppColors.primary, size: 40),
            const SizedBox(height: 12),
            Text(
              'Send money to another account',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            const Text(
              'Transfer funds instantly using an account number.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _openTransfer(context),
              child: const Text('Send Money'),
            ),
            const SizedBox(height: 28),

            // Favourite accounts section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Favourite accounts',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showAddFavouriteSheet(context),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (favourites.isEmpty)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.star_outline_rounded,
                        color: AppColors.textSecondary, size: 32),
                    SizedBox(height: 10),
                    Text(
                      'No favourite accounts yet',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Add accounts you send to often for quick transfer.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...favourites.map(
                (fav) => _FavouriteTile(
                  favourite: fav,
                  onTap: () => _openTransfer(
                    context,
                    toAccountNumber: fav.accountNumber,
                    recipientName: fav.name,
                  ),
                  onDelete: () =>
                      context.read<FavouriteProvider>().remove(fav.id),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FavouriteTile extends StatelessWidget {
  final FavouriteAccount favourite;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _FavouriteTile({
    required this.favourite,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.12),
          child: Text(
            favourite.name.isNotEmpty ? favourite.name[0].toUpperCase() : '?',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        title: Text(
          favourite.name,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          favourite.accountNumber,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.send_rounded, color: AppColors.primary, size: 20),
            IconButton(
              tooltip: 'Remove',
              icon: const Icon(Icons.star_rounded, color: Colors.amber),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _NeedsAccountView extends StatelessWidget {
  final String message;
  final VoidCallback onOpenAccount;
  const _NeedsAccountView({required this.message, required this.onOpenAccount});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.account_balance_rounded,
                    color: AppColors.textSecondary, size: 48),
                const SizedBox(height: 16),
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 20),
                OutlinedButton(
                    onPressed: onOpenAccount, child: const Text('Go to Home')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ComingSoonView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  const _ComingSoonView(
      {required this.icon, required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.textSecondary, size: 48),
              const SizedBox(height: 16),
              Text(message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}
