import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_layout.dart';
import '../../../shared/shared.dart';
import '../services/cart_reader.dart';
import '../services/order_repository.dart';
import '../widgets/order_item_tile.dart';
import 'order_confirmation_screen.dart';

/// Reviews the user's Firestore cart and confirms the order after it is saved.
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key, this.onShopPressed});

  final VoidCallback? onShopPressed;

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

  final _currency = NumberFormat.simpleCurrency(name: 'USD');

  String _formatCents(int cents) => _currency.format(cents / 100);

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
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadError = 'Check your connection and try again.';
          _loadingCart = false;
        });
      }
    }
  }

  Future<void> _placeOrder() async {
    final cart = _cart;
    if (_submitting || cart == null || !cart.canPlaceOrder) return;

    setState(() {
      _submitting = true;
      _submitError = null;
    });

    try {
      final orderId = await _orderRepo.placeOrder(cart);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => OrderConfirmationScreen(
              orderId: orderId,
              onShopPressed: widget.onShopPressed,
            ),
          ),
        );
      }
    } on CartChangedException {
      if (!mounted) return;
      await _loadCart();
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitError =
            'Your cart or product prices changed. Review the updated order.';
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _submitError = 'Could not confirm your order. Check My Orders before trying again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final error = _loadError;

    return PopScope(
      canPop: !_submitting,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: !_submitting,
          title: const Text('Checkout'),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppLayout.detailMaxWidth,
            ),
            child: _loadingCart
                ? const LoadingWidget(label: 'Loading checkout')
                : error != null
                ? StateMessage.error(
                    title: 'Could not load your cart',
                    message: error,
                    onRetry: _loadCart,
                  )
                : _buildBody(),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    final cart = _cart!;
    final items = cart.items;
    final text = Theme.of(context).textTheme;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppLayout.large),
            children: [
              if (cart.issues.isNotEmpty) ...[
                _CheckoutNotice(
                  title: 'Some items could not be loaded',
                  messages: cart.issues,
                  warning: true,
                ),
                const SizedBox(height: AppLayout.medium),
              ],
              if (cart.isEmpty)
                const StateMessage(
                  icon: Icons.shopping_bag_outlined,
                  title: 'Your cart is empty.',
                  message: 'Add items before checking out.',
                )
              else ...[
                Text('Your Order', style: text.titleLarge),
                const SizedBox(height: AppLayout.small),
                for (final item in items) OrderItemTile(item: item),
                const Divider(height: AppLayout.section),
                SummaryRow('Subtotal', _formatCents(cart.subtotalCents)),
                SummaryRow(
                  'Shipping',
                  cart.shippingCents == 0
                      ? 'Free'
                      : _formatCents(cart.shippingCents),
                ),
                SummaryRow('Est. Tax (8%)', _formatCents(cart.taxCents)),
                const Divider(height: AppLayout.page),
                SummaryRow(
                  'Total',
                  _formatCents(cart.totalCents),
                  emphasized: true,
                ),
                const SizedBox(height: AppLayout.small),
                Text(
                  'This is a demo checkout. No payment is collected.',
                  style: text.bodySmall,
                ),
              ],
              if (cart.blockingIssue case final issue?) ...[
                const SizedBox(height: AppLayout.large),
                _CheckoutNotice(messages: [issue]),
              ],
              if (_submitError case final error?) ...[
                const SizedBox(height: AppLayout.large),
                _CheckoutNotice(messages: [error]),
              ],
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppLayout.large,
              AppLayout.small,
              AppLayout.large,
              AppLayout.large,
            ),
            child: VeloraButton(
              text: _submitting ? 'Placing Order...' : 'Place Order',
              onPressed: cart.canPlaceOrder && !_submitting
                  ? _placeOrder
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}

class _CheckoutNotice extends StatelessWidget {
  const _CheckoutNotice({
    this.title,
    required this.messages,
    this.warning = false,
  });

  final String? title;
  final List<String> messages;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final heading = title;
    final foreground = warning ? AppColors.warning : scheme.onErrorContainer;
    return Semantics(
      liveRegion: !warning,
      child: Container(
        padding: const EdgeInsets.all(AppLayout.medium),
        decoration: BoxDecoration(
          color: warning ? AppColors.warningSurface : scheme.errorContainer,
          borderRadius: BorderRadius.circular(AppLayout.radius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (heading != null) ...[
              Text(
                heading,
                style: text.titleSmall?.copyWith(color: foreground),
              ),
              const SizedBox(height: AppLayout.small),
            ],
            for (final message in messages)
              Text(
                message,
                style: text.bodyMedium?.copyWith(color: foreground),
              ),
          ],
        ),
      ),
    );
  }
}
