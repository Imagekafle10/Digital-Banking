import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/theme/app_theme.dart';
import '../models/transaction.dart';

class TransactionTile extends StatelessWidget {
  final BankTransaction transaction;
  final String currency;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.currency = 'NPR',
  });

  static final Map<String, NumberFormat> _formatCache = {};

  String _currencySymbol(String currency) {
    if (currency.toUpperCase() == 'NPR') return 'Rs ';
    return '$currency ';
  }

  NumberFormat _formatFor(String currency) => _formatCache.putIfAbsent(
        currency,
        () => NumberFormat.currency(
          symbol: _currencySymbol(currency),
          decimalDigits: 2,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction.isCredit;
    final format = _formatFor(currency);
    final dateLabel = transaction.createdAt != null
        ? DateFormat('MMM d, yyyy · h:mm a')
            .format(transaction.createdAt!.toLocal())
        : '—';

    // Other user / party name (for transfers), else activity label
    final partyName = transaction.displayPartyName;

    // Secondary line: type + optional account number of other party
    String secondary;
    if (transaction.isTransfer) {
      final parts = <String>[transaction.typeLabel];
      if (transaction.relatedAccountNumber != null &&
          transaction.relatedAccountNumber!.isNotEmpty &&
          partyName != transaction.relatedAccountNumber) {
        parts.add('A/C ${transaction.relatedAccountNumber}');
      }
      secondary = parts.join(' · ');
    } else if (transaction.remarks?.isNotEmpty == true &&
        partyName != transaction.remarks) {
      secondary = '${transaction.typeLabel} · ${transaction.remarks}';
    } else {
      secondary = transaction.typeLabel;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: (isCredit ? AppColors.success : AppColors.primary)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isCredit ? Icons.south_west_rounded : Icons.north_east_rounded,
              color: isCredit ? AppColors.success : AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Other user / party name
                Text(
                  partyName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  secondary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                // Date
                Text(
                  dateLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Amount in Rs
          Text(
            '${isCredit ? '+' : '-'}${format.format(transaction.amount)}',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14.5,
              color: isCredit ? AppColors.success : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
