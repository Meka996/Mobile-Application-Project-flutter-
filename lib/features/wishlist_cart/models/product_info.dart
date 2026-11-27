/// Read-only view of a document in `products/{productId}`.
///
/// This file has NO Firebase imports on purpose, so it can be unit tested
/// without a Firebase connection. The repositories convert Firestore data
/// into this class with [ProductInfo.fromMap].
class ProductInfo {
  const ProductInfo({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.isActive,
    required this.stock,
  });

  final String id;
  final String name;
  final double price;
  final String? imageUrl;
  final bool isActive;
  final int stock;

  factory ProductInfo.fromMap(String id, Map<String, dynamic> data) {
    final images = data['imageUrls'];
    String? firstImage;
    if (images is List && images.isNotEmpty && images.first is String) {
      firstImage = images.first as String;
    }

    final rawPrice = data['price'];
    final rawStock = data['stock'];

    return ProductInfo(
      id: id,
      name: data['name'] is String ? data['name'] as String : 'Unnamed product',
      price: rawPrice is num ? rawPrice.toDouble() : 0,
      imageUrl: firstImage,
      isActive: data['isActive'] == true,
      stock: rawStock is num ? rawStock.toInt() : 0,
    );
  }

  /// A product can be bought only if it is active, in stock and has a price.
  bool get isPurchasable => isActive && stock > 0 && price > 0;
}

/// One saved favorite. [product] is null when the product document no
/// longer exists (so the user can still remove the dead favorite).
class FavoriteItem {
  const FavoriteItem({required this.productId, required this.product});

  final String productId;
  final ProductInfo? product;
}
