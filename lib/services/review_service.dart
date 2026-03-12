import '../config/api_config.dart';
import '../models/api_response.dart';
import '../models/review/review.dart';
import 'api_client.dart';

class ReviewService {
  final ApiClient _client;
  ReviewService(this._client);

  Future<ApiResponse> createReview(int productId, CreateReviewRequest request) async {
    final response = await _client.post(
      ApiConfig.createReview(productId),
      data: request.toJson(),
    );
    return ApiResponse.fromJson(response.data, null);
  }

  Future<ApiResponse> updateReview(
    int productId,
    int reviewId,
    UpdateReviewRequest request,
  ) async {
    final response = await _client.put(
      ApiConfig.updateReview(productId, reviewId),
      data: request.toJson(),
    );
    return ApiResponse.fromJson(response.data, null);
  }

  Future<ApiResponse> deleteReview(int productId, int reviewId) async {
    final response = await _client.delete(ApiConfig.deleteReview(productId, reviewId));
    return ApiResponse.fromJson(response.data, null);
  }
}
