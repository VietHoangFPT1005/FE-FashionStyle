class Review {
  final int reviewId;
  final int productId;
  final int userId;
  final String? userName;
  final String? userAvatar;
  final int rating;
  final String? comment;
  final String? reviewImageUrl;
  final bool? showBodyInfo;
  final DateTime? createdAt;

  Review({
    required this.reviewId,
    required this.productId,
    required this.userId,
    this.userName,
    this.userAvatar,
    required this.rating,
    this.comment,
    this.reviewImageUrl,
    this.showBodyInfo,
    this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    // BE trả về user dưới dạng nested object { userId, fullName, avatarUrl }
    final user = json['user'] as Map<String, dynamic>?;
    return Review(
      reviewId:       json['reviewId'] ?? json['id'] ?? 0,
      productId:      json['productId'] ?? 0,
      userId:         user?['userId'] ?? json['userId'] ?? 0,
      userName:       user?['fullName'] ?? json['userName'],
      userAvatar:     user?['avatarUrl'] ?? json['userAvatar'],
      rating:         json['rating'] ?? 0,
      comment:        json['comment'],
      reviewImageUrl: json['reviewImageUrl'],
      showBodyInfo:   json['showBodyInfo'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) : null,
    );
  }
}

class CreateReviewRequest {
  final int rating;
  final String? comment;
  final String? reviewImageUrl;
  final double? heightCm;
  final double? weightKg;
  final String? sizeOrdered;
  final bool showBodyInfo;

  CreateReviewRequest({
    required this.rating,
    this.comment,
    this.reviewImageUrl,
    this.heightCm,
    this.weightKg,
    this.sizeOrdered,
    this.showBodyInfo = false,
  });

  Map<String, dynamic> toJson() => {
        'rating': rating,
        if (comment != null) 'comment': comment,
        if (reviewImageUrl != null) 'reviewImageUrl': reviewImageUrl,
        if (heightCm != null) 'heightCm': heightCm,
        if (weightKg != null) 'weightKg': weightKg,
        if (sizeOrdered != null) 'sizeOrdered': sizeOrdered,
        'showBodyInfo': showBodyInfo,
      };
}

class UpdateReviewRequest {
  final int? rating;
  final String? comment;
  final String? reviewImageUrl;
  final bool? showBodyInfo;

  UpdateReviewRequest({this.rating, this.comment, this.reviewImageUrl, this.showBodyInfo});

  Map<String, dynamic> toJson() => {
        if (rating != null) 'rating': rating,
        if (comment != null) 'comment': comment,
        if (reviewImageUrl != null) 'reviewImageUrl': reviewImageUrl,
        if (showBodyInfo != null) 'showBodyInfo': showBodyInfo,
      };
}
