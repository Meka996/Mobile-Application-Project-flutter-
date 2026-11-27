import 'package:flutter/material.dart';
import '../services/cart_reader.dart';
import '../services/order_repository.dart';
import '../models/order_item.dart';
import '../widgets/order_item_tile.dart';
import 'order_confirmation_screen.dart';

/// CheckoutScreen — Phase 02 + 03 of the build plan.
///
/// What it does:
///   1. Loads the signed-in user's real Firestore cart via [CartReader].
///   2. Cross-references current product prices (re-read, not cached totals).
///   3. Shows item list, subtotal/shipping/tax summary, warnings for
///      unavailable items, and a Place Order button.
///   4. On tap: creates the order + clears the cart atomically via
///      [OrderRepository.placeOrder]; button is disabled during submission.
///   5. Navigates to [OrderConfirmationScreen] only after Firestore write
///      succeeds; never shows success from a failed write.
///
/// State pattern: StatefulWidget — no external state manager needed.
/// The screen self-manages loading, cart data, error messages and submission.
class CheckoutScreen extends StatefulWidget {
  /// Called by Mohamed Hassan's router — no arguments needed.
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _cartReader = CartReader();
  final _orderRepo = OrderRepository();

  // Loading / data state
  bool _loadingCart = true;
  String? _loadError;
  CartSnapshot? _cart;

  // Submission state
  bool _submitting = false;
  String? _submitError;

  static const double _shippingThreshold = 150.0;
  static const double _taxRate = 0.08;

  double get _shipping =>
      (_cart?.total ?? 0) >= _shippingThreshold ? 0.0 : 9.99;
  double get _tax {
    final subtotalCents = ((_cart?.total ?? 0) * 100).round();
    return (subtotalCents * 8 / 100).round() / 100;
  }
  double get _grandTotal => (_cart?.total ?? 0) + _shipping + _tax;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    setState(() {
      _loadingCart = true;
      _loadError = null;
    });
    try {
      final snap = await _cartReader.readCart();
      if (mounted) {
        setState(() {
          _cart = snap;
          _loadingCart = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadError = e.toString();
          _loadingCart = false;
        });
      }
    }
  }

  Future<void> _placeOrder() async {
    final cart = _cart;
    if (cart == null || cart.isEmpty) return;

    setState(() {
      _submitting = true;
      _submitError = null;
    });

    try {
      if (!cart.canCheckout) {
        throw Exception('Please fix all unavailable or invalid cart items first.');
      }
      final orderId = await _orderRepo.placeOrder();

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => OrderConfirmationScreen(orderId: orderId),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _submitError =
              'Order could not be placed. Your cart is unchanged. Please try again.\n$e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF8F9),
        elevation: 0,
        leading: const BackButton(color: Color(0xFF2C2C2C)),
        title: const Text(
          'Checkout',
          style: TextStyle(
            color: Color(0xFF2C2C2C),
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: _loadingCart
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFC45D75)))
          : _loadError != null
              ? _ErrorState(message: _loadError!, onRetry: _loadCart)
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    final cart = _cart!;
    final isEmpty = cart.isEmpty;
    final canCheckout = cart.canCheckout;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Warnings for skipped items
              if (cart.issues.isNotEmpty) ...[
                _IssuesBanner(issues: cart.issues),
                const SizedBox(height: 12),
              ],

              // ── Empty state
              if (isEmpty) ...[
                const SizedBox(height: 48),
                const Icon(Icons.shopping_bag_outlined,
                    size: 64, color: Color(0xFFE8A8B4)),
                const SizedBox(height: 16),
                const Center(
                  child: Text(
                    'Your cart is empty.\nAdd items before checking out.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF7A7A7A), fontSize: 15),
                  ),
                ),
              ] else ...[
                Text('Your Order (${cart.items.length} item${cart.items.length == 1 ? '' : 's'})',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                ...cart.items.map((item) => OrderItemTile(item: item)),
                const Divider(height: 32),
                _SummaryRow('Subtotal',
                    '\$${cart.total.toStringAsFixed(2)}'),
                _SummaryRow(
                    'Shipping',
                    _shipping == 0
                        ? 'Free'
                        : '\$${_shipping.toStringAsFixed(2)}'),
                _SummaryRow('Est. Tax (8%)',
                    '\$${_tax.toStringAsFixed(2)}'),
                const Divider(height: 24),
                _SummaryRow(
                  'Total',
                  '\$${_grandTotal.toStringAsFixed(2)}',
                  bold: true,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Final price and stock are verified securely when you place the order. No payment is charged.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF999999)),
                ),
              ],

              // ── Submission error
              if (_submitError != null) ...[
                const SizedBox(height: 16),
                _ErrorBanner(message: _submitError!),
              ],
            ],
          ),
        ),

        // ── Place Order button — pinned at bottom
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: (!canCheckout || _submitting) ? null : _placeOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC45D75),
                  disabledBackgroundColor: const Color(0xFFE8A8B4),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(
                        isEmpty ? 'Add Items to Order' : (canCheckout ? 'Place Order' : 'Fix Cart Items'),
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────── Helper widgets ───────────────

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.label, this.value, {this.bold = false});
  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = bold
        ? const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)
        : const TextStyle(fontSize: 14, color: Color(0xFF555555));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }
}

class _IssuesBanner extends StatelessWidget {
  const _IssuesBanner({required this.issues});
  final List<String> issues;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3CD),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFCE6E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Some items could not be loaded:',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 4),
          ...issues.map((e) => Text('• $e',
              style:
                  const TextStyle(fontSize: 12, color: Color(0xFF7A5A00)))),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEDED),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE57373)),
      ),
      child: Text(message,
          style: const TextStyle(fontSize: 12, color: Color(0xFFB71C1C))),
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
            const Icon(Icons.error_outline, size: 48, color: Color(0xFFC45D75)),
            const SizedBox(height: 16),
            Text('Could not load your cart',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF999999), fontSize: 12)),
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