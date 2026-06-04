class RegisterRequestEntity {
  final String fullName;
  final String phone;
  final String cccd;
  final String email;
  final String password;
  final DateTime dateOfBirth;

  const RegisterRequestEntity({
    required this.fullName,
    required this.phone,
    required this.cccd,
    required this.email,
    required this.password,
    required this.dateOfBirth,
  });
}
