import 'package:flutter/material.dart';
import 'package:velora/core/theme/app_layout.dart';
import 'package:velora/shared/shared.dart';

import '../models/cart_line.dart';
import '../services/cart_repository.dart';
import '../services/wishlist_cart_errors.dart';
import '../widgets/auth_gate.dart';
import '../widgets/cart_item_tile.dart';

/// The shopping cart: live lines, quantity controls, subtotals and total.
///
/// Push it as its own route (shows an AppBar by default). Set [showAppBar]
/// to false if you embed it in a tab that already has an AppBar.
class CartScreen extends StatelessWidget {
  const CartScreen({
    super.key,
    this.onCheckout,
    this.onShopPressed,
    this.onSignInRequested,
    this.onOpenProduct,
    this.repository,
    this.showAppBar = true,
  });

  /// Hand-off to Checkout (Task E). Receives the current cart; use
  /// `cart.purchasableLines` and `cart.totalCents`. If null, the Checkout
  /// button is hidden instead of pretending to work.
  final void Function(CartSnapshot cart)? onCheckout;

  /// "Start shopping" button on the empty state.
  final VoidCallback? onShopPressed;

  /// Open the sign-in screen (Task B).
  final VoidCallback? onSignInRequested;

  /// Open Product Details (Task C) when a cart row photo is tapped.
  final void Function(String productId)? onOpenProduct;

  final CartRepository? repository;
  final bool showAppBar;

  @override
  Widget build(BuildContext context) {
    final body = AuthGate(
      guestTitle: 'Your bag is waiting',
      guestMessage: 'Sign in to see and edit your shopping cart.',
      onSignInRequested: onSignInRequested,
      signedInBuilder: (context) => _CartContent(
        repository: repository ?? CartRepository(),
        onCheckout: onCheckout,
        onShopPressed: onShopPressed,
        onOpenProduct: onOpenProduct,
      ),
    );

    if (!showAppBar) return body;
    return Scaffold(
      appBar: AppBar(title: const Text('Your Cart')),
      body: body,
    );
  }
}

class _CartContent extends StatefulWidget {
  const _CartContent({
    required this.repository,
    this.onCheckout,
    this.onShopPressed,
    this.onOpenProduct,
  });

  final CartRepository repository;
  final void Function(CartSnapshot cart)? onCheckout;
  final VoidCallback? onShopPressed;
  final void Function(String productId)? onOpenProduct;

  @override
  State<_CartContent> createState() => _CartContentState();
}

class _CartContentState extends State<_CartContent> {
  late Stream<CartSnapshot> _stream = widget.repository.watchCart();

  /// Runs a Firestore action and shows a truthful error if it fails.
  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(friendlyError(error))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<CartSnapshot>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return StateMessage.error(
            icon: Icons.cloud_off_outlined,
            title: 'Could not load your cart',
            message: friendlyError(snapshot.error!),
            onRetry: () =>
                setState(() => _stream = widget.repository.watchCart()),
          );
        }
        if (!snapshot.hasData) return const LoadingWidget();

        final cart = snapshot.data!;
        if (cart.isEmpty) {
          return StateMessage(
            icon: Icons.shopping_bag_outlined,
            title: 'Your bag is empty',
            message: 'Find something you love and add it to your bag.',
            actionLabel: widget.onShopPressed == null ? null : 'Start shopping',
            onAction: widget.onShopPressed,
          );
        }

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppLayout.detailMaxWidth,
            ),
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(AppLayout.large),
                  sliver: SliverList.separated(
                    itemCount: cart.lines.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppLayout.medium),
                    itemBuilder: (context, index) {
                      final line = cart.lines[index];
                      final id = line.entry.id;
                      final open = widget.onOpenProduct;
                      return CartItemTile(
                        key: ValueKey(id),
                        line: line,
                        onTap: open == null || line.product == null
                            ? null
                            : () => open(line.entry.productId),
                        onIncrement: () => _run(
                          () => widget.repository.increment(
                            id,
                            maxQuantity: line.product?.stock,
                          ),
                        ),
                        onDecrement: () =>
                            _run(() => widget.repository.decrement(id)),
                        onRemove: () =>
                            _run(() => widget.repository.removeItem(id)),
                      );
                    },
                  ),
                ),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: _SummaryPanel(
                      cart: cart,
                      onCheckout: widget.onCheckout,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SummaryPanel extends StatelessWidget {
  const _SummaryPanel({required this.cart, this.onCheckout});

  final CartSnapshot cart;
  final void Function(CartSnapshot cart)? onCheckout;

  @override
  Widget build(BuildContext context) {
    final checkout = onCheckout;
    final total = formatCents(cart.totalCents);

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppLayout.large),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SummaryRow('Items', '${cart.itemCount}'),
            const Divider(height: AppLayout.page),
            SummaryRow('Cart total', total, emphasized: true),
            if (cart.hasProblems)
              Padding(
                padding: const EdgeInsets.only(top: AppLayout.small),
                child: Text(
                  'Unavailable items are excluded from the total. Review affected items before checkout.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.error,
                  ),
                ),
              ),
            if (checkout != null) ...[
              const SizedBox(height: AppLayout.medium),
              VeloraButton(
                text: 'Checkout',
                icon: Icons.lock_outline,
                onPressed: cart.canCheckout ? () => checkout(cart) : null,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
