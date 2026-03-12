import 'package:flutter/material.dart';
import '../../config/app_routes.dart';
import '../../services/service_locator.dart';
import '../../utils/helpers.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/error_widget.dart';
import '../../widgets/common/empty_widget.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  List<dynamic> _products = [];
  bool _isLoading = true;
  String? _error;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProducts({String? search}) async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final res = await sl.adminService.getProducts(pageSize: 50, search: search);
      if (res.success && res.data != null) {
        final data = res.data;
        if (data is List) {
          setState(() => _products = data);
        } else if (data is Map && data['items'] is List) {
          setState(() => _products = data['items'] as List);
        } else {
          setState(() => _products = []);
        }
      }
    } catch (e) {
      setState(() => _error = e.toString());
    }
    setState(() => _isLoading = false);
  }

  Future<void> _openForm({Map<String, dynamic>? product}) async {
    final result = await Navigator.pushNamed(
      context,
      AppRoutes.adminProductForm,
      arguments: product,
    );
    if (result == true) _loadProducts(search: _searchCtrl.text.isNotEmpty ? _searchCtrl.text : null);
  }

  Future<void> _deleteProduct(int productId, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa "$name"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xóa', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final res = await sl.adminService.deleteProduct(productId);
      if (res.success) {
        Helpers.showSnackBar(context, 'Đã xóa sản phẩm');
        _loadProducts();
      } else {
        Helpers.showSnackBar(context, res.message ?? 'Thất bại', isError: true);
      }
    } catch (_) {
      Helpers.showSnackBar(context, 'Có lỗi xảy ra', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý sản phẩm'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm sản phẩm...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchCtrl.clear(); _loadProducts(); })
                    : null,
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onSubmitted: (v) => _loadProducts(search: v),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: Colors.black,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Thêm sản phẩm', style: TextStyle(color: Colors.white)),
      ),
      body: _isLoading
          ? const LoadingWidget()
          : _error != null
              ? AppErrorWidget(message: _error!, onRetry: _loadProducts)
              : _products.isEmpty
                  ? const EmptyWidget(icon: Icons.inventory_2_outlined, message: 'Không có sản phẩm')
                  : RefreshIndicator(
                      onRefresh: _loadProducts,
                      child: ListView.builder(
                        itemCount: _products.length,
                        padding: const EdgeInsets.only(bottom: 80),
                        itemBuilder: (_, i) => _buildProductTile(_products[i] as Map<String, dynamic>),
                      ),
                    ),
    );
  }

  Widget _buildProductTile(Map<String, dynamic> product) {
    final id = (product['productId'] ?? product['id'] ?? 0) as int;
    final name = (product['name'] ?? product['productName'] ?? 'Unknown') as String;
    final price = (product['price'] ?? product['basePrice'] ?? 0 as num).toDouble();
    final category = (product['categoryName'] ?? '') as String;
    final isActive = (product['isActive'] ?? true) as bool;
    final thumbnail = product['thumbnailUrl'] ??
        (product['images'] is List && (product['images'] as List).isNotEmpty
            ? (product['images'] as List).first['url']
            : null);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _openForm(product: product),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: thumbnail != null
                    ? Image.network(thumbnail as String, width: 56, height: 56, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder())
                    : _placeholder(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
                    if (category.isNotEmpty)
                      Text(category, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                    const SizedBox(height: 2),
                    Text(Helpers.formatCurrency(price),
                        style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: (isActive ? Colors.green : Colors.red).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(isActive ? 'Active' : 'Off',
                        style: TextStyle(color: isActive ? Colors.green : Colors.red, fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () => _openForm(product: product),
                        child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.edit_outlined, size: 18, color: Colors.blue)),
                      ),
                      InkWell(
                        onTap: () => _deleteProduct(id, name),
                        child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.delete_outline, size: 18, color: Colors.red)),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
    width: 56, height: 56,
    color: Colors.grey.shade200,
    child: const Icon(Icons.image_outlined, color: Colors.grey),
  );
}
