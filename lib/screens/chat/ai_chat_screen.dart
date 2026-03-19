import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/chat/chat_message.dart';
import '../../models/product/product_detail.dart';
import '../../providers/cart_provider.dart';
import '../../services/service_locator.dart';
import '../../utils/helpers.dart';
import '../../utils/app_image.dart';
import '../cart/cart_screen.dart';
import '../product/product_detail_screen.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _messageCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  List<ChatMessage> _messages = [];
  String? _sessionId;
  bool _isSending = false;
  bool _isLoadingSessions = false;

  @override
  void initState() {
    super.initState();
    // Load cart count on open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CartProvider>().loadCart();
    });
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
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

  Future<void> _showAddToCartSheet(ChatSuggestedProduct product) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.black)),
    );

    List<ProductVariant> variants = [];
    try {
      final res = await sl.productService.getVariants(product.productId);
      if (res.success && res.data != null) variants = res.data!;
    } catch (_) {}

    if (!mounted) return;
    Navigator.pop(context); // close loading

    if (variants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sản phẩm hiện không có hàng')),
      );
      return;
    }

    // Get distinct sizes and colors
    final sizes = variants.map((v) => v.size).whereType<String>().toSet().toList();
    final allColors = variants.map((v) => v.color).whereType<String>().toSet().toList();

    // Pre-select recommended size
    String? selectedSize = sizes.contains(product.recommendedSize)
        ? product.recommendedSize
        : (sizes.isNotEmpty ? sizes.first : null);
    String? selectedColor = allColors.isNotEmpty ? allColors.first : null;
    int quantity = 1;

    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          // Filter colors available for selected size
          final colorsForSize = variants
              .where((v) => selectedSize == null || v.size == selectedSize)
              .map((v) => v.color)
              .whereType<String>()
              .toSet()
              .toList();

          // Fix selected color if not in available colors
          if (selectedColor != null && !colorsForSize.contains(selectedColor)) {
            selectedColor = colorsForSize.isNotEmpty ? colorsForSize.first : null;
          }

          // Find matching variant
          final matchingVariant = variants.firstWhere(
            (v) => v.size == selectedSize && v.color == selectedColor,
            orElse: () => variants.firstWhere(
              (v) => v.size == selectedSize,
              orElse: () => variants.first,
            ),
          );
          final inStock = matchingVariant.isInStock;

          return Padding(
            padding: EdgeInsets.only(
              left: 16, right: 16, top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 36, height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                // Product header
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: product.primaryImage != null
                          ? AppNetworkImage(
                              imageUrl: product.primaryImage!,
                              width: 64, height: 64, fit: BoxFit.cover)
                          : Container(
                              width: 64, height: 64,
                              color: Colors.grey.shade100,
                              child: const Icon(Icons.image_outlined, color: Colors.grey)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(product.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 14),
                              maxLines: 2, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Text(
                            Helpers.formatCurrency(product.salePrice != null &&
                                    product.salePrice! < product.price
                                ? product.salePrice!
                                : product.price),
                            style: TextStyle(
                                color: Colors.red.shade600,
                                fontWeight: FontWeight.bold,
                                fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 0),
                const SizedBox(height: 14),

                // Size selection
                if (sizes.isNotEmpty) ...[
                  Row(
                    children: [
                      const Text('Kích thước:',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      if (product.recommendedSize != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                              color: Colors.amber.shade100,
                              borderRadius: BorderRadius.circular(4)),
                          child: Text('AI gợi ý: ${product.recommendedSize}',
                              style: TextStyle(
                                  fontSize: 10, color: Colors.amber.shade800)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: sizes.map((size) {
                      final isSelected = selectedSize == size;
                      return GestureDetector(
                        onTap: () => setSheetState(() => selectedSize = size),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.black : Colors.white,
                            border: Border.all(
                                color: isSelected ? Colors.black : Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(size,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: isSelected ? Colors.white : Colors.black87)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                ],

                // Color selection
                if (colorsForSize.isNotEmpty) ...[
                  const Text('Màu sắc:',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: colorsForSize.map((color) {
                      final isSelected = selectedColor == color;
                      return GestureDetector(
                        onTap: () => setSheetState(() => selectedColor = color),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.black : Colors.white,
                            border: Border.all(
                                color: isSelected ? Colors.black : Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(color,
                              style: TextStyle(
                                  fontSize: 13,
                                  color: isSelected ? Colors.white : Colors.black87)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                ],

                // Quantity
                Row(
                  children: [
                    const Text('Số lượng:',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const Spacer(),
                    Container(
                      decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove, size: 18),
                            onPressed: quantity > 1
                                ? () => setSheetState(() => quantity--)
                                : null,
                            padding: const EdgeInsets.all(6),
                            constraints: const BoxConstraints(),
                          ),
                          SizedBox(
                            width: 32,
                            child: Text('$quantity',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 15)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add, size: 18),
                            onPressed: () => setSheetState(() => quantity++),
                            padding: const EdgeInsets.all(6),
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Stock status
                if (!inStock)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            size: 16, color: Colors.orange.shade700),
                        const SizedBox(width: 6),
                        Text('Kết hợp size/màu này đã hết hàng',
                            style: TextStyle(
                                fontSize: 12, color: Colors.orange.shade700)),
                      ],
                    ),
                  ),

                // Add to cart button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: inStock
                        ? () async {
                            Navigator.pop(ctx);
                            final cartProvider = context.read<CartProvider>();
                            final success = await cartProvider.addToCart(
                              matchingVariant.variantId,
                              quantity: quantity,
                            );
                            if (!mounted) return;
                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Row(
                                    children: [
                                      Icon(Icons.check_circle,
                                          color: Colors.white, size: 18),
                                      SizedBox(width: 8),
                                      Text('Đã thêm vào giỏ hàng!'),
                                    ],
                                  ),
                                  backgroundColor: Colors.black87,
                                  duration: const Duration(seconds: 3),
                                  action: SnackBarAction(
                                    label: 'Xem giỏ hàng',
                                    textColor: Colors.amber,
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => const CartScreen()),
                                    ),
                                  ),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Không thể thêm vào giỏ hàng'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        : null,
                    icon: const Icon(Icons.shopping_cart_outlined, size: 20),
                    label: const Text('Thêm vào giỏ hàng',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _sendMessage({String? overrideText}) async {
    final text = (overrideText ?? _messageCtrl.text).trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _messages.add(ChatMessage(role: 'user', content: text, timestamp: DateTime.now()));
      _isSending = true;
    });
    _messageCtrl.clear();
    _scrollToBottom();

    try {
      final request = SendMessageRequest(message: text, sessionId: _sessionId);
      final res = await sl.chatService.sendMessage(request);
      if (res.success && res.data != null) {
        final data = res.data as Map<String, dynamic>;
        _sessionId ??= data['sessionId'];
        final replyText = (data['content'] ?? data['reply'] ?? data['message'] ?? '').toString();

        // Parse suggested products nếu có
        List<ChatSuggestedProduct>? suggested;
        if (data['suggestedProducts'] != null) {
          suggested = (data['suggestedProducts'] as List)
              .map((e) => ChatSuggestedProduct.fromJson(e as Map<String, dynamic>))
              .toList();
        }

        setState(() => _messages.add(ChatMessage(
          role: 'assistant',
          content: replyText,
          timestamp: DateTime.now(),
          suggestedProducts: suggested,
        )));
      } else {
        setState(() => _messages.add(ChatMessage(
          role: 'assistant',
          content: 'Xin lỗi, tôi không thể trả lời lúc này. Vui lòng thử lại sau nhé! 🙏',
          timestamp: DateTime.now(),
        )));
      }
    } catch (_) {
      setState(() => _messages.add(ChatMessage(
        role: 'assistant',
        content: 'Đã xảy ra lỗi kết nối. Bạn hãy kiểm tra mạng và thử lại nhé!',
        timestamp: DateTime.now(),
      )));
    }
    setState(() => _isSending = false);
    _scrollToBottom();
  }

  Future<void> _loadSession(String sessionId) async {
    try {
      final res = await sl.chatService.getSessionMessages(sessionId);
      if (res.success && res.data != null) {
        setState(() {
          _messages = res.data!;
          _sessionId = sessionId;
        });
        _scrollToBottom();
      }
    } catch (_) {}
  }

  void _showSessionHistory() async {
    setState(() => _isLoadingSessions = true);
    try {
      final res = await sl.chatService.getSessions();
      if (!mounted) return;
      final sessions = res.success && res.data != null ? res.data! : <ChatSession>[];
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (ctx) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 36, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text('Lịch sử hội thoại',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      setState(() { _messages = []; _sessionId = null; });
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Mới'),
                  ),
                ],
              ),
            ),
            const Divider(height: 0),
            if (sessions.isEmpty)
              const Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('Chưa có cuộc hội thoại nào',
                      style: TextStyle(color: Colors.grey)))
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: sessions.length > 10 ? 10 : sessions.length,
                  separatorBuilder: (_, __) => const Divider(height: 0),
                  itemBuilder: (_, i) {
                    final s = sessions[i];
                    final subtitle = s.title != null && s.title!.isNotEmpty
                        ? s.title!
                        : 'Hội thoại ${i + 1}';
                    return ListTile(
                      leading: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.07),
                            shape: BoxShape.circle),
                        child: const Icon(Icons.chat_bubble_outline,
                            size: 18, color: Colors.black54),
                      ),
                      title: Text(subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                      subtitle: s.lastMessageAt != null
                          ? Text(Helpers.formatTimeAgo(s.lastMessageAt!),
                              style: const TextStyle(fontSize: 11))
                          : null,
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                        onPressed: () async {
                          await sl.chatService.deleteSession(s.sessionId);
                          Navigator.pop(ctx);
                          if (s.sessionId == _sessionId) {
                            setState(() { _messages = []; _sessionId = null; });
                          }
                        },
                      ),
                      onTap: () { Navigator.pop(ctx); _loadSession(s.sessionId); },
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
          ],
        ),
      );
    } catch (_) {}
    setState(() => _isLoadingSessions = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
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
              child: const Icon(Icons.smart_toy_outlined, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Trợ lý Fashion AI',
                    style: GoogleFonts.cormorantGaramond(
                        color: Colors.black, fontSize: 17, fontWeight: FontWeight.w700)),
                Row(
                  children: [
                    Container(
                        width: 6, height: 6,
                        decoration: const BoxDecoration(
                            color: Colors.green, shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Text('Đang hoạt động',
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Cart button with badge
          Consumer<CartProvider>(
            builder: (_, cart, __) {
              final count = cart.itemCount;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined, color: Colors.black),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CartScreen()),
                    ),
                    tooltip: 'Giỏ hàng',
                  ),
                  if (count > 0)
                    Positioned(
                      right: 6, top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                            color: Colors.red, shape: BoxShape.circle),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          count > 99 ? '99+' : '$count',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: _isLoadingSessions
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                : const Icon(Icons.history, color: Colors.black),
            onPressed: _showSessionHistory,
            tooltip: 'Lịch sử',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    itemCount: _messages.length + (_isSending ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (i >= _messages.length) return _buildTypingIndicator();
                      return _buildMessageBubble(_messages[i]);
                    },
                  ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 20),
        Center(
          child: Column(
            children: [
              Container(
                width: 88, height: 88,
                decoration: BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 16, offset: const Offset(0, 4))]),
                child: const Icon(Icons.smart_toy_outlined, size: 44, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Text('Xin chào! Tôi là Fashion AI',
                  style: GoogleFonts.cormorantGaramond(
                      fontSize: 24, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text('Chuyên gia tư vấn thời trang BigSize của bạn',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(
                  color: Colors.black.withOpacity(0.05), blurRadius: 8)]),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tôi có thể giúp bạn:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 10),
              _buildFeatureRow(Icons.checkroom, 'Gợi ý outfit phù hợp dáng người'),
              _buildFeatureRow(Icons.straighten, 'Tư vấn size chính xác theo số đo'),
              _buildFeatureRow(Icons.palette, 'Phối màu sắc & phong cách'),
              _buildFeatureRow(Icons.star_outline, 'Giới thiệu sản phẩm đang bán tốt'),
              _buildFeatureRow(Icons.trending_up, 'Xu hướng thời trang mới nhất'),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text('Câu hỏi gợi ý:',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: [
            _buildSuggestionChip('👗 Gợi ý outfit đi làm'),
            _buildSuggestionChip('📏 Tư vấn size cho tôi'),
            _buildSuggestionChip('🎨 Cách phối màu quần áo'),
            _buildSuggestionChip('🛍️ Sản phẩm đang hot'),
            _buildSuggestionChip('📐 Cách đo số đo chuẩn'),
            _buildSuggestionChip('👠 Xu hướng 2025'),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.black54),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 13, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return ActionChip(
      label: Text(text, style: const TextStyle(fontSize: 12)),
      backgroundColor: Colors.white,
      side: BorderSide(color: Colors.grey.shade300),
      onPressed: () => _sendMessage(overrideText: text),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final isUser = msg.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser) ...[
                Container(
                  width: 30, height: 30,
                  decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
                  child: const Icon(Icons.smart_toy_outlined, size: 15, color: Colors.white),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Column(
                  crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isUser ? Colors.black : Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(18),
                          topRight: const Radius.circular(18),
                          bottomLeft: Radius.circular(isUser ? 18 : 4),
                          bottomRight: Radius.circular(isUser ? 4 : 18),
                        ),
                        boxShadow: [BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 4, offset: const Offset(0, 1))],
                      ),
                      child: Text(
                        msg.content.replaceAll(RegExp(r'\[ID:\d+\]'), '').trim(),
                        style: TextStyle(
                            color: isUser ? Colors.white : Colors.black87,
                            height: 1.5, fontSize: 14),
                      ),
                    ),
                    if (msg.timestamp != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          Helpers.formatTimeAgo(msg.timestamp!),
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
                        ),
                      ),
                  ],
                ),
              ),
              if (isUser) const SizedBox(width: 8),
            ],
          ),
          // Suggested products carousel
          if (!isUser &&
              msg.suggestedProducts != null &&
              msg.suggestedProducts!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 38),
              child: _buildSuggestedProducts(msg.suggestedProducts!),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSuggestedProducts(List<ChatSuggestedProduct> products) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome, size: 13, color: Colors.amber),
              const SizedBox(width: 4),
              Text(
                'Sản phẩm phù hợp với bạn',
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        ...products.map((p) => _buildProductCard(p)),
      ],
    );
  }

  Widget _buildProductCard(ChatSuggestedProduct product) {
    final hasDiscount = product.salePrice != null && product.salePrice! < product.price;
    final displayPrice = hasDiscount ? product.salePrice! : product.price;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailScreen(productId: product.productId),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.07),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
              child: product.primaryImage != null && product.primaryImage!.isNotEmpty
                  ? AppNetworkImage(
                      imageUrl: product.primaryImage!,
                      width: 110, height: 130, fit: BoxFit.cover,
                      errorWidget: _imagePlaceholder(110, 130),
                    )
                  : _imagePlaceholder(110, 130),
            ),
            // Product details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // Recommended size badge
                    if (product.recommendedSize != null) ...[
                      Row(
                        children: [
                          const Icon(Icons.straighten, size: 12, color: Colors.black54),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(6)),
                            child: Text(
                              'Size phù hợp: ${product.recommendedSize}',
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                    ],
                    // Price row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          Helpers.formatCurrency(displayPrice),
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: hasDiscount ? Colors.red.shade600 : Colors.black),
                        ),
                        if (hasDiscount) ...[
                          const SizedBox(width: 6),
                          Text(
                            Helpers.formatCurrency(product.price),
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade400,
                                decoration: TextDecoration.lineThrough),
                          ),
                        ],
                      ],
                    ),
                    if (hasDiscount) ...[
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(4)),
                        child: Text(
                          'Giảm ${(((product.price - product.salePrice!) / product.price) * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                              fontSize: 10,
                              color: Colors.red.shade600,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    // Action buttons
                    Row(
                      children: [
                        // View detail
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ProductDetailScreen(productId: product.productId),
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              side: const BorderSide(color: Colors.black54),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Chi tiết',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w500)),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Add to cart
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _showAddToCartSheet(product),
                            icon: const Icon(Icons.add_shopping_cart, size: 13),
                            label: const Text('Thêm giỏ',
                                style: TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w600)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder(double width, double height) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade100,
      child: const Center(
          child: Icon(Icons.image_outlined, color: Colors.grey, size: 32)),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 30, height: 30,
            decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
            child: const Icon(Icons.smart_toy_outlined, size: 15, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4)
                ]),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                3,
                (i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Container(
                      width: 7, height: 7,
                      decoration: BoxDecoration(
                          color: Colors.grey.shade400, shape: BoxShape.circle)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8, offset: const Offset(0, -2))
        ],
      ),
      child: SafeArea(
        child: Row(children: [
          Expanded(
            child: TextField(
              controller: _messageCtrl,
              decoration: InputDecoration(
                hintText: 'Hỏi về thời trang, size, phối đồ...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.grey.shade300)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: Colors.black, width: 1.5)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
            onTap: _isSending ? null : _sendMessage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44, height: 44,
              decoration: BoxDecoration(
                  color: _isSending ? Colors.grey.shade400 : Colors.black,
                  shape: BoxShape.circle),
              child: _isSending
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_rounded, size: 20, color: Colors.white),
            ),
          ),
        ]),
      ),
    );
  }
}
