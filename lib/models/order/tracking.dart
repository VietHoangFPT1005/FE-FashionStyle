class TrackingResponse {
  final int orderId;
  final String orderCode;
  final String status;
  final TrackingShipperInfo shipper;
  final TrackingCurrentLocation? currentLocation;
  final TrackingDestination destination;
  final TrackingTimeline timeline;

  TrackingResponse({
    required this.orderId,
    required this.orderCode,
    required this.status,
    required this.shipper,
    this.currentLocation,
    required this.destination,
    required this.timeline,
  });

  factory TrackingResponse.fromJson(Map<String, dynamic> json) {
    return TrackingResponse(
      orderId: json['orderId'] ?? 0,
      orderCode: json['orderCode'] ?? '',
      status: json['status'] ?? '',
      shipper: TrackingShipperInfo.fromJson(json['shipper'] ?? {}),
      currentLocation: json['currentLocation'] != null
          ? TrackingCurrentLocation.fromJson(json['currentLocation'])
          : null,
      destination: TrackingDestination.fromJson(json['destination'] ?? {}),
      timeline: TrackingTimeline.fromJson(json['timeline'] ?? {}),
    );
  }
}

class TrackingShipperInfo {
  final int shipperId;
  final String? fullName;
  final String? phone;

  TrackingShipperInfo({required this.shipperId, this.fullName, this.phone});

  factory TrackingShipperInfo.fromJson(Map<String, dynamic> json) {
    return TrackingShipperInfo(
      shipperId: json['shipperId'] ?? 0,
      fullName: json['fullName'],
      phone: json['phone'],
    );
  }
}

class TrackingCurrentLocation {
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? speed;
  final double? heading;
  final DateTime? updatedAt;

  TrackingCurrentLocation({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.speed,
    this.heading,
    this.updatedAt,
  });

  factory TrackingCurrentLocation.fromJson(Map<String, dynamic> json) {
    return TrackingCurrentLocation(
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      accuracy: (json['accuracy'] as num?)?.toDouble(),
      speed: (json['speed'] as num?)?.toDouble(),
      heading: (json['heading'] as num?)?.toDouble(),
      updatedAt:
          json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null,
    );
  }
}

class TrackingDestination {
  final double? latitude;
  final double? longitude;
  final String address;

  TrackingDestination({this.latitude, this.longitude, required this.address});

  factory TrackingDestination.fromJson(Map<String, dynamic> json) {
    return TrackingDestination(
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      address: json['address'] ?? '',
    );
  }
}

class TrackingTimeline {
  final DateTime? shippedAt;
  final int? estimatedMinutes;

  TrackingTimeline({this.shippedAt, this.estimatedMinutes});

  factory TrackingTimeline.fromJson(Map<String, dynamic> json) {
    return TrackingTimeline(
      shippedAt:
          json['shippedAt'] != null ? DateTime.tryParse(json['shippedAt']) : null,
      estimatedMinutes: json['estimatedMinutes'],
    );
  }
}
