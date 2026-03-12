import '../config/api_config.dart';
import '../models/api_response.dart';
import '../models/chat/chat_message.dart';
import 'api_client.dart';

class ChatService {
  final ApiClient _client;
  ChatService(this._client);

  Future<ApiResponse> sendMessage(SendMessageRequest request) async {
    final response = await _client.post(ApiConfig.chatAi, data: request.toJson());
    return ApiResponse.fromJson(response.data, null);
  }

  Future<ApiResponse<List<ChatSession>>> getSessions() async {
    final response = await _client.get(ApiConfig.chatSessions);
    return ApiResponse.fromJson(
      response.data,
      (d) => (d as List).map((e) => ChatSession.fromJson(e)).toList(),
    );
  }

  Future<ApiResponse<List<ChatMessage>>> getSessionMessages(String sessionId) async {
    final response = await _client.get(ApiConfig.chatSessionById(sessionId));
    return ApiResponse.fromJson(
      response.data,
      // BE trả về { sessionId, messages: [...] } không phải List trực tiếp
      (d) {
        final map = d as Map<String, dynamic>;
        final list = map['messages'] as List? ?? [];
        return list.map((e) => ChatMessage.fromJson(e as Map<String, dynamic>)).toList();
      },
    );
  }

  Future<ApiResponse> deleteSession(String sessionId) async {
    final response = await _client.delete(ApiConfig.chatSessionById(sessionId));
    return ApiResponse.fromJson(response.data, null);
  }
}
