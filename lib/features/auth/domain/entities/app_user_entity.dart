class AppUserEntity {
  final String uid;
  final String username;
  final String email;
  final String phone;
  final String fullName;
  final String cccd;
  final String role;
  final String status;
  final bool emailVerified;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AppUserEntity({
    required this.uid,
    required this.username,
    required this.email,
    required this.phone,
    required this.fullName,
    required this.cccd,
    required this.role,
    required this.status,
    required this.emailVerified,
    required this.createdAt,
    required this.updatedAt,
  });
}