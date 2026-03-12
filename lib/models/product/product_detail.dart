class ProductDetail {
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
  final List<ProductVariant> variants;
  final List<ProductImage> images;
  final SizeGuide? sizeGuide;
  final DateTime? createdAt;

  ProductDetail({
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
    this.variants = const [],
    this.images = const [],
    this.sizeGuide,
    this.createdAt,
  });

  factory ProductDetail.fromJson(Map<String, dynamic> json) {
    return ProductDetail(
      productId: json['productId'] ?? json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'],
      price: (json['price'] as num?)?.toDouble() ?? 0,
      salePrice: (json['salePrice'] as num?)?.toDouble(),
      thumbnailUrl: json['thumbnailUrl'],
      categoryName: json['categoryName'],
      categoryId: json['categoryId'],
      averageRating: (json['averageRating'] as num?)?.toDouble(),
      totalReviews: json['totalReviews'],
      isActive: json['isActive'] ?? true,
      isFeatured: json['isFeatured'] ?? false,
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      variants: (json['variants'] as List? ?? [])
          .map((e) => ProductVariant.fromJson(e))
          .toList(),
      images: (json['images'] as List? ?? [])
          .map((e) => ProductImage.fromJson(e))
          .toList(),
      sizeGuide:
          json['sizeGuide'] != null ? SizeGuide.fromJson(json['sizeGuide']) : null,
      createdAt:
          json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
    );
  }

  bool get isOnSale => salePrice != null && salePrice! < price;
  double get effectivePrice => salePrice ?? price;
}

class ProductVariant {
  final int variantId;
  final String? color;
  final String? size;
  final String? sku;
  final int stockQuantity;
  final double? priceAdjustment;

  ProductVariant({
    required this.variantId,
    this.color,
    this.size,
    this.sku,
    this.stockQuantity = 0,
    this.priceAdjustment,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      variantId: json['variantId'] ?? json['id'] ?? 0,
      color: json['color'],
      size: json['size'],
      sku: json['sku'],
      stockQuantity: json['stockQuantity'] ?? 0,
      priceAdjustment: (json['priceAdjustment'] as num?)?.toDouble(),
    );
  }

  bool get isInStock => stockQuantity > 0;
}

class ProductImage {
  final int imageId;
  final String imageUrl;
  final String? altText;
  final bool isPrimary;
  final int displayOrder;

  ProductImage({
    required this.imageId,
    required this.imageUrl,
    this.altText,
    this.isPrimary = false,
    this.displayOrder = 0,
  });

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      imageId: json['imageId'] ?? json['id'] ?? 0,
      imageUrl: json['imageUrl'] ?? '',
      altText: json['altText'],
      isPrimary: json['isPrimary'] ?? false,
      displayOrder: json['displayOrder'] ?? 0,
    );
  }
}

class SizeGuide {
  final int sizeGuideId;
  final String? sizeGuideUrl;
  final String? description;

  SizeGuide({required this.sizeGuideId, this.sizeGuideUrl, this.description});

  factory SizeGuide.fromJson(Map<String, dynamic> json) {
    return SizeGuide(
      sizeGuideId: json['sizeGuideId'] ?? json['id'] ?? 0,
      sizeGuideUrl: json['sizeGuideUrl'],
      description: json['description'],
    );
  }
}
