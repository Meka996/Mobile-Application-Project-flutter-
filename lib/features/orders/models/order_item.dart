/// Snapshot of a single product line in a placed order.
/// Fields match the agreed Firestore schema exactly.
class OrderItem {
  final String productId;
  final String name;
  final String size;
  final String color;
  final int quantity;
  final double unitPrice;

  const OrderItem({
    required this.productId,
    required this.name,
    required this.size,
    required this.color,
    required this.quantity,
    required this.unitPrice,
  });

  double get lineTotal => unitPrice * quantity;

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: map['productId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      size: map['size'] as String? ?? '',
      color: map['color'] as String? ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'name': name,
        'size': size,
        'color': color,
        'quantity': quantity,
        'unitPrice': unitPrice,
      };
}