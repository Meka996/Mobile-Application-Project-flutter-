import 'package:flutter/material.dart';
import '../models/product.dart';

typedef ProductCartCallback = void Function(Product product, String? selectedSize, String? selectedColor);
typedef ProductFavoriteCallback = void Function(Product product);

class ProductDetailsScreen extends StatefulWidget {
  final Product product;
  final ProductCartCallback? onAddToCart;
  final ProductFavoriteCallback? onAddToWishlist;

  const ProductDetailsScreen({super.key, required this.product, this.onAddToCart, this.onAddToWishlist});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  String? _selectedSize;
  String? _selectedColor;

  bool get _hasRequiredOptions =>
      (widget.product.sizes.isEmpty || _selectedSize != null) &&
      (widget.product.colors.isEmpty || _selectedColor != null);

  void _addToCart() {
    final callback = widget.onAddToCart;
    if (callback == null || widget.product.stock <= 0 || !_hasRequiredOptions) return;
    callback(widget.product, _selectedSize, _selectedColor);
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final isAvailable = product.stock > 0;
    final hasImages = product.imagePaths.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F9),
      appBar: AppBar(
        title: const Text('Product Details', style: TextStyle(color: Color(0xFFC45D75), fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFFFF8F9),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFC45D75)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 350,
              width: double.infinity,
              child: hasImages
                  ? PageView.builder(
                      itemCount: product.imagePaths.length,
                      itemBuilder: (context, index) => Image.asset(
                        product.imagePaths[index],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _imageFallback(),
                      ),
                    )
                  : _imageFallback(),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.category.toUpperCase(), style: const TextStyle(color: Color(0xFFC45D75), fontWeight: FontWeight.w600, letterSpacing: 1.2)),
                  const SizedBox(height: 8),
                  Text(product.name, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
                  const SizedBox(height: 10),
                  Text(product.price.toStringAsFixed(2), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFC45D75))),
                  const SizedBox(height: 16),
                  Text(product.description, style: const TextStyle(fontSize: 15, height: 1.6, color: Colors.black87)),
                  const SizedBox(height: 22),
                  const Text('Available Sizes', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  if (product.sizes.isEmpty) const Text('No sizes available')
                  else Wrap(spacing: 10, runSpacing: 10, children: product.sizes.map((size) {
                    final selected = _selectedSize == size;
                    return ChoiceChip(label: Text(size), selected: selected, selectedColor: const Color(0xFFE8A8B4),
                      onSelected: (_) => setState(() => _selectedSize = size));
                  }).toList()),
                  const SizedBox(height: 22),
                  const Text('Available Colors', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  if (product.colors.isEmpty) const Text('No colors available')
                  else Wrap(spacing: 10, runSpacing: 10, children: product.colors.map((color) {
                    final selected = _selectedColor == color;
                    return ChoiceChip(label: Text(color), selected: selected, selectedColor: const Color(0xFFE8A8B4),
                      onSelected: (_) => setState(() => _selectedColor = color));
                  }).toList()),
                  const SizedBox(height: 22),
                  Row(children: [
                    const Text('Availability: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(isAvailable ? 'In Stock (${product.stock})' : 'Out of Stock',
                      style: TextStyle(color: isAvailable ? Colors.green : Colors.red, fontWeight: FontWeight.w600)),
                  ]),
                  const SizedBox(height: 24),
                  SizedBox(width: double.infinity, child: ElevatedButton(
                    onPressed: isAvailable && _hasRequiredOptions && widget.onAddToCart != null ? _addToCart : null,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC45D75), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: const Text('Add to Cart'),
                  )),
                  const SizedBox(height: 10),
                  SizedBox(width: double.infinity, child: OutlinedButton(
                    onPressed: widget.onAddToWishlist == null ? null : () => widget.onAddToWishlist!(product),
                    style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFC45D75), side: const BorderSide(color: Color(0xFFC45D75)), padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: const Text('Add to Wishlist'),
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageFallback() => Container(
    color: const Color(0xFFFADCE4),
    alignment: Alignment.center,
    child: const Icon(Icons.image_not_supported_outlined, size: 60, color: Color(0xFFC45D75)),
  );
}
