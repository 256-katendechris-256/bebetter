class User {
  final int id;
  final String email;
  final bool emailVerified;
  final String? username;
  final String? firstName;
  final String? lastName;
  final String role;
  final bool isActive;
  final bool isStaff;
  final DateTime createdAt;

  User({
    required this.id,
    required this.email,
    required this.emailVerified,
    this.username,
    this.firstName,
    this.lastName,
    required this.role,
    required this.isActive,
    required this.isStaff,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      email: json['email'] as String,
      emailVerified: json['email_verified'] as bool? ?? false,
      username: json['username'] as String?,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      role: json['role'] as String? ?? 'USER',
      isActive: json['is_active'] as bool? ?? true,
      isStaff: json['is_staff'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'email_verified': emailVerified,
        'username': username,
        'first_name': firstName,
        'last_name': lastName,
        'role': role,
        'is_active': isActive,
        'is_staff': isStaff,
        'created_at': createdAt.toIso8601String(),
      };

  String get displayName {
    if (firstName != null && firstName!.isNotEmpty) return firstName!;
    if (username != null && username!.isNotEmpty) return username!;
    return email.split('@').first;
  }

  String get fullName {
    final parts = [firstName, lastName].whereType<String>().where((s) => s.isNotEmpty);
    return parts.isNotEmpty ? parts.join(' ') : displayName;
  }
}
