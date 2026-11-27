import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/order_model.dart';
import 'cart_reader.dart';

class CartChangedException implements Exception {
  const CartChangedException();
}

/// Handles all Firestore reads and writes for the orders feature.
///
/// Security rules allow:
///   CREATE  users/{uid}/orders  — fields: items(1-20), total>0, status=='placed', createdAt
///   READ    users/{uid}/orders  — own documents only
///   UPDATE / DELETE — denied
///
/// LIMITATION: totals are client-calculated and are NOT payment-grade.
/// No stock is decremented (product writes are denied by rules).
class OrderRepository {
  OrderRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> _ordersCol(String uid) =>
      _firestore.collection('users').doc(uid).collection('orders');

  /// Rechecks reviewed lines and product prices, then writes the order and
  /// removes those lines in the same transaction.
  Future<String> placeOrder(CartSnapshot reviewedCart) async {
    final uid = _uid;
    if (uid == null || uid != reviewedCart.uid) {
      throw StateError('Your sign-in session changed.');
    }
    if (!reviewedCart.canPlaceOrder) {
      throw StateError('Your cart cannot be checked out.');
    }

    final orderRef = _ordersCol(uid).doc();
    final cartCol = _firestore.collection('users').doc(uid).collection('cart');
    final cartRefs = reviewedCart.lines.keys.map(cartCol.doc).toList();
    final productIds = reviewedCart.items.map((item) => item.productId).toSet();

    final placed = await _firestore.runTransaction<bool>((transaction) async {
      final cart = <String, Map<String, dynamic>>{};
      for (final ref in cartRefs) {
        final data = (await transaction.get(ref)).data();
        if (data != null) cart[ref.id] = data;
      }

      final products = <String, Map<String, dynamic>>{};
      for (final id in productIds) {
        final ref = _firestore.collection('products').doc(id);
        final data = (await transaction.get(ref)).data();
        if (data != null) products[id] = data;
      }

      final latest = CartSnapshot.fromDocuments(uid, cart, products);
      if (!latest.canPlaceOrder || !reviewedCart.matchesReviewedLines(latest)) {
        return false;
      }

      transaction.set(orderRef, {
        'items': latest.items.map((item) => item.toMap()).toList(),
        'total': latest.totalCents / 100,
        'status': 'placed',
        'createdAt': FieldValue.serverTimestamp(),
      });
      for (final ref in cartRefs) {
        transaction.delete(ref);
      }
      return true;
    });
    // Keep the UI exception on the Dart side of the Firestore web bridge.
    if (!placed) throw const CartChangedException();
    return orderRef.id;
  }

  /// Stream of this user's orders, newest first.
  /// Returns an empty stream if the user is not signed in.
  Stream<List<OrderModel>> ordersStream() {
    final uid = _uid;
    if (uid == null) return const Stream.empty();
    return _ordersCol(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(OrderModel.fromDoc).toList());
  }

  /// One-time fetch of orders (for history screen initial load).
  Future<List<OrderModel>> fetchOrders() async {
    final uid = _uid;
    if (uid == null) return [];
    final snap = await _ordersCol(uid)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map(OrderModel.fromDoc).toList();
  }
}
