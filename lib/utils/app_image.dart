import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Custom cache manager: cache 30 ngày, tối đa 500 ảnh
class AppCacheManager {
  static const key = 'fashionStyleImageCache';

  static CacheManager get instance => CacheManager(
        Config(
          key,
          stalePeriod: const Duration(days: 30),
          maxNrOfCacheObjects: 500,
          repo: JsonCacheInfoRepository(databaseName: key),
          fileService: HttpFileService(),
        ),
      );
}

/// Tối ưu Cloudinary URL: thêm transformation để giảm kích thước ảnh
String optimizeImageUrl(String url, {int width = 400, int height = 400}) {
  if (url.contains('res.cloudinary.com') && url.contains('/upload/')) {
    // Chèn transformation vào sau /upload/
    final transform = 'c_fill,w_$width,h_$height,q_auto,f_auto';
    return url.replaceFirst('/upload/', '/upload/$transform/');
  }
  // Unsplash: đã có params, thay thế w= nếu có
  if (url.contains('images.unsplash.com')) {
    final uri = Uri.parse(url);
    final params = Map<String, String>.from(uri.queryParameters)
      ..['w'] = width.toString()
      ..['q'] = '75'
      ..['auto'] = 'format';
    return uri.replace(queryParameters: params).toString();
  }
  return url;
}

/// Widget ảnh tối ưu: cache disk, tự động resize Cloudinary, không fade
class AppNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final bool optimize;

  const AppNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.optimize = true,
  });

  @override
  Widget build(BuildContext context) {
    final int? targetW = width?.toInt();
    final int? targetH = height?.toInt();

    final url = optimize
        ? optimizeImageUrl(
            imageUrl,
            width: (targetW != null && targetW > 0) ? targetW * 2 : 400,
            height: (targetH != null && targetH > 0) ? targetH * 2 : 400,
          )
        : imageUrl;

    return CachedNetworkImage(
      imageUrl: url,
      cacheManager: AppCacheManager.instance,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: targetW != null ? targetW * 2 : null,
      memCacheHeight: targetH != null ? targetH * 2 : null,
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      placeholderFadeInDuration: Duration.zero,
      placeholder: (context, url) =>
          placeholder ??
          Container(
            width: width,
            height: height,
            color: Colors.grey.shade100,
          ),
      errorWidget: (context, url, error) =>
          errorWidget ??
          Container(
            width: width,
            height: height,
            color: Colors.grey.shade100,
            child: const Icon(Icons.image_not_supported, color: Colors.grey),
          ),
    );
  }
}
