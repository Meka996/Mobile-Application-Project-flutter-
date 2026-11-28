import 'package:flutter/material.dart';
import 'package:velora/core/theme/app_theme.dart';

import '../models/cart_line.dart';
import '../models/product_info.dart';
import '../services/favorites_repository.dart';
import '../services/wishlist_cart_errors.dart';
import '../widgets/auth_gate.dart';
import '../widgets/product_image.dart';
import '../widgets/state_views.dart';

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
    return Scaffold(appBar: AppBar(title: const Text('Wishlist')), body: body);
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyError(error))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<FavoriteItem>>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return StateMessage(
            icon: Icons.cloud_off_outlined,
            title: 'Could not load your wishlist',
            message: friendlyError(snapshot.error!),
            actionLabel: 'Try again',
            onAction: () =>
                setState(() => _stream = widget.repository.watchFavorites()),
          );
        }
        if (!snapshot.hasData) return const LoadingView();

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

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.68,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return _WishlistCard(
              item: item,
              onRemove: () => _remove(item.productId),
              onTap: item.product == null || widget.onOpenProduct == null
                  ? null
                  : () => widget.onOpenProduct!(item.productId),
            );
          },
        );
      },
    );
  }
}

class _WishlistCard extends StatelessWidget {
  const _WishlistCard({
    required this.item,
    required this.onRemove,
    this.onTap,
  });

  final FavoriteItem item;
  final VoidCallback onRemove;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final product = item.product;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.babyPink),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ProductImage(assetPath: product?.imagePath),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Material(
                      color: Colors.white,
                      shape: const CircleBorder(),
                      child: IconButton(
                        tooltip: 'Remove from wishlist',
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(
                          Icons.favorite,
                          color: AppTheme.deepRose,
                          size: 20,
                        ),
                        onPressed: onRemove,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              product?.name ?? 'Unavailable product',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              product == null
                  ? 'No longer available'
                  : formatCents(toCents(product.price)),
              style: TextStyle(
                color: product == null ? Colors.red.shade700 : AppTheme.deepRose,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
