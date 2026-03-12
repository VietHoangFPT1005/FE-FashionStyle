import '../config/api_config.dart';
import '../models/api_response.dart';
import '../models/refund/refund.dart';
import 'api_client.dart';

class RefundService {
  final ApiClient _client;
  RefundService(this._client);

  Future<ApiResponse<Refund>> requestRefund(int orderId, CreateRefundRequest request) async {
    final response = await _client.post(
      ApiConfig.createRefund(orderId),
      data: request.toJson(),
    );
    return ApiResponse.fromJson(response.data, (d) => Refund.fromJson(d));
  }

  Future<ApiResponse<Refund>> getRefund(int orderId) async {
    final response = await _client.get(ApiConfig.getRefund(orderId));
    return ApiResponse.fromJson(response.data, (d) => Refund.fromJson(d));
  }
}
