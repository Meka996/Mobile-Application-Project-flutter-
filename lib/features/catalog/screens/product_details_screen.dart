import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_layout.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/shared.dart';
import '../models/product.dart';

// Cart receives the product and the selected variant.
typedef ProductCartCallback = FutureOr<void> Function(
  Product product,
  String? selectedSize,
  String? selectedColor,
);

// Wishlist receives the product.
typedef ProductFavoriteCallback = void Function(Product product);

class ProductDetailsScreen extends StatefulWidget {
  final Product product;
  final ProductCartCallback? onAddToCart;
  final ProductFavoriteCallback? onAddToWishlist;
  final Widget? wishlistAction;
  final VoidCallback? onCartPressed;
  final String Function(Object error)? cartErrorMessage;

  const ProductDetailsScreen({
    super.key,
    required this.product,
    this.onAddToCart,
    this.onAddToWishlist,
    this.wishlistAction,
    this.onCartPressed,
    this.cartErrorMessage,
  });

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  String? _selectedSize;
  String? _selectedColor;
  bool _addingToCart = false;

  bool get _hasRequiredOptions {
    final sizeSelected = widget.product.sizes.isEmpty || _selectedSize != null;

    final colorSelected =
        widget.product.colors.isEmpty || _selectedColor != null;

    return sizeSelected && colorSelected;
  }

  Future<void> _addToCart() async {
    final callback = widget.onAddToCart;

    if (_addingToCart ||
        callback == null ||
        widget.product.stock <= 0 ||
        !_hasRequiredOptions) {
      return;
    }

    setState(() => _addingToCart = true);
    try {
      await callback(widget.product, _selectedSize, _selectedColor);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Added to your cart.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.cartErrorMessage?.call(error) ??
                'Could not add this item to your cart.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _addingToCart = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final available = product.stock > 0;
    final theme = Theme.of(context);
    final text = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
        actions: [
          if (widget.wishlistAction != null) widget.wishlistAction!,
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
          constraints: const BoxConstraints(maxWidth: AppLayout.detailMaxWidth),
          child: ListView(
            children: [
              SizedBox(
                height: 350,
                child: product.imageUrls.isEmpty
                    ? const ProductImage(url: null, radius: 0)
                    : PageView.builder(
                        itemCount: product.imageUrls.length,
                        itemBuilder: (_, index) => ProductImage(
                          url: product.imageUrls[index],
                          semanticLabel: product.name,
                          radius: 0,
                        ),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppLayout.page),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.category.toUpperCase(),
                      style: text.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: AppLayout.small),
                    Text(product.name, style: text.headlineMedium),
                    const SizedBox(height: AppLayout.small),
                    Text(
                      '\$${product.price.toStringAsFixed(2)}',
                      style: AppTextStyles.price(context, prominent: true),
                    ),
                    const SizedBox(height: AppLayout.large),
                    Text(product.description, style: text.bodyLarge),
                    const SizedBox(height: AppLayout.page),
                    _VariantOptions(
                      heading: 'Available Sizes',
                      emptyLabel: 'No sizes available',
                      values: product.sizes,
                      selected: _selectedSize,
                      onSelect: (size) => setState(() => _selectedSize = size),
                    ),
                    const SizedBox(height: AppLayout.large),
                    _VariantOptions(
                      heading: 'Available Colors',
                      emptyLabel: 'No colors available',
                      values: product.colors,
                      selected: _selectedColor,
                      onSelect: (color) =>
                          setState(() => _selectedColor = color),
                    ),
                    const SizedBox(height: AppLayout.large),
                    Text(
                      available
                          ? 'In Stock (${product.stock})'
                          : 'Out of Stock',
                      style: text.labelLarge?.copyWith(
                        color: available
                            ? AppColors.success
                            : theme.colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: AppLayout.page),
                    VeloraButton(
                      text: _addingToCart ? 'Adding to Cart...' : 'Add to Cart',
                      icon: Icons.shopping_bag_outlined,
                      onPressed:
                          !_addingToCart &&
                              available &&
                              _hasRequiredOptions &&
                              widget.onAddToCart != null
                          ? _addToCart
                          : null,
                    ),
                    if (widget.onAddToWishlist != null &&
                        widget.wishlistAction == null) ...[
                      const SizedBox(height: AppLayout.small),
                      VeloraButton(
                        text: 'Add to Wishlist',
                        icon: Icons.favorite_border,
                        outlined: true,
                        onPressed: () => widget.onAddToWishlist!(product),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VariantOptions extends StatelessWidget {
  const _VariantOptions({
    required this.heading,
    required this.emptyLabel,
    required this.values,
    required this.selected,
    required this.onSelect,
  });

  final String heading;
  final String emptyLabel;
  final List<String> values;
  final String? selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(heading, style: text.titleMedium),
        const SizedBox(height: AppLayout.small),
        if (values.isEmpty)
          Text(emptyLabel, style: text.bodySmall)
        else
          Wrap(
            spacing: AppLayout.small,
            runSpacing: AppLayout.small,
            children: [
              for (final value in values)
                ChoiceChip(
                  label: Text(value),
                  selected: selected == value,
                  onSelected: (_) => onSelect(value),
                ),
            ],
          ),
      ],
    );
  }
}
