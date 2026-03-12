import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/product/product.dart';


import '../../services/service_locator.dart';
import '../../widgets/product/product_card.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/empty_widget.dart';

class ProductSearchScreen extends StatefulWidget {
  const ProductSearchScreen({super.key});

  @override
  State<ProductSearchScreen> createState() => _ProductSearchScreenState();
}

class _ProductSearchScreenState extends State<ProductSearchScreen> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  List<Product> _results = [];
  bool _isLoading = false;
  bool _hasSearched = false;


  @override
  void initState() {
    super.initState();
    // services from sl
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.trim().length >= 2) _search(query.trim());
    });
  }

  Future<void> _search(String keyword) async {
    setState(() { _isLoading = true; _hasSearched = true; });
    try {
      final res = await sl.productService.searchProducts(keyword, pageSize: 40);
      if (res.success && res.data != null) {
        setState(() => _results = res.data!);
      }
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchCtrl,
          autofocus: true,
          style: const TextStyle(fontSize: 16),
          decoration: const InputDecoration(
            hintText: 'Tìm kiếm sản phẩm...',
            border: InputBorder.none,
          ),
          onChanged: _onSearchChanged,
          onSubmitted: (v) { if (v.trim().isNotEmpty) _search(v.trim()); },
        ),
        actions: [
          if (_searchCtrl.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () { _searchCtrl.clear(); setState(() { _results = []; _hasSearched = false; }); },
            ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () { if (_searchCtrl.text.trim().isNotEmpty) _search(_searchCtrl.text.trim()); },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const LoadingWidget();
    if (!_hasSearched) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('Nhập từ khóa để tìm kiếm', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
          ],
        ),
      );
    }
    if (_results.isEmpty) {
      return const EmptyWidget(icon: Icons.search_off, message: 'Không tìm thấy sản phẩm nào');
    }
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, childAspectRatio: 0.55, crossAxisSpacing: 12, mainAxisSpacing: 12,
      ),
      itemCount: _results.length,
      itemBuilder: (_, i) => ProductCard(product: _results[i]),
    );
  }
}
