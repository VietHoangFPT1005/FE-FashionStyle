import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_image.dart';
import '../../config/app_routes.dart';
import '../../models/category/category.dart';

import '../../services/service_locator.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/error_widget.dart';
import '../../widgets/common/empty_widget.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  List<Category> _categories = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final res = await sl.categoryService.getCategories();
      if (res.success && res.data != null) {
        setState(() => _categories = res.data!);
      }
    } catch (e) {
      setState(() => _error = e.toString());
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('COLLECTIONS'),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const LoadingWidget();
    if (_error != null) return AppErrorWidget(message: _error!, onRetry: _loadCategories);
    if (_categories.isEmpty) return const EmptyWidget(icon: Icons.category_outlined, message: 'No collections available');

    return RefreshIndicator(
      onRefresh: _loadCategories,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(height: 4), // Small gap between large images
        itemBuilder: (_, i) => _buildCategoryCard(_categories[i]),
      ),
    );
  }

  Widget _buildCategoryCard(Category category) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.productList, arguments: {
        'categoryId': category.categoryId,
        'categoryName': category.name,
      }),
      child: SizedBox(
        height: 200, // Large banner-like category card
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image
            category.imageUrl != null
                ? AppNetworkImage(
                    imageUrl: category.imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: Container(color: Colors.grey.shade100),
                    errorWidget: Container(color: Colors.grey.shade100, child: const Icon(Icons.image, color: Colors.grey)),
                  )
                : Container(color: Colors.grey.shade100, child: const Icon(Icons.category, color: Colors.grey)),
            
            // Dark Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withOpacity(0.0), Colors.black.withOpacity(0.5)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            
            // Text Content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    category.name.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cormorantGaramond(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${category.productCount} ITEMS',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
