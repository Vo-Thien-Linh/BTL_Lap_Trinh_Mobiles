enum AppRole {
  patient,
  doctor,
  admin,
}

extension AppRoleX on AppRole {
  String get value => switch (this) {
    AppRole.patient => 'patient',
    AppRole.doctor => 'doctor',
    AppRole.admin => 'admin',
  };

  static AppRole fromString(String value) {
    final cleanValue = value.trim().toLowerCase();
    switch (cleanValue) {
      case 'doctor':
        return AppRole.doctor;
      case 'admin':
        return AppRole.admin;
      case 'patient':
      default:
        return AppRole.patient;
    }
  }
}