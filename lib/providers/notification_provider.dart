import 'package:flutter/foundation.dart';
import '../models/notification/notification.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _notifService;

  List<AppNotification> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;

  NotificationProvider(this._notifService);

  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;

  Future<void> loadNotifications() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _notifService.getNotifications();
      if (response.success && response.data != null) {
        _notifications = response.data!;
        // Tính unread count từ dữ liệu đã load (không cần gọi API riêng)
        _unreadCount = _notifications.where((n) => !n.isRead).length;
      }
    } catch (_) {}
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadUnreadCount() async {
    try {
      final response = await _notifService.getUnreadCount();
      if (response.success && response.data != null) {
        _unreadCount = response.data!;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> markAsRead(int id) async {
    try {
      await _notifService.markAsRead(id);
      final index = _notifications.indexWhere((n) => n.notificationId == id);
      if (index != -1) {
        _unreadCount = (_unreadCount - 1).clamp(0, _unreadCount);
        await loadNotifications();
      }
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    try {
      await _notifService.markAllAsRead();
      _unreadCount = 0;
      await loadNotifications();
    } catch (_) {}
  }
}
