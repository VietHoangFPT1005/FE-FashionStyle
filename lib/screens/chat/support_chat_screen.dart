// ================================================================
// [CHAT SUPPORT]
// Màn hình chat hỗ trợ dành cho Customer
// - Load lịch sử chat qua REST khi vào màn hình
// - Kết nối SignalR để nhận/gửi tin real-time
// - Hỗ trợ gửi hình ảnh
// ================================================================

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/chat/support_message.dart';
import '../../services/service_locator.dart';
import '../../utils/helpers.dart';
import '../../widgets/common/loading_widget.dart';

/// Màn hình chat Customer <-> Staff/Admin
class SupportChatScreen extends StatefulWidget {
  const SupportChatScreen({super.key});

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  final _messageCtrl  = TextEditingController();
  final _scrollCtrl   = ScrollController();
  final _picker       = ImagePicker();
  final List<SupportMessage> _messages = [];
  bool _isLoading     = true;
  bool _isSending     = false;
  bool _isConnected   = false;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    _scrollCtrl.dispose();
    sl.supportChatService.disconnect();
    super.dispose();
  }

  Future<void> _init() async {
    await _loadHistory();
    await _connectSignalR();
  }

  Future<void> _loadHistory() async {
    try {
      final res = await sl.supportChatService.getMyHistory();
      if (res.success && res.data != null) {
        setState(() => _messages.addAll(res.data!));
        _scrollToBottom();
      }
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  Future<void> _connectSignalR() async {
    final token = await sl.storage.getAccessToken();
    if (token == null) return;

    try {
      await sl.supportChatService.connect(
        accessToken: token,
        onReceiveMessage: (msg) {
          if (_messages.any((m) => m.id == msg.id && msg.id != 0)) return;
          setState(() => _messages.add(msg));
          _scrollToBottom();
        },
      );
      setState(() => _isConnected = true);
    } catch (_) {
      setState(() => _isConnected = false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageCtrl.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _messageCtrl.clear();

    try {
      await sl.supportChatService.sendMessageToSupport(text);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể gửi tin nhắn. Vui lòng thử lại.')),
        );
      }
    }
    if (mounted) setState(() => _isSending = false);
  }

  Future<void> _pickAndSendImage() async {
    final source = await _showImageSourceDialog();
    if (source == null) return;

    final XFile? picked = await _picker.pickImage(
      source: source,
      imageQuality: 75,
      maxWidth: 1200,
    );
    if (picked == null) return;

    setState(() => _isUploadingImage = true);
    try {
      final url = await sl.supportChatService.uploadChatImage(picked.path);
      if (url != null) {
        await sl.supportChatService.sendMessageToSupport('[IMAGE]$url');
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không thể tải ảnh lên. Vui lòng thử lại.')),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lỗi khi gửi hình ảnh.')),
        );
      }
    }
    if (mounted) setState(() => _isUploadingImage = false);
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Chọn từ thư viện'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Chụp ảnh'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
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
        title: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
              child: const Icon(Icons.headset_mic, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Hỗ trợ khách hàng',
                  style: GoogleFonts.cormorantGaramond(
                      fontSize: 17, fontWeight: FontWeight.w700, color: Colors.black)),
                Row(
                  children: [
                    Container(
                      width: 7, height: 7,
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        color: _isConnected ? Colors.green : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Text(
                      _isConnected ? 'Đang kết nối' : 'Đang kết nối...',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const LoadingWidget()
                : _messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (_, i) => _buildMessageBubble(_messages[i]),
                      ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.05), shape: BoxShape.circle),
              child: Icon(Icons.headset_mic_outlined, size: 40, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 20),
            Text('Xin chào!',
              style: GoogleFonts.cormorantGaramond(
                  fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('Nhắn tin cho chúng tôi nếu bạn cần hỗ trợ.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(SupportMessage msg) {
    // Customer (senderRole=3) = bên phải (màu đen)
    // Staff/Admin (senderRole=1,2) = bên trái (màu indigo)
    final isMe = msg.isFromCustomer;
    final bubbleColor = isMe ? Colors.black : const Color(0xFF3D5AFE);
    final textColor = Colors.white;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF3D5AFE),
              backgroundImage: msg.senderAvatar != null
                  ? NetworkImage(msg.senderAvatar!) : null,
              child: msg.senderAvatar == null
                  ? const Icon(Icons.support_agent, size: 16, color: Colors.white) : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(msg.senderName,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500)),
                  ),
                Container(
                  padding: msg.isImageMessage
                      ? const EdgeInsets.all(4)
                      : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: msg.isImageMessage ? Colors.transparent : bubbleColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMe ? 16 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 16),
                    ),
                    boxShadow: msg.isImageMessage ? [] : [BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 4, offset: const Offset(0, 1))],
                  ),
                  child: msg.isImageMessage
                      ? _buildImageContent(msg.imageUrl!)
                      : Text(msg.message,
                          style: TextStyle(color: textColor, fontSize: 14, height: 1.4)),
                ),
                const SizedBox(height: 3),
                Text(Helpers.formatTimeAgo(msg.createdAt),
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 10)),
              ],
            ),
          ),
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildImageContent(String imageUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: 200,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          width: 200, height: 150,
          color: Colors.grey.shade200,
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        errorWidget: (_, __, ___) => Container(
          width: 200, height: 150,
          color: Colors.grey.shade200,
          child: Icon(Icons.broken_image_outlined, color: Colors.grey.shade400, size: 40),
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        child: Row(children: [
          // Nút gửi hình ảnh
          GestureDetector(
            onTap: _isUploadingImage ? null : _pickAndSendImage,
            child: Container(
              width: 40, height: 40,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: _isUploadingImage
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : Icon(Icons.image_outlined, size: 20, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: TextField(
              controller: _messageCtrl,
              decoration: InputDecoration(
                hintText: 'Nhắn tin cho chúng tôi...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.grey.shade300)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: Colors.black)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: _isSending ? Colors.grey : Colors.black,
                shape: BoxShape.circle,
              ),
              child: _isSending
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_rounded, size: 18, color: Colors.white),
            ),
          ),
        ]),
      ),
    );
  }
}
