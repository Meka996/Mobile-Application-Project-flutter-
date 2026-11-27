// LOCAL INTEGRATION TEST VERSION - only for the branch mohamed-integration-test.
// Copy over lib/core/navigation/main_navigation.dart on that branch.
// Hassan (Task A) owns the real version of this file.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:velora/core/theme/app_theme.dart';
import 'package:velora/features/auth/presentation/screens/auth_gate.dart';
import 'package:velora/features/catalog/models/product.dart';
import 'package:velora/features/catalog/screens/home_screen.dart';
import 'package:velora/features/catalog/screens/product_catalog_screen.dart';
import 'package:velora/features/catalog/screens/product_details_screen.dart';
import 'package:velora/features/orders/orders.dart';
import 'package:velora/features/wishlist_cart/wishlist_cart.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int selectedIndex = 0;

  final CartRepository _cartRepository = CartRepository();
  final FavoritesRepository _favoritesRepository = FavoritesRepository();

  void _select(int index) => setState(() => selectedIndex = index);

  void _say(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  // ---- Task C -> Task D: Product Details callbacks ----------------------

  Future<void> _addToCart(Product product, String? size, String? color) async {
    if (FirebaseAuth.instance.currentUser == null) {
      _say('Please sign in from the Profile tab first.');
      return;
    }
    try {
      await _cartRepository.addToCart(
        productId: product.id,
        size: size ?? 'One Size',
        color: color ?? 'Default',
      );
      _say('Added to cart');
    } catch (error) {
      _say(friendlyError(error));
    }
  }

  Future<void> _toggleWishlist(Product product) async {
    if (FirebaseAuth.instance.currentUser == null) {
      _say('Please sign in from the Profile tab first.');
      return;
    }
    try {
      final isFavorite = await _favoritesRepository.toggleFavorite(product.id);
      _say(isFavorite ? 'Added to wishlist' : 'Removed from wishlist');
    } catch (error) {
      _say(friendlyError(error));
    }
  }

  void _openProduct(Product product) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProductDetailsScreen(
          product: product,
          onAddToCart: _addToCart,
          onAddToWishlist: _toggleWishlist,
        ),
      ),
    );
  }

  // The wishlist only knows the product id, so load the product first.
  Future<void> _openProductById(String productId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .get();
      final data = doc.data();
      if (!doc.exists || data == null) {
        _say('This product is no longer available.');
        return;
      }
      if (!mounted) return;
      _openProduct(Product.fromMap(doc.id, data));
    } catch (error) {
      _say(friendlyError(error));
    }
  }

  // ---- Task D -> Task E: checkout hand-off -------------------------------

  void _openCheckout(CartSnapshot cart) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const CheckoutScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      HomeScreen(onProductTap: _openProduct, onShopTap: () => _select(1)),
      ProductCatalogScreen(onProductTap: _openProduct),
      WishlistScreen(
        showAppBar: true,
        onOpenProduct: _openProductById,
        onShopPressed: () => _select(1),
        onSignInRequested: () => _select(4),
      ),
      CartScreen(
        showAppBar: true,
        onCheckout: _openCheckout,
        onShopPressed: () => _select(1),
        onSignInRequested: () => _select(4),
        onOpenProduct: _openProductById,
      ),
      const AuthGate(),
    ];

    return Scaffold(
      body: IndexedStack(index: selectedIndex, children: screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppTheme.offWhite,
        selectedItemColor: AppTheme.deepRose,
        unselectedItemColor: Colors.grey,
        onTap: _select,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_outlined),
            label: 'Shop',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            label: 'Wishlist',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag_outlined),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}