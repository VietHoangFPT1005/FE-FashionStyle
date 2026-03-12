class OrderSummary {
  final int orderId;
  final String orderCode;
  final String status;
  final double total;
  final String paymentMethod;
  final int totalItems;
  final String? thumbnailUrl;
  final DateTime? createdAt;

  OrderSummary({
    required this.orderId,
    required this.orderCode,
    required this.status,
    required this.total,
    required this.paymentMethod,
    this.totalItems = 0,
    this.thumbnailUrl,
    this.createdAt,
  });

  factory OrderSummary.fromJson(Map<String, dynamic> json) {
    return OrderSummary(
      orderId: json['orderId'] ?? json['id'] ?? 0,
      orderCode: json['orderCode'] ?? '',
      status: json['status'] ?? '',
      total: (json['total'] as num?)?.toDouble() ?? 0,
      paymentMethod: json['paymentMethod'] ?? '',
      totalItems: json['totalItems'] ?? 0,
      thumbnailUrl: json['firstItemImage'] ?? json['thumbnailUrl'],
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
    );
  }
}
