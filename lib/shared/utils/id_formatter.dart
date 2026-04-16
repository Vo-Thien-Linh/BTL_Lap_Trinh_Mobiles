class IdFormatter {
  static String format({
    required String prefix,
    required String rawId,
    int digits = 6,
  }) {
    final normalized = rawId
        .replaceAll(RegExp(r'[^A-Za-z0-9]'), '')
        .toUpperCase();
    if (normalized.isEmpty) {
      return '$prefix-${'0' * digits}';
    }

    var hash = 0;
    for (final unit in normalized.codeUnits) {
      hash = ((hash * 31) + unit) & 0x7fffffff;
    }

    final max = _pow10(digits);
    final value = (hash % max).toString().padLeft(digits, '0');
    return '$prefix-$value';
  }

  static int _pow10(int exponent) {
    var result = 1;
    for (var i = 0; i < exponent; i++) {
      result *= 10;
    }
    return result;
  }
}
