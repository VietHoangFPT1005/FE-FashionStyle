// ================================================================
// [CHAT SUPPORT - MỚI THÊM]
// Model cho tin nhắn chat hỗ trợ Customer <-> Staff/Admin
// Khác với ChatMessage (AI chat)
// ================================================================

/// [CHAT SUPPORT - MỚI THÊM]
/// Một tin nhắn trong hội thoại hỗ trợ
class SupportMessage {
  final int id;
  final int customerId;
  final int senderId;
  final String senderName;
  final String? senderAvatar;
  final int senderRole;   // 1=Admin, 2=Staff, 3=Customer
  final String message;
  final bool isRead;
  final DateTime createdAt;

  SupportMessage({
    required this.id,
    required this.customerId,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.senderRole,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory SupportMessage.fromJson(Map<String, dynamic> json) {
    return SupportMessage(
      id:           json['id'] ?? 0,
      customerId:   json['customerId'] ?? 0,
      senderId:     json['senderId'] ?? 0,
      senderName:   json['senderName'] ?? 'Người dùng',
      senderAvatar: json['senderAvatar'],
      senderRole:   json['senderRole'] ?? 3,
      message:      json['message'] ?? '',
      isRead:       json['isRead'] ?? false,
      createdAt:    json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  // Customer gửi tin = senderRole 3
  bool get isFromCustomer => senderRole == 3;

  // Staff hoặc Admin gửi
  bool get isFromStaff => senderRole == 1 || senderRole == 2;

  // Tin nhắn hình ảnh — prefix [IMAGE]
  bool get isImageMessage => message.startsWith('[IMAGE]');

  // URL ảnh (bỏ prefix [IMAGE])
  String? get imageUrl => isImageMessage ? message.substring(7) : null;
}

/// [CHAT SUPPORT - MỚI THÊM]
/// Một cuộc hội thoại trong danh sách của Staff/Admin
class SupportConversation {
  final int customerId;
  final String customerName;
  final String? customerAvatar;
  final String lastMessage;
  final DateTime lastMessageAt;
  final int unreadCount;

  SupportConversation({
    required this.customerId,
    required this.customerName,
    this.customerAvatar,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unreadCount,
  });

  factory SupportConversation.fromJson(Map<String, dynamic> json) {
    return SupportConversation(
      customerId:     json['customerId'] ?? 0,
      customerName:   json['customerName'] ?? 'Khách hàng',
      customerAvatar: json['customerAvatar'],
      lastMessage:    json['lastMessage'] ?? '',
      lastMessageAt:  json['lastMessageAt'] != null
          ? DateTime.tryParse(json['lastMessageAt']) ?? DateTime.now()
          : DateTime.now(),
      unreadCount:    json['unreadCount'] ?? 0,
    );
  }
}
