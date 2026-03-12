import '../config/api_config.dart';
import '../models/api_response.dart';
import '../models/voucher/voucher.dart';
import 'api_client.dart';

class VoucherService {
  final ApiClient _client;
  VoucherService(this._client);

  Future<ApiResponse<List<Voucher>>> getAvailableVouchers() async {
    final response = await _client.get(ApiConfig.vouchers);
    return ApiResponse.fromJson(
      response.data,
      (d) => (d as List).map((e) => Voucher.fromJson(e)).toList(),
    );
  }

  Future<ApiResponse> validateVoucher(ValidateVoucherRequest request) async {
    final response = await _client.post(ApiConfig.validateVoucher, data: request.toJson());
    return ApiResponse.fromJson(response.data, null);
  }
}
