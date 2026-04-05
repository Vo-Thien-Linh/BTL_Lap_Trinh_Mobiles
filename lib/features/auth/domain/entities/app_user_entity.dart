class AppUserEntity {
  final String uid;
  final String email;
  final String fullName;
  final String phone;
  final String role;
  final String status;

  const AppUserEntity({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.phone,
    required this.role,
    required this.status,
  });
}
