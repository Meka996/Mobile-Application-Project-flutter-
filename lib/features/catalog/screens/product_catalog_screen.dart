import 'package:flutter/material.dart';

import '../../../core/theme/app_layout.dart';
import '../../../shared/shared.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../widgets/catalog_filters.dart';
import '../widgets/product_card.dart';

class ProductCatalogScreen extends StatefulWidget {
  const ProductCatalogScreen({
    super.key,
    required this.onProductTap,
    this.onCartPressed,
  });

  final ValueChanged<Product> onProductTap;
  final VoidCallback? onCartPressed;

  @override
  State<ProductCatalogScreen> createState() => _ProductCatalogScreenState();
}

class _ProductCatalogScreenState extends State<ProductCatalogScreen> {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop'),
        actions: [
          if (widget.onCartPressed != null)
            IconButton(
              onPressed: widget.onCartPressed,
              tooltip: 'Cart',
              icon: const Icon(Icons.shopping_bag_outlined),
            ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppLayout.catalogMaxWidth,
          ),
          child: StreamBuilder<List<Product>>(
            stream: _productsStream,
            builder: (context, snapshot) {
              final products = filterProducts(
                snapshot.data ?? [],
                _searchQuery,
                _selectedCategory,
              );

              Widget? state;
              if (snapshot.connectionState == ConnectionState.waiting) {
                state = const LoadingWidget(label: 'Loading products');
              } else if (snapshot.hasError) {
                state = StateMessage.error(
                  title: 'Unable to load products.',
                  message: 'Check your connection and try again.',
                  onRetry: () => setState(() {
                    _productsStream = _productService.getProducts();
                  }),
                );
              } else if (products.isEmpty) {
                state = const StateMessage(
                  icon: Icons.search_off_outlined,
                  title: 'No products found.',
                  message: 'Try a different search or category.',
                );
              }

              return CustomScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppLayout.large,
                      ),
                      child: CatalogFilters(
                        controller: _searchController,
                        category: _selectedCategory,
                        onSearchChanged: (value) =>
                            setState(() => _searchQuery = value),
                        onCategoryChanged: (value) =>
                            setState(() => _selectedCategory = value),
                      ),
                    ),
                  ),
                  if (state != null)
                    SliverFillRemaining(hasScrollBody: false, child: state)
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        AppLayout.large,
                        0,
                        AppLayout.large,
                        AppLayout.page,
                      ),
                      sliver: SliverLayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.crossAxisExtent;
                          final textScaler = MediaQuery.textScalerOf(context);
                          final columns = width >= 960
                              ? 4
                              : width >= 620
                              ? 3
                              : width >=
                                    textScaler.scale(140) * 2 + AppLayout.medium
                              ? 2
                              : 1;
                          return SliverGrid.builder(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: columns,
                                  crossAxisSpacing: AppLayout.medium,
                                  mainAxisSpacing: AppLayout.medium,
                                  mainAxisExtent: 150 + textScaler.scale(108),
                                ),
                            itemCount: products.length,
                            itemBuilder: (context, index) => ProductCard(
                              product: products[index],
                              onTap: () => widget.onProductTap(products[index]),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
