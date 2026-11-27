import 'package:flutter/material.dart';
import 'package:velora/core/theme/app_theme.dart';

/// Rounded product photo with loading and error fallbacks.
class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    required this.url,
    this.width,
    this.height,
  });

  final String? url;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final imageUrl = url;

    final placeholder = Container(
      width: width,
      height: height,
      color: AppTheme.babyPink,
      child: const Icon(Icons.image_outlined, color: AppTheme.deepRose),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: imageUrl == null || imageUrl.isEmpty
          ? placeholder
          : Image.network(
              imageUrl,
              width: width,
              height: height,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) =>
                  progress == null ? child : placeholder,
              errorBuilder: (context, error, stack) => placeholder,
            ),
    );
  }
}
