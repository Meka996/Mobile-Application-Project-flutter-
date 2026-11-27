import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_layout.dart';
import '../../../shared/shared.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../widgets/catalog_filters.dart';
import '../widgets/product_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.onProductTap,
    this.onShopTap,
    this.onCartPressed,
  });

  final ValueChanged<Product> onProductTap;
  final VoidCallback? onShopTap;
  final VoidCallback? onCartPressed;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _productService = ProductService();
  final _searchController = TextEditingController();
  late Stream<List<Product>> _productsStream = _productService.getProducts();
  String _searchQuery = '';
  String _selectedCategory = CatalogFilters.allCategories;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const VeloraLogo(),
        actions: [
          if (widget.onCartPressed != null)
            IconButton(
              onPressed: widget.onCartPressed,
              tooltip: 'Cart',
              icon: const Icon(Icons.shopping_bag_outlined),
            ),
        ],
      ),
      body: StreamBuilder<List<Product>>(
        stream: _productsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingWidget(label: 'Loading products');
          }
          if (snapshot.hasError) {
            return StateMessage.error(
              title: 'Unable to load products.',
              message: 'Check your connection and try again.',
              onRetry: () => setState(() {
                _productsStream = _productService.getProducts();
              }),
            );
          }

          final products = filterProducts(
            snapshot.data ?? [],
            _searchQuery,
            _selectedCategory,
          );
          final isFiltering =
              _searchQuery.trim().isNotEmpty ||
              _selectedCategory != CatalogFilters.allCategories;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppLayout.catalogMaxWidth,
              ),
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.only(bottom: AppLayout.page),
                children: [
                  _CollectionBanner(onShopTap: widget.onShopTap),
                  CatalogFilters(
                    controller: _searchController,
                    category: _selectedCategory,
                    onSearchChanged: (value) =>
                        setState(() => _searchQuery = value),
                    onCategoryChanged: (value) =>
                        setState(() => _selectedCategory = value),
                    showCategoryHeading: true,
                  ),
                  const SizedBox(height: AppLayout.page),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppLayout.large,
                    ),
                    child: Text(
                      isFiltering ? 'Search Results' : 'Featured Products',
                      style: text.titleLarge,
                    ),
                  ),
                  const SizedBox(height: AppLayout.medium),
                  if (products.isEmpty)
                    const StateMessage(
                      icon: Icons.search_off_outlined,
                      title: 'No products found.',
                    )
                  else
                    SizedBox(
                      height: 220 + MediaQuery.textScalerOf(context).scale(90),
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppLayout.large,
                        ),
                        itemCount: products.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(width: AppLayout.medium),
                        itemBuilder: (context, index) => SizedBox(
                          width: 190,
                          child: ProductCard(
                            product: products[index],
                            onTap: () => widget.onProductTap(products[index]),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CollectionBanner extends StatelessWidget {
  const _CollectionBanner({this.onShopTap});

  final VoidCallback? onShopTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme;
    final onPink = theme.colorScheme.onPrimaryContainer;

    return Container(
      margin: const EdgeInsets.all(AppLayout.large),
      padding: const EdgeInsets.all(AppLayout.page),
      constraints: const BoxConstraints(minHeight: 220),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.babyPink, AppColors.blushPink],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppLayout.cardRadius),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NEW COLLECTION',
            style: text.labelMedium?.copyWith(color: onPink, letterSpacing: 2),
          ),
          const SizedBox(height: AppLayout.small),
          Text(
            'Spring Elegance',
            style: text.displaySmall?.copyWith(color: onPink),
          ),
          const SizedBox(height: AppLayout.small),
          Text(
            'Discover your style with VELORA.',
            style: text.bodyMedium?.copyWith(color: onPink),
          ),
          const SizedBox(height: AppLayout.large),
          if (onShopTap != null)
            ElevatedButton(onPressed: onShopTap, child: const Text('Shop Now')),
        ],
      ),
    );
  }
}
