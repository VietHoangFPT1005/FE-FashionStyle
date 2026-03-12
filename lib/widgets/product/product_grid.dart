import 'package:flutter/material.dart';
import '../../models/product/product.dart';
import 'product_card.dart';

class ProductGrid extends StatelessWidget {
  final List<Product> products;
  final ScrollController? scrollController;
  final bool isLoadingMore;
  /// Set to true when ProductGrid is nested inside a SingleChildScrollView
  /// to avoid Expanded/hasSize layout errors
  final bool shrinkWrap;

  const ProductGrid({
    super.key,
    required this.products,
    this.scrollController,
    this.isLoadingMore = false,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    if (shrinkWrap) {
      // Inside SingleChildScrollView: shrinkWrap + NeverScrollableScrollPhysics
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GridView.builder(
            controller: scrollController,
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.55,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: products.length,
            itemBuilder: (_, index) => ProductCard(product: products[index]),
          ),
          if (isLoadingMore)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)),
            ),
        ],
      );
    }

    // Full-height mode (screen-level content, e.g. ProductListScreen)
    return Column(
      children: [
        Expanded(
          child: GridView.builder(
            controller: scrollController,
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.55,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: products.length,
            itemBuilder: (_, index) => ProductCard(product: products[index]),
          ),
        ),
        if (isLoadingMore)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
      ],
    );
  }
}
