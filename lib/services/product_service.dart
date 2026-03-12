import '../config/api_config.dart';
import '../models/api_response.dart';
import '../models/product/product.dart';
import '../models/product/product_detail.dart';
import '../models/review/review.dart';
import 'api_client.dart';

class ProductService {
  final ApiClient _client;
  ProductService(this._client);

  Future<ApiResponse<PaginatedResponse<Product>>> getProducts({
    int page = 1,
    int pageSize = 20,
    String? sortBy,
    String? sortOrder,
    double? minPrice,
    double? maxPrice,
    bool? isFeatured,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
      if (sortBy != null) 'sortBy': sortBy,
      if (sortOrder != null) 'sortOrder': sortOrder,
      if (minPrice != null) 'minPrice': minPrice,
      if (maxPrice != null) 'maxPrice': maxPrice,
      if (isFeatured != null) 'isFeatured': isFeatured,
    };
    final response = await _client.get(ApiConfig.products, queryParams: params);
    return ApiResponse.fromJson(
      response.data,
      (d) => PaginatedResponse.fromJson(d, Product.fromJson),
    );
  }

  Future<ApiResponse<List<Product>>> searchProducts(String keyword, {int page = 1, int pageSize = 20}) async {
    final params = {'keyword': keyword, 'page': page, 'pageSize': pageSize};
    final response = await _client.get(ApiConfig.productSearch, queryParams: params);
    return ApiResponse.fromJson(
      response.data,
      (d) => (d as List).map((e) => Product.fromJson(e)).toList(),
    );
  }

  Future<ApiResponse<ProductDetail>> getProductDetail(int productId) async {
    final response = await _client.get(ApiConfig.productDetail(productId));
    return ApiResponse.fromJson(response.data, (d) => ProductDetail.fromJson(d));
  }

  Future<ApiResponse<List<ProductVariant>>> getVariants(int productId) async {
    final response = await _client.get(ApiConfig.productVariants(productId));
    return ApiResponse.fromJson(
      response.data,
      (d) => (d as List).map((e) => ProductVariant.fromJson(e)).toList(),
    );
  }

  Future<ApiResponse<List<ProductImage>>> getImages(int productId) async {
    final response = await _client.get(ApiConfig.productImages(productId));
    return ApiResponse.fromJson(
      response.data,
      (d) => (d as List).map((e) => ProductImage.fromJson(e)).toList(),
    );
  }

  Future<ApiResponse> getSizeGuide(int productId) async {
    final response = await _client.get(ApiConfig.productSizeGuide(productId));
    return ApiResponse.fromJson(response.data, null);
  }

  Future<ApiResponse> getRecommendSize(int productId) async {
    final response = await _client.get(ApiConfig.productRecommendSize(productId));
    return ApiResponse.fromJson(response.data, null);
  }

  Future<ApiResponse<List<Review>>> getReviews(int productId) async {
    final response = await _client.get(ApiConfig.productReviews(productId));
    return ApiResponse.fromJson(
      response.data,
      (d) {
        // BE trả về { summary, reviews: [...], pagination }
        // Fallback: nếu d là List thẳng thì dùng trực tiếp
        if (d is List) {
          return d.map((e) => Review.fromJson(e as Map<String, dynamic>)).toList();
        }
        final map = d as Map<String, dynamic>;
        final list = (map['reviews'] as List?) ?? [];
        return list.map((e) => Review.fromJson(e as Map<String, dynamic>)).toList();
      },
    );
  }
}
