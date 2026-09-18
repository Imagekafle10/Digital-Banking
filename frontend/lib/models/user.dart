class AppUser {
  final String id;
  final String fullName;
  final String email;
  final String role;
  final String status;
  final String? phone;
  final DateTime? dateOfBirth;
  final String? gender;

  AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.status,
    this.phone,
    this.dateOfBirth,
    this.gender,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      role: (json['role'] as String?) ?? 'user',
      status: (json['status'] as String?) ?? 'active',
      phone: json['phone'] as String?,
      // Backend returns this as an ISO date string ("YYYY-MM-DD") or null
      // for legacy accounts created before this field existed.
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.tryParse(json['dateOfBirth'] as String)
          : null,
      gender: json['gender'] as String?,
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
