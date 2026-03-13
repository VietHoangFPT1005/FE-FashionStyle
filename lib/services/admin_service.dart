import 'dart:io';
import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/api_response.dart';
import 'api_client.dart';

class AdminService {
  final ApiClient _client;
  AdminService(this._client);

  // ==================== Users ====================
  Future<ApiResponse> getUsers({int page = 1, int pageSize = 20, int? role, bool? isActive, String? search}) async {
    final params = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
      if (role != null) 'role': role,
      if (isActive != null) 'isActive': isActive,
      if (search != null && search.isNotEmpty) 'search': search,
    };
    final res = await _client.get(ApiConfig.adminUsers, queryParams: params);
    return ApiResponse.fromJson(res.data, null);
  }

  Future<ApiResponse> changeUserRole(int userId, int role) async {
    final res = await _client.put(ApiConfig.adminUserRole(userId), data: {'roleId': role});
    return ApiResponse.fromJson(res.data, null);
  }

  Future<ApiResponse> changeUserStatus(int userId, bool isActive) async {
    final res = await _client.put(ApiConfig.adminUserStatus(userId), data: {'isActive': isActive});
    return ApiResponse.fromJson(res.data, null);
  }

  // ==================== Orders ====================
  Future<ApiResponse> getOrders({int page = 1, int pageSize = 20, String? status, String? search}) async {
    final params = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
      if (status != null) 'status': status,
      if (search != null && search.isNotEmpty) 'search': search,
    };
    final res = await _client.get(ApiConfig.adminOrders, queryParams: params);
    return ApiResponse.fromJson(res.data, null);
  }

  Future<ApiResponse> getOrderDetail(int orderId) async {
    final res = await _client.get(ApiConfig.adminOrderDetail(orderId));
    return ApiResponse.fromJson(res.data, null);
  }

  Future<ApiResponse> confirmOrder(int orderId) async {
    final res = await _client.put(ApiConfig.adminConfirmOrder(orderId));
    return ApiResponse.fromJson(res.data, null);
  }

  Future<ApiResponse> assignShipper(int orderId, int shipperId) async {
    final res = await _client.put(ApiConfig.adminAssignShipper(orderId), data: {'shipperId': shipperId});
    return ApiResponse.fromJson(res.data, null);
  }

  Future<ApiResponse> cancelOrder(int orderId, String reason) async {
    final res = await _client.put(ApiConfig.adminCancelOrder(orderId), data: {'reason': reason});
    return ApiResponse.fromJson(res.data, null);
  }

  // ==================== Products ====================
  Future<ApiResponse> getProducts({int page = 1, int pageSize = 20, String? search, int? categoryId, bool? isActive}) async {
    final params = <String, dynamic>{
      'page': page, 'pageSize': pageSize,
      if (search != null && search.isNotEmpty) 'search': search,
      if (categoryId != null) 'categoryId': categoryId,
      if (isActive != null) 'isActive': isActive,
    };
    final res = await _client.get(ApiConfig.adminProducts, queryParams: params);
    return ApiResponse.fromJson(res.data, null);
  }

  Future<ApiResponse> getProductDetail(int productId) async {
    final res = await _client.get(ApiConfig.adminProductDetail(productId));
    return ApiResponse.fromJson(res.data, null);
  }

  Future<ApiResponse> createProduct(Map<String, dynamic> data) async {
    final res = await _client.post(ApiConfig.adminProducts, data: data);
    return ApiResponse.fromJson(res.data, null);
  }

  Future<ApiResponse> updateProduct(int productId, Map<String, dynamic> data) async {
    final res = await _client.put(ApiConfig.adminProductDetail(productId), data: data);
    return ApiResponse.fromJson(res.data, null);
  }

  Future<ApiResponse> deleteProduct(int productId) async {
    final res = await _client.delete(ApiConfig.adminProductDetail(productId));
    return ApiResponse.fromJson(res.data, null);
  }

  // Upload ảnh lên Cloudinary, trả về URL string
  Future<ApiResponse<String>> uploadProductImage(File imageFile) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(imageFile.path, filename: imageFile.path.split('/').last),
    });
    final res = await _client.uploadFile(ApiConfig.adminProductUploadImage, formData);
    return ApiResponse.fromJson(res.data, (d) => d as String);
  }

  // Thêm URL ảnh vào sản phẩm
  Future<ApiResponse> addProductImage(int productId, String imageUrl, {bool isPrimary = false}) async {
    final res = await _client.post(ApiConfig.adminProductImages(productId), data: {
      'imageUrl': imageUrl,
      'isPrimary': isPrimary,
    });
    return ApiResponse.fromJson(res.data, null);
  }

  // Xóa ảnh sản phẩm
  Future<ApiResponse> deleteProductImage(int imageId) async {
    final res = await _client.delete(ApiConfig.adminImage(imageId));
    return ApiResponse.fromJson(res.data, null);
  }

  // ==================== Vouchers ====================
  Future<ApiResponse> getVouchers({int page = 1, int pageSize = 20, bool? isActive}) async {
    final params = <String, dynamic>{'page': page, 'pageSize': pageSize, if (isActive != null) 'isActive': isActive};
    final res = await _client.get(ApiConfig.adminVouchers, queryParams: params);
    return ApiResponse.fromJson(res.data, null);
  }

  Future<ApiResponse> createVoucher(Map<String, dynamic> data) async {
    final res = await _client.post(ApiConfig.adminVouchers, data: data);
    return ApiResponse.fromJson(res.data, null);
  }

  Future<ApiResponse> deleteVoucher(int voucherId) async {
    final res = await _client.delete(ApiConfig.adminVoucherById(voucherId));
    return ApiResponse.fromJson(res.data, null);
  }

  // ==================== Refunds ====================
  Future<ApiResponse> getRefunds({int page = 1, int pageSize = 20, String? status}) async {
    final params = <String, dynamic>{'page': page, 'pageSize': pageSize, if (status != null) 'status': status};
    final res = await _client.get(ApiConfig.adminRefunds, queryParams: params);
    return ApiResponse.fromJson(res.data, null);
  }

  Future<ApiResponse> approveRefund(int refundId, {String? note}) async {
    final res = await _client.put(ApiConfig.adminApproveRefund(refundId), data: {'adminNote': note ?? ''});
    return ApiResponse.fromJson(res.data, null);
  }

  Future<ApiResponse> rejectRefund(int refundId, {String? note}) async {
    final res = await _client.put(ApiConfig.adminRejectRefund(refundId), data: {'adminNote': note ?? ''});
    return ApiResponse.fromJson(res.data, null);
  }

  // ==================== Dashboard ====================
  Future<ApiResponse> getDashboard() async {
    final res = await _client.get('/admin/dashboard');
    return ApiResponse.fromJson(res.data, null);
  }

  // ==================== Broadcast ====================
  Future<ApiResponse> broadcastNotification(String title, String message) async {
    final res = await _client.post(ApiConfig.adminBroadcast, data: {'title': title, 'message': message});
    return ApiResponse.fromJson(res.data, null);
  }
}
