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

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction.isCredit;
    final format = NumberFormat.currency(symbol: '$currency ', decimalDigits: 2);
    final dateLabel = transaction.createdAt != null
        ? DateFormat('MMM d, h:mm a').format(transaction.createdAt!.toLocal())
        : '';

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
              isCredit
                  ? Icons.south_west_rounded
                  : Icons.north_east_rounded,
              color: isCredit ? AppColors.success : AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.typeLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  transaction.remarks?.isNotEmpty == true
                      ? transaction.remarks!
                      : (dateLabel.isNotEmpty ? dateLabel : transaction.status),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
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
