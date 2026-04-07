class RegisterRequestEntity {
  final String fullName;
  final String phone;
  final String cccd;
  final String email;
  final String password;

  const RegisterRequestEntity({
    required this.fullName,
    required this.phone,
    required this.cccd,
    required this.email,
    required this.password,
  });
}