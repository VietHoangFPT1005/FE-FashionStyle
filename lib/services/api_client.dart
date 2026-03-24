import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../config/api_config.dart';
import 'storage_service.dart';

class ApiClient {
  late Dio _dio;
  final StorageService _storage;

  ApiClient(this._storage) {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(milliseconds: ApiConfig.connectTimeout),
        receiveTimeout: const Duration(milliseconds: ApiConfig.receiveTimeout),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    // === Interceptors ===
    _dio.interceptors.add(_AuthInterceptor(_storage, _dio));

    if (kDebugMode) {
      _dio.interceptors.add(PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        compact: true,
      ));
    }
  }

  Dio get dio => _dio;

  // === Convenient methods ===
  Future<Response> get(String path, {Map<String, dynamic>? queryParams}) {
    return _dio.get(path, queryParameters: queryParams);
  }

  Future<Response> post(String path, {dynamic data, Map<String, dynamic>? queryParams}) {
    return _dio.post(path, data: data, queryParameters: queryParams);
  }

  // Dùng cho AI Chat — timeout dài hơn vì Gemini cần thời gian generate
  Future<Response> postAi(String path, {dynamic data, Map<String, dynamic>? queryParams}) {
    return _dio.post(
      path,
      data: data,
      queryParameters: queryParams,
      options: Options(
        receiveTimeout: const Duration(milliseconds: ApiConfig.aiReceiveTimeout),
      ),
    );
  }

  Future<Response> put(String path, {dynamic data, Map<String, dynamic>? queryParams}) {
    return _dio.put(path, data: data, queryParameters: queryParams);
  }

  Future<Response> delete(String path, {dynamic data, Map<String, dynamic>? queryParams}) {
    return _dio.delete(path, data: data, queryParameters: queryParams);
  }

  Future<Response> uploadFile(String path, FormData formData) {
    return _dio.post(
      path,
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
        headers: {'Accept': 'application/json'},
      ),
    );
  }
}

/// Auth interceptor: Auto-attach token + handle 401 refresh
class _AuthInterceptor extends Interceptor {
  final StorageService _storage;
  final Dio _dio;
  bool _isRefreshing = false;

  _AuthInterceptor(this._storage, this._dio);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _storage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;
      try {
        final refreshToken = await _storage.getRefreshToken();
        if (refreshToken != null) {
          final response = await Dio().post(
            '${ApiConfig.baseUrl}${ApiConfig.refreshToken}',
            data: {'refreshToken': refreshToken},
          );

          if (response.statusCode == 200 && response.data['success'] == true) {
            final newToken = response.data['data']['accessToken'];
            final newRefresh = response.data['data']['refreshToken'];
            await _storage.saveTokens(newToken, newRefresh);

            // Retry original request
            final options = err.requestOptions;
            options.headers['Authorization'] = 'Bearer $newToken';
            final retryResponse = await _dio.fetch(options);
            _isRefreshing = false;
            return handler.resolve(retryResponse);
          }
        }
      } catch (_) {}
      _isRefreshing = false;
      // Token refresh failed -> clear and let app handle logout
      await _storage.clearAll();
    }
    handler.next(err);
  }
}
