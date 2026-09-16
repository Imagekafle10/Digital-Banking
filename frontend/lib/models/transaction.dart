class BankTransaction {
  final String id;
  final String accountId;
  final String type; // deposit | withdrawal | transfer_in | transfer_out
  final double amount;
  final double balanceAfter;
  final String reference;
  final String? relatedAccountId;
  final String status; // pending | completed | failed | reversed
  final String? remarks;
  final DateTime? createdAt;

  /// Optional counterparty details (when backend includes them).
  final String? relatedAccountNumber;
  final String? counterpartyName;

  BankTransaction({
    required this.id,
    required this.accountId,
    required this.type,
    required this.amount,
    required this.balanceAfter,
    required this.reference,
    this.relatedAccountId,
    required this.status,
    this.remarks,
    this.createdAt,
    this.relatedAccountNumber,
    this.counterpartyName,
  });

  factory BankTransaction.fromJson(Map<String, dynamic> json) {
    // Backend may nest related account under different keys.
    final related = json['relatedAccount'] is Map
        ? json['relatedAccount'] as Map<String, dynamic>
        : null;
    final counterparty = json['counterparty'] is Map
        ? json['counterparty'] as Map<String, dynamic>
        : null;

    String? pickName() {
      for (final key in [
        'counterpartyName',
        'otherPartyName',
        'relatedUserName',
        'toUserName',
        'fromUserName',
        'recipientName',
        'senderName',
      ]) {
        final v = json[key];
        if (v is String && v.trim().isNotEmpty) return v.trim();
      }
      if (related != null) {
        for (final key in ['fullName', 'name', 'userName', 'holderName']) {
          final v = related[key];
          if (v is String && v.trim().isNotEmpty) return v.trim();
        }
      }
      if (counterparty != null) {
        for (final key in ['fullName', 'name', 'userName']) {
          final v = counterparty[key];
          if (v is String && v.trim().isNotEmpty) return v.trim();
        }
      }
      return null;
    }

    String? pickAccountNumber() {
      for (final key in [
        'relatedAccountNumber',
        'toAccountNumber',
        'fromAccountNumber',
        'otherAccountNumber',
        'counterpartyAccountNumber',
      ]) {
        final v = json[key];
        if (v is String && v.trim().isNotEmpty) return v.trim();
      }
      if (related != null) {
        final v = related['accountNumber'];
        if (v is String && v.trim().isNotEmpty) return v.trim();
      }
      if (counterparty != null) {
        final v = counterparty['accountNumber'];
        if (v is String && v.trim().isNotEmpty) return v.trim();
      }
      return null;
    }

    return BankTransaction(
      id: json['id'] as String,
      accountId: json['accountId'] as String,
      type: json['type'] as String,
      amount: (json['amount'] is String)
          ? double.parse(json['amount'] as String)
          : (json['amount'] as num).toDouble(),
      balanceAfter: (json['balanceAfter'] is String)
          ? double.parse(json['balanceAfter'] as String)
          : (json['balanceAfter'] as num).toDouble(),
      reference: json['reference'] as String,
      relatedAccountId: json['relatedAccountId'] as String?,
      status: json['status'] as String,
      remarks: json['remarks'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      relatedAccountNumber: pickAccountNumber(),
      counterpartyName: pickName(),
    );
  }

  bool get isCredit => type == 'deposit' || type == 'transfer_in';

  bool get isTransfer => type == 'transfer_in' || type == 'transfer_out';

  String get typeLabel {
    switch (type) {
      case 'deposit':
        return 'Deposit';
      case 'withdrawal':
        return 'Withdrawal';
      case 'transfer_in':
        return 'Transfer received';
      case 'transfer_out':
        return 'Transfer sent';
      default:
        return type;
    }
  }

  /// Best available label for the other party (transfers) or the activity itself.
  String get displayPartyName {
    if (counterpartyName != null && counterpartyName!.trim().isNotEmpty) {
      return counterpartyName!.trim();
    }
    if (relatedAccountNumber != null &&
        relatedAccountNumber!.trim().isNotEmpty) {
      return relatedAccountNumber!.trim();
    }
    if (remarks != null && remarks!.trim().isNotEmpty) {
      return remarks!.trim();
    }
    return typeLabel;
  }
}

class TransactionPage {
  final List<BankTransaction> rows;
  final int count;

  TransactionPage({required this.rows, required this.count});

  factory TransactionPage.fromJson(Map<String, dynamic> json) {
    return TransactionPage(
      rows: (json['rows'] as List<dynamic>)
          .map((e) => BankTransaction.fromJson(e as Map<String, dynamic>))
          .toList(),
      count: (json['count'] as num).toInt(),
    );
  }
}
