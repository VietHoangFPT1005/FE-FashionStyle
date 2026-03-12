import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_routes.dart';
import '../../models/wishlist/wishlist.dart';
import '../../providers/wishlist_provider.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/empty_widget.dart';
import '../../utils/helpers.dart';
import '../../utils/extensions.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WishlistProvider>().loadWishlist();
    });
  }

  Future<void> _removeItem(int productId) async {
    final ok = await context.read<WishlistProvider>().removeFromWishlist(productId);
    if (ok && mounted) Helpers.showSnackBar(context, 'Đã xóa khỏi danh sách yêu thích');
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WishlistProvider>(
      builder: (_, wishlist, __) {
        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Yêu thích',
              style: GoogleFonts.cormorantGaramond(
                color: Colors.black, fontSize: 22, fontWeight: FontWeight.w700),
            ),
            actions: [
              if (wishlist.count > 0)
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(right: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('${wishlist.count}',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ),
            ],
          ),
          body: _buildBody(wishlist),
        );
      },
    );
  }

  Widget _buildBody(WishlistProvider wishlist) {
    if (wishlist.isLoading) return const LoadingWidget();
    if (wishlist.items.isEmpty) {
      return EmptyWidget(
        icon: Icons.favorite_border,
        message: 'Chưa có sản phẩm yêu thích',
        actionText: 'Khám phá ngay',
        onAction: () => Navigator.pop(context),
      );
    }

    return RefreshIndicator(
      color: Colors.black,
      onRefresh: () => context.read<WishlistProvider>().loadWishlist(),
      child: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, childAspectRatio: 0.6,
          crossAxisSpacing: 12, mainAxisSpacing: 12,
        ),
        itemCount: wishlist.items.length,
        itemBuilder: (_, i) => _buildWishlistCard(wishlist.items[i]),
      ),
    );
  }

  Widget _buildWishlistCard(WishlistItem item) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.productDetail, arguments: item.productId),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  item.thumbnailUrl != null
                      ? CachedNetworkImage(
                          imageUrl: item.thumbnailUrl!, fit: BoxFit.cover,
                          placeholder: (_, __) => Container(color: Colors.grey.shade100),
                          errorWidget: (_, __, ___) => Container(
                            color: Colors.grey.shade100,
                            child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey)),
                        )
                      : Container(color: Colors.grey.shade100,
                          child: const Icon(Icons.image_not_supported_outlined, size: 40, color: Colors.grey)),
                  Positioned(
                    top: 6, right: 6,
                    child: GestureDetector(
                      onTap: () => _removeItem(item.productId),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
                        ),
                        child: const Icon(Icons.favorite, color: Colors.red, size: 16),
                      ),
                    ),
                  ),
                  if (item.salePrice != null && item.salePrice! < item.price)
                    Positioned(
                      top: 0, left: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        color: Colors.red,
                        child: Text(
                          '-${((1 - item.salePrice! / item.price) * 100).round()}%',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.productName,
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, height: 1.3)),
                    const Spacer(),
                    Text(
                      (item.salePrice ?? item.price).toCurrency,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 14)),
                    if (item.salePrice != null && item.salePrice! < item.price)
                      Text(item.price.toCurrency,
                        style: const TextStyle(
                          decoration: TextDecoration.lineThrough, color: Colors.grey, fontSize: 11)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
