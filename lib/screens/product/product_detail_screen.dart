import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_image.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../models/product/product_detail.dart';

import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/custom_button.dart';
import '../../config/app_routes.dart';
import '../../utils/extensions.dart';
import '../../utils/helpers.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final _pageCtrl = PageController();
  int? _selectedVariantId;
  String? _selectedColor;
  String? _selectedSize;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProductDetail(widget.productId);
    });
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _selectVariant(ProductDetail product) {
    final matching = product.variants.where((v) {
      bool match = true;
      if (_selectedColor != null) match = match && v.color == _selectedColor;
      if (_selectedSize != null) match = match && v.size == _selectedSize;
      return match;
    }).toList();
    if (matching.isNotEmpty) {
      setState(() => _selectedVariantId = matching.first.variantId);
    }
  }

  Future<void> _toggleWishlist() async {
    final wishlistProvider = context.read<WishlistProvider>();
    final isWishlisted = wishlistProvider.isWishlisted(widget.productId);
    if (isWishlisted) {
      final ok = await wishlistProvider.removeFromWishlist(widget.productId);
      if (ok && mounted) Helpers.showSnackBar(context, 'Đã xóa khỏi yêu thích');
    } else {
      final ok = await wishlistProvider.addToWishlist(widget.productId);
      if (ok && mounted) Helpers.showSnackBar(context, 'Đã thêm vào yêu thích');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Consumer<ProductProvider>(
        builder: (ctx, provider, __) {
          if (provider.isLoading) return const Scaffold(body: LoadingWidget());
          final product = provider.currentProduct;
          final isWishlisted = ctx.watch<WishlistProvider>().isWishlisted(widget.productId);
          if (product == null) return Scaffold(appBar: AppBar(), body: const Center(child: Text('Không tìm thấy sản phẩm')));

          final colors = product.variants.map((v) => v.color).where((c) => c != null).toSet().toList();
          final sizes = product.variants.map((v) => v.size).where((s) => s != null).toSet().toList();
          final images = product.images.isNotEmpty ? product.images : <ProductImage>[];

          return CustomScrollView(
            slivers: [
              // Image carousel with SliverAppBar (Fashion Style: Full Height)
              SliverAppBar(
                expandedHeight: MediaQuery.of(context).size.height * 0.65,
                pinned: true,
                backgroundColor: Colors.transparent,
                leading: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircleAvatar(
                    backgroundColor: Colors.white.withOpacity(0.5),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CircleAvatar(
                      backgroundColor: Colors.white.withOpacity(0.5),
                      child: IconButton(
                        icon: Icon(isWishlisted ? Icons.favorite : Icons.favorite_border, color: isWishlisted ? Colors.red : Colors.black),
                        onPressed: _toggleWishlist,
                      ),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: images.isNotEmpty
                      ? Stack(
                          children: [
                            PageView.builder(
                              controller: _pageCtrl,
                              itemCount: images.length,
                              itemBuilder: (_, i) => AppNetworkImage(
                                imageUrl: images[i].imageUrl,
                                fit: BoxFit.cover,
                                placeholder: Container(color: Colors.grey.shade100),
                                errorWidget: Container(color: Colors.grey.shade100, child: const Icon(Icons.image, size: 60)),
                                optimize: false,
                              ),
                            ),
                            if (images.length > 1)
                              Positioned(
                                bottom: 24, left: 0, right: 0,
                                child: Center(
                                  child: SmoothPageIndicator(
                                    controller: _pageCtrl,
                                    count: images.length,
                                    effect: ExpandingDotsEffect(
                                      dotHeight: 6, dotWidth: 6,
                                      activeDotColor: Colors.black,
                                      dotColor: Colors.black.withOpacity(0.3),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        )
                      : Container(
                          color: Colors.grey.shade100,
                          child: product.thumbnailUrl != null
                              ? AppNetworkImage(imageUrl: product.thumbnailUrl!, fit: BoxFit.cover, optimize: false)
                              : const Center(child: Icon(Icons.image, size: 80, color: Colors.grey)),
                        ),
                ),
              ),

              // Product info
              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                  ),
                  transform: Matrix4.translationValues(0, -20, 0),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Brand & Name
                        Text('LUMINA EXCLUSIVE', style: TextStyle(color: Colors.grey.shade500, fontSize: 12, letterSpacing: 2.0)),
                        const SizedBox(height: 8),
                        Text(
                          product.name.toUpperCase(),
                          style: GoogleFonts.cormorantGaramond(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Price & Status
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              product.effectivePrice.toCurrency,
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                            if (product.isOnSale) ...[
                              const SizedBox(width: 12),
                              Text(
                                product.price.toCurrency,
                                style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey, fontSize: 16),
                              ),
                            ],
                            const Spacer(),
                            if (product.averageRating != null && product.averageRating! > 0)
                              GestureDetector(
                                onTap: () => Navigator.pushNamed(context, AppRoutes.reviews, arguments: widget.productId),
                                child: Row(
                                  children: [
                                    const Icon(Icons.star, color: Colors.amber, size: 20),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${product.averageRating!.toStringAsFixed(1)} (${product.totalReviews})',
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Divider(thickness: 1, color: Color(0xFFEEEEEE)),
                        ),

                        // Color selector (Elegant circles)
                        if (colors.isNotEmpty) ...[
                          const Text('COLORS', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: 1.5, color: Colors.black54)),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12, runSpacing: 12,
                            children: colors.map((color) => GestureDetector(
                              onTap: () {
                                setState(() => _selectedColor = color);
                                _selectVariant(product);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                decoration: BoxDecoration(
                                  color: _selectedColor == color ? Colors.black : Colors.white,
                                  border: Border.all(color: _selectedColor == color ? Colors.black : Colors.grey.shade300),
                                ),
                                child: Text(
                                  color!.toUpperCase(),
                                  style: TextStyle(
                                    color: _selectedColor == color ? Colors.white : Colors.black87,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            )).toList(),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Size selector
                        if (sizes.isNotEmpty) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('SIZES', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: 1.5, color: Colors.black54)),
                              if (product.sizeGuide != null)
                                GestureDetector(
                                  onTap: () => _showSizeGuide(product.sizeGuide!),
                                  child: const Text('Size Guide', style: TextStyle(fontSize: 13, decoration: TextDecoration.underline, color: Colors.black87)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12, runSpacing: 12,
                            children: sizes.map((size) {
                              final variant = product.variants.firstWhere(
                                (v) => v.size == size && (_selectedColor == null || v.color == _selectedColor),
                                orElse: () => product.variants.firstWhere((v) => v.size == size),
                              );
                              final inStock = variant.isInStock;
                              return GestureDetector(
                                onTap: inStock ? () {
                                  setState(() => _selectedSize = size);
                                  _selectVariant(product);
                                } : null,
                                child: Container(
                                  width: 48, height: 48,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: !inStock ? Colors.grey.shade100 : _selectedSize == size ? Colors.black : Colors.white,
                                    border: Border.all(color: !inStock ? Colors.grey.shade200 : _selectedSize == size ? Colors.black : Colors.grey.shade300),
                                  ),
                                  child: Text(
                                    size!,
                                    style: TextStyle(
                                      color: !inStock ? Colors.grey.shade400 : _selectedSize == size ? Colors.white : Colors.black87,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Description
                        const Text('DESCRIPTION', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: 1.5, color: Colors.black54)),
                        const SizedBox(height: 12),
                        Text(
                          product.description ?? 'Chưa có mô tả sản phẩm.',
                          style: const TextStyle(fontSize: 15, height: 1.8, color: Colors.black87),
                        ),
                        
                        const SizedBox(height: 32),
                        // Reviews link
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(context, AppRoutes.reviews, arguments: widget.productId),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              border: Border(top: BorderSide(color: Colors.grey.shade200), bottom: BorderSide(color: Colors.grey.shade200)),
                            ),
                            child: Row(
                              children: [
                                const Text('CUSTOMER REVIEWS', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                const Spacer(),
                                Text('(${product.totalReviews ?? 0})', style: const TextStyle(color: Colors.grey)),
                                const Icon(Icons.chevron_right, color: Colors.grey),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              // Quantity Selector
              Container(
                height: 52,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    IconButton(icon: const Icon(Icons.remove, size: 20), onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null),
                    SizedBox(width: 24, child: Text('$_quantity', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16))),
                    IconButton(icon: const Icon(Icons.add, size: 20), onPressed: () => setState(() => _quantity++)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Add to Bag Button
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                      elevation: 0,
                    ),
                    onPressed: () async {
                      if (_selectedVariantId == null) {
                        Helpers.showSnackBar(context, 'Vui lòng chọn màu sắc và kích thước', isError: true);
                        return;
                      }
                      final success = await context.read<CartProvider>().addToCart(
                        _selectedVariantId!,
                        quantity: _quantity,
                      );
                      if (success && mounted) {
                        Helpers.showSnackBar(context, 'Đã thêm vào giỏ hàng');
                      }
                    },
                    child: const Text('ADD TO BAG', style: TextStyle(letterSpacing: 2.0, fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSizeGuide(SizeGuide sizeGuide) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      backgroundColor: Colors.white,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 40, left: 24, right: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('SIZE GUIDE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 2.0)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const Divider(),
            const SizedBox(height: 16),
            if (sizeGuide.description != null) Text(sizeGuide.description!, style: const TextStyle(height: 1.6, fontSize: 15)),
            if (sizeGuide.sizeGuideUrl != null) ...[
              const SizedBox(height: 24),
              AppNetworkImage(imageUrl: sizeGuide.sizeGuideUrl!, fit: BoxFit.fitWidth, optimize: false),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
