class Address {
  final int addressId;
  final String receiverName;
  final String phone;
  final String addressLine;
  final String? ward;
  final String district;
  final String city;
  final double? latitude;
  final double? longitude;
  final bool isDefault;
  final DateTime? createdAt;

  Address({
    required this.addressId,
    required this.receiverName,
    required this.phone,
    required this.addressLine,
    this.ward,
    required this.district,
    required this.city,
    this.latitude,
    this.longitude,
    this.isDefault = false,
    this.createdAt,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      addressId: json['addressId'] ?? json['id'] ?? 0,
      receiverName: json['receiverName'] ?? '',
      phone: json['phone'] ?? '',
      addressLine: json['addressLine'] ?? '',
      ward: json['ward'],
      district: json['district'] ?? '',
      city: json['city'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      isDefault: json['isDefault'] ?? false,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
    );
  }

  String get fullAddress {
    final parts = [addressLine, ward, district, city]
        .where((p) => p != null && p.isNotEmpty)
        .toList();
    return parts.join(', ');
  }
}

class CreateAddressRequest {
  final String receiverName;
  final String phone;
  final String addressLine;
  final String? ward;
  final String district;
  final String city;
  final double? latitude;
  final double? longitude;
  final bool isDefault;

  CreateAddressRequest({
    required this.receiverName,
    required this.phone,
    required this.addressLine,
    this.ward,
    required this.district,
    required this.city,
    this.latitude,
    this.longitude,
    this.isDefault = false,
  });

  Map<String, dynamic> toJson() => {
        'receiverName': receiverName,
        'phone': phone,
        'addressLine': addressLine,
        if (ward != null) 'ward': ward,
        'district': district,
        'city': city,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        'isDefault': isDefault,
      };
}
