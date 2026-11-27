import 'package:flutter/material.dart';
import 'package:velora/core/theme/app_layout.dart';
import 'package:velora/core/theme/app_text_styles.dart';
import 'package:velora/shared/shared.dart';

import '../models/cart_line.dart';

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

    final theme = Theme.of(context);
    final text = theme.textTheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppLayout.medium),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppLayout.radius),
              child: ProductImage(
                url: product?.imageUrl,
                width: 72,
                height: 96,
                semanticLabel: product?.name,
              ),
            ),
            const SizedBox(width: AppLayout.medium),
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
                          style: text.titleMedium,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Remove item',
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: onRemove,
                      ),
                    ],
                  ),
                  Text(
                    'Color: ${entry.color}  ·  Size: ${entry.size}',
                    style: text.bodySmall,
                  ),
                  if (problem != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        problem,
                        style: text.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                  const SizedBox(height: AppLayout.small),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: AppLayout.medium,
                    runSpacing: AppLayout.small,
                    children: [
                      _QuantityControl(
                        quantity: entry.quantity,
                        canIncrease: line.canIncrease,
                        onIncrement: onIncrement,
                        onDecrement: onDecrement,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (line.isPurchasable)
                            Text(
                              '${formatCents(line.unitPriceCents)} each',
                              style: text.bodySmall,
                            ),
                          Text(
                            line.isPurchasable
                                ? formatCents(line.subtotalCents)
                                : '—',
                            style: AppTextStyles.price(context),
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
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(AppLayout.radius),
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          IconButton(
            tooltip: quantity <= 1 ? 'Remove item' : 'Decrease quantity',
            // At quantity 1 the minus becomes a trash can, because pressing
            // it deletes the cart document (quantity can never be 0).
            icon: Icon(
              quantity <= 1 ? Icons.delete_outline : Icons.remove,
              size: 18,
            ),
            onPressed: onDecrement,
          ),
          Text('$quantity', style: theme.textTheme.labelLarge),
          IconButton(
            tooltip: 'Increase quantity',
            icon: const Icon(Icons.add, size: 18),
            onPressed: canIncrease ? onIncrement : null,
          ),
        ],
      ),
    );
  }
}
