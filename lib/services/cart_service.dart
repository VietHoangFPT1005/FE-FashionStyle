import '../config/api_config.dart';
import '../models/api_response.dart';
import '../models/cart/cart.dart';
import 'api_client.dart';

class CartService {
  final ApiClient _client;
  CartService(this._client);

  Future<ApiResponse<Cart>> getCart() async {
    final response = await _client.get(ApiConfig.cart);
    return ApiResponse.fromJson(response.data, (d) => Cart.fromJson(d));
  }

  Future<ApiResponse> addToCart(AddToCartRequest request) async {
    final response = await _client.post(ApiConfig.cartItems, data: request.toJson());
    return ApiResponse.fromJson(response.data, null);
  }

  Future<ApiResponse> updateCartItem(int cartItemId, int quantity) async {
    final response = await _client.put(
      ApiConfig.cartItemById(cartItemId),
      data: {'quantity': quantity},
    );
    return ApiResponse.fromJson(response.data, null);
  }

  Future<ApiResponse> removeCartItem(int cartItemId) async {
    final response = await _client.delete(ApiConfig.cartItemById(cartItemId));
    return ApiResponse.fromJson(response.data, null);
  }

  Future<ApiResponse> clearCart() async {
    final response = await _client.delete(ApiConfig.cart);
    return ApiResponse.fromJson(response.data, null);
  }
}
