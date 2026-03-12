// ================================================================
// [CHAT SUPPORT - MỚI THÊM]
// Màn hình danh sách hội thoại dành cho Staff/Admin
// - Hiển thị tất cả customers đã nhắn tin
// - Chấm đỏ nếu có tin chưa đọc
// ================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_routes.dart';
import '../../models/chat/support_message.dart';
import '../../services/service_locator.dart';
import '../../utils/helpers.dart';

/// [CHAT SUPPORT - MỚI THÊM]
/// Màn hình Staff/Admin xem danh sách tất cả hội thoại với customers
class StaffChatListScreen extends StatefulWidget {
  const StaffChatListScreen({super.key});

  @override
  State<StaffChatListScreen> createState() => _StaffChatListScreenState();
}

class _StaffChatListScreenState extends State<StaffChatListScreen> {
  List<SupportConversation> _conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    setState(() => _isLoading = true);
    try {
      final res = await sl.supportChatService.getConversations();
      if (res.success && res.data != null) {
        setState(() => _conversations = res.data!);
      }
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Hỗ trợ khách hàng',
          style: GoogleFonts.cormorantGaramond(
              fontSize: 20, fontWeight: FontWeight.w700, color: Colors.black)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _loadConversations,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : _conversations.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadConversations,
                  color: Colors.black,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _conversations.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: Colors.grey.shade200),
                    itemBuilder: (_, i) => _buildConversationTile(_conversations[i]),
                  ),
                ),
    );
  }

  Widget _buildConversationTile(SupportConversation conv) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: conv.customerAvatar != null
                ? NetworkImage(conv.customerAvatar!) : null,
            child: conv.customerAvatar == null
                ? Text(conv.customerName.isNotEmpty
                    ? conv.customerName[0].toUpperCase() : 'K',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54))
                : null,
          ),
          // Badge số tin chưa đọc
          if (conv.unreadCount > 0)
            Positioned(
              right: 0, top: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                child: Text('${conv.unreadCount}',
                  style: const TextStyle(color: Colors.white, fontSize: 10,
                      fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
      title: Text(conv.customerName,
        style: TextStyle(
          fontWeight: conv.unreadCount > 0 ? FontWeight.w700 : FontWeight.w500,
          fontSize: 15,
        )),
      subtitle: Text(conv.lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 13,
          color: conv.unreadCount > 0 ? Colors.black87 : Colors.grey.shade500,
          fontWeight: conv.unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
        )),
      trailing: Text(Helpers.formatTimeAgo(conv.lastMessageAt),
        style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
      onTap: () async {
        // Chuyển sang màn hình chat chi tiết
        await Navigator.pushNamed(
          context,
          AppRoutes.staffChatDetail,
          arguments: conv,
        );
        // Khi quay lại, refresh danh sách (unread có thể đã thay đổi)
        _loadConversations();
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('Chưa có hội thoại nào',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
        ],
      ),
    );
  }
}
