import '../config/api_config.dart';
import '../models/api_response.dart';
import '../models/notification/notification.dart';
import 'api_client.dart';

class NotificationService {
  final ApiClient _client;
  NotificationService(this._client);

  Future<ApiResponse<List<AppNotification>>> getNotifications() async {
    final response = await _client.get(ApiConfig.notifications);
    return ApiResponse.fromJson(
      response.data,
      // BE trả về { items: [...], pagination: {...}, unreadCount: N }
      (d) => ((d['items'] as List?) ?? [])
          .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<ApiResponse> markAsRead(int notificationId) async {
    final response = await _client.put(ApiConfig.readNotification(notificationId));
    return ApiResponse.fromJson(response.data, null);
  }

  Future<ApiResponse> markAllAsRead() async {
    final response = await _client.put(ApiConfig.readAllNotifications);
    return ApiResponse.fromJson(response.data, null);
  }

  Future<ApiResponse<int>> getUnreadCount() async {
    final response = await _client.get(ApiConfig.unreadCount);
    return ApiResponse.fromJson(response.data, (d) => d['unreadCount'] as int);
  }

  Future<ApiResponse> deleteNotification(int notificationId) async {
    final response = await _client.delete(ApiConfig.deleteNotification(notificationId));
    return ApiResponse.fromJson(response.data, null);
  }
}
