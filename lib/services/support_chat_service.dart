// ================================================================
// [CHAT SUPPORT - MỚI THÊM]
// Service kết nối SignalR và gọi REST API cho chat hỗ trợ
// ================================================================

import 'package:dio/dio.dart';
import 'package:signalr_netcore/signalr_client.dart';
import '../config/api_config.dart';
import '../models/api_response.dart';
import '../models/chat/support_message.dart';
import 'api_client.dart';

/// [CHAT SUPPORT - MỚI THÊM]
/// Quản lý kết nối SignalR và REST API cho chat hỗ trợ
class SupportChatService {
  final ApiClient _client;
  HubConnection? _hubConnection;

  SupportChatService(this._client);

  // ── SignalR ────────────────────────────────────────────────────

  /// [CHAT SUPPORT - MỚI THÊM]
  /// Kết nối tới SignalR Hub với JWT token
  /// [onReceiveMessage]: callback khi nhận được tin nhắn mới
  Future<void> connect({
    required String accessToken,
    required void Function(SupportMessage msg) onReceiveMessage,
  }) async {
    // Truyền JWT qua query string (cách duy nhất với WebSocket)
    final hubUrl = '${ApiConfig.chatHubUrl}?access_token=$accessToken';

    _hubConnection = HubConnectionBuilder()
        .withUrl(hubUrl)
        .withAutomaticReconnect()
        .build();

    // Lắng nghe sự kiện "ReceiveMessage" từ server
    _hubConnection!.on('ReceiveMessage', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        final data = arguments[0] as Map<String, dynamic>;
        final msg = SupportMessage.fromJson(data);
        onReceiveMessage(msg);
      }
    });

    await _hubConnection!.start();
  }

  /// [CHAT SUPPORT - MỚI THÊM]
  /// Ngắt kết nối SignalR
  Future<void> disconnect() async {
    await _hubConnection?.stop();
    _hubConnection = null;
  }

  /// [CHAT SUPPORT - MỚI THÊM]
  /// Customer gửi tin nhắn đến Staff/Admin
  Future<void> sendMessageToSupport(String message) async {
    await _hubConnection?.invoke('SendMessageToSupport', args: [message]);
  }

  /// [CHAT SUPPORT - MỚI THÊM]
  /// Staff/Admin gửi tin nhắn đến customer cụ thể
  Future<void> sendMessageToCustomer(int customerId, String message) async {
    await _hubConnection?.invoke('SendMessageToCustomer', args: [customerId, message]);
  }

  bool get isConnected =>
      _hubConnection?.state == HubConnectionState.Connected;

  // ── REST API ──────────────────────────────────────────────────

  /// [CHAT SUPPORT - MỚI THÊM]
  /// Customer lấy lịch sử chat của mình
  Future<ApiResponse<List<SupportMessage>>> getMyHistory({int skip = 0, int take = 50}) async {
    final response = await _client.get(
      ApiConfig.supportChatHistory,
      queryParams: {'skip': skip, 'take': take},
    );
    return ApiResponse.fromJson(
      response.data,
      (d) => (d as List).map((e) => SupportMessage.fromJson(e)).toList(),
    );
  }

  /// [CHAT SUPPORT - MỚI THÊM]
  /// Staff/Admin lấy danh sách hội thoại với tất cả customers
  Future<ApiResponse<List<SupportConversation>>> getConversations() async {
    final response = await _client.get(ApiConfig.supportChatConversations);
    return ApiResponse.fromJson(
      response.data,
      (d) => (d as List).map((e) => SupportConversation.fromJson(e)).toList(),
    );
  }

  /// [CHAT SUPPORT - MỚI THÊM]
  /// Staff/Admin lấy lịch sử chat của customer cụ thể
  Future<ApiResponse<List<SupportMessage>>> getCustomerHistory(
      int customerId, {int skip = 0, int take = 50}) async {
    final response = await _client.get(
      ApiConfig.supportChatCustomerHistory(customerId),
      queryParams: {'skip': skip, 'take': take},
    );
    return ApiResponse.fromJson(
      response.data,
      (d) => (d as List).map((e) => SupportMessage.fromJson(e)).toList(),
    );
  }

  /// [CHAT SUPPORT - MỚI THÊM]
  /// Staff/Admin đánh dấu đã đọc tin của customer
  Future<void> markAsRead(int customerId) async {
    await _client.put(ApiConfig.supportChatMarkRead(customerId));
  }

  /// Upload ảnh chat lên Cloudinary qua BE, trả về URL hoặc null nếu lỗi
  Future<String?> uploadChatImage(String filePath) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });
      final response = await _client.uploadFile(
          ApiConfig.supportChatUploadImage, formData);
      final apiRes = ApiResponse<String>.fromJson(
        response.data,
        (d) => d as String,
      );
      return apiRes.success ? apiRes.data : null;
    } catch (_) {
      return null;
    }
  }
}
