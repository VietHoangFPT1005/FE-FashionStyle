import '../config/api_config.dart';
import '../models/api_response.dart';
import '../models/user/user.dart';
import 'api_client.dart';

class UserService {
  final ApiClient _client;
  UserService(this._client);

  Future<ApiResponse<UserProfile>> getProfile() async {
    final response = await _client.get(ApiConfig.userProfile);
    return ApiResponse.fromJson(response.data, (d) => UserProfile.fromJson(d));
  }

  Future<ApiResponse> updateProfile(UpdateProfileRequest request) async {
    final response = await _client.put(ApiConfig.userProfile, data: request.toJson());
    return ApiResponse.fromJson(response.data, null);
  }

  Future<ApiResponse<BodyProfile>> getBodyProfile() async {
    final response = await _client.get(ApiConfig.bodyProfile);
    return ApiResponse.fromJson(response.data, (d) => BodyProfile.fromJson(d));
  }

  Future<ApiResponse> updateBodyProfile(BodyProfile profile) async {
    final response = await _client.put(ApiConfig.bodyProfile, data: profile.toJson());
    return ApiResponse.fromJson(response.data, null);
  }
}
