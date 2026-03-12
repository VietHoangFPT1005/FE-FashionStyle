import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/app_routes.dart';
import '../../models/category/category.dart';
import '../../models/product/product.dart';
import '../../providers/product_provider.dart';
import '../../services/service_locator.dart';
import '../../widgets/product/product_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scrollController = ScrollController();
  int _currentBannerIndex = 0;

  List<Category> _categories = [];
  List<Product> _featuredProducts = [];
  bool _isLoadingCategories = true;
  bool _isLoadingFeatured = true;

  final List<Map<String, String>> _banners = [
    {
      'url': 'https://images.unsplash.com/photo-1469334031218-e382a71b716b?q=80&w=2070&auto=format&fit=crop',
      'tag': 'NEW COLLECTION',
      'title': 'Elegance\nRediscovered',
      'cta': 'SHOP NOW',
    },
    {
      'url': 'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?q=80&w=2070&auto=format&fit=crop',
      'tag': 'EXCLUSIVE',
      'title': 'Premium\nFashion',
      'cta': 'EXPLORE',
    },
    {
      'url': 'https://images.unsplash.com/photo-1445205170230-053b83016050?q=80&w=2071&auto=format&fit=crop',
      'tag': 'AUTUMN 2025',
      'title': 'Timeless\nStyle',
      'cta': 'DISCOVER',
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts();
    });
    _scrollController.addListener(_onScroll);
    _loadCategories();
    _loadFeaturedProducts();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<ProductProvider>().loadMore();
    }
  }

  Future<void> _loadCategories() async {
    try {
      final res = await sl.categoryService.getCategories();
      if (res.success && res.data != null && mounted) {
        setState(() => _categories = res.data!.where((c) => c.isActive).toList());
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoadingCategories = false);
  }

  Future<void> _loadFeaturedProducts() async {
    try {
      final res = await sl.productService.getProducts(
        page: 1, pageSize: 6, isFeatured: true,
      );
      if (res.success && res.data != null && mounted) {
        setState(() => _featuredProducts = res.data!.items);
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoadingFeatured = false);
  }

  Future<void> _refresh() async {
    setState(() {
      _isLoadingCategories = true;
      _isLoadingFeatured = true;
    });
    await Future.wait([
      context.read<ProductProvider>().loadProducts(),
      _loadCategories(),
      _loadFeaturedProducts(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Consumer<ProductProvider>(
        builder: (_, provider, __) {
          return RefreshIndicator(
            color: Colors.black,
            onRefresh: _refresh,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // App Bar
                SliverAppBar(
                  backgroundColor: Colors.white,
                  elevation: 0,
                  floating: true,
                  snap: true,
                  leading: Builder(
                    builder: (ctx) => IconButton(
                      icon: const Icon(Icons.menu, color: Colors.black),
                      onPressed: () => Scaffold.of(ctx).openDrawer(),
                    ),
                  ),
                  title: Text(
                    'LUMINA STYLE',
                    style: GoogleFonts.cormorantGaramond(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 3,
                    ),
                  ),
                  centerTitle: true,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.search, color: Colors.black),
                      onPressed: () => Navigator.pushNamed(context, AppRoutes.productSearch),
                    ),
                    IconButton(
                      icon: const Icon(Icons.smart_toy_outlined, color: Colors.black),
                      onPressed: () => Navigator.pushNamed(context, AppRoutes.aiChat),
                    ),
                  ],
                ),

                // Banner Carousel
                SliverToBoxAdapter(child: _buildBannerCarousel()),

                // Categories
                SliverToBoxAdapter(child: _buildCategoriesSection()),

                // Featured Products title
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'NỔI BẬT',
                              style: TextStyle(
                                fontSize: 11,
                                letterSpacing: 3,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Sản phẩm nổi bật',
                              style: GoogleFonts.cormorantGaramond(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () => Navigator.pushNamed(
                            context, AppRoutes.productList,
                            arguments: <String, dynamic>{'isFeatured': true},
                          ),
                          child: const Text(
                            'Xem tất cả',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Featured Products Grid
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                    child: _buildFeaturedGrid(),
                  ),
                ),

                // Divider
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 24, 16, 0),
                    child: Row(children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('MỚI NHẤT', style: TextStyle(fontSize: 10, letterSpacing: 2, color: Colors.grey)),
                      ),
                      Expanded(child: Divider()),
                    ]),
                  ),
                ),

                // New Arrivals title
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'MỚI NHẤT',
                              style: TextStyle(
                                fontSize: 11,
                                letterSpacing: 3,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Hàng mới về',
                              style: GoogleFonts.cormorantGaramond(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () => Navigator.pushNamed(context, AppRoutes.productList),
                          child: const Text(
                            'Xem tất cả',
                            style: TextStyle(fontSize: 12, color: Colors.black, decoration: TextDecoration.underline),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // New Arrivals products
                if (provider.isLoading && provider.products.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: CircularProgressIndicator(color: Colors.black)),
                    ),
                  )
                else if (provider.products.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
                      child: Column(
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text(
                            'Chưa có sản phẩm',
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) {
                          if (i >= provider.products.length) {
                            return const Center(child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2));
                          }
                          return ProductCard(product: provider.products[i]);
                        },
                        childCount: provider.products.length + (provider.isLoadingMore ? 1 : 0),
                      ),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.55,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                    ),
                  ),

                // Bottom padding
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
          );
        },
      ),
      drawer: _buildDrawer(),
    );
  }

  Widget _buildBannerCarousel() {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        CarouselSlider(
          options: CarouselOptions(
            height: 500.0,
            viewportFraction: 1.0,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 4),
            onPageChanged: (index, _) => setState(() => _currentBannerIndex = index),
          ),
          items: _banners.map((banner) {
            return Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: banner['url']!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: Colors.grey.shade200),
                  errorWidget: (_, __, ___) => Container(
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.image, size: 60, color: Colors.grey),
                  ),
                ),
                // Dark gradient overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.4, 1.0],
                    ),
                  ),
                ),
                // Banner text content
                Positioned(
                  bottom: 60,
                  left: 24,
                  right: 24,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white54),
                        ),
                        child: Text(
                          banner['tag']!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            letterSpacing: 3,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        banner['title']!,
                        style: GoogleFonts.cormorantGaramond(
                          color: Colors.white,
                          fontSize: 38,
                          fontWeight: FontWeight.w600,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, AppRoutes.productList),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          color: Colors.white,
                          child: Text(
                            banner['cta']!,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
        // Page indicators
        Positioned(
          bottom: 20,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_banners.length, (i) {
              final isActive = _currentBannerIndex == i;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: isActive ? 20 : 6,
                height: 3,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: isActive ? Colors.white : Colors.white38,
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DANH MỤC',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 3,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Khám phá bộ sưu tập',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.categories),
                child: const Text(
                  'Tất cả',
                  style: TextStyle(fontSize: 12, color: Colors.black, decoration: TextDecoration.underline),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 110,
          child: _isLoadingCategories
              ? const Center(child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
              : _categories.isEmpty
                  ? _buildDefaultCategories()
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (_, i) => _buildCategoryChip(_categories[i]),
                    ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildCategoryChip(Category category) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context, AppRoutes.productList,
        arguments: {'categoryId': category.categoryId, 'categoryName': category.name},
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(4),
            ),
            clipBehavior: Clip.antiAlias,
            child: category.imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: category.imageUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => _categoryIcon(category.name),
                  )
                : _categoryIcon(category.name),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 72,
            child: Text(
              category.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultCategories() {
    final defaults = [
      {'name': 'Áo', 'icon': Icons.dry_cleaning_outlined},
      {'name': 'Quần', 'icon': Icons.accessibility_new_outlined},
      {'name': 'Váy', 'icon': Icons.woman_outlined},
      {'name': 'Phụ kiện', 'icon': Icons.watch_outlined},
      {'name': 'Giày dép', 'icon': Icons.shopping_bag_outlined},
    ];
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      scrollDirection: Axis.horizontal,
      itemCount: defaults.length,
      separatorBuilder: (_, __) => const SizedBox(width: 12),
      itemBuilder: (_, i) {
        final item = defaults[i];
        return GestureDetector(
          onTap: () => Navigator.pushNamed(context, AppRoutes.categories),
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(item['icon'] as IconData, size: 30, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 6),
              Text(
                item['name'] as String,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _categoryIcon(String name) {
    return Icon(
      name.toLowerCase().contains('áo') ? Icons.dry_cleaning_outlined
          : name.toLowerCase().contains('quần') ? Icons.accessibility_new_outlined
          : name.toLowerCase().contains('váy') ? Icons.woman_outlined
          : Icons.category_outlined,
      size: 30,
      color: Colors.grey.shade600,
    );
  }

  Widget _buildFeaturedGrid() {
    if (_isLoadingFeatured) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: CircularProgressIndicator(color: Colors.black),
        ),
      );
    }
    if (_featuredProducts.isEmpty) {
      return const SizedBox.shrink();
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.55,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _featuredProducts.length,
      itemBuilder: (_, i) => ProductCard(product: _featuredProducts[i]),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.black),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'LUMINA STYLE',
                  style: GoogleFonts.cormorantGaramond(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Premium Fashion Destination',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 12,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home_outlined, color: Colors.black),
            title: const Text('Trang chủ'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.category_outlined, color: Colors.black),
            title: const Text('Danh mục'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.categories);
            },
          ),
          ListTile(
            leading: const Icon(Icons.fiber_new_outlined, color: Colors.black),
            title: const Text('Hàng mới về'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.productList);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.favorite_outline, color: Colors.black),
            title: const Text('Yêu thích'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.wishlist);
            },
          ),
          ListTile(
            leading: const Icon(Icons.local_offer_outlined, color: Colors.black),
            title: const Text('Voucher'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.vouchers);
            },
          ),
          ListTile(
            leading: const Icon(Icons.smart_toy_outlined, color: Colors.black),
            title: const Text('AI Fashion Advisor'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.aiChat);
            },
          ),
          ListTile(
            leading: const Icon(Icons.support_agent_rounded, color: Colors.black),
            title: const Text('Chat hỗ trợ'),
            subtitle: const Text('Nhắn tin với nhân viên', style: TextStyle(fontSize: 11, color: Colors.grey)),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.supportChat);
            },
          ),
        ],
      ),
    );
  }
}
