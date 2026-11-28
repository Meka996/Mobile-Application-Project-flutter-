import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../models/order_model.dart';

/// Sends order requests to the trusted VELORA API. The API verifies the
/// Firebase ID token and performs all price/stock checks with the Admin SDK.
class OrderRepository {
  OrderRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    http.Client? client,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _client = client ?? http.Client();

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final http.Client _client;

  static const String _apiBaseUrl = String.fromEnvironment(
    'ORDER_API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );

  CollectionReference<Map<String, dynamic>> _ordersCol(String uid) =>
      _firestore.collection('users').doc(uid).collection('orders');

  Future<String> placeOrder() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Please sign in before placing an order.');
    final baseUrl = _apiBaseUrl.trim().replaceFirst(RegExp(r'/+$'), '');
    if (baseUrl.isEmpty) throw Exception('Order API URL is not configured.');
    final token = await user.getIdToken(true);
    if (token == null || token.isEmpty) throw Exception('Could not verify your session. Please sign in again.');

    final response = await _client.post(
      Uri.parse(baseUrl + '/orders'),
      headers: {
        'Authorization': 'Bearer ' + token,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: '{}',
    );
    Map<String, dynamic> data = {};
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) data = decoded;
    } catch (_) {}
    if (response.statusCode != 201) {
      throw Exception(data['error'] is String ? data['error'] as String : 'Order request failed (' + response.statusCode.toString() + ').');
    }
    final orderId = data['orderId'];
    if (orderId is! String || orderId.isEmpty) throw Exception('The order API returned an invalid response.');
    return orderId;
  }

  Stream<List<OrderModel>> ordersStream() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return _ordersCol(uid).orderBy('createdAt', descending: true).snapshots()
        .map((snapshot) => snapshot.docs.map(OrderModel.fromDoc).toList());
  }

  Future<List<OrderModel>> fetchOrders() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return [];
    final snapshot = await _ordersCol(uid).orderBy('createdAt', descending: true).get();
    return snapshot.docs.map(OrderModel.fromDoc).toList();
  }
}