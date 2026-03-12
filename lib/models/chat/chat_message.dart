class ChatSession {
  final String sessionId;
  final String? title;
  final int messageCount;
  final DateTime? createdAt;
  final DateTime? lastMessageAt;

  ChatSession({
    required this.sessionId,
    this.title,
    this.messageCount = 0,
    this.createdAt,
    this.lastMessageAt,
  });

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      sessionId: json['sessionId'] ?? '',
      // BE trả về lastMessage (preview text), dùng làm title
      title: json['lastMessage'] ?? json['title'],
      messageCount: json['messageCount'] ?? 0,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      // BE trả về updatedAt
      lastMessageAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : (json['lastMessageAt'] != null ? DateTime.tryParse(json['lastMessageAt']) : null),
    );
  }
}

class ChatMessage {
  final String role; // user, assistant
  final String content;
  final DateTime? timestamp;
  final List<ChatSuggestedProduct>? suggestedProducts;

  ChatMessage({
    required this.role,
    required this.content,
    this.timestamp,
    this.suggestedProducts,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    List<ChatSuggestedProduct>? products;
    if (json['suggestedProducts'] != null) {
      products = (json['suggestedProducts'] as List)
          .map((e) => ChatSuggestedProduct.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return ChatMessage(
      role: json['role'] ?? '',
      content: json['content'] ?? '',
      // BE có thể trả về createdAt hoặc timestamp
      timestamp: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : (json['timestamp'] != null ? DateTime.tryParse(json['timestamp']) : null),
      suggestedProducts: products,
    );
  }

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';
}

class ChatSuggestedProduct {
  final int productId;
  final String name;
  final double price;
  final double? salePrice;
  final String? recommendedSize;
  final String? primaryImage;

  ChatSuggestedProduct({
    required this.productId,
    required this.name,
    required this.price,
    this.salePrice,
    this.recommendedSize,
    this.primaryImage,
  });

  factory ChatSuggestedProduct.fromJson(Map<String, dynamic> json) {
    return ChatSuggestedProduct(
      productId: json['productId'] ?? 0,
      name: json['name'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      salePrice: (json['salePrice'] as num?)?.toDouble(),
      recommendedSize: json['recommendedSize'],
      primaryImage: json['primaryImage'],
    );
  }
}

class SendMessageRequest {
  final String message;
  final String? sessionId;

  SendMessageRequest({required this.message, this.sessionId});

  Map<String, dynamic> toJson() => {
        'message': message,
        if (sessionId != null) 'sessionId': sessionId,
      };
}
