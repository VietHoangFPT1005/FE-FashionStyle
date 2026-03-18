class Cart {
  final List<CartItem> items;
  final double totalAmount;
  final int totalItems;

  Cart({this.items = const [], this.totalAmount = 0, this.totalItems = 0});

  factory Cart.fromJson(Map<String, dynamic> json) {
    final itemList = (json['items'] as List? ?? [])
        .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
        .toList();
    // Backend returns totals under summary object
    // Dùng subtotal (chưa cộng phí ship) để checkout tự cộng riêng
    final summary = json['summary'] as Map<String, dynamic>? ?? {};
    final serverSubtotal = (summary['subtotal'] as num?)?.toDouble() ?? 0;
    final calculatedTotal = itemList.fold(0.0, (s, i) => s + i.subtotal);
    return Cart(
      items: itemList,
      totalAmount: serverSubtotal > 0 ? serverSubtotal : calculatedTotal,
      totalItems: (summary['totalItems'] as num?)?.toInt() ?? itemList.length,
    );
  }
}

class CartItem {
  final int cartItemId;
  final int productId;
  final int? variantId;
  final String productName;
  final String? thumbnailUrl;
  final String? color;
  final String? size;
  final double unitPrice;
  final int quantity;
  final double subtotal;

  CartItem({
    required this.cartItemId,
    required this.productId,
    this.variantId,
    required this.productName,
    this.thumbnailUrl,
    this.color,
    this.size,
    required this.unitPrice,
    required this.quantity,
    required this.subtotal,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    // Backend returns nested: variant.{variantId,size,color}, product.{productId,name,primaryImage}
    final variant = json['variant'] as Map<String, dynamic>? ?? {};
    final product = json['product'] as Map<String, dynamic>? ?? {};
    return CartItem(
      cartItemId: json['cartItemId'] ?? json['id'] ?? 0,
      productId: (product['productId'] as num?)?.toInt() ?? json['productId'] ?? 0,
      variantId: (variant['variantId'] as num?)?.toInt(),
      productName: product['name'] as String? ?? json['productName'] ?? '',
      thumbnailUrl: product['primaryImage'] as String? ?? json['thumbnailUrl'],
      color: variant['color'] as String? ?? json['color'],
      size: variant['size'] as String? ?? json['size'],
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
      quantity: json['quantity'] ?? 1,
      subtotal: (json['itemTotal'] ?? json['subtotal'] as num?)?.toDouble() ?? 0,
    );
  }
}

class AddToCartRequest {
  final int productVariantId;
  final int quantity;

  AddToCartRequest({required this.productVariantId, this.quantity = 1});

  Map<String, dynamic> toJson() => {
        'productVariantId': productVariantId,
        'quantity': quantity,
      };
}

class UpdateCartRequest {
  final int quantity;
  UpdateCartRequest({required this.quantity});
  Map<String, dynamic> toJson() => {'quantity': quantity};
}
