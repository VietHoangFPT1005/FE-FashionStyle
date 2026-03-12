class Validators {
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Vui lòng nhập email';
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!regex.hasMatch(value.trim())) return 'Email không hợp lệ';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Vui lòng nhập mật khẩu';
    if (value.length < 6) return 'Mật khẩu phải có ít nhất 6 ký tự';
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'Vui lòng xác nhận mật khẩu';
    if (value != password) return 'Mật khẩu không khớp';
    return null;
  }

  static String? required(String? value, [String fieldName = 'Trường này']) {
    if (value == null || value.trim().isEmpty) return '$fieldName không được để trống';
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Vui lòng nhập số điện thoại';
    final regex = RegExp(r'^(0[3|5|7|8|9])+([0-9]{8})$');
    if (!regex.hasMatch(value.trim())) return 'Số điện thoại không hợp lệ';
    return null;
  }

  static String? minLength(String? value, int min, [String fieldName = 'Trường này']) {
    if (value == null || value.length < min) {
      return '$fieldName phải có ít nhất $min ký tự';
    }
    return null;
  }

  static String? maxLength(String? value, int max, [String fieldName = 'Trường này']) {
    if (value != null && value.length > max) {
      return '$fieldName không được quá $max ký tự';
    }
    return null;
  }
}
