import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../models/account.dart';

/// Shows a QR code that encodes the account holder's name and account
/// number, so someone else can scan it (via QrScanScreen) to quickly fill
/// in the recipient details when sending money.
///
/// The QR payload is JSON: {"accountNumber":"...","name":"..."}
/// which matches what QrScanScreen._extractAccountNumber already expects.
class MyQrScreen extends StatelessWidget {
  final BankAccount account;
  final String? accountHolderName;

  const MyQrScreen({
    super.key,
    required this.account,
    this.accountHolderName,
  });

  String get _qrPayload {
    final data = <String, dynamic>{
      'accountNumber': account.accountNumber,
      if (accountHolderName != null && accountHolderName!.trim().isNotEmpty)
        'name': accountHolderName!.trim(),
    };
    return jsonEncode(data);
  }

  @override
  Widget build(BuildContext context) {
    final name = accountHolderName?.trim();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('My QR')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    QrImageView(
                      data: _qrPayload,
                      version: QrVersions.auto,
                      size: 220,
                      backgroundColor: Colors.white,
                    ),
                    const SizedBox(height: 20),
                    if (name != null && name.isNotEmpty) ...[
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      account.accountNumber,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      account.accountTypeLabel,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.skyTint,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded,
                        color: AppColors.primary, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Show this QR code to someone sending you money. "
                        "They can scan it from the Send Money screen to "
                        "fill in your account number automatically.",
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
