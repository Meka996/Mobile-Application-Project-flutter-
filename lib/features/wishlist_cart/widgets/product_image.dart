import 'package:flutter/material.dart';
import 'package:velora/core/theme/app_theme.dart';

/// Displays a bundled product image. No network request is made.
class ProductImage extends StatelessWidget {
  const ProductImage({super.key, required this.assetPath, this.width, this.height});

  final String? assetPath;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final path = assetPath;
    final placeholder = Container(
      width: width,
      height: height,
      color: AppTheme.babyPink,
      child: const Icon(Icons.image_outlined, color: AppTheme.deepRose),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: path == null || path.isEmpty
          ? placeholder
          : Image.asset(path, width: width, height: height, fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => placeholder),
    );
  }
}
