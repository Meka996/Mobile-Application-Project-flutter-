import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/order_item.dart';

/// Reads the signed-in user's cart and resolves prices from Firestore products.
class CartReader {
  CartReader({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<CartSnapshot> readCart() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('Sign in to review your cart.');

    final cart = await _firestore
        .collection('users')
        .doc(uid)
        .collection('cart')
        .get(const GetOptions(source: Source.server));
    final cartData = {for (final doc in cart.docs) doc.id: doc.data()};
    final productIds = cartData.values
        .map((line) => line['productId'])
        .whereType<String>()
        .where((id) => id.isNotEmpty && !id.contains('/'))
        .toSet()
        .toList();

    final products = <String, Map<String, dynamic>>{};
    for (var i = 0; i < productIds.length; i += 30) {
      final end = i + 30;
      final batch = productIds.sublist(i, end < productIds.length ? end : null);
      final snapshot = await _firestore
          .collection('products')
          .where(FieldPath.documentId, whereIn: batch)
          .get(const GetOptions(source: Source.server));
      for (final doc in snapshot.docs) {
        products[doc.id] = doc.data();
      }
    }

    return CartSnapshot.fromDocuments(uid, cartData, products);
  }
}

/// The cart lines and prices a customer sees before placing an order.
class CartSnapshot {
  static const lineLimit = 20;

  CartSnapshot._({
    required this.uid,
    required Map<String, OrderItem> lines,
    required Map<String, Object?> revisions,
    required List<String> issues,
    required this.blockingIssue,
  }) : lines = Map.unmodifiable(lines),
       revisions = Map.unmodifiable(revisions),
       issues = List.unmodifiable(issues);

  final String uid;
  final Map<String, OrderItem> lines;
  final Map<String, Object?> revisions;
  final List<String> issues;
  final String? blockingIssue;

  List<OrderItem> get items => lines.values.toList();
  bool get isEmpty => lines.isEmpty;
  bool get canPlaceOrder => !isEmpty && blockingIssue == null;
  int get subtotalCents =>
      lines.values.fold(0, (total, line) => total + line.lineTotalCents);
  int get shippingCents => isEmpty || subtotalCents >= 15000 ? 0 : 999;
  int get taxCents => (subtotalCents * 8 + 50) ~/ 100;
  int get totalCents => subtotalCents + shippingCents + taxCents;

  factory CartSnapshot.fromDocuments(
    String uid,
    Map<String, Map<String, dynamic>> cart,
    Map<String, Map<String, dynamic>> products,
  ) {
    final lines = <String, OrderItem>{};
    final revisions = <String, Object?>{};
    final issues = <String>[];
    final quantities = <String, int>{};

    for (final entry in cart.entries) {
      final productId = entry.value['productId'];
      final quantity = entry.value['quantity'];
      final size = entry.value['size'];
      final color = entry.value['color'];
      if (productId is! String ||
          productId.isEmpty ||
          productId.contains('/') ||
          quantity is! int ||
          quantity < 1 ||
          size is! String ||
          color is! String) {
        issues.add(
          'An invalid cart item was skipped. Remove it from your cart.',
        );
        continue;
      }

      final product = products[productId];
      final name = product?['name'];
      final stock = product?['stock'];
      final price = product?['price'];
      final label = name is String && name.isNotEmpty ? name : 'A cart item';
      if (product?['isActive'] != true ||
          stock is! int ||
          stock < 1 ||
          price is! num ||
          !(price * 100).isFinite ||
          price < 0.01) {
        issues.add('$label is unavailable and will stay in your cart.');
        continue;
      }

      lines[entry.key] = OrderItem(
        productId: productId,
        name: label,
        size: size,
        color: color,
        quantity: quantity,
        unitPrice: (price * 100).round() / 100,
      );
      revisions[entry.key] = entry.value['updatedAt'];
      quantities.update(
        productId,
        (total) => total + quantity,
        ifAbsent: () => quantity,
      );
    }

    String? blockingIssue;
    if (lines.length > lineLimit) {
      blockingIssue =
          'An order can contain up to $lineLimit cart lines. Remove some items to continue.';
    } else {
      for (final entry in quantities.entries) {
        final product = products[entry.key]!;
        final stock = product['stock'] as int;
        if (entry.value > stock) {
          final name = product['name'];
          blockingIssue =
              'Only $stock of $name are in stock across all sizes and colors. Adjust your cart.';
          break;
        }
      }
    }

    return CartSnapshot._(
      uid: uid,
      lines: lines,
      revisions: revisions,
      issues: issues,
      blockingIssue: blockingIssue,
    );
  }

  bool matchesReviewedLines(CartSnapshot latest) {
    if (uid != latest.uid || lines.length != latest.lines.length) return false;
    for (final entry in lines.entries) {
      final current = latest.lines[entry.key];
      if (current == null ||
          revisions[entry.key] != latest.revisions[entry.key] ||
          !entry.value.matches(current)) {
        return false;
      }
    }
    return true;
  }
}
