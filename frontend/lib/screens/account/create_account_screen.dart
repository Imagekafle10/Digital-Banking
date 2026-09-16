import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/account_provider.dart';
import '../../services/api_client.dart';
import '../../widgets/custom_button.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  String _selectedType = 'savings';
  bool _isLoading = false;

  final _types = const [
    {
      'value': 'savings',
      'label': 'Savings',
      'desc': 'Earn interest on your balance',
      'icon': Icons.savings_outlined,
    },
    {
      'value': 'checking',
      'label': 'Checking',
      'desc': 'Everyday spending account',
      'icon': Icons.account_balance_wallet_outlined,
    },
    {
      'value': 'wallet',
      'label': 'Wallet',
      'desc': 'Fast top-ups and payments',
      'icon': Icons.wallet_outlined,
    },
  ];

  Future<void> _create() async {
    setState(() => _isLoading = true);
    try {
      await context
          .read<AccountProvider>()
          .createAccount(accountType: _selectedType);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(extractErrorMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Open an account')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose an account type',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              Text(
                'You can add more accounts later.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              ..._types.map((type) {
                final isSelected = _selectedType == type['value'];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () =>
                        setState(() => _selectedType = type['value'] as String),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.skyTint
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.border,
                          width: isSelected ? 1.6 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            height: 46,
                            width: 46,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              type['icon'] as IconData,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  type['label'] as String,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  type['desc'] as String,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            isSelected
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.border,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const Spacer(),
              CustomButton(
                label: 'Open Account',
                isLoading: _isLoading,
                onPressed: _create,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
