import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/account.dart';
import '../../providers/account_provider.dart';
import '../../services/api_client.dart';
import '../../services/banking_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class TransferScreen extends StatefulWidget {
  final BankAccount account;
  const TransferScreen({super.key, required this.account});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _toAccountController = TextEditingController();
  final _amountController = TextEditingController();
  final _remarksController = TextEditingController();
  final _bankingService = BankingService();
  bool _isLoading = false;

  @override
  void dispose() {
    _toAccountController.dispose();
    _amountController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final transaction = await _bankingService.transfer(
        fromAccountId: widget.account.id,
        toAccountNumber: _toAccountController.text.trim(),
        amount: double.parse(_amountController.text),
        remarks: _remarksController.text.trim(),
      );
      if (!mounted) return;
      await context.read<AccountProvider>().refreshAfterTransaction(transaction);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transfer successful')),
      );
      Navigator.of(context).pop();
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
      appBar: AppBar(title: const Text('Transfer')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.skyTint,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.swap_horiz_rounded, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Sending from ${widget.account.accountTypeLabel} '
                          '(${widget.account.accountNumber})',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                CustomTextField(
                  label: "Recipient's account number",
                  controller: _toAccountController,
                  keyboardType: TextInputType.number,
                  icon: Icons.person_search_rounded,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Enter the recipient's account number";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                CustomTextField(
                  label: 'Amount (${widget.account.currency})',
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  icon: Icons.payments_outlined,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Enter an amount';
                    final parsed = double.tryParse(value);
                    if (parsed == null || parsed <= 0) return 'Enter a valid positive amount';
                    if (parsed > widget.account.balance) return 'Insufficient balance';
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
                  label: 'Send Transfer',
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
