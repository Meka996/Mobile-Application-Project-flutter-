import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/order_model.dart';
import '../widgets/order_item_tile.dart';

/// Read-only view of a single historical order.
/// Users cannot modify or cancel orders (UPDATE/DELETE denied by rules).
class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key, required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final dateLabel =
        DateFormat('EEEE, d MMMM yyyy  ·  HH:mm').format(order.createdAt);
    final shortId = order.id.length >= 8
        ? order.id.substring(0, 8).toUpperCase()
        : order.id.toUpperCase();

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF8F9),
        elevation: 0,
        leading: const BackButton(color: Color(0xFF2C2C2C)),
        title: Text(
          'Order #$shortId',
          style: const TextStyle(
            color: Color(0xFF2C2C2C),
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Meta
          _InfoCard(children: [
            _MetaRow('Date', dateLabel),
            _MetaRow('Status', order.status),
            _MetaRow('Order ID', order.id,
                mono: true, selectable: true),
          ]),
          const SizedBox(height: 16),

          // ── Items
          Text(
            'Items (${order.items.length})',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ...order.items.map((item) => OrderItemTile(item: item)),
          const Divider(height: 32),

          // ── Totals (snapshot)
          _SummaryRow('Items total',
              '\$${order.total.toStringAsFixed(2)}'),
          const SizedBox(height: 4),
          const Text(
            'Note: total shown is the value recorded at placement time.',
            style: TextStyle(fontSize: 11, color: Color(0xFFAAAAAA)),
          ),
          const SizedBox(height: 24),

          // ── Limitation note
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Orders are read-only. No payment has been processed and stock '
              'has not been decremented. This is a demonstration-grade checkout.',
              style: TextStyle(fontSize: 11, color: Color(0xFF888888)),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow(this.label, this.value,
      {this.mono = false, this.selectable = false});
  final String label;
  final String value;
  final bool mono;
  final bool selectable;

  @override
  Widget build(BuildContext context) {
    final valueWidget = Text(
      value,
      style: TextStyle(
        fontSize: 13,
        fontFamily: mono ? 'monospace' : null,
        color: const Color(0xFF444444),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 68,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF999999),
                    fontWeight: FontWeight.w600)),
          ),
          Expanded(
              child: selectable ? SelectableText(value) : valueWidget),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: Color(0xFFC45D75))),
      ],
    );
  }
}