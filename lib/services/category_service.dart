import '../config/api_config.dart';
import '../models/api_response.dart';
import '../models/category/category.dart';
import '../models/product/product.dart';
import 'api_client.dart';

class CategoryService {
  final ApiClient _client;
  CategoryService(this._client);

  Future<ApiResponse<List<Category>>> getCategories() async {
    final response = await _client.get(ApiConfig.categories);
    return ApiResponse.fromJson(
      response.data,
      (d) => (d as List).map((e) => Category.fromJson(e)).toList(),
    );
  }

  Future<ApiResponse<PaginatedResponse<Product>>> getCategoryProducts(
    int categoryId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _client.get(
      ApiConfig.categoryProducts(categoryId),
      queryParams: {'page': page, 'pageSize': pageSize},
    );
    return ApiResponse.fromJson(
      response.data,
      (d) => PaginatedResponse.fromJson(d, Product.fromJson),
    );
  }
}
