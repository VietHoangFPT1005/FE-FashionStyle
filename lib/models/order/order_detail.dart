class OrderDetail {
  final int orderId;
  final String orderCode;
  final String status;
  final double subtotal;
  final double shippingFee;
  final double discount;
  final double total;
  final String paymentMethod;
  final String? paymentStatus;
  final String? note;
  final OrderShippingInfo shippingInfo;
  final List<OrderItem> items;
  final OrderTimeline timeline;
  final String? voucherCode;

  OrderDetail({
    required this.orderId,
    required this.orderCode,
    required this.status,
    required this.subtotal,
    this.shippingFee = 0,
    this.discount = 0,
    required this.total,
    required this.paymentMethod,
    this.paymentStatus,
    this.note,
    required this.shippingInfo,
    this.items = const [],
    required this.timeline,
    this.voucherCode,
  });

  factory OrderDetail.fromJson(Map<String, dynamic> json) {
    return OrderDetail(
      orderId: json['orderId'] ?? json['id'] ?? 0,
      orderCode: json['orderCode'] ?? '',
      status: json['status'] ?? '',
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      shippingFee: (json['shippingFee'] as num?)?.toDouble() ?? 0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num?)?.toDouble() ?? 0,
      paymentMethod: json['paymentMethod'] ?? '',
      paymentStatus: json['paymentStatus'],
      note: json['note'],
      shippingInfo: OrderShippingInfo.fromJson(json['shippingInfo'] ?? {}),
      items: (json['items'] as List? ?? [])
          .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      timeline: OrderTimeline.fromJson(json['timeline'] ?? {}),
      voucherCode: json['voucherCode'],
    );
  }
}

class OrderShippingInfo {
  final String name;
  final String phone;
  final String address;
  final double? latitude;
  final double? longitude;

  OrderShippingInfo({
    required this.name,
    required this.phone,
    required this.address,
    this.latitude,
    this.longitude,
  });

  factory OrderShippingInfo.fromJson(Map<String, dynamic> json) {
    return OrderShippingInfo(
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }
}

class OrderItem {
  final int orderItemId;
  final int productId;
  final String productName;
  final String? thumbnailUrl;
  final String? color;
  final String? size;
  final double unitPrice;
  final int quantity;
  final double subtotal;

  OrderItem({
    required this.orderItemId,
    required this.productId,
    required this.productName,
    this.thumbnailUrl,
    this.color,
    this.size,
    required this.unitPrice,
    required this.quantity,
    required this.subtotal,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      orderItemId: json['orderItemId'] ?? json['id'] ?? 0,
      productId: json['productId'] ?? 0,
      productName: json['productName'] ?? '',
      thumbnailUrl: json['thumbnailUrl'],
      color: json['color'],
      size: json['size'],
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
      quantity: json['quantity'] ?? 1,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
    );
  }
}

class OrderTimeline {
  final DateTime? createdAt;
  final DateTime? confirmedAt;
  final DateTime? shippedAt;
  final DateTime? deliveredAt;
  final DateTime? cancelledAt;

  OrderTimeline({
    this.createdAt,
    this.confirmedAt,
    this.shippedAt,
    this.deliveredAt,
    this.cancelledAt,
  });

  factory OrderTimeline.fromJson(Map<String, dynamic> json) {
    return OrderTimeline(
      createdAt: _parse(json['createdAt']),
      confirmedAt: _parse(json['confirmedAt']),
      shippedAt: _parse(json['shippedAt']),
      deliveredAt: _parse(json['deliveredAt']),
      cancelledAt: _parse(json['cancelledAt']),
    );
  }

  static DateTime? _parse(dynamic v) => v != null ? DateTime.tryParse(v) : null;
}

class CreateOrderRequest {
  final int addressId;
  final String paymentMethod;
  final String? voucherCode;
  final String? note;

  CreateOrderRequest({
    required this.addressId,
    required this.paymentMethod,
    this.voucherCode,
    this.note,
  });

  Map<String, dynamic> toJson() => {
        'addressId': addressId,
        'paymentMethod': paymentMethod,
        if (voucherCode != null) 'voucherCode': voucherCode,
        if (note != null) 'note': note,
      };
}

/// Response returned by POST /Order/checkout
class CreateOrderResponse {
  final int orderId;
  final String orderCode;
  final String status;
  final double subtotal;
  final double shippingFee;
  final double discount;
  final double total;
  final String paymentMethod;
  final String? paymentUrl; // only set for SEPAY; not used directly by Flutter

  CreateOrderResponse({
    required this.orderId,
    required this.orderCode,
    required this.status,
    required this.subtotal,
    this.shippingFee = 0,
    this.discount = 0,
    required this.total,
    required this.paymentMethod,
    this.paymentUrl,
  });

  factory CreateOrderResponse.fromJson(Map<String, dynamic> json) {
    return CreateOrderResponse(
      orderId: json['orderId'] ?? json['id'] ?? 0,
      orderCode: json['orderCode'] ?? '',
      status: json['status'] ?? '',
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      shippingFee: (json['shippingFee'] as num?)?.toDouble() ?? 0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num?)?.toDouble() ?? 0,
      paymentMethod: json['paymentMethod'] ?? '',
      paymentUrl: json['paymentUrl'],
    );
  }
}
