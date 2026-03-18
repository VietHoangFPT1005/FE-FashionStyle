import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../utils/helpers.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _plugin.initialize(settings);

    // Request Android 13+ notification permission
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> showPaymentSuccessNotification({
    required int orderId,
    required double amount,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'payment_channel',
      'Thanh toán',
      channelDescription: 'Thông báo thanh toán đơn hàng',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    await _plugin.show(
      orderId,
      '🎉 Thanh toán thành công!',
      'Đơn hàng #$orderId - ${Helpers.formatCurrency(amount)} đã được xác nhận.',
      details,
    );
  }

  static Future<void> showOrderNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'order_channel',
      'Đơn hàng',
      channelDescription: 'Thông báo cập nhật đơn hàng',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    await _plugin.show(id, title, body, details);
  }
}
