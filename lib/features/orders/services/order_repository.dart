import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/order_item.dart';
import '../models/order_model.dart';

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
  OrderRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> _ordersCol(String uid) =>
      _firestore.collection('users').doc(uid).collection('orders');

  /// Creates an order and clears the cart atomically.
  /// [cartItemIds] — the document IDs of the cart items to delete.
  /// Throws [Exception] if the user is not signed in.
  /// Throws [FirebaseException] if Firestore rejects the write.
  Future<String> placeOrder({
    required List<OrderItem> items,
    required double total,
    required List<String> cartItemIds,
  }) async {
    final uid = _uid;
    if (uid == null) throw Exception('User not signed in');
    if (items.isEmpty) throw Exception('Cart is empty');
    if (items.length > 20) throw Exception('Order exceeds 20 line items');

    final batch = _firestore.batch();

    // 1. New order document
    final orderRef = _ordersCol(uid).doc();
    batch.set(orderRef, {
      'items': items.map((i) => i.toMap()).toList(),
      'total': total,
      'status': 'placed',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 2. Delete captured cart documents
    final cartCol = _firestore
        .collection('users')
        .doc(uid)
        .collection('cart');
    for (final id in cartItemIds) {
      batch.delete(cartCol.doc(id));
    }

    await batch.commit();
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