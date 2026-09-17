import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/account.dart';
import '../../models/favourite_account.dart';
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
  final _remarkController = TextEditingController();
  final _bankingService = BankingService();
  bool _isLoading = false;
  bool _saveAsFavourite = false;

  // Recipient verification (auto-looks up the account holder's name as
  // soon as a full account number is typed or scanned, the way real
  // banking/wallet apps confirm "who you're sending to" before you send).
  Timer? _verifyDebounce;
  String? _verifiedForNumber;
  bool _verifying = false;
  AccountLookupResult? _verifiedAccount;
  bool _accountNotFound = false;
  bool _verifyErrored = false;

  @override
  void initState() {
    super.initState();
    _toAccountController = TextEditingController(
      text: widget.initialToAccountNumber ?? '',
    );
    _toAccountController.addListener(_onAccountNumberChanged);
    if (widget.initialToAccountNumber != null &&
        widget.initialToAccountNumber!.trim().isNotEmpty) {
      _onAccountNumberChanged();
    }
  }

  @override
  void dispose() {
    _verifyDebounce?.cancel();
    _toAccountController.removeListener(_onAccountNumberChanged);
    _toAccountController.dispose();
    _amountController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  void _onAccountNumberChanged() {
    final number = _toAccountController.text.trim();
    _verifyDebounce?.cancel();

    // Reset any stale verification as soon as the number no longer matches
    // what was last checked, so an outdated "Verified" badge never lingers.
    if (_verifiedForNumber != null && _verifiedForNumber != number) {
      setState(() {
        _verifiedAccount = null;
        _accountNotFound = false;
        _verifyErrored = false;
        _verifiedForNumber = null;
      });
    }

    if (number.length < 8) return;

    _verifyDebounce = Timer(const Duration(milliseconds: 500), () {
      _verifyAccount(number);
    });
  }

  Future<void> _verifyAccount(String number) async {
    if (!mounted || number.isEmpty) return;
    setState(() {
      _verifying = true;
      _accountNotFound = false;
      _verifyErrored = false;
    });
    try {
      final result = await _bankingService.lookupAccountByNumber(number);
      // The user may have kept typing while this was in flight - only
      // apply the result if the field still holds the number we checked.
      if (!mounted || _toAccountController.text.trim() != number) return;
      setState(() {
        _verifying = false;
        _verifiedForNumber = number;
        if (result == null) {
          _accountNotFound = true;
          _verifiedAccount = null;
        } else {
          _verifiedAccount = result;
        }
      });
    } catch (_) {
      if (!mounted || _toAccountController.text.trim() != number) return;
      setState(() {
        _verifying = false;
        _verifiedForNumber = number;
        _verifyErrored = true;
      });
    }
  }

  void _applyFavourite(FavouriteAccount fav) {
    setState(() {
      _toAccountController.text = fav.accountNumber;
      _toAccountController.selection = TextSelection.fromPosition(
        TextPosition(offset: _toAccountController.text.length),
      );
    });
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

  Future<void> _confirmAndSend() async {
    if (!_formKey.currentState!.validate()) return;

    final toNumber = _toAccountController.text.trim();

    // The recipient must be verified before we let the user send - no more
    // typing a name yourself, the real account holder's name is required.
    if (_verifiedForNumber != toNumber || _verifiedAccount == null) {
      final String message;
      if (_verifying) {
        message = 'Still verifying the account, please wait a moment.';
      } else if (_accountNotFound) {
        message = 'No account was found with that number. '
            'Please double-check it before sending.';
      } else if (_verifyErrored) {
        message = "Couldn't verify the account. "
            'Check your connection and try again.';
      } else {
        message = 'Enter the full account number so we can verify '
            'the recipient first.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      return;
    }

    final holderName = _verifiedAccount!.name;
    final maskedName = maskName(holderName);
    final remark = _remarkController.text.trim();
    final amount = double.parse(_amountController.text);

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Confirm transfer',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              _ConfirmRow(label: 'Account number', value: toNumber),
              _ConfirmRow(label: 'Recipient name', value: maskedName),
              _ConfirmRow(
                label: 'Amount',
                value:
                    '${widget.account.currency} ${amount.toStringAsFixed(2)}',
                valueColor: const Color(0xFFE0473F),
              ),
              _ConfirmRow(
                label: 'From',
                value:
                    '${widget.account.accountTypeLabel} (${widget.account.accountNumber})',
              ),
              _ConfirmRow(
                label: 'Remark',
                value: remark.isNotEmpty ? remark : '—',
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Confirm & Send'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true && mounted) {
      await _submit();
    }
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
        remarks: _remarkController.text.trim(),
      );
      if (!mounted) return;

      // Optionally save recipient as favourite
      if (_saveAsFavourite) {
        final verifiedName = _verifiedAccount?.name.trim() ?? '';
        final name =
            verifiedName.isNotEmpty ? verifiedName : 'Account $toNumber';
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
                _FavouritesPicker(onSelect: _applyFavourite),
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
                _RecipientPreview(
                  verifying: _verifying,
                  verified: _verifiedAccount,
                  notFound: _accountNotFound,
                  errored: _verifyErrored,
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
                  label: 'Remark (optional)',
                  controller: _remarkController,
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
                  onPressed: _confirmAndSend,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Masks a person's name for privacy, e.g. "Image" -> "Im**e",
/// "Test User" -> "Te**t Us*r". Keeps the first two and last one
/// character of each word visible; words of 3 chars or fewer are
/// barely touched since there's nothing meaningful to hide.
String maskName(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return trimmed;
  return trimmed.split(RegExp(r'\s+')).map(_maskWord).join(' ');
}

String _maskWord(String word) {
  if (word.length <= 2) return word;
  if (word.length == 3) return '${word[0]}*${word[word.length - 1]}';
  final first = word.substring(0, 2);
  final last = word.substring(word.length - 1);
  final stars = '*' * (word.length - 3);
  return '$first$stars$last';
}

/// Shows the recipient's (masked) verified name right under the account
/// number field - this is not optional decoration, it's the confirmation
/// that you're sending to the right person, the way real banking/wallet
/// apps show it before you can proceed.
class _RecipientPreview extends StatelessWidget {
  final bool verifying;
  final AccountLookupResult? verified;
  final bool notFound;
  final bool errored;

  const _RecipientPreview({
    required this.verifying,
    required this.verified,
    required this.notFound,
    required this.errored,
  });

  @override
  Widget build(BuildContext context) {
    if (!verifying && verified == null && !notFound && !errored) {
      return const SizedBox(height: 4);
    }

    Color background;
    Widget content;

    if (verifying) {
      background = AppColors.skyTint;
      content = const Row(
        children: [
          SizedBox(
            width: 15,
            height: 15,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 10),
          Text(
            'Verifying account…',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      );
    } else if (verified != null) {
      const green = Color(0xFF1AAE6F);
      background = const Color(0xFFE7F7EF);
      content = Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: green, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 13.5),
                children: [
                  const TextSpan(
                    text: 'Account holder: ',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextSpan(
                    text: maskName(verified!.name),
                    style: const TextStyle(
                      color: green,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    } else if (notFound) {
      const red = Color(0xFFE0473F);
      background = const Color(0xFFFCEBEA);
      content = const Row(
        children: [
          Icon(Icons.error_outline_rounded, color: red, size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'No account found with this number',
              style: TextStyle(
                color: red,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      );
    } else {
      background = AppColors.skyTint;
      content = const Row(
        children: [
          Icon(Icons.wifi_off_rounded,
              color: AppColors.textSecondary, size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              "Couldn't verify - check your connection",
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: content,
      ),
    );
  }
}

class _FavouritesPicker extends StatelessWidget {
  final ValueChanged<FavouriteAccount> onSelect;
  const _FavouritesPicker({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final favourites = context.watch<FavouriteProvider>().favourites;
    if (favourites.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Favourites',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 78,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: favourites.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final fav = favourites[index];
                return InkWell(
                  onTap: () => onSelect(fav),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 130,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.skyTint,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor:
                                  AppColors.primary.withOpacity(0.15),
                              child: Text(
                                fav.name.isNotEmpty
                                    ? fav.name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                fav.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12.5,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          fav.accountNumber,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _ConfirmRow(
      {required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
                color: valueColor ?? AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
