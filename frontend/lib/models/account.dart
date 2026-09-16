class BankAccount {
  final String id;
  final String userId;
  final String accountNumber;
  final String accountType; // savings | checking | wallet
  final double balance;
  final String currency;
  final String status;

  BankAccount({
    required this.id,
    required this.userId,
    required this.accountNumber,
    required this.accountType,
    required this.balance,
    required this.currency,
    required this.status,
  });

  factory BankAccount.fromJson(Map<String, dynamic> json) {
    return BankAccount(
      id: json['id'] as String,
      userId: json['userId'] as String,
      accountNumber: json['accountNumber'] as String,
      accountType: json['accountType'] as String,
      balance: (json['balance'] is String)
          ? double.parse(json['balance'] as String)
          : (json['balance'] as num).toDouble(),
      currency: (json['currency'] as String?) ?? 'NPR',
      status: (json['status'] as String?) ?? 'active',
    );
  }

  String get accountTypeLabel {
    switch (accountType) {
      case 'savings':
        return 'Savings Account';
      case 'checking':
        return 'Checking Account';
      case 'wallet':
        return 'Wallet';
      default:
        return accountType;
    }
  }
}
