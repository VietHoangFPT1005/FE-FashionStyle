import '../config/api_config.dart';
import '../models/api_response.dart';
import '../models/address/address.dart';
import 'api_client.dart';

class AddressService {
  final ApiClient _client;
  AddressService(this._client);

  Future<ApiResponse<List<Address>>> getAddresses() async {
    final response = await _client.get(ApiConfig.addresses);
    return ApiResponse.fromJson(
      response.data,
      (d) => (d as List).map((e) => Address.fromJson(e)).toList(),
    );
  }

  Future<ApiResponse> createAddress(CreateAddressRequest request) async {
    final response = await _client.post(ApiConfig.addresses, data: request.toJson());
    return ApiResponse.fromJson(response.data, null);
  }

  Future<ApiResponse> updateAddress(int addressId, CreateAddressRequest request) async {
    final response = await _client.put(ApiConfig.addressById(addressId), data: request.toJson());
    return ApiResponse.fromJson(response.data, null);
  }

  Future<ApiResponse> deleteAddress(int addressId) async {
    final response = await _client.delete(ApiConfig.addressById(addressId));
    return ApiResponse.fromJson(response.data, null);
  }

  Future<ApiResponse> setDefaultAddress(int addressId) async {
    final response = await _client.put(ApiConfig.setDefaultAddress(addressId));
    return ApiResponse.fromJson(response.data, null);
  }
}
