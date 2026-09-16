class PaymentInitiation {
  final String provider; // khalti | esewa
  final String providerReference;
  final String? paymentUrl; // khalti: open this URL
  final String? formAction; // esewa: form POST target
  final Map<String, String>? formFields; // esewa: signed fields

  PaymentInitiation({
    required this.provider,
    required this.providerReference,
    this.paymentUrl,
    this.formAction,
    this.formFields,
  });

  factory PaymentInitiation.fromJson(Map<String, dynamic> json) {
    return PaymentInitiation(
      provider: json['provider'] as String,
      providerReference: json['providerReference'] as String,
      paymentUrl: json['paymentUrl'] as String?,
      formAction: json['formAction'] as String?,
      formFields: (json['formFields'] as Map?)
          ?.map((key, value) => MapEntry(key.toString(), value.toString())),
    );
  }
}

class PaymentResult {
  final String id;
  final String accountId;
  final String provider;
  final double amount;
  final String providerReference;
  final String status;

  PaymentResult({
    required this.id,
    required this.accountId,
    required this.provider,
    required this.amount,
    required this.providerReference,
    required this.status,
  });

  factory PaymentResult.fromJson(Map<String, dynamic> json) {
    return PaymentResult(
      id: json['id'] as String,
      accountId: json['accountId'] as String,
      provider: json['provider'] as String,
      amount: (json['amount'] is String)
          ? double.parse(json['amount'] as String)
          : (json['amount'] as num).toDouble(),
      providerReference: json['providerReference'] as String,
      status: json['status'] as String,
    );
  }

  bool get isSuccessful => status.toLowerCase() == 'completed';
}
