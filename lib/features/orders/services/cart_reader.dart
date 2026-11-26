import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/order_item.dart';

/// Reads the signed-in user's live cart from Firestore and
/// cross-references product prices from the products collection.
///
/// Cart schema (Task D):
///   users/{uid}/cart/{cartItemId}: productId, size, color, quantity, updatedAt
///
/// Product schema (Task C):
///   products/{productId}: name, price, isActive, sizes, colors, ...
///
/// This reader returns only active items; it re-fetches prices from
/// products to reflect current catalogue values before checkout.
/// Totals are client-calculated — NOT payment-grade.
class CartReader {
  CartReader({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String? get _uid => _auth.currentUser?.uid;

  /// Returns a resolved list of [OrderItem] ready for checkout, plus
  /// the matching cart document IDs (for atomic cart clearing) and
  /// a client-calculated [total].
  Future<CartSnapshot> readCart() async {
    final uid = _uid;
    if (uid == null) throw Exception('User not signed in');

    // 1. Fetch cart documents
    final cartSnap = await _firestore
        .collection('users')
        .doc(uid)
        .collection('cart')
        .get();

    if (cartSnap.docs.isEmpty) {
      return CartSnapshot(items: [], cartItemIds: [], total: 0.0, issues: []);
    }

    // 2. Collect product IDs to fetch (deduplicated)
    final productIds =
        cartSnap.docs.map((d) => d['productId'] as String).toSet().toList();

    // Firestore whereIn supports up to 30 items; handle overflow gracefully
    final productDocs = <String, Map<String, dynamic>>{};
    for (var i = 0; i < productIds.length; i += 30) {
      final batch = productIds.sublist(
          i, i + 30 > productIds.length ? productIds.length : i + 30);
      final snap = await _firestore
          .collection('products')
          .where(FieldPath.documentId, whereIn: batch)
          .get();
      for (final d in snap.docs) {
        productDocs[d.id] = d.data();
      }
    }

    // 3. Build OrderItem list; flag issues for missing/inactive products
    final items = <OrderItem>[];
    final cartItemIds = <String>[];
    final issues = <String>[];
    double total = 0.0;

    for (final cartDoc in cartSnap.docs) {
      final data = cartDoc.data();
      final productId = data['productId'] as String? ?? '';
      final product = productDocs[productId];

      if (product == null) {
        issues.add('Product $productId not found — item skipped');
        continue;
      }
      if (product['isActive'] == false) {
        issues.add('${product['name']} is unavailable — item skipped');
        continue;
      }

      final unitPrice = (product['price'] as num?)?.toDouble() ?? 0.0;
      final quantity = (data['quantity'] as num?)?.toInt() ?? 1;
      final item = OrderItem(
        productId: productId,
        name: product['name'] as String? ?? '',
        size: data['size'] as String? ?? '',
        color: data['color'] as String? ?? '',
        quantity: quantity,
        unitPrice: unitPrice,
      );
      items.add(item);
      cartItemIds.add(cartDoc.id);
      total += item.lineTotal;
    }

    return CartSnapshot(
      items: items,
      cartItemIds: cartItemIds,
      total: total,
      issues: issues,
    );
  }
}

class CartSnapshot {
  final List<OrderItem> items;
  final List<String> cartItemIds;
  final double total;
  final List<String> issues; // warnings about skipped/unavailable items

  bool get isEmpty => items.isEmpty;

  const CartSnapshot({
    required this.items,
    required this.cartItemIds,
    required this.total,
    required this.issues,
  });
}