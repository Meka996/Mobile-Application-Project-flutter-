import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_layout.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/shared.dart';
import '../models/product.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, required this.onTap});

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = theme.textTheme;
    final inStock = product.stock > 0;

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ProductImage(url: product.imageUrls.firstOrNull, radius: 0),
                  if (!inStock)
                    ColoredBox(
                      color: AppColors.imageScrim,
                      child: Center(
                        child: Text(
                          'Out of stock',
                          textAlign: TextAlign.center,
                          style: text.labelLarge?.copyWith(
                            color: scheme.onPrimary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppLayout.medium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall,
                  ),
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleMedium,
                  ),
                  const SizedBox(height: AppLayout.small),
                  Text(
                    '\$${product.price.toStringAsFixed(2)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.price(context),
                  ),
                  if (inStock)
                    Text(
                      'Available',
                      style: text.bodySmall?.copyWith(color: AppColors.success),
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
