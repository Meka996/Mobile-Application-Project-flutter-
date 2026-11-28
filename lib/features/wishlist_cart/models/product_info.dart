/// Read-only view of a document in products/{productId}.
class ProductInfo {
  const ProductInfo({
    required this.id,
    required this.name,
    required this.price,
    required this.imagePath,
    required this.isActive,
    required this.stock,
  });

  final String id;
  final String name;
  final double price;
  final String? imagePath;
  final bool isActive;
  final int stock;

  factory ProductInfo.fromMap(String id, Map<String, dynamic> data) {
    final images = data['imagePaths'];
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
      imagePath: firstImage,
      isActive: data['isActive'] == true,
      stock: rawStock is num ? rawStock.toInt() : 0,
    );
  }

  bool get isPurchasable => isActive && stock > 0 && price > 0;
}

class FavoriteItem {
  const FavoriteItem({required this.productId, required this.product});
  final String productId;
  final ProductInfo? product;
}
