class Validators {
  static String? validateFullName(String? value) {
    final input = value?.trim() ?? '';

    if (input.isEmpty) {
      return 'Vui lòng nhập họ và tên.';
    }

    if (input.length < 2) {
      return 'Họ và tên phải có ít nhất 2 ký tự.';
    }

    if (RegExp(r'^[0-9]+$').hasMatch(input)) {
      return 'Họ và tên không được chỉ gồm chữ số.';
    }

    return null;
  }

  static String? validateEmail(String? value) {
    final input = value?.trim() ?? '';

    if (input.isEmpty) {
      return 'Vui lòng nhập email.';
    }

    final emailRegex = RegExp(r'^[\w.\-]+@([\w\-]+\.)+[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(input)) {
      return 'Email không đúng định dạng.';
    }

    return null;
  }

  static String? validatePhone(String? value) {
    final input = value?.trim() ?? '';

    if (input.isEmpty) {
      return 'Vui lòng nhập số điện thoại.';
    }

    final phoneRegex = RegExp(r'^(0|\+84)[0-9]{9,10}$');
    if (!phoneRegex.hasMatch(input)) {
      return 'Số điện thoại không hợp lệ.';
    }

    return null;
  }

  static String? validateCccd(String? value) {
    final input = value?.trim() ?? '';

    if (input.isEmpty) {
      return 'Vui lòng nhập CCCD.';
    }

    if (!RegExp(r'^[0-9]+$').hasMatch(input)) {
      return 'CCCD chỉ được gồm chữ số.';
    }

    if (input.length != 12) {
      return 'CCCD phải gồm đúng 12 chữ số.';
    }

    return null;
  }

  static String? validatePassword(String? value) {
    final input = value ?? '';

    if (input.isEmpty) {
      return 'Vui lòng nhập mật khẩu.';
    }

    if (input.length < 6) {
      return 'Mật khẩu phải có ít nhất 6 ký tự.';
    }

    if (!RegExp(r'[A-Za-z]').hasMatch(input)) {
      return 'Mật khẩu nên có ít nhất 1 chữ cái.';
    }

    if (!RegExp(r'[0-9]').hasMatch(input)) {
      return 'Mật khẩu nên có ít nhất 1 chữ số.';
    }

    return null;
  }

  static String? validateConfirmPassword(String? value, String password) {
    final input = value ?? '';

    if (input.isEmpty) {
      return 'Vui lòng nhập lại mật khẩu.';
    }

    if (input != password) {
      return 'Mật khẩu xác nhận không khớp.';
    }

    return null;
  }
}