import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/order_model.dart';

/// Creates orders through a trusted Firebase callable function.
/// The server reloads the cart/catalogue, validates stock and prices,
/// decrements inventory and clears the cart in one Firestore transaction.
class OrderRepository {
  OrderRepository({
    FirebaseFunctions? functions,
    FirebaseAuth? auth,
  })  : _functions = functions ?? FirebaseFunctions.instanceFor(region: 'europe-west3'),
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFunctions _functions;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> _ordersCol(String uid) =>
      FirebaseFirestore.instance.collection('users').doc(uid).collection('orders');

  Future<String> placeOrder() async {
    if (_auth.currentUser == null) {
      throw Exception('User not signed in');
    }
    final callable = _functions.httpsCallable('placeOrder');
    final result = await callable.call();
    final data = result.data;
    if (data is! Map || data['orderId'] is! String ||
        (data['orderId'] as String).isEmpty) {
      throw Exception('The server returned an invalid order response.');
    }
    return data['orderId'] as String;
  }

  /// Stream this user's orders, newest first.
  Stream<List<OrderModel>> ordersStream() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return _ordersCol(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(OrderModel.fromDoc).toList());
  }

  /// One-time order history fetch.
  Future<List<OrderModel>> fetchOrders() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return [];
    final snapshot = await _ordersCol(uid)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map(OrderModel.fromDoc).toList();
  }
}
