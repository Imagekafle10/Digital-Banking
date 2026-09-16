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
  });

  factory BankTransaction.fromJson(Map<String, dynamic> json) {
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
    );
  }

  bool get isCredit => type == 'deposit' || type == 'transfer_in';

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
