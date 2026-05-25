class HealthInsuranceValidator {
  HealthInsuranceValidator._();

  static String normalize(String value) {
    return value.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '');
  }

  static String? validate(String? value) {
    final raw = value?.trim() ?? '';

    if (raw.isEmpty) {
      return 'Vui lòng nhập mã số thẻ BHYT';
    }

    final normalized = normalize(raw);

    if (!RegExp(r'^[A-Z0-9]+$').hasMatch(normalized)) {
      return 'Mã BHYT chỉ được gồm chữ cái và số';
    }

    if (normalized.length < 10 || normalized.length > 15) {
      return 'Mã BHYT phải có từ 10 đến 15 ký tự';
    }

    return null;
  }
}
