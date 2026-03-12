class WishlistItem {
  final int wishlistId;
  final int productId;
  final String productName;
  final String? thumbnailUrl;
  final double price;
  final double? salePrice;
  final double? averageRating;
  final DateTime? createdAt;

  WishlistItem({
    required this.wishlistId,
    required this.productId,
    required this.productName,
    this.thumbnailUrl,
    required this.price,
    this.salePrice,
    this.averageRating,
    this.createdAt,
  });

  factory WishlistItem.fromJson(Map<String, dynamic> json) {
    // Backend returns: name, primaryImage, addedAt (no wishlistId)
    return WishlistItem(
      wishlistId: json['wishlistId'] ?? json['productId'] ?? 0,
      productId: json['productId'] ?? 0,
      productName: json['name'] as String? ?? json['productName'] ?? '',
      thumbnailUrl: json['primaryImage'] as String? ?? json['thumbnailUrl'],
      price: (json['price'] as num?)?.toDouble() ?? 0,
      salePrice: (json['salePrice'] as num?)?.toDouble(),
      averageRating: (json['averageRating'] as num?)?.toDouble(),
      createdAt: (json['addedAt'] ?? json['createdAt']) != null
          ? DateTime.tryParse(json['addedAt'] ?? json['createdAt'])
          : null,
    );
  }
}
