import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../config/app_constants.dart';
import '../models/auth/auth_models.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final StorageService _storage;

  AuthStatus _status = AuthStatus.initial;
  UserInfo? _user;
  String? _errorMessage;

  AuthProvider(this._authService, this._storage);

  AuthStatus get status => _status;
  UserInfo? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isAdmin => _user?.isAdmin ?? false;
  bool get isShipper => _user?.isShipper ?? false;

  /// Check stored token on app start
  Future<void> checkAuth() async {
    final token = await _storage.getAccessToken();
    final savedUser = _storage.getUser();
    if (token != null && savedUser != null) {
      _user = savedUser;
      _status = AuthStatus.authenticated;
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  /// Login with email/password
  Future<bool> login(String email, String password) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authService.login(
        LoginRequest(emailOrPhone: email, password: password),
      );
      if (response.success && response.data != null) {
        await _handleAuthSuccess(response.data!);
        return true;
      } else {
        _errorMessage = response.message;
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = _extractErrorMessage(e, 'Đăng nhập thất bại');
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  /// Register
  Future<bool> register(RegisterRequest request) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authService.register(request);
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      if (response.success) return true;
      _errorMessage = response.message;
      return false;
    } catch (e) {
      _errorMessage = _extractErrorMessage(e, 'Đăng ký thất bại');
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  /// Google Sign In
  Future<bool> googleLogin() async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      // serverClientId (Web Client ID) is REQUIRED to get idToken for backend verification
      final googleSignIn = GoogleSignIn(
        serverClientId: AppConstants.googleWebClientId,
        scopes: ['email', 'profile'],
      );
      // Sign out first to force account picker
      await googleSignIn.signOut();
      final account = await googleSignIn.signIn();
      if (account == null) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }

      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) {
        _errorMessage = 'Không lấy được Google ID Token. Kiểm tra Web Client ID trong Firebase Console.';
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }

      final response = await _authService.googleLogin(idToken);
      if (response.success && response.data != null) {
        await _handleAuthSuccess(response.data!);
        return true;
      }
      _errorMessage = response.message;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = _extractErrorMessage(e, 'Đăng nhập Google thất bại');
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  /// Logout
  Future<void> logout() async {
    await _authService.logout();
    await _storage.clearAll();
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  String _extractErrorMessage(Object e, String fallback) {
    if (e is PlatformException) {
      if (e.code == 'sign_in_failed') return 'Đăng nhập Google bị lỗi cấu hình (SHA-1/ClientID).';
      if (e.code == 'network_error') return 'Lỗi mạng khi kết nối Google.';
      return 'Lỗi hệ thống Google Sign In: ${e.message}';
    }
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        // BE ApiResponse format
        if (data['message'] != null) return data['message'];
        // ASP.NET validation error format
        if (data['errors'] != null && data['errors'] is Map) {
          final errors = data['errors'] as Map;
          final msgs = <String>[];
          for (final v in errors.values) {
            if (v is List) {
              msgs.addAll(v.map((e) => e.toString()));
            }
          }
          if (msgs.isNotEmpty) return msgs.join('. ');
        }
        if (data['title'] != null) return data['title'];
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return 'Kết nối tới server thất bại. Vui lòng kiểm tra mạng.';
      }
      if (e.type == DioExceptionType.connectionError) {
        return 'Không thể kết nối tới server. Vui lòng thử lại.';
      }
    }
    return fallback;
  }

  /// Handle successful auth
  Future<void> _handleAuthSuccess(AuthResponse authResponse) async {
    await _storage.saveTokens(authResponse.accessToken, authResponse.refreshToken);
    await _storage.saveUser(authResponse.user);
    _user = authResponse.user;
    _status = AuthStatus.authenticated;
    notifyListeners();
  }
}
