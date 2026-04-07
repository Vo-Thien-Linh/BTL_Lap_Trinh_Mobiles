enum UserStatus {
  active,
  inactive,
  blocked,
}

extension UserStatusX on UserStatus {
  String get value => switch (this) {
    UserStatus.active => 'active',
    UserStatus.inactive => 'inactive',
    UserStatus.blocked => 'blocked',
  };

  static UserStatus fromString(String value) {
    switch (value) {
      case 'inactive':
        return UserStatus.inactive;
      case 'blocked':
        return UserStatus.blocked;
      case 'active':
      default:
        return UserStatus.active;
    }
  }
}