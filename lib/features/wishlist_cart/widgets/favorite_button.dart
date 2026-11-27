import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/favorites_repository.dart';
import '../services/wishlist_cart_errors.dart';

/// Heart icon that is filled when the product is a favorite.
///
/// Drop it into Home cards or Product Details:
/// `FavoriteButton(productId: product.id)`.
/// The heart reads Firestore live, so it stays in sync with the Wishlist.
class FavoriteButton extends StatelessWidget {
  const FavoriteButton({
    super.key,
    required this.productId,
    this.repository,
    this.onSignInRequested,
  });

  final String productId;
  final FavoritesRepository? repository;

  /// Called when a guest taps the heart (e.g. open the login screen).
  final VoidCallback? onSignInRequested;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      initialData: FirebaseAuth.instance.currentUser,
      builder: (context, snapshot) {
        final user = snapshot.data;
        if (user == null) {
          return IconButton(
            tooltip: 'Add to wishlist',
            icon: const Icon(Icons.favorite_border),
            onPressed: () {
              final signIn = onSignInRequested;
              if (signIn != null) {
                signIn();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please sign in to save favorites.'),
                  ),
                );
              }
            },
          );
        }
        return _SignedInHeart(
          key: ValueKey('${user.uid}-$productId'),
          productId: productId,
          repository: repository ?? FavoritesRepository(),
        );
      },
    );
  }
}

class _SignedInHeart extends StatefulWidget {
  const _SignedInHeart({
    super.key,
    required this.productId,
    required this.repository,
  });

  final String productId;
  final FavoritesRepository repository;

  @override
  State<_SignedInHeart> createState() => _SignedInHeartState();
}

class _SignedInHeartState extends State<_SignedInHeart> {
  late final Stream<bool> _isFavorite = widget.repository.watchIsFavorite(
    widget.productId,
  );

  Future<void> _toggle() async {
    try {
      await widget.repository.toggleFavorite(widget.productId);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(friendlyError(error))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: _isFavorite,
      builder: (context, snapshot) {
        final isFavorite = snapshot.data ?? false;
        return IconButton(
          tooltip: isFavorite ? 'Remove from wishlist' : 'Add to wishlist',
          icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
          onPressed: snapshot.hasData ? _toggle : null,
        );
      },
    );
  }
}
