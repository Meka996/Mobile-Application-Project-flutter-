import 'product_info.dart';

/// Builds the stable cart document ID for one product + size + color variant.
///
/// Every part is URL-encoded, so it can never contain `/` (illegal in a
/// Firestore document ID) or `|` (our separator). Same variant => same ID,
/// which is how "add the same item again" increments instead of duplicating.
String cartItemIdFor({
  required String productId,
  required String size,
  required String color,
}) {
  return '${Uri.encodeComponent(productId)}'
      '|${Uri.encodeComponent(size)}'
      '|${Uri.encodeComponent(color)}';
}

/// Converts a price like 89.99 to whole cents (8999) so totals never suffer
/// from floating point errors such as 0.1 + 0.2 = 0.30000000000000004.
int toCents(double price) => (price * 100).round();

/// Formats cents as a price with exactly two decimals, e.g. 8900 -> $89.00.
String formatCents(int cents) {
  final whole = cents ~/ 100;
  final fraction = (cents % 100).toString().padLeft(2, '0');
  return '\$$whole.$fraction';
}

/// The raw data stored in `users/{uid}/cart/{cartItemId}`.
class CartEntry {
  const CartEntry({
    required this.id,
    required this.productId,
    required this.size,
    required this.color,
    required this.quantity,
  });

  final String id;
  final String productId;
  final String size;
  final String color;
  final int quantity;
}

/// A cart entry joined with its live product document.
class CartLine {
  const CartLine({required this.entry, required this.product});

  final CartEntry entry;

  /// Null when `products/{productId}` does not exist any more.
  final ProductInfo? product;

  bool get isPurchasable {
    final p = product;
    return p != null && p.isPurchasable;
  }

  int get unitPriceCents {
    final p = product;
    return p == null ? 0 : toCents(p.price);
  }

  /// Unit price x quantity. Unavailable lines contribute nothing.
  int get subtotalCents => isPurchasable ? unitPriceCents * entry.quantity : 0;

  bool get exceedsStock {
    final p = product;
    return p != null && p.isPurchasable && entry.quantity > p.stock;
  }

  bool get canIncrease {
    final p = product;
    return p != null && p.isPurchasable && entry.quantity < p.stock;
  }

  /// Human readable warning, or null when the line is fine.
  String? get problem {
    final p = product;
    if (p == null || !p.isActive) return 'This product is no longer available.';
    if (p.stock <= 0) return 'Out of stock.';
    if (entry.quantity > p.stock) return 'Only ${p.stock} left in stock.';
    return null;
  }
}

/// Everything the cart screen (and the checkout hand-off) needs.
class CartSnapshot {
  const CartSnapshot({required this.lines});

  final List<CartLine> lines;

  bool get isEmpty => lines.isEmpty;

  /// Total number of pieces (sum of quantities), handy for a cart badge.
  int get itemCount =>
      lines.fold<int>(0, (sum, line) => sum + line.entry.quantity);

  /// Lines that can really be bought. Task E should use these for orders.
  List<CartLine> get purchasableLines =>
      lines.where((line) => line.isPurchasable && !line.exceedsStock).toList();

  int get totalCents =>
      lines.fold<int>(0, (sum, line) => sum + line.subtotalCents);

  bool get hasProblems => lines.any((line) => line.problem != null);

  /// Checkout is allowed only when every cart line is currently purchasable
  /// and every requested quantity is within the product's available stock.
  /// This prevents unavailable products from being silently skipped at checkout.
  bool get canCheckout =>
      lines.isNotEmpty &&
      lines.every((line) => line.isPurchasable && !line.exceedsStock);
}
