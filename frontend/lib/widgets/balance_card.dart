import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../models/account.dart';
import '../providers/balance_visibility_provider.dart';

/// Displays the account as an ATM/debit-card-style widget: brand at top,
/// a decorative chip, a tap-to-reveal balance, and the holder name +
/// masked account number anchored bottom-left, like a physical card.
///
/// The show/hide state is app-wide (see [BalanceVisibilityProvider]), so
/// revealing the balance on one screen keeps it revealed everywhere else
/// this card is shown, and it never resets just from scrolling, navigating,
/// or the parent rebuilding.
class BalanceCard extends StatelessWidget {
  final BankAccount account;

  /// Cardholder name shown in the bottom-left corner.
  final String? accountName;

  /// Optional callback for the small QR icon shown at the top of the card.
  /// When null, the icon is not shown.
  final VoidCallback? onQrTap;

  /// Optional callback fired when the card itself is tapped (outside the
  /// eye and QR icons), e.g. to open a personal/account detail page.
  /// When null, the card is not tappable.
  final VoidCallback? onTap;

  const BalanceCard({
    super.key,
    required this.account,
    this.accountName,
    this.onQrTap,
    this.onTap,
  });

  static final Map<String, NumberFormat> _formatCache = {};

  String _currencySymbol(String currency) {
    if (currency.toUpperCase() == 'NPR') return 'Rs ';
    return '$currency ';
  }

  String _formatAccountNumber(String number) {
    final buffer = StringBuffer();
    for (var i = 0; i < number.length; i++) {
      buffer.write(number[i]);
      if ((i + 1) % 4 == 0 && i + 1 != number.length) buffer.write('  ');
    }
    return buffer.toString();
  }

  /// Masks all but the last 4 digits, in the same "xxxx  xxxx  xxxx  1234"
  /// grouping real cards use.
  String _maskedAccountNumber(String number) {
    if (number.length <= 4) return _formatAccountNumber(number);
    final visible = number.substring(number.length - 4);
    final masked = '•' * (number.length - 4) + visible;
    return _formatAccountNumber(masked);
  }

  @override
  Widget build(BuildContext context) {
    final obscured = context.watch<BalanceVisibilityProvider>().obscured;
    final format = _formatCache.putIfAbsent(
      account.currency,
      () => NumberFormat.currency(
        symbol: _currencySymbol(account.currency),
        decimalDigits: 2,
      ),
    );

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          decoration: BoxDecoration(
            gradient: AppColors.heroGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.35),
                blurRadius: 24,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Faint decorative circle for a bit of card-like texture.
              Positioned(
                right: -30,
                top: -30,
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.06),
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Top row: brand + status + QR ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.account_balance_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'IMAGE BANK',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
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
                                fontSize: 10,
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
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // --- Chip graphic ---
                  Container(
                    width: 38,
                    height: 28,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF6D67A), Color(0xFFD8A742)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // --- Balance (tap eye to reveal) ---
                  Text(
                    account.accountTypeLabel,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          obscured
                              ? '${_currencySymbol(account.currency)}•••••••'
                              : format.format(account.balance),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () =>
                            context.read<BalanceVisibilityProvider>().toggle(),
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            obscured
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            color: Colors.white70,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // --- Bottom-left: holder name + account number ---
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (accountName != null &&
                                accountName!.trim().isNotEmpty)
                              Text(
                                accountName!.trim().toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            const SizedBox(height: 4),
                            Text(
                              obscured
                                  ? _maskedAccountNumber(account.accountNumber)
                                  : _formatAccountNumber(account.accountNumber),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
