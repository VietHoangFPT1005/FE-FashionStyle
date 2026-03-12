import '../config/api_config.dart';
import '../models/api_response.dart';
import '../models/auth/auth_models.dart';
import 'api_client.dart';

class AuthService {
  final ApiClient _client;
  AuthService(this._client);

  Future<ApiResponse<AuthResponse>> login(LoginRequest request) async {
    final response = await _client.post(ApiConfig.login, data: request.toJson());
    return ApiResponse.fromJson(response.data, (d) => AuthResponse.fromJson(d));
  }

  Future<ApiResponse> register(RegisterRequest request) async {
    final response = await _client.post(ApiConfig.register, data: request.toJson());
    return ApiResponse.fromJson(response.data, null);
  }

  Future<ApiResponse> verifyEmail(String email, String otp) async {
    final response = await _client.post(ApiConfig.verifyEmail, data: {'email': email, 'otpCode': otp});
    return ApiResponse.fromJson(response.data, null);
  }

  Future<ApiResponse> resendOtp(String email, {String type = 'VERIFY_EMAIL'}) async {
    final response = await _client.post(ApiConfig.resendOtp, data: {'email': email, 'type': type});
    return ApiResponse.fromJson(response.data, null);
  }

  Future<ApiResponse> forgotPassword(String email) async {
    final response = await _client.post(ApiConfig.forgotPassword, data: {'email': email});
    return ApiResponse.fromJson(response.data, null);
  }

  Future<ApiResponse> resetPassword(ResetPasswordRequest request) async {
    final response = await _client.post(ApiConfig.resetPassword, data: request.toJson());
    return ApiResponse.fromJson(response.data, null);
  }

  Future<ApiResponse> changePassword(ChangePasswordRequest request) async {
    final response = await _client.put(ApiConfig.changePassword, data: request.toJson());
    return ApiResponse.fromJson(response.data, null);
  }

  Future<ApiResponse<AuthResponse>> googleLogin(String idToken) async {
    final response = await _client.post(ApiConfig.googleLogin, data: {'idToken': idToken});
    return ApiResponse.fromJson(response.data, (d) => AuthResponse.fromJson(d));
  }

  Future<ApiResponse<AuthResponse>> refreshToken(String refreshToken) async {
    final response = await _client.post(ApiConfig.refreshToken, data: {'refreshToken': refreshToken});
    return ApiResponse.fromJson(response.data, (d) => AuthResponse.fromJson(d));
  }

  Future<void> logout() async {
    try {
      await _client.post(ApiConfig.logout);
    } catch (_) {}
  }
}
