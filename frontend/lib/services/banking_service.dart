import '../core/constants/api_constants.dart';
import '../models/account.dart';
import '../models/transaction.dart';
import 'api_client.dart';

class BankingService {
  final _client = ApiClient.instance;

  Future<BankAccount?> getMyAccount() async {
    try {
      final response = await _client.dio.get(ApiConstants.myAccount);
      return BankAccount.fromJson(
        response.data['data'] as Map<String, dynamic>,
      );
    } on Object catch (e) {
      final status = _statusCodeOf(e);
      if (status == 404) return null;
      rethrow;
    }
  }

  Future<BankAccount> createAccount({
    required String accountType,
    String currency = 'NPR',
  }) async {
    final response = await _client.dio.post(
      ApiConstants.createAccount,
      data: {'accountType': accountType, 'currency': currency},
    );
    return BankAccount.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<BankTransaction> deposit({
    required String accountId,
    required double amount,
    String? remarks,
  }) async {
    final response = await _client.dio.post(
      ApiConstants.deposit,
      data: {
        'accountId': accountId,
        'amount': amount,
        if (remarks != null && remarks.isNotEmpty) 'remarks': remarks,
      },
    );
    return BankTransaction.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<BankTransaction> withdraw({
    required String accountId,
    required double amount,
    String? remarks,
  }) async {
    final response = await _client.dio.post(
      ApiConstants.withdraw,
      data: {
        'accountId': accountId,
        'amount': amount,
        if (remarks != null && remarks.isNotEmpty) 'remarks': remarks,
      },
    );
    return BankTransaction.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<BankTransaction> transfer({
    required String fromAccountId,
    required String toAccountNumber,
    required double amount,
    String? remarks,
  }) async {
    final response = await _client.dio.post(
      ApiConstants.transfer,
      data: {
        'fromAccountId': fromAccountId,
        'toAccountNumber': toAccountNumber,
        'amount': amount,
        if (remarks != null && remarks.isNotEmpty) 'remarks': remarks,
      },
    );
    return BankTransaction.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<TransactionPage> getTransactionHistory({
    required String accountId,
    String? type,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _client.dio.get(
      ApiConstants.transactions(accountId),
      queryParameters: {
        if (type != null) 'type': type,
        'page': page,
        'limit': limit,
      },
    );
    return TransactionPage.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  int? _statusCodeOf(Object e) {
    try {
      return (e as dynamic).response?.statusCode as int?;
    } catch (_) {
      return null;
    }
  }
}
