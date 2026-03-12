class Refund {
  final int refundId;
  final int orderId;
  final String? orderCode;
  final String? customerName;
  final String reason;
  final String? adminNote;
  final String status; // PENDING, APPROVED, REJECTED
  final double? orderTotal;
  final DateTime? createdAt;
  final DateTime? processedAt;
  final String? processedByName;

  Refund({
    required this.refundId,
    required this.orderId,
    this.orderCode,
    this.customerName,
    required this.reason,
    this.adminNote,
    required this.status,
    this.orderTotal,
    this.createdAt,
    this.processedAt,
    this.processedByName,
  });

  factory Refund.fromJson(Map<String, dynamic> json) {
    return Refund(
      refundId: json['refundId'] ?? json['id'] ?? 0,
      orderId: json['orderId'] ?? 0,
      orderCode: json['orderCode'],
      customerName: json['customerName'],
      reason: json['reason'] ?? '',
      adminNote: json['adminNote'],
      status: json['status'] ?? 'PENDING',
      orderTotal: (json['orderTotal'] as num?)?.toDouble(),
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      processedAt:
          json['processedAt'] != null ? DateTime.tryParse(json['processedAt']) : null,
      processedByName: json['processedByName'],
    );
  }

  bool get isPending => status == 'PENDING';
  bool get isApproved => status == 'APPROVED';
  bool get isRejected => status == 'REJECTED';
}

class CreateRefundRequest {
  final String reason;
  CreateRefundRequest({required this.reason});
  Map<String, dynamic> toJson() => {'reason': reason};
}
