import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/account.dart';
import '../../models/payment.dart';
import '../../providers/account_provider.dart';
import '../../services/api_client.dart';
import '../../services/payment_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import 'payment_webview_screen.dart';

class PaymentScreen extends StatefulWidget {
  final BankAccount account;
  const PaymentScreen({super.key, required this.account});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _remarksController = TextEditingController();
  final _paymentService = PaymentService();
  String _provider = 'khalti';
  bool _isLoading = false;

  final _providers = const [
    {
      'value': 'khalti',
      'label': 'Khalti',
      'desc': 'Pay with your Khalti wallet',
      'color': Color(0xFF5C2D91),
    },
    {
      'value': 'esewa',
      'label': 'eSewa',
      'desc': 'Pay with your eSewa account',
      'color': Color(0xFF60BB46),
    },
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final initiation = await _paymentService.initiate(
        accountId: widget.account.id,
        provider: _provider,
        amount: double.parse(_amountController.text),
        remarks: _remarksController.text.trim(),
      );
      if (!mounted) return;
      final result = await Navigator.of(context).push<PaymentResult?>(
        MaterialPageRoute(
          builder: (_) => PaymentWebViewScreen(initiation: initiation),
        ),
      );
      if (!mounted) return;
      if (result != null) {
        if (result.isSuccessful) {
          await context.read<AccountProvider>().loadAccount();
        }
        if (!mounted) return;
        await showDialog(
          context: context,
          builder: (_) => _PaymentResultDialog(result: result),
        );
        if (!mounted) return;
        if (result.isSuccessful) Navigator.of(context).pop();
      }
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
      appBar: AppBar(title: const Text('Pay')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose a payment method',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 14),
                Row(
                  children: _providers.map((provider) {
                    final isSelected = _provider == provider['value'];
                    final color = provider['color'] as Color;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: provider['value'] == 'khalti' ? 10 : 0,
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () => setState(
                            () => _provider = provider['value'] as String,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? color.withOpacity(0.08)
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isSelected ? color : AppColors.border,
                                width: isSelected ? 1.6 : 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  height: 38,
                                  width: 38,
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.14),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.account_balance_wallet_rounded,
                                    color: color,
                                    size: 19,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  provider['label'] as String,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  provider['desc'] as String,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                CustomTextField(
                  label: 'Amount (${widget.account.currency})',
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  icon: Icons.payments_outlined,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Enter an amount';
                    final parsed = double.tryParse(value);
                    if (parsed == null || parsed <= 0) return 'Enter a valid positive amount';
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                CustomTextField(
                  label: 'Remarks (optional)',
                  controller: _remarksController,
                  icon: Icons.notes_rounded,
                ),
                const SizedBox(height: 32),
                CustomButton(
                  label: 'Continue to pay',
                  icon: Icons.lock_outline_rounded,
                  isLoading: _isLoading,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PaymentResultDialog extends StatelessWidget {
  final PaymentResult result;
  const _PaymentResultDialog({required this.result});

  @override
  Widget build(BuildContext context) {
    final success = result.isSuccessful;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            success ? Icons.check_circle_rounded : Icons.error_rounded,
            color: success ? AppColors.success : AppColors.danger,
            size: 56,
          ),
          const SizedBox(height: 16),
          Text(
            success ? 'Payment successful' : 'Payment ${result.status}',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
          ),
          const SizedBox(height: 8),
          Text(
            'Reference: ${result.providerReference}',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done'),
        ),
      ],
    );
  }
}
