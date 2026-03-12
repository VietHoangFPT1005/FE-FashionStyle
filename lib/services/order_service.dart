import '../config/api_config.dart';
import '../models/api_response.dart';
import '../models/order/order.dart';
import '../models/order/order_detail.dart';
import '../models/order/tracking.dart';
import 'api_client.dart';

class OrderService {
  final ApiClient _client;
  OrderService(this._client);

  Future<ApiResponse<CreateOrderResponse>> createOrder(CreateOrderRequest request) async {
    final response = await _client.post(ApiConfig.createOrder, data: request.toJson());
    return ApiResponse.fromJson(
      response.data,
      (d) => CreateOrderResponse.fromJson(d as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<List<OrderSummary>>> getOrders({String? status}) async {
    final params = <String, dynamic>{if (status != null) 'status': status};
    final response = await _client.get(ApiConfig.myOrders, queryParams: params);
    return ApiResponse.fromJson(
      response.data,
      (d) {
        final map = d as Map<String, dynamic>;
        final items = map['items'] as List? ?? [];
        return items.map((e) => OrderSummary.fromJson(e as Map<String, dynamic>)).toList();
      },
    );
  }

  Future<ApiResponse<OrderDetail>> getOrderDetail(int orderId) async {
    final response = await _client.get(ApiConfig.orderDetail(orderId));
    return ApiResponse.fromJson(response.data, (d) => OrderDetail.fromJson(d));
  }

  Future<ApiResponse> cancelOrder(int orderId, {String? reason}) async {
    final response = await _client.put(
      ApiConfig.cancelOrder(orderId),
      data: reason != null ? {'cancelReason': reason} : null,
    );
    return ApiResponse.fromJson(response.data, null);
  }

  Future<ApiResponse<TrackingResponse>> getOrderTracking(int orderId) async {
    final response = await _client.get(ApiConfig.orderTracking(orderId));
    return ApiResponse.fromJson(response.data, (d) => TrackingResponse.fromJson(d));
  }
}
