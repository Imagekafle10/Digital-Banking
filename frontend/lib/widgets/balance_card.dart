import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/theme/app_theme.dart';
import '../models/account.dart';

class BalanceCard extends StatelessWidget {
  final BankAccount account;

  /// Optional holder name shown under the account type.
  final String? accountName;

  /// Optional callback for the small QR icon shown at the top of the card.
  /// When null, the icon is not shown.
  final VoidCallback? onQrTap;

  const BalanceCard({
    super.key,
    required this.account,
    this.accountName,
    this.onQrTap,
  });

  static final Map<String, NumberFormat> _formatCache = {};

  String _currencySymbol(String currency) {
    if (currency.toUpperCase() == 'NPR') return 'Rs ';
    return '$currency ';
  }

  @override
  Widget build(BuildContext context) {
    final format = _formatCache.putIfAbsent(
      account.currency,
      () => NumberFormat.currency(
        symbol: _currencySymbol(account.currency),
        decimalDigits: 2,
      ),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.35),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                account.accountTypeLabel,
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      account.status.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  if (onQrTap != null) ...[
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: onQrTap,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.qr_code_2_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          if (accountName != null && accountName!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              accountName!.trim(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 16),
          Text(
            format.format(account.balance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 33,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Icon(Icons.credit_card, color: Colors.white70, size: 16),
              const SizedBox(width: 8),
              Text(
                _formatAccountNumber(account.accountNumber),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14.5,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatAccountNumber(String number) {
    final buffer = StringBuffer();
    for (var i = 0; i < number.length; i++) {
      buffer.write(number[i]);
      if ((i + 1) % 4 == 0 && i + 1 != number.length) buffer.write('  ');
    }
    return buffer.toString();
  }
}
