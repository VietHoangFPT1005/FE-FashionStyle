import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/review/review.dart';
import '../../providers/auth_provider.dart';
import '../../services/service_locator.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/error_widget.dart';
import '../../widgets/common/empty_widget.dart';
import '../../utils/helpers.dart';

class ReviewScreen extends StatefulWidget {
  final int productId;
  const ReviewScreen({super.key, required this.productId});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  List<Review> _reviews = [];
  bool _isLoading = true;
  String? _error;
  int? _filterRating;

  // Review của user hiện tại (nếu đã review rồi)
  Review? _myReview;

  // userId lấy từ AuthProvider
  int _currentUserId = 0;

  @override
  void initState() {
    super.initState();
    _currentUserId = context.read<AuthProvider>().user?.userId ?? 0;
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final res = await sl.productService.getReviews(widget.productId);
      if (res.success && res.data != null) {
        final reviews = res.data as List<Review>;
        // Tìm review của user hiện tại
        Review? mine;
        if (_currentUserId > 0) {
          try {
            mine = reviews.firstWhere((r) => r.userId == _currentUserId);
          } catch (_) {
            mine = null;
          }
        }
        setState(() {
          _reviews = reviews;
          _myReview = mine;
        });
      }
    } catch (e) {
      setState(() => _error = e.toString());
    }
    setState(() => _isLoading = false);
  }

  List<Review> get _filteredReviews {
    if (_filterRating == null) return _reviews;
    return _reviews.where((r) => r.rating == _filterRating).toList();
  }

  double get _averageRating {
    if (_reviews.isEmpty) return 0;
    return _reviews.map((r) => r.rating).reduce((a, b) => a + b) /
        _reviews.length;
  }

  // ─── Viết đánh giá mới ───────────────────────────────────────────────────
  void _showWriteReview() {
    int rating = 5;
    final commentCtrl = TextEditingController();
    _showReviewBottomSheet(
      title: 'Viết đánh giá',
      initialRating: 5,
      initialComment: '',
      commentCtrl: commentCtrl,
      onSubmit: () async {
        final req = CreateReviewRequest(
          rating: rating,
          comment: commentCtrl.text.trim().isNotEmpty
              ? commentCtrl.text.trim()
              : null,
        );
        final res =
            await sl.reviewService.createReview(widget.productId, req);
        if (res.success) {
          if (context.mounted) Navigator.pop(context);
          Helpers.showSnackBar(context, 'Đã gửi đánh giá!');
          _loadReviews();
        } else {
          // Xử lý lỗi cụ thể từ BE
          final msg = res.message ?? 'Gửi thất bại';
          if (msg.contains('not purchased') ||
              msg.contains('not been delivered')) {
            Helpers.showSnackBar(
              context,
              'Bạn cần mua và nhận sản phẩm này trước khi đánh giá',
              isError: true,
            );
          } else if (msg.contains('already reviewed')) {
            Helpers.showSnackBar(
              context,
              'Bạn đã đánh giá sản phẩm này rồi',
              isError: true,
            );
          } else {
            Helpers.showSnackBar(context, msg, isError: true);
          }
        }
      },
      onRatingUpdate: (v) => rating = v.toInt(),
      submitLabel: 'GỬI ĐÁNH GIÁ',
    );
  }

  // ─── Sửa đánh giá ────────────────────────────────────────────────────────
  void _showEditReview() {
    if (_myReview == null) return;
    int rating = _myReview!.rating;
    final commentCtrl =
        TextEditingController(text: _myReview!.comment ?? '');
    _showReviewBottomSheet(
      title: 'Sửa đánh giá',
      initialRating: rating.toDouble(),
      initialComment: _myReview!.comment ?? '',
      commentCtrl: commentCtrl,
      onSubmit: () async {
        final req = UpdateReviewRequest(
          rating: rating,
          comment: commentCtrl.text.trim().isNotEmpty
              ? commentCtrl.text.trim()
              : null,
        );
        final res = await sl.reviewService.updateReview(
          widget.productId,
          _myReview!.reviewId,
          req,
        );
        if (res.success) {
          if (context.mounted) Navigator.pop(context);
          Helpers.showSnackBar(context, 'Đã cập nhật đánh giá!');
          _loadReviews();
        } else {
          Helpers.showSnackBar(
            context,
            res.message ?? 'Cập nhật thất bại',
            isError: true,
          );
        }
      },
      onRatingUpdate: (v) => rating = v.toInt(),
      submitLabel: 'CẬP NHẬT',
    );
  }

  // ─── Xóa đánh giá ────────────────────────────────────────────────────────
  Future<void> _deleteReview() async {
    if (_myReview == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: const RoundedRectangleBorder(),
        title: Text('Xoá đánh giá',
            style: GoogleFonts.cormorantGaramond(
                fontSize: 18, fontWeight: FontWeight.w700)),
        content: const Text('Bạn có chắc muốn xoá đánh giá này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Huỷ',
                style: TextStyle(color: Colors.grey.shade600)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xoá',
                style: TextStyle(
                    color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final res = await sl.reviewService
        .deleteReview(widget.productId, _myReview!.reviewId);
    if (res.success) {
      Helpers.showSnackBar(context, 'Đã xoá đánh giá');
      _loadReviews();
    } else {
      Helpers.showSnackBar(context, res.message ?? 'Xoá thất bại',
          isError: true);
    }
  }

  // ─── Bottom sheet dùng chung cho Write & Edit ────────────────────────────
  void _showReviewBottomSheet({
    required String title,
    required double initialRating,
    required String initialComment,
    required TextEditingController commentCtrl,
    required Future<void> Function() onSubmit,
    required void Function(double) onRatingUpdate,
    required String submitLabel,
  }) {
    bool submitting = false;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Text(title,
                  style: GoogleFonts.cormorantGaramond(
                      fontWeight: FontWeight.bold, fontSize: 20)),
              const SizedBox(height: 20),
              RatingBar.builder(
                initialRating: initialRating,
                minRating: 1,
                maxRating: 5,
                itemCount: 5,
                itemSize: 40,
                itemBuilder: (_, __) =>
                    const Icon(Icons.star, color: Colors.amber),
                onRatingUpdate: onRatingUpdate,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: commentCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Chia sẻ trải nghiệm của bạn...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide:
                          BorderSide(color: Colors.grey.shade300)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(color: Colors.black)),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: const RoundedRectangleBorder(),
                  ),
                  onPressed: submitting
                      ? null
                      : () async {
                          setModalState(() => submitting = true);
                          await onSubmit();
                          setModalState(() => submitting = false);
                        },
                  child: submitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text(submitLabel,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Đánh giá & Nhận xét',
          style: GoogleFonts.cormorantGaramond(
              color: Colors.black,
              fontSize: 22,
              fontWeight: FontWeight.w700),
        ),
        actions: [
          // Chỉ hiện nút viết đánh giá khi CHƯA review
          if (_myReview == null && !_isLoading)
            IconButton(
              icon: const Icon(Icons.rate_review_outlined,
                  color: Colors.black),
              onPressed: _showWriteReview,
              tooltip: 'Viết đánh giá',
            ),
          // Đã review → hiện nút sửa
          if (_myReview != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.black),
              onPressed: _showEditReview,
              tooltip: 'Sửa đánh giá của bạn',
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const LoadingWidget();
    if (_error != null)
      return AppErrorWidget(message: _error!, onRetry: _loadReviews);

    return Column(
      children: [
        _buildSummaryHeader(),
        // Banner đánh giá của tôi (nếu có)
        if (_myReview != null) _buildMyReviewBanner(),
        _buildFilterChips(),
        Expanded(
          child: _filteredReviews.isEmpty
              ? EmptyWidget(
                  icon: Icons.rate_review_outlined,
                  message: 'Chưa có đánh giá nào',
                  actionText: _myReview == null
                      ? 'Viết đánh giá đầu tiên'
                      : null,
                  onAction:
                      _myReview == null ? _showWriteReview : null,
                )
              : RefreshIndicator(
                  color: Colors.black,
                  onRefresh: _loadReviews,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredReviews.length,
                    separatorBuilder: (_, __) =>
                        Divider(color: Colors.grey.shade100, height: 1),
                    itemBuilder: (_, i) =>
                        _buildReviewItem(_filteredReviews[i]),
                  ),
                ),
        ),
      ],
    );
  }

  // Banner nhỏ "Đánh giá của bạn" với nút Sửa/Xóa
  Widget _buildMyReviewBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Đánh giá của bạn',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13),
                ),
                Row(
                  children: List.generate(
                    5,
                    (i) => Icon(
                      i < _myReview!.rating
                          ? Icons.star
                          : Icons.star_border,
                      color: Colors.amber,
                      size: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _showEditReview,
            style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
            child: const Text('Sửa',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: _deleteReview,
            style: TextButton.styleFrom(
                foregroundColor: Colors.red.shade300,
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
            child: const Text('Xoá',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.grey.shade50,
      child: Row(
        children: [
          Column(
            children: [
              Text(_averageRating.toStringAsFixed(1),
                  style: const TextStyle(
                      fontSize: 40, fontWeight: FontWeight.bold)),
              RatingBarIndicator(
                rating: _averageRating,
                itemCount: 5,
                itemSize: 18,
                itemBuilder: (_, __) =>
                    const Icon(Icons.star, color: Colors.amber),
              ),
              const SizedBox(height: 6),
              Text('${_reviews.length} đánh giá',
                  style: TextStyle(
                      color: Colors.grey.shade600, fontSize: 12)),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              children: List.generate(5, (i) {
                final star = 5 - i;
                final count =
                    _reviews.where((r) => r.rating == star).length;
                final ratio =
                    _reviews.isEmpty ? 0.0 : count / _reviews.length;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Text('$star',
                          style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 2),
                      const Icon(Icons.star, size: 12, color: Colors.amber),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: ratio,
                            minHeight: 6,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.amber),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 20,
                        child: Text('$count',
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey),
                            textAlign: TextAlign.end),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 48,
      color: Colors.white,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: FilterChip(
              label: const Text('Tất cả'),
              selected: _filterRating == null,
              selectedColor: Colors.black,
              labelStyle: TextStyle(
                  color: _filterRating == null
                      ? Colors.white
                      : Colors.black87,
                  fontSize: 12),
              onSelected: (_) =>
                  setState(() => _filterRating = null),
            ),
          ),
          ...List.generate(5, (i) {
            final star = 5 - i;
            return Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: FilterChip(
                label: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('$star '),
                  const Icon(Icons.star, size: 13, color: Colors.amber),
                ]),
                selected: _filterRating == star,
                selectedColor: Colors.black,
                labelStyle: TextStyle(
                    color: _filterRating == star
                        ? Colors.white
                        : Colors.black87,
                    fontSize: 12),
                onSelected: (_) => setState(() =>
                    _filterRating = _filterRating == star ? null : star),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildReviewItem(Review review) {
    final isMyReview =
        _currentUserId > 0 && review.userId == _currentUserId;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: review.userAvatar != null
                    ? CachedNetworkImageProvider(review.userAvatar!)
                    : null,
                child: review.userAvatar == null
                    ? Text(
                        (review.userName ?? 'U')[0].toUpperCase(),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black54))
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          review.userName ?? 'Người dùng',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        // Tag "Bạn" nếu là review của mình
                        if (isMyReview) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('Bạn',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    RatingBarIndicator(
                      rating: review.rating.toDouble(),
                      itemCount: 5,
                      itemSize: 14,
                      itemBuilder: (_, __) =>
                          const Icon(Icons.star, color: Colors.amber),
                    ),
                  ],
                ),
              ),
              if (review.createdAt != null)
                Text(
                  Helpers.formatTimeAgo(review.createdAt!),
                  style: TextStyle(
                      color: Colors.grey.shade500, fontSize: 11)),
            ],
          ),
          if (review.comment != null) ...[
            const SizedBox(height: 10),
            Text(review.comment!,
                style: const TextStyle(
                    fontSize: 14, height: 1.5, color: Colors.black87)),
          ],
          if (review.reviewImageUrl != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: CachedNetworkImage(
                  imageUrl: review.reviewImageUrl!,
                  height: 160,
                  width: 160,
                  fit: BoxFit.cover),
            ),
          ],
        ],
      ),
    );
  }
}
