import 'package:flutter/material.dart';
import '../../config/app_routes.dart';
import '../../models/product/product.dart';
import '../../services/service_locator.dart';
import '../../widgets/product/product_card.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/error_widget.dart';
import '../../widgets/common/empty_widget.dart';

class ProductListScreen extends StatefulWidget {
  final int? categoryId;
  final String? categoryName;
  const ProductListScreen({super.key, this.categoryId, this.categoryName});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final ScrollController _scrollCtrl = ScrollController();
  List<Product> _products = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;
  int _page = 1;
  bool _hasMore = true;
  String _sortBy = 'createdAt';
  String _sortOrder = 'desc';
  RangeValues _priceRange = const RangeValues(0, 10000000);
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _loadProducts();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadProducts() async {
    setState(() { _isLoading = true; _error = null; _page = 1; });
    try {
      if (widget.categoryId != null) {
        final res = await sl.categoryService.getCategoryProducts(widget.categoryId!, page: 1, pageSize: 20);
        if (res.success && res.data != null) {
          setState(() { _products = res.data!.items; _hasMore = res.data!.pagination.hasNext; });
        }
      } else {
        final res = await sl.productService.getProducts(
          page: 1, pageSize: 20, sortBy: _sortBy, sortOrder: _sortOrder,
          minPrice: _priceRange.start > 0 ? _priceRange.start : null,
          maxPrice: _priceRange.end < 10000000 ? _priceRange.end : null,
        );
        if (res.success && res.data != null) {
          setState(() { _products = res.data!.items; _hasMore = res.data!.pagination.hasNext; });
        }
      }
    } catch (e) {
      setState(() => _error = e.toString());
    }
    setState(() => _isLoading = false);
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    _page++;
    try {
      if (widget.categoryId != null) {
        final res = await sl.categoryService.getCategoryProducts(widget.categoryId!, page: _page, pageSize: 20);
        if (res.success && res.data != null) {
          setState(() { _products.addAll(res.data!.items); _hasMore = res.data!.pagination.hasNext; });
        }
      } else {
        final res = await sl.productService.getProducts(
          page: _page, pageSize: 20, sortBy: _sortBy, sortOrder: _sortOrder,
          minPrice: _priceRange.start > 0 ? _priceRange.start : null,
          maxPrice: _priceRange.end < 10000000 ? _priceRange.end : null,
        );
        if (res.success && res.data != null) {
          setState(() { _products.addAll(res.data!.items); _hasMore = res.data!.pagination.hasNext; });
        }
      }
    } catch (_) {}
    setState(() => _isLoadingMore = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName ?? 'Sản phẩm'),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () => Navigator.pushNamed(context, AppRoutes.productSearch)),
          IconButton(
            icon: Icon(_showFilters ? Icons.filter_list_off : Icons.filter_list),
            onPressed: () => setState(() => _showFilters = !_showFilters),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_showFilters) _buildFilterBar(),
          _buildSortChips(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Khoảng giá', style: TextStyle(fontWeight: FontWeight.w600)),
          RangeSlider(
            values: _priceRange, min: 0, max: 10000000, divisions: 100,
            labels: RangeLabels('${(_priceRange.start / 1000).toInt()}k', '${(_priceRange.end / 1000).toInt()}k'),
            onChanged: (v) => setState(() => _priceRange = v),
            onChangeEnd: (_) => _loadProducts(),
          ),
        ],
      ),
    );
  }

  Widget _buildSortChips() {
    final sorts = [
      {'label': 'Mới nhất', 'field': 'createdAt', 'order': 'desc'},
      {'label': 'Giá tăng', 'field': 'price', 'order': 'asc'},
      {'label': 'Giá giảm', 'field': 'price', 'order': 'desc'},
      {'label': 'Bán chạy', 'field': 'totalSold', 'order': 'desc'},
      {'label': 'Đánh giá', 'field': 'averageRating', 'order': 'desc'},
    ];
    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemCount: sorts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final s = sorts[i];
          final selected = _sortBy == s['field'] && _sortOrder == s['order'];
          return FilterChip(
            label: Text(
              s['label']!,
              style: TextStyle(
                color: selected ? Colors.white : Colors.black87,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            selected: selected,
            selectedColor: Colors.black,
            backgroundColor: Colors.grey.shade100,
            showCheckmark: false,
            side: BorderSide(color: selected ? Colors.black : Colors.grey.shade300),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            onSelected: (_) { setState(() { _sortBy = s['field']!; _sortOrder = s['order']!; }); _loadProducts(); },
          );
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const LoadingWidget();
    if (_error != null) return AppErrorWidget(message: _error!, onRetry: _loadProducts);
    if (_products.isEmpty) return const EmptyWidget(icon: Icons.inventory_2_outlined, message: 'Không có sản phẩm nào');
    return RefreshIndicator(
      onRefresh: _loadProducts,
      child: GridView.builder(
        controller: _scrollCtrl,
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, childAspectRatio: 0.55, crossAxisSpacing: 12, mainAxisSpacing: 12,
        ),
        itemCount: _products.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (_, i) {
          if (i >= _products.length) return const Center(child: CircularProgressIndicator());
          return ProductCard(product: _products[i]);
        },
      ),
    );
  }
}
