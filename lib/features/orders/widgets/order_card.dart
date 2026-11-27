import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_layout.dart';
import '../../../shared/shared.dart';
import '../models/order_model.dart';

/// Summary card shown in the OrderHistoryScreen list.
class OrderCard extends StatelessWidget {
  const OrderCard({super.key, required this.order, required this.onTap});

  final OrderModel order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateLabel = DateFormat('d MMM yyyy  HH:mm').format(order.createdAt);
    final itemCount = order.items.fold<int>(0, (s, i) => s + i.quantity);
    final shortId = order.id.length > 8 ? order.id.substring(0, 8) : order.id;

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppLayout.large,
        vertical: 6,
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppLayout.large),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Order #${shortId.toUpperCase()}',
                      style: theme.textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppLayout.small),
                  Flexible(child: _StatusChip(status: order.status)),
                ],
              ),
              const SizedBox(height: AppLayout.small),
              Text(dateLabel, style: theme.textTheme.bodySmall),
              const SizedBox(height: AppLayout.small),
              SummaryRow(
                '$itemCount item${itemCount == 1 ? '' : 's'}',
                '\$${order.total.toStringAsFixed(2)}',
                emphasized: true,
              ),
              if (order.items.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  order.items.map((i) => i.name).take(3).join(', ') +
                      (order.items.length > 3 ? ' …' : ''),
                  style: theme.textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppLayout.medium,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(AppLayout.radius),
      ),
      child: Text(
        status,
        style: theme.textTheme.labelMedium?.copyWith(
          color: scheme.onSecondaryContainer,
        ),
      ),
    );
  }
}
