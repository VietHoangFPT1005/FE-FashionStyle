import '../config/api_config.dart';
import '../models/api_response.dart';
import '../models/wishlist/wishlist.dart';
import 'api_client.dart';

class WishlistService {
  final ApiClient _client;
  WishlistService(this._client);

  Future<ApiResponse<List<WishlistItem>>> getWishlists() async {
    final response = await _client.get(ApiConfig.wishlists);
    return ApiResponse.fromJson(
      response.data,
      (d) => (d as List).map((e) => WishlistItem.fromJson(e)).toList(),
    );
  }

  Future<ApiResponse> addToWishlist(int productId) async {
    final response = await _client.post(ApiConfig.wishlists, data: {'productId': productId});
    return ApiResponse.fromJson(response.data, null);
  }

  Future<ApiResponse> removeFromWishlist(int productId) async {
    final response = await _client.delete(ApiConfig.removeWishlist(productId));
    return ApiResponse.fromJson(response.data, null);
  }
}
