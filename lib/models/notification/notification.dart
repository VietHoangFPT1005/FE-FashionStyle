class AppNotification {
  final int notificationId;
  final String title;
  final String message;
  final String? type;
  final int? referenceId;
  final bool isRead;
  final DateTime? createdAt;

  AppNotification({
    required this.notificationId,
    required this.title,
    required this.message,
    this.type,
    this.referenceId,
    this.isRead = false,
    this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      notificationId: json['notificationId'] ?? json['id'] ?? 0,
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'],
      referenceId: json['referenceId'],
      isRead: json['isRead'] ?? false,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
    );
  }
}
