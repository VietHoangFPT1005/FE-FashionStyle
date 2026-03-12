class Category {
  final int categoryId;
  final String name;
  final String? slug;
  final String? description;
  final String? imageUrl;
  final int? parentId;
  final String? parentName;
  final int productCount;
  final bool isActive;

  Category({
    required this.categoryId,
    required this.name,
    this.slug,
    this.description,
    this.imageUrl,
    this.parentId,
    this.parentName,
    this.productCount = 0,
    this.isActive = true,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      categoryId: json['categoryId'] ?? json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'],
      description: json['description'],
      imageUrl: json['imageUrl'],
      parentId: json['parentId'],
      parentName: json['parentName'],
      productCount: json['productCount'] ?? 0,
      isActive: json['isActive'] ?? true,
    );
  }
}
