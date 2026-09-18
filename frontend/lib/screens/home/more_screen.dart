import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/account_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/dashboard_menu.dart';

/// Shown from the bottom nav's "More" button. Lists every action from the
/// dashboard's quick-menu grid, so nothing is hidden just because there
/// wasn't room for a 5th nav tab.
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final account = context.watch<AccountProvider>().account;
    final userName = context.watch<AuthProvider>().user?.fullName;
    final items = buildDashboardMenuItems(
      context,
      account: account,
      userName: userName,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('More')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: DashboardMenuGrid(items: items),
            ),
          ],
        ),
      ),
    );
  }
}
