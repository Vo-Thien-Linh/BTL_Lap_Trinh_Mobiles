enum GenderType {
  male,
  female,
  other,
}

extension GenderTypeX on GenderType {
  String get value => switch (this) {
    GenderType.male => 'male',
    GenderType.female => 'female',
    GenderType.other => 'other',
  };

  static GenderType fromString(String value) {
    switch (value) {
      case 'female':
        return GenderType.female;
      case 'other':
        return GenderType.other;
      case 'male':
      default:
        return GenderType.male;
    }
  }
}