import 'package:flutter/foundation.dart';

import '../models/account.dart';
import '../models/transaction.dart';
import '../services/banking_service.dart';

class AccountProvider extends ChangeNotifier {
  final _bankingService = BankingService();

  BankAccount? account;
  List<BankTransaction> recentTransactions = [];
  bool isLoading = false;
  String? error;

  Future<void> loadAccount() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      account = await _bankingService.getMyAccount();
      if (account != null) {
        final page = await _bankingService.getTransactionHistory(
          accountId: account!.id,
          limit: 5,
        );
        recentTransactions = page.rows;
      }
    } catch (e) {
      error = 'Could not load your account.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<BankAccount> createAccount({
    required String accountType,
    String currency = 'NPR',
  }) async {
    final created = await _bankingService.createAccount(
      accountType: accountType,
      currency: currency,
    );
    account = created;
    notifyListeners();
    return created;
  }

  Future<void> refreshAfterTransaction(BankTransaction transaction) async {
    account = account == null
        ? null
        : BankAccount(
            id: account!.id,
            userId: account!.userId,
            accountNumber: account!.accountNumber,
            accountType: account!.accountType,
            balance: transaction.balanceAfter,
            currency: account!.currency,
            status: account!.status,
          );
    recentTransactions = [transaction, ...recentTransactions].take(5).toList();
    notifyListeners();
  }

  void clear() {
    account = null;
    recentTransactions = [];
    notifyListeners();
  }
}
