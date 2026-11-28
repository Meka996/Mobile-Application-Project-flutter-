import 'package:flutter/material.dart';
import 'package:velora/core/theme/app_theme.dart';

import '../models/cart_line.dart';
import 'product_image.dart';

/// One row of the cart: photo, name, variant, quantity controls, subtotal.
class CartItemTile extends StatelessWidget {
  const CartItemTile({
    super.key,
    required this.line,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
    this.onTap,
  });

  final CartLine line;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final product = line.product;
    final entry = line.entry;
    final problem = line.problem;

    return Card(
      color: Theme.of(context).colorScheme.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.babyPink),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: onTap,
              child: ProductImage(
                assetPath: product?.imagePath,
                width: 80,
                height: 100,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          product?.name ?? 'Unavailable product',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Remove item',
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: onRemove,
                      ),
                    ],
                  ),
                  Text(
                    'Color: ${entry.color}  |  Size: ${entry.size}',
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                  if (problem != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        problem,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _QuantityControl(
                        quantity: entry.quantity,
                        canIncrease: line.canIncrease,
                        onIncrement: onIncrement,
                        onDecrement: onDecrement,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (line.isPurchasable)
                            Text(
                              '${formatCents(line.unitPriceCents)} each',
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 12,
                              ),
                            ),
                          Text(
                            line.isPurchasable
                                ? formatCents(line.subtotalCents)
                                : '--',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppTheme.deepRose,
                            ),
                          ),
                        ],
                      ),
                    ],
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

class _QuantityControl extends StatelessWidget {
  const _QuantityControl({
    required this.quantity,
    required this.canIncrease,
    required this.onIncrement,
    required this.onDecrement,
  });

  final int quantity;
  final bool canIncrease;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.babyPink,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: quantity <= 1 ? 'Remove item' : 'Decrease quantity',
            visualDensity: VisualDensity.compact,
            // At quantity 1 the minus becomes a trash can, because pressing
            // it deletes the cart document (quantity can never be 0).
            icon: Icon(
              quantity <= 1 ? Icons.delete_outline : Icons.remove,
              size: 18,
            ),
            onPressed: onDecrement,
          ),
          Text(
            '$quantity',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          IconButton(
            tooltip: 'Increase quantity',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.add, size: 18),
            onPressed: canIncrease ? onIncrement : null,
          ),
        ],
      ),
    );
  }
}
