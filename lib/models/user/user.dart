class UserProfile {
  final int userId;
  final String fullName;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final int role;
  final String? gender;
  final DateTime? dateOfBirth;
  final String? status;
  final DateTime? createdAt;

  UserProfile({
    required this.userId,
    required this.fullName,
    required this.email,
    this.phone,
    this.avatarUrl,
    required this.role,
    this.gender,
    this.dateOfBirth,
    this.status,
    this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['userId'] ?? json['id'] ?? 0,
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      avatarUrl: json['avatarUrl'],
      role: json['role'] ?? 3,
      gender: json['gender'],
      dateOfBirth:
          json['dateOfBirth'] != null ? DateTime.tryParse(json['dateOfBirth']) : null,
      status: json['status'],
      createdAt:
          json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
    );
  }

  String get roleName {
    switch (role) {
      case 1:
        return 'Admin';
      case 2:
        return 'Staff';
      case 3:
        return 'Customer';
      case 4:
        return 'Shipper';
      default:
        return 'Unknown';
    }
  }
}

class UpdateProfileRequest {
  final String? fullName;
  final String? phone;
  final String? gender;
  final String? dateOfBirth;

  UpdateProfileRequest({this.fullName, this.phone, this.gender, this.dateOfBirth});

  Map<String, dynamic> toJson() => {
        if (fullName != null) 'fullName': fullName,
        if (phone != null) 'phone': phone,
        if (gender != null) 'gender': gender,
        if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
      };
}

class BodyProfile {
  final double? height;
  final double? weight;
  final double? chest;
  final double? waist;
  final double? hips;
  final String? bodyShape;

  BodyProfile({
    this.height,
    this.weight,
    this.chest,
    this.waist,
    this.hips,
    this.bodyShape,
  });

  factory BodyProfile.fromJson(Map<String, dynamic> json) {
    return BodyProfile(
      height: (json['height'] as num?)?.toDouble(),
      weight: (json['weight'] as num?)?.toDouble(),
      chest: (json['bust'] as num?)?.toDouble(),
      waist: (json['waist'] as num?)?.toDouble(),
      hips: (json['hips'] as num?)?.toDouble(),
      bodyShape: json['bodyShape'],
    );
  }

  Map<String, dynamic> toJson() => {
        if (height != null) 'height': height,
        if (weight != null) 'weight': weight,
        if (chest != null) 'bust': chest,
        if (waist != null) 'waist': waist,
        if (hips != null) 'hips': hips,
        if (bodyShape != null) 'bodyShape': bodyShape,
      };
}
