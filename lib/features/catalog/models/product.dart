class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String category;
  final List<String> imagePaths;
  final List<String> sizes;
  final List<String> colors;
  final int stock;
  final bool isActive;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.imagePaths,
    required this.sizes,
    required this.colors,
    required this.stock,
    required this.isActive,
  });

  factory Product.fromMap(String id, Map<String, dynamic> data) {
    return Product(
      id: id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      category: data['category'] as String? ?? '',
      imagePaths: List<String>.from(data['imagePaths'] ?? []),
      sizes: List<String>.from(data['sizes'] ?? []),
      colors: List<String>.from(data['colors'] ?? []),
      stock: (data['stock'] as num?)?.toInt() ?? 0,
      isActive: data['isActive'] as bool? ?? false,
    );
  }
}
