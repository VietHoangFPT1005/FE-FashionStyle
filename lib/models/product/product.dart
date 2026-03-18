class Product {
  final int productId;
  final String name;
  final String slug;
  final String? description;
  final double price;
  final double? salePrice;
  final String? thumbnailUrl;
  final String? categoryName;
  final int? categoryId;
  final double? averageRating;
  final int? totalReviews;
  final bool isActive;
  final bool isFeatured;
  final List<String>? tags;
  final DateTime? createdAt;

  Product({
    required this.productId,
    required this.name,
    required this.slug,
    this.description,
    required this.price,
    this.salePrice,
    this.thumbnailUrl,
    this.categoryName,
    this.categoryId,
    this.averageRating,
    this.totalReviews,
    this.isActive = true,
    this.isFeatured = false,
    this.tags,
    this.createdAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      productId: json['productId'] ?? json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'],
      price: (json['price'] as num?)?.toDouble() ?? 0,
      salePrice: (json['salePrice'] as num?)?.toDouble(),
      thumbnailUrl: json['primaryImage'] ?? json['thumbnailUrl'],
      categoryName: json['categoryName'],
      categoryId: json['categoryId'],
      averageRating: (json['averageRating'] as num?)?.toDouble(),
      totalReviews: json['totalReviews'],
      isActive: json['isActive'] ?? true,
      isFeatured: json['isFeatured'] ?? false,
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
    );
  }

  double get effectivePrice => salePrice ?? price;
  bool get isOnSale => salePrice != null && salePrice! < price;
  int get discountPercent =>
      isOnSale ? ((1 - salePrice! / price) * 100).round() : 0;
}
