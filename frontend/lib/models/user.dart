class AppUser {
  final String id;
  final String fullName;
  final String email;
  final String role;
  final String status;

  AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.status,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      role: (json['role'] as String?) ?? 'user',
      status: (json['status'] as String?) ?? 'active',
    );
  }

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}
