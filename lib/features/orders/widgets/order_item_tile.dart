import 'package:flutter/material.dart';

import '../../../core/theme/app_layout.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/order_item.dart';

/// Displays a single line item — used in both CheckoutScreen and
/// order detail views.
class OrderItemTile extends StatelessWidget {
  const OrderItemTile({super.key, required this.item, this.showImage = true});

  final OrderItem item;
  final bool showImage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppLayout.small),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showImage) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(AppLayout.radius),
              child: Container(
                width: 72,
                height: 88,
                color: scheme.secondaryContainer,
                child: Icon(
                  Icons.checkroom,
                  color: scheme.onSecondaryContainer,
                  size: 32,
                ),
              ),
            ),
            const SizedBox(width: AppLayout.medium),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: theme.textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  'Size: ${item.size}  ·  Color: ${item.color}',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'Qty: ${item.quantity}  ·  \$${item.unitPrice.toStringAsFixed(2)} each',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${item.lineTotal.toStringAsFixed(2)}',
                  style: AppTextStyles.price(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
