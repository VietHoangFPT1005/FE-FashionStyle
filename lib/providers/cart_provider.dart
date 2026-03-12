import 'package:flutter/foundation.dart';
import '../models/cart/cart.dart';
import '../services/cart_service.dart';

class CartProvider extends ChangeNotifier {
  final CartService _cartService;

  Cart? _cart;
  bool _isLoading = false;
  String? _errorMessage;

  CartProvider(this._cartService);

  Cart? get cart => _cart;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get itemCount => _cart?.items.length ?? 0;
  double get totalAmount => _cart?.totalAmount ?? 0;

  Future<void> loadCart() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _cartService.getCart();
      if (response.success && response.data != null) {
        _cart = response.data;
      } else {
        _errorMessage = response.message;
      }
    } catch (e) {
      _errorMessage = 'Failed to load cart';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addToCart(int productVariantId, {int quantity = 1}) async {
    try {
      final response = await _cartService.addToCart(
        AddToCartRequest(productVariantId: productVariantId, quantity: quantity),
      );
      if (response.success) {
        await loadCart();
        return true;
      }
      _errorMessage = response.message;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to add to cart';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateQuantity(int cartItemId, int quantity) async {
    try {
      final response = await _cartService.updateCartItem(cartItemId, quantity);
      if (response.success) {
        await loadCart();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> removeItem(int cartItemId) async {
    try {
      final response = await _cartService.removeCartItem(cartItemId);
      if (response.success) {
        await loadCart();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> clearCart() async {
    try {
      final response = await _cartService.clearCart();
      if (response.success) {
        _cart = Cart();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
