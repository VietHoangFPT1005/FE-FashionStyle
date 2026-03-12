import 'package:flutter/foundation.dart';
import '../models/product/product.dart';
import '../models/product/product_detail.dart';
import '../models/api_response.dart';
import '../services/product_service.dart';

class ProductProvider extends ChangeNotifier {
  final ProductService _productService;

  List<Product> _products = [];
  ProductDetail? _currentProduct;
  PaginationInfo _pagination = PaginationInfo();
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;

  ProductProvider(this._productService);

  List<Product> get products => _products;
  ProductDetail? get currentProduct => _currentProduct;
  PaginationInfo get pagination => _pagination;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  bool get hasMore => _pagination.hasNext;

  /// Load first page
  Future<void> loadProducts({
    String? sortBy,
    String? sortOrder,
    double? minPrice,
    double? maxPrice,
    bool? isFeatured,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _productService.getProducts(
        page: 1,
        sortBy: sortBy,
        sortOrder: sortOrder,
        minPrice: minPrice,
        maxPrice: maxPrice,
        isFeatured: isFeatured,
      );
      if (response.success && response.data != null) {
        _products = response.data!.items;
        _pagination = response.data!.pagination;
      } else {
        _errorMessage = response.message;
      }
    } catch (e) {
      _errorMessage = 'Failed to load products';
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Load next page
  Future<void> loadMore() async {
    if (_isLoadingMore || !_pagination.hasNext) return;
    _isLoadingMore = true;
    notifyListeners();

    try {
      final response = await _productService.getProducts(
        page: _pagination.currentPage + 1,
      );
      if (response.success && response.data != null) {
        _products.addAll(response.data!.items);
        _pagination = response.data!.pagination;
      }
    } catch (_) {}
    _isLoadingMore = false;
    notifyListeners();
  }

  /// Load product detail
  Future<void> loadProductDetail(int productId) async {
    _isLoading = true;
    _currentProduct = null;
    notifyListeners();

    try {
      final response = await _productService.getProductDetail(productId);
      if (response.success && response.data != null) {
        _currentProduct = response.data;
      } else {
        _errorMessage = response.message;
      }
    } catch (e) {
      _errorMessage = 'Failed to load product';
    }
    _isLoading = false;
    notifyListeners();
  }

  void clearCurrentProduct() {
    _currentProduct = null;
    notifyListeners();
  }
}
