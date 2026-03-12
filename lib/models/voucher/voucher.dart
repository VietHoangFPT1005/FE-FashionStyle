class Voucher {
  final int voucherId;
  final String code;
  final String? description;
  final String discountType; // PERCENTAGE, FIXED
  final double discountValue;
  final double? minimumOrderAmount;
  final double? maximumDiscount;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? usageLimit;
  final int? usedCount;
  final bool isActive;

  Voucher({
    required this.voucherId,
    required this.code,
    this.description,
    required this.discountType,
    required this.discountValue,
    this.minimumOrderAmount,
    this.maximumDiscount,
    this.startDate,
    this.endDate,
    this.usageLimit,
    this.usedCount,
    this.isActive = true,
  });

  factory Voucher.fromJson(Map<String, dynamic> json) {
    return Voucher(
      voucherId: json['voucherId'] ?? json['id'] ?? 0,
      code: json['code'] ?? '',
      description: json['description'],
      discountType: json['discountType'] ?? 'PERCENTAGE',
      discountValue: (json['discountValue'] as num?)?.toDouble() ?? 0,
      // BE trả về minOrderAmount (camelCase của MinOrderAmount)
      minimumOrderAmount: (json['minOrderAmount'] as num?)?.toDouble()
          ?? (json['minimumOrderAmount'] as num?)?.toDouble(),
      // BE trả về maxDiscountAmount (camelCase của MaxDiscountAmount)
      maximumDiscount: (json['maxDiscountAmount'] as num?)?.toDouble()
          ?? (json['maximumDiscount'] as num?)?.toDouble(),
      startDate: json['startDate'] != null ? DateTime.tryParse(json['startDate']) : null,
      endDate: json['endDate'] != null ? DateTime.tryParse(json['endDate']) : null,
      usageLimit: json['usageLimit'],
      usedCount: json['usedCount'],
      isActive: json['isActive'] ?? true,
    );
  }

  bool get isPercentage => discountType == 'PERCENTAGE';
  String get displayDiscount =>
      isPercentage ? '${discountValue.toInt()}%' : '${discountValue.toInt()}d';

  bool get isValid {
    final now = DateTime.now();
    if (startDate != null && now.isBefore(startDate!)) return false;
    if (endDate != null && now.isAfter(endDate!)) return false;
    if (usageLimit != null && usedCount != null && usedCount! >= usageLimit!) return false;
    return isActive;
  }
}

class ValidateVoucherRequest {
  final String code;
  final double orderTotal;

  ValidateVoucherRequest({required this.code, required this.orderTotal});

  Map<String, dynamic> toJson() => {'voucherCode': code, 'orderTotal': orderTotal};
}
