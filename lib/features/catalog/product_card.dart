import 'package:flutter/material.dart';
import 'models/product.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const ProductCard({super.key, required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasImage = product.imagePaths.isNotEmpty;
    return Card(
      color: const Color(0xFFFFF8F9),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (hasImage)
                    Image.asset(
                      product.imagePaths.first,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _imageFallback(),
                    )
                  else
                    _imageFallback(),
                  if (product.stock == 0)
                    Container(
                      color: Colors.black45,
                      alignment: Alignment.center,
                      child: const Text('OUT OF STOCK',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.category, style: const TextStyle(color: Color(0xFFC45D75), fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 5),
                  Text(product.price.toStringAsFixed(2),
                    style: const TextStyle(color: Color(0xFFC45D75), fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(product.stock > 0 ? 'Available' : 'Unavailable',
                    style: TextStyle(fontSize: 12, color: product.stock > 0 ? Colors.green : Colors.red)),
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
    child: const Icon(Icons.image_not_supported_outlined, size: 45, color: Color(0xFFC45D75)),
  );
}
