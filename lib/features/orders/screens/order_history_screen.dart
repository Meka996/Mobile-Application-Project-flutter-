import 'package:flutter/material.dart';
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
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  late final OrderRepository _repo;

  @override
  void initState() {
    super.initState();
    _repo = OrderRepository();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: const BackButton(color: Color(0xFF2C2C2C)),
        title: const Text(
          'My Orders',
          style: TextStyle(
            color: Color(0xFF2C2C2C),
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<List<OrderModel>>(
        stream: _repo.ordersStream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child:
                    CircularProgressIndicator(color: Color(0xFFC45D75)));
          }

          if (snap.hasError) {
            return _ErrorState(
              message: snap.error.toString(),
              onRetry: () => setState(() {}), // triggers rebuild → new stream
            );
          }

          final orders = snap.data ?? [];

          if (orders.isEmpty) {
            return _EmptyState(
              onShopNow: () =>
                  Navigator.of(context).popUntil((r) => r.isFirst),
            );
          }

          return RefreshIndicator(
            color: const Color(0xFFC45D75),
            onRefresh: () async => setState(() {}),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: orders.length,
              itemBuilder: (_, i) => OrderCard(
                order: orders[i],
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => OrderDetailScreen(order: orders[i]),
                )),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────── Helper widgets ───────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onShopNow});
  final VoidCallback onShopNow;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.receipt_long_outlined,
                size: 72, color: Color(0xFFE8A8B4)),
            const SizedBox(height: 20),
            const Text(
              "No orders yet",
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2C2C2C)),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your placed orders will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Color(0xFF7A7A7A)),
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: onShopNow,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC45D75),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              ),
              child: const Text('Shop Now',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded,
                size: 48, color: Color(0xFFC45D75)),
            const SizedBox(height: 16),
            const Text('Could not load orders',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 12, color: Color(0xFF999999))),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC45D75)),
            ),
          ],
        ),
      ),
    );
  }
}