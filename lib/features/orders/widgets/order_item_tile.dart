import 'package:flutter/material.dart';
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showImage) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 72,
                height: 88,
                color: const Color(0xFFFADCE4),
                child: const Icon(Icons.checkroom,
                    color: Color(0xFFC45D75), size: 32),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  'Size: ${item.size}  ·  Color: ${item.color}',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Text(
                  'Qty: ${item.quantity}  ·  \$${item.unitPrice.toStringAsFixed(2)} each',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '\$${item.lineTotal.toStringAsFixed(2)}',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w700, color: const Color(0xFFC45D75)),
          ),
        ],
      ),
    );
  }
}