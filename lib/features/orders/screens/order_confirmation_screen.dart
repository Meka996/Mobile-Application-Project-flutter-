import 'package:flutter/material.dart';
import 'order_history_screen.dart';

/// Shown only after [OrderRepository.placeOrder] completes successfully.
/// Displays order ID and placed status; never shown before Firestore write
/// finishes.
class OrderConfirmationScreen extends StatelessWidget {
  const OrderConfirmationScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    final shortId = orderId.length >= 8
        ? orderId.substring(0, 8).toUpperCase()
        : orderId.toUpperCase();

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F9),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ── Success icon
              Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8A8B4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    size: 56, color: Colors.white),
              ),
              const SizedBox(height: 28),

              const Text(
                'Order Placed!',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2C2C2C),
                ),
              ),
              const SizedBox(height: 10),

              Text(
                'Order #$shortId has been placed.\nStatus: placed',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: Color(0xFF6A6A6A)),
              ),
              const SizedBox(height: 8),

              Text(
                'Full ID: $orderId',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFFAAAAAA),
                    fontFamily: 'monospace'),
              ),

              const SizedBox(height: 40),

              // ── View Orders button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                          builder: (_) => const OrderHistoryScreen()),
                      (route) => route.isFirst,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC45D75),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text(
                    'View My Orders',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // ── Continue shopping
              TextButton(
                onPressed: () {
                  // Pop back to root (Mohamed Hassan's home route)
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text(
                  'Continue Shopping',
                  style: TextStyle(
                    color: Color(0xFFC45D75),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}