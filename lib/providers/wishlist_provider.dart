import 'package:flutter/material.dart';
import '../models/wishlist/wishlist.dart';
import '../services/wishlist_service.dart';

class WishlistProvider extends ChangeNotifier {
  final WishlistService _wishlistService;
  WishlistProvider(this._wishlistService);

  List<WishlistItem> _items = [];
  bool _isLoading = false;

  List<WishlistItem> get items => _items;
  bool get isLoading => _isLoading;
  int get count => _items.length;

  bool isWishlisted(int productId) => _items.any((i) => i.productId == productId);

  Future<void> loadWishlist() async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await _wishlistService.getWishlists();
      if (res.success && res.data != null) {
        _items = res.data!;
      }
    } catch (_) {}
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addToWishlist(int productId) async {
    try {
      final res = await _wishlistService.addToWishlist(productId);
      if (res.success) {
        await loadWishlist();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> removeFromWishlist(int productId) async {
    try {
      final res = await _wishlistService.removeFromWishlist(productId);
      if (res.success) {
        _items.removeWhere((i) => i.productId == productId);
        notifyListeners();
        return true;
      }
    } catch (_) {}
    return false;
  }
}
