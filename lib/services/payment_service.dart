import '../config/api_config.dart';
import '../models/api_response.dart';
import 'api_client.dart';

class PaymentService {
  final ApiClient _client;
  PaymentService(this._client);

  /// POST /Payment/sepay/create → SePayPaymentResponse
  Future<ApiResponse<Map<String, dynamic>>> createSepayPayment(int orderId) async {
    final response = await _client.post(
      ApiConfig.createPayment,
      data: {'orderId': orderId},
    );
    return ApiResponse.fromJson(
      response.data,
      (d) => d as Map<String, dynamic>,
    );
  }

  /// GET /Payment/{orderId}/poll-status → { status, isPaid, remainingSeconds }
  /// NOTE: This endpoint returns raw JSON (no ApiResponse wrapper), so we wrap it manually.
  Future<ApiResponse<Map<String, dynamic>>> pollPaymentStatus(int orderId) async {
    final response = await _client.get(ApiConfig.paymentPollStatus(orderId));
    final raw = response.data;
    if (raw is Map<String, dynamic>) {
      return ApiResponse(success: true, message: '', data: raw);
    }
    return ApiResponse(success: false, message: 'Invalid poll response');
  }
}
