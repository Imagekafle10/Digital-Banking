import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/account.dart';
import '../../providers/account_provider.dart';
import '../../providers/favourite_provider.dart';
import '../../services/api_client.dart';
import '../../services/banking_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import 'qr_scan_screen.dart';

class TransferScreen extends StatefulWidget {
  final BankAccount account;

  /// Pre-fill recipient account number (e.g. from a favourite).
  final String? initialToAccountNumber;

  /// Pre-fill remarks with recipient name when coming from favourites.
  final String? initialRecipientName;

  const TransferScreen({
    super.key,
    required this.account,
    this.initialToAccountNumber,
    this.initialRecipientName,
  });

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _toAccountController;
  final _amountController = TextEditingController();
  late final TextEditingController _remarksController;
  final _bankingService = BankingService();
  bool _isLoading = false;
  bool _saveAsFavourite = false;

  @override
  void initState() {
    super.initState();
    _toAccountController = TextEditingController(
      text: widget.initialToAccountNumber ?? '',
    );
    _remarksController = TextEditingController(
      text: widget.initialRecipientName ?? '',
    );
  }

  @override
  void dispose() {
    _toAccountController.dispose();
    _amountController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _scanQr() async {
    final scanned = await Navigator.of(context).push<String?>(
      MaterialPageRoute(builder: (_) => const QrScanScreen()),
    );
    if (scanned == null || !mounted) return;
    setState(() {
      _toAccountController.text = scanned;
      _toAccountController.selection = TextSelection.fromPosition(
        TextPosition(offset: _toAccountController.text.length),
      );
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final toNumber = _toAccountController.text.trim();
      final transaction = await _bankingService.transfer(
        fromAccountId: widget.account.id,
        toAccountNumber: toNumber,
        amount: double.parse(_amountController.text),
        remarks: _remarksController.text.trim(),
      );
      if (!mounted) return;

      // Optionally save recipient as favourite
      if (_saveAsFavourite) {
        final name = _remarksController.text.trim().isNotEmpty
            ? _remarksController.text.trim()
            : 'Account $toNumber';
        await context.read<FavouriteProvider>().add(
              name: name,
              accountNumber: toNumber,
            );
      }

      await context
          .read<AccountProvider>()
          .refreshAfterTransaction(transaction);
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
    final alreadyFavourite = context.watch<FavouriteProvider>().isFavourite(
          _toAccountController.text,
        );

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
                      const Icon(Icons.swap_horiz_rounded,
                          color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Sending from ${widget.account.accountTypeLabel} '
                          '(${widget.account.accountNumber})',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13),
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
                  suffix: IconButton(
                    tooltip: 'Scan QR code',
                    icon: const Icon(
                      Icons.qr_code_scanner_rounded,
                      color: AppColors.primary,
                      size: 22,
                    ),
                    onPressed: _scanQr,
                  ),
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
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  icon: Icons.payments_outlined,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter an amount';
                    }
                    final parsed = double.tryParse(value);
                    if (parsed == null || parsed <= 0) {
                      return 'Enter a valid positive amount';
                    }
                    if (parsed > widget.account.balance) {
                      return 'Insufficient balance';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                CustomTextField(
                  label: 'Name / remarks (optional)',
                  controller: _remarksController,
                  icon: Icons.notes_rounded,
                ),
                const SizedBox(height: 12),
                if (!alreadyFavourite)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Save as favourite account',
                      style: TextStyle(fontSize: 14),
                    ),
                    value: _saveAsFavourite,
                    activeColor: AppColors.primary,
                    onChanged: (v) =>
                        setState(() => _saveAsFavourite = v ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                  )
                else
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                        SizedBox(width: 6),
                        Text(
                          'Already in favourites',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
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
