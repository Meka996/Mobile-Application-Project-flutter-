import 'package:flutter/material.dart';

import '../../core/theme/app_layout.dart';

/// Rounded product photo with loading and error fallbacks.
class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.radius = AppLayout.radius,
    this.semanticLabel,
  });

  final String? url;
  final double? width;
  final double? height;
  final double radius;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final imageUrl = url;
    final scheme = Theme.of(context).colorScheme;

    final placeholder = Container(
      width: width,
      height: height,
      color: scheme.secondaryContainer,
      alignment: Alignment.center,
      child: Icon(
        Icons.image_not_supported_outlined,
        color: scheme.onSecondaryContainer,
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: imageUrl == null || imageUrl.isEmpty
          ? placeholder
          : Image.network(
              imageUrl,
              width: width,
              height: height,
              fit: BoxFit.cover,
              semanticLabel: semanticLabel,
              excludeFromSemantics: semanticLabel == null,
              loadingBuilder: (context, child, progress) =>
                  progress == null ? child : placeholder,
              errorBuilder: (context, error, stack) => placeholder,
            ),
    );
  }
}
