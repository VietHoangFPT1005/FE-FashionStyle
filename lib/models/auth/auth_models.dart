// ==================== Request Models ====================

class LoginRequest {
  final String emailOrPhone;
  final String password;

  LoginRequest({required this.emailOrPhone, required this.password});

  Map<String, dynamic> toJson() => {'emailOrPhone': emailOrPhone, 'password': password};
}

class RegisterRequest {
  final String username;
  final String fullName;
  final String email;
  final String password;
  final String confirmPassword;
  final String? phone;
  final String? gender;

  RegisterRequest({
    required this.username,
    required this.fullName,
    required this.email,
    required this.password,
    required this.confirmPassword,
    this.phone,
    this.gender,
  });

  Map<String, dynamic> toJson() => {
        'username': username,
        'fullName': fullName,
        'email': email,
        'password': password,
        'confirmPassword': confirmPassword,
        if (phone != null) 'phone': phone,
        if (gender != null) 'gender': gender,
      };
}

class ForgotPasswordRequest {
  final String email;
  ForgotPasswordRequest({required this.email});
  Map<String, dynamic> toJson() => {'email': email};
}

class ResetPasswordRequest {
  final String email;
  final String otp;
  final String newPassword;
  final String confirmPassword;

  ResetPasswordRequest({
    required this.email,
    required this.otp,
    required this.newPassword,
    required this.confirmPassword,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'otpCode': otp,
        'newPassword': newPassword,
      };
}

class ChangePasswordRequest {
  final String currentPassword;
  final String newPassword;
  final String? otpCode;

  ChangePasswordRequest({
    required this.currentPassword,
    required this.newPassword,
    this.otpCode,
  });

  Map<String, dynamic> toJson() => {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
        if (otpCode != null) 'otpCode': otpCode,
      };
}

class GoogleLoginRequest {
  final String idToken;
  GoogleLoginRequest({required this.idToken});
  Map<String, dynamic> toJson() => {'idToken': idToken};
}

// ==================== Response Models ====================

class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final UserInfo user;

  AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['accessToken'] ?? '',
      refreshToken: json['refreshToken'] ?? '',
      user: UserInfo.fromJson(json['user'] ?? {}),
    );
  }
}

class UserInfo {
  final int userId;
  final String fullName;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final int role;
  final String? status;

  UserInfo({
    required this.userId,
    required this.fullName,
    required this.email,
    this.phone,
    this.avatarUrl,
    required this.role,
    this.status,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      userId: json['userId'] ?? json['id'] ?? 0,
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      avatarUrl: json['avatarUrl'],
      role: json['role'] ?? 3,
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'avatarUrl': avatarUrl,
        'role': role,
        'status': status,
      };

  bool get isAdmin => role == 1;
  bool get isStaff => role == 2;
  bool get isCustomer => role == 3;
  bool get isShipper => role == 4;
}
