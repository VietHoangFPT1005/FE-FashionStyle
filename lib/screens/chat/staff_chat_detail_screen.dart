// ================================================================
// [CHAT SUPPORT]
// Màn hình chat chi tiết dành cho Staff/Admin
// - Nhận argument là SupportConversation từ StaffChatListScreen
// - Load lịch sử chat của customer đó
// - Kết nối SignalR, gửi tin nhắn real-time
// - Hỗ trợ gửi hình ảnh
// ================================================================

import 'package:flutter/material.dart';
import '../../utils/app_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/chat/support_message.dart';
import '../../services/service_locator.dart';
import '../../utils/helpers.dart';
import '../../widgets/common/loading_widget.dart';

/// Màn hình Staff/Admin chat với một customer cụ thể
class StaffChatDetailScreen extends StatefulWidget {
  const StaffChatDetailScreen({super.key});

  @override
  State<StaffChatDetailScreen> createState() => _StaffChatDetailScreenState();
}

class _StaffChatDetailScreenState extends State<StaffChatDetailScreen> {
  final _messageCtrl = TextEditingController();
  final _scrollCtrl  = ScrollController();
  final _picker      = ImagePicker();
  final List<SupportMessage> _messages = [];
  late SupportConversation _conversation;
  bool _isLoading    = true;
  bool _isSending    = false;
  bool _isConnected  = false;
  bool _initialized  = false;
  bool _isUploadingImage = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _conversation = ModalRoute.of(context)!.settings.arguments as SupportConversation;
      _init();
    }
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
    sl.supportChatService.markAsRead(_conversation.customerId);
  }

  Future<void> _loadHistory() async {
    try {
      final res = await sl.supportChatService
          .getCustomerHistory(_conversation.customerId);
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
          if (msg.customerId != _conversation.customerId) return;
          if (_messages.any((m) => m.id == msg.id && msg.id != 0)) return;
          setState(() => _messages.add(msg));
          _scrollToBottom();
          sl.supportChatService.markAsRead(_conversation.customerId);
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
      await sl.supportChatService.sendMessageToCustomer(
        _conversation.customerId, text);
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
        await sl.supportChatService.sendMessageToCustomer(
            _conversation.customerId, '[IMAGE]$url');
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
            CircleAvatar(
              radius: 17,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: _conversation.customerAvatar != null
                  ? NetworkImage(_conversation.customerAvatar!) : null,
              child: _conversation.customerAvatar == null
                  ? Text(_conversation.customerName.isNotEmpty
                      ? _conversation.customerName[0].toUpperCase() : 'K',
                    style: const TextStyle(fontWeight: FontWeight.bold,
                        color: Colors.black54, fontSize: 14))
                  : null,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_conversation.customerName,
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
                    Text(_isConnected ? 'Đang kết nối' : 'Đang kết nối...',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
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
                    ? Center(
                        child: Text('Chưa có tin nhắn',
                          style: TextStyle(color: Colors.grey.shade400)))
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

  Widget _buildMessageBubble(SupportMessage msg) {
    // Staff/Admin (senderRole=1,2) = bên phải (màu đen)
    // Customer (senderRole=3) = bên trái (màu teal/xanh lá)
    final isMe = msg.isFromStaff;
    final bubbleColor = isMe ? Colors.black : const Color(0xFF00897B); // teal 600

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF00897B),
              backgroundImage: msg.senderAvatar != null
                  ? NetworkImage(msg.senderAvatar!) : null,
              child: msg.senderAvatar == null
                  ? Text(msg.senderName.isNotEmpty
                      ? msg.senderName[0].toUpperCase() : 'K',
                    style: const TextStyle(fontSize: 12, color: Colors.white))
                  : null,
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
                          style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4)),
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
      child: AppNetworkImage(
        imageUrl: imageUrl,
        width: 200,
        fit: BoxFit.cover,
        placeholder: Container(
          width: 200, height: 150,
          color: Colors.grey.shade200,
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        errorWidget: Container(
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
                hintText: 'Nhắn tin cho khách hàng...',
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
                filled: true, fillColor: Colors.grey.shade50,
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
