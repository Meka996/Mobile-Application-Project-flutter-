import 'package:flutter/material.dart';
import 'package:velora/core/theme/app_layout.dart';
import 'package:velora/core/theme/app_text_styles.dart';
import 'package:velora/shared/shared.dart';

import '../models/cart_line.dart';
import '../models/product_info.dart';
import '../services/favorites_repository.dart';
import '../services/wishlist_cart_errors.dart';
import '../widgets/auth_gate.dart';

/// Grid of the signed-in user's favorite products (live from Firestore).
///
/// Mount it as the Wishlist tab (index 2). [showAppBar] is false by default
/// because MainNavigation already has an AppBar; set it to true if you push
/// this screen as its own route.
class WishlistScreen extends StatelessWidget {
  const WishlistScreen({
    super.key,
    this.onOpenProduct,
    this.onShopPressed,
    this.onSignInRequested,
    this.repository,
    this.showAppBar = false,
  });

  /// Open Product Details (owned by Task C). If null, cards are not tappable.
  final void Function(String productId)? onOpenProduct;

  /// "Start shopping" button on the empty state (switch to the Shop tab).
  final VoidCallback? onShopPressed;

  /// Open the sign-in screen (owned by Task B).
  final VoidCallback? onSignInRequested;

  final FavoritesRepository? repository;
  final bool showAppBar;

  @override
  Widget build(BuildContext context) {
    final body = AuthGate(
      guestTitle: 'Your wishlist is waiting',
      guestMessage: 'Sign in to save the pieces you love.',
      onSignInRequested: onSignInRequested,
      signedInBuilder: (context) => _WishlistContent(
        repository: repository ?? FavoritesRepository(),
        onOpenProduct: onOpenProduct,
        onShopPressed: onShopPressed,
      ),
    );

    if (!showAppBar) return body;
    return Scaffold(
      appBar: AppBar(title: const Text('Wishlist')),
      body: body,
    );
  }
}

class _WishlistContent extends StatefulWidget {
  const _WishlistContent({
    required this.repository,
    this.onOpenProduct,
    this.onShopPressed,
  });

  final FavoritesRepository repository;
  final void Function(String productId)? onOpenProduct;
  final VoidCallback? onShopPressed;

  @override
  State<_WishlistContent> createState() => _WishlistContentState();
}

class _WishlistContentState extends State<_WishlistContent> {
  late Stream<List<FavoriteItem>> _stream = widget.repository.watchFavorites();

  Future<void> _remove(String productId) async {
    try {
      await widget.repository.removeFavorite(productId);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(friendlyError(error))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<FavoriteItem>>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return StateMessage.error(
            icon: Icons.cloud_off_outlined,
            title: 'Could not load your wishlist',
            message: friendlyError(snapshot.error!),
            onRetry: () =>
                setState(() => _stream = widget.repository.watchFavorites()),
          );
        }
        if (!snapshot.hasData) return const LoadingWidget();

        final items = snapshot.data!;
        if (items.isEmpty) {
          return StateMessage(
            icon: Icons.favorite_border,
            title: 'No favorites yet',
            message: 'Tap the heart on any product to save it here.',
            actionLabel: widget.onShopPressed == null ? null : 'Start shopping',
            onAction: widget.onShopPressed,
          );
        }

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppLayout.catalogMaxWidth,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final scaler = MediaQuery.textScalerOf(context);
                final contentWidth = constraints.maxWidth - AppLayout.large * 2;
                final columns =
                    (contentWidth ~/ (scaler.scale(140) + AppLayout.medium))
                        .clamp(1, 4);

                return GridView.builder(
                  padding: const EdgeInsets.all(AppLayout.large),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: AppLayout.medium,
                    crossAxisSpacing: AppLayout.medium,
                    mainAxisExtent: 150 + scaler.scale(92),
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _WishlistCard(
                      item: item,
                      onRemove: () => _remove(item.productId),
                      onTap:
                          item.product == null || widget.onOpenProduct == null
                          ? null
                          : () => widget.onOpenProduct!(item.productId),
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _WishlistCard extends StatelessWidget {
  const _WishlistCard({required this.item, required this.onRemove, this.onTap});

  final FavoriteItem item;
  final VoidCallback onRemove;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final product = item.product;

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = theme.textTheme;

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ProductImage(url: product?.imageUrl, radius: 0),
                  ),
                  PositionedDirectional(
                    top: AppLayout.small,
                    end: AppLayout.small,
                    child: Material(
                      color: scheme.surfaceContainer,
                      shape: const CircleBorder(),
                      child: IconButton(
                        tooltip: 'Remove from wishlist',
                        icon: const Icon(Icons.favorite, size: 20),
                        onPressed: onRemove,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppLayout.medium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product?.name ?? 'Unavailable product',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleMedium,
                  ),
                  Text(
                    product == null
                        ? 'No longer available'
                        : formatCents(toCents(product.price)),
                    style: product == null
                        ? text.bodySmall?.copyWith(color: scheme.error)
                        : AppTextStyles.price(context),
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
