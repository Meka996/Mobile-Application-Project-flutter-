import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_layout.dart';
import '../../../shared/shared.dart';
import '../models/order_model.dart';
import '../widgets/order_item_tile.dart';

/// Read-only view of a single historical order.
/// Users cannot modify or cancel orders (UPDATE/DELETE denied by rules).
class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key, required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('EEEE, d MMMM yyyy  ·  HH:mm')
        .format(order.createdAt);
    final shortId = order.id.length >= 8
        ? order.id.substring(0, 8).toUpperCase()
        : order.id.toUpperCase();

    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text('Order #$shortId')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppLayout.detailMaxWidth),
          child: ListView(
            padding: const EdgeInsets.all(AppLayout.large),
            children: [
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(AppLayout.large),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _OrderField('Date', dateLabel),
                      _OrderField('Status', order.status),
                      _OrderField('Order ID', order.id, selectable: true),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppLayout.page),
              Text('Items (${order.items.length})', style: text.titleLarge),
              const SizedBox(height: AppLayout.small),
              for (final item in order.items) OrderItemTile(item: item),
              const Divider(height: AppLayout.section),
              SummaryRow(
                'Order total',
                '\$${order.total.toStringAsFixed(2)}',
                emphasized: true,
              ),
              Text('Total recorded at checkout.', style: text.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderField extends StatelessWidget {
  const _OrderField(this.label, this.value, {this.selectable = false});

  final String label;
  final String value;
  final bool selectable;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: text.labelMedium)),
          Expanded(
            flex: 3,
            child: selectable
                ? SelectableText(value, style: text.bodyMedium)
                : Text(value, style: text.bodyMedium),
          ),
        ],
      ),
    );
  }
}
