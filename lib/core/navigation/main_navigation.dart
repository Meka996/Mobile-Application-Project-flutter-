import 'package:flutter/material.dart';

import '../../features/auth/presentation/screens/profile_screen.dart';
import '../../features/catalog/models/product.dart';
import '../../features/catalog/screens/home_screen.dart';
import '../../features/catalog/screens/product_catalog_screen.dart';
import '../../features/catalog/screens/product_details_screen.dart';
import '../../features/catalog/services/product_service.dart';
import '../../features/orders/orders.dart';
import '../../features/wishlist_cart/wishlist_cart.dart';
import '../../shared/shared.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  final _visitedTabs = {0};
  late final _cart = CartRepository();

  void _selectTab(int index) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _selectedIndex = index;
      _visitedTabs.add(index);
    });
  }

  void _openShop() {
    Navigator.of(context).popUntil((route) => route.isFirst);
    _selectTab(1);
  }

  void _openProduct(Product product) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => _productDetails(product)));
  }

  void _openProductById(String id) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _ProductLookup(id: id, buildDetails: _productDetails),
      ),
    );
  }

  Widget _productDetails(Product product) {
    return ProductDetailsScreen(
      product: product,
      onCartPressed: _openCart,
      wishlistAction: FavoriteButton(productId: product.id),
      cartErrorMessage: friendlyError,
      onAddToCart: (product, size, color) => _cart.addToCart(
        productId: product.id,
        size: size ?? 'One Size',
        color: color ?? 'No Color',
      ),
    );
  }

  void _openCart() {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (routeContext) => CartScreen(
          repository: _cart,
          onShopPressed: _openShop,
          onOpenProduct: _openProductById,
          onCheckout: (_) => Navigator.of(routeContext).push(
            MaterialPageRoute<void>(
              builder: (_) => CheckoutScreen(onShopPressed: _openShop),
            ),
          ),
        ),
      ),
    );
  }

  void _openOrders() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OrderHistoryScreen(onShopPressed: _openShop),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      HomeScreen(
        onProductTap: _openProduct,
        onShopTap: _openShop,
        onCartPressed: _openCart,
      ),
      ProductCatalogScreen(
        onProductTap: _openProduct,
        onCartPressed: _openCart,
      ),
      WishlistScreen(
        showAppBar: true,
        onOpenProduct: _openProductById,
        onShopPressed: _openShop,
      ),
      ProfileScreen(onOrdersPressed: _openOrders),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          for (var i = 0; i < tabs.length; i++)
            TickerMode(
              enabled: i == _selectedIndex,
              child: _visitedTabs.contains(i)
                  ? tabs[i]
                  : const SizedBox.shrink(),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _selectTab,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_outlined),
            label: 'Shop',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            label: 'Wishlist',
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

class _ProductLookup extends StatefulWidget {
  const _ProductLookup({required this.id, required this.buildDetails});

  final String id;
  final Widget Function(Product) buildDetails;

  @override
  State<_ProductLookup> createState() => _ProductLookupState();
}

class _ProductLookupState extends State<_ProductLookup> {
  final _products = ProductService();
  late Future<Product?> _product = _products.getActiveProduct(widget.id);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Product?>(
      future: _product,
      builder: (context, snapshot) {
        if (snapshot.hasData) return widget.buildDetails(snapshot.data!);

        return Scaffold(
          appBar: AppBar(title: const Text('Product Details')),
          body: Center(
            child: snapshot.connectionState == ConnectionState.waiting
                ? const LoadingWidget(label: 'Loading product')
                : snapshot.hasError
                ? StateMessage.error(
                    title: 'Could not load this product.',
                    onRetry: () => setState(() {
                      _product = _products.getActiveProduct(widget.id);
                    }),
                  )
                : const StateMessage(
                    icon: Icons.inventory_2_outlined,
                    title: 'This product is no longer available.',
                  ),
          ),
        );
      },
    );
  }
}
