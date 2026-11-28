import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/order_item.dart';

/// Resolves cart entries against current catalogue data for checkout display.
/// This is only a preview; OrderRepository revalidates everything
/// transactionally using current Firestore product and cart documents.
class CartReader {
  CartReader({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String? get _uid => _auth.currentUser?.uid;

  Future<CartSnapshot> readCart() async {
    final uid = _uid;
    if (uid == null) throw Exception('User not signed in');

    final cartSnap = await _firestore
        .collection('users').doc(uid).collection('cart').get();

    if (cartSnap.docs.isEmpty) {
      return const CartSnapshot(items: [], cartItemIds: [], total: 0, issues: []);
    }

    final entries = <({String id, String productId, String size, String color, int quantity})>[];
    final issues = <String>[];
    for (final doc in cartSnap.docs) {
      final data = doc.data();
      final productId = data['productId'];
      final size = data['size'];
      final color = data['color'];
      final quantity = data['quantity'];
      if (productId is! String || productId.isEmpty ||
          size is! String || size.trim().isEmpty ||
          color is! String || color.trim().isEmpty ||
          quantity is! int || quantity < 1) {
        issues.add('A cart item has invalid data. Remove it before checkout.');
        continue;
      }
      entries.add((id: doc.id, productId: productId, size: size,
        color: color, quantity: quantity));
    }

    final ids = entries.map((e) => e.productId).toSet().toList();
    final products = <String, Map<String, dynamic>>{};
    for (var i = 0; i < ids.length; i += 30) {
      final batch = ids.sublist(i, i + 30 > ids.length ? ids.length : i + 30);
      final result = await _firestore.collection('products')
          .where(FieldPath.documentId, whereIn: batch).get();
      for (final doc in result.docs) {
        products[doc.id] = doc.data();
      }
    }

    final items = <OrderItem>[];
    final cartItemIds = <String>[];
    var totalCents = 0;
    for (final entry in entries) {
      final product = products[entry.productId];
      if (product == null || product['isActive'] != true) {
        issues.add('A product in your cart is no longer available.');
        continue;
      }
      final rawPrice = product['price'];
      final rawStock = product['stock'];
      if (rawPrice is! num || rawPrice <= 0 ||
          rawStock is! int || rawStock <= 0) {
        issues.add('A product in your cart has invalid price or stock data.');
        continue;
      }
      if (entry.quantity > rawStock) {
        issues.add('Only $rawStock units remain for ${product['name'] ?? 'a product'}.');
        continue;
      }
      final sizes = product['sizes'];
      final colors = product['colors'];
      if (sizes is List && sizes.isNotEmpty && !sizes.contains(entry.size)) {
        issues.add('A selected size is no longer available.');
        continue;
      }
      if (colors is List && colors.isNotEmpty && !colors.contains(entry.color)) {
        issues.add('A selected color is no longer available.');
        continue;
      }
      final unitPrice = rawPrice.toDouble();
      items.add(OrderItem(
        productId: entry.productId,
        name: product['name'] is String ? product['name'] as String : 'Product',
        size: entry.size,
        color: entry.color,
        quantity: entry.quantity,
        unitPrice: unitPrice,
      ));
      cartItemIds.add(entry.id);
      totalCents += (unitPrice * 100).round() * entry.quantity;
    }

    if (cartSnap.docs.length > 20) {
      issues.add('Orders are limited to 20 different cart items. Remove some items to continue.');
    }
    return CartSnapshot(
      items: items,
      cartItemIds: cartItemIds,
      total: totalCents / 100,
      issues: issues,
    );
  }
}

class CartSnapshot {
  final List<OrderItem> items;
  final List<String> cartItemIds;
  final double total;
  final List<String> issues;

  const CartSnapshot({
    required this.items,
    required this.cartItemIds,
    required this.total,
    required this.issues,
  });

  bool get isEmpty => items.isEmpty;
  bool get canCheckout => items.isNotEmpty && issues.isEmpty;
}
