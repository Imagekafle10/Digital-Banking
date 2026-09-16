class FavouriteAccount {
  final String id;
  final String name;
  final String accountNumber;

  FavouriteAccount({
    required this.id,
    required this.name,
    required this.accountNumber,
  });

  factory FavouriteAccount.fromJson(Map<String, dynamic> json) {
    return FavouriteAccount(
      id: json['id'] as String,
      name: json['name'] as String,
      accountNumber: json['accountNumber'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'accountNumber': accountNumber,
      };
}
