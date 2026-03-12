import '../config/api_config.dart';
import '../models/api_response.dart';
import 'api_client.dart';

class ShipperService {
  final ApiClient _client;
  ShipperService(this._client);

  Future<ApiResponse> getShipperOrders({String? status}) async {
    final params = <String, dynamic>{if (status != null) 'status': status};
    final response = await _client.get(ApiConfig.shipperOrders, queryParams: params);
    return ApiResponse.fromJson(response.data, null);
  }

  Future<ApiResponse> pickupOrder(int orderId, {String? trackingNumber}) async {
    final response = await _client.put(ApiConfig.shipperPickup(orderId),
        data: trackingNumber != null ? {'trackingNumber': trackingNumber} : null);
    return ApiResponse.fromJson(response.data, null);
  }

  Future<ApiResponse> deliverOrder(int orderId) async {
    final response = await _client.put(ApiConfig.shipperDeliver(orderId));
    return ApiResponse.fromJson(response.data, null);
  }

  Future<ApiResponse> deliveryFailed(int orderId, {String? reason}) async {
    final response = await _client.put(
      ApiConfig.shipperFail(orderId),
      data: reason != null ? {'reason': reason} : null,
    );
    return ApiResponse.fromJson(response.data, null);
  }

  Future<ApiResponse> updateLocation({
    required int orderId,
    required double latitude,
    required double longitude,
    double? accuracy,
    double? speed,
    double? heading,
  }) async {
    final response = await _client.post(ApiConfig.shipperLocation, data: {
      'orderId': orderId,
      'latitude': latitude,
      'longitude': longitude,
      if (accuracy != null) 'accuracy': accuracy,
      if (speed != null) 'speed': speed,
      if (heading != null) 'heading': heading,
    });
    return ApiResponse.fromJson(response.data, null);
  }
}
