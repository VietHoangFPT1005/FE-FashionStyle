import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_image.dart';
import '../../models/product/product.dart';
import '../../config/app_routes.dart';
import '../../providers/wishlist_provider.dart';
import '../../utils/extensions.dart';

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.productDetail,
        arguments: product.productId,
      ),
      child: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Area
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  product.thumbnailUrl != null
                      ? AppNetworkImage(
                          imageUrl: product.thumbnailUrl!,
                          fit: BoxFit.cover,
                          placeholder: Container(color: Colors.grey.shade100),
                          errorWidget: Container(
                            color: Colors.grey.shade100,
                            child: const Icon(Icons.image_not_supported, size: 30, color: Colors.grey),
                          ),
                        )
                      : Container(
                          color: Colors.grey.shade100,
                          child: const Icon(Icons.image, size: 40, color: Colors.grey),
                        ),

                  // Favorite Button - kết nối WishlistProvider
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Consumer<WishlistProvider>(
                      builder: (ctx, wishlist, _) {
                        final isWishlisted = wishlist.isWishlisted(product.productId);
                        return GestureDetector(
                          onTap: () async {
                            if (isWishlisted) {
                              await wishlist.removeFromWishlist(product.productId);
                            } else {
                              await wishlist.addToWishlist(product.productId);
                            }
                          },
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.white70,
                              shape: BoxShape.circle,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(6.0),
                              child: Icon(
                                isWishlisted ? Icons.favorite : Icons.favorite_outline,
                                size: 18,
                                color: isWishlisted ? Colors.red : Colors.black87,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Discount badge
                  if (product.isOnSale)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: const BoxDecoration(color: Colors.black),
                        child: Text(
                          '-${product.discountPercent}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Info Area
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    product.name.toUpperCase(),
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        product.effectivePrice.toCurrency,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      if (product.isOnSale) ...[
                        const SizedBox(width: 8),
                        Text(
                          product.price.toCurrency,
                          style: TextStyle(
                            fontSize: 11,
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
