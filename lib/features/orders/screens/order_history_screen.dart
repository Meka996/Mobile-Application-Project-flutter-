import 'package:flutter/material.dart';

import '../../../core/theme/app_layout.dart';
import '../../../shared/shared.dart';

import '../services/order_repository.dart';
import '../models/order_model.dart';
import '../widgets/order_card.dart';
import 'order_detail_screen.dart';

/// Displays the signed-in user's order history from Firestore,
/// newest first. Uses a StreamBuilder so new orders appear in real time.
///
/// States handled: loading, empty, error, populated list.
/// Only the authenticated user's own orders are shown (enforced by
/// Firestore security rules on the users/{uid}/orders path).
class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key, this.onShopPressed});

  final VoidCallback? onShopPressed;

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  late final OrderRepository _repo;
  late Stream<List<OrderModel>> _orders;

  @override
  void initState() {
    super.initState();
    _repo = OrderRepository();
    _orders = _repo.ordersStream();
  }

  void _retry() => setState(() => _orders = _repo.ordersStream());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppLayout.detailMaxWidth),
          child: StreamBuilder<List<OrderModel>>(
            stream: _orders,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const LoadingWidget(label: 'Loading orders');
              }

              if (snap.hasError) {
                return StateMessage.error(
                  title: 'Could not load orders',
                  icon: Icons.cloud_off_outlined,
                  message: 'Check your connection and try again.',
                  onRetry: _retry,
                );
              }

              final orders = snap.data ?? [];

              if (orders.isEmpty) {
                return StateMessage(
                  icon: Icons.receipt_long_outlined,
                  title: 'No orders yet',
                  message: 'Your placed orders will appear here.',
                  actionLabel: 'Shop Now',
                  onAction:
                      widget.onShopPressed ??
                      () => Navigator.of(context).popUntil((r) => r.isFirst),
                );
              }

              return RefreshIndicator(
                onRefresh: () async => _retry(),
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    vertical: AppLayout.medium,
                  ),
                  itemCount: orders.length,
                  itemBuilder: (_, i) => OrderCard(
                    order: orders[i],
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => OrderDetailScreen(order: orders[i]),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
