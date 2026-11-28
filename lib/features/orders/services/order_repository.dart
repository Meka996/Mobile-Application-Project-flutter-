import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/order_item.dart';
import '../models/order_model.dart';

/// Places demo orders directly in Firestore. The transaction creates the
/// order, decreases stock and removes the user's cart items together.
class OrderRepository {
  OrderRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _ordersCol(String uid) =>
      _firestore.collection('users').doc(uid).collection('orders');

  Future<String> placeOrder() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Please sign in before placing an order.');

    final cartRef = _firestore.collection('users').doc(uid).collection('cart');
    final cartSnapshot = await cartRef.get();
    if (cartSnapshot.docs.isEmpty) throw Exception('Your cart is empty.');
    if (cartSnapshot.docs.length > 20) {
      throw Exception('Orders are limited to 20 different items.');
    }

    final orderRef = _ordersCol(uid).doc();
    return _firestore.runTransaction((transaction) async {
      // Read each cart line again inside the transaction.
      final cartDocs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
      for (final doc in cartSnapshot.docs) {
        final current = await transaction.get(doc.reference);
        if (!current.exists) throw Exception('Your cart changed. Please try again.');
        cartDocs.add(doc);
      }

      final cartLines = <({
        DocumentReference<Map<String, dynamic>> ref,
        String productId,
        String size,
        String color,
        int quantity,
      })>[];
      for (final doc in cartDocs) {
        final data = doc.data();
        final productId = data['productId'];
        final size = data['size'];
        final color = data['color'];
        final quantity = data['quantity'];
        if (productId is! String || productId.isEmpty ||
            size is! String || size.trim().isEmpty ||
            color is! String || color.trim().isEmpty ||
            quantity is! int || quantity < 1) {
          throw Exception('Your cart contains an invalid item.');
        }
        cartLines.add((ref: doc.reference, productId: productId,
          size: size, color: color, quantity: quantity));
      }

      final productIds = cartLines.map((line) => line.productId).toSet();
      final productRefs = <String, DocumentReference<Map<String, dynamic>>>{
        for (final id in productIds) id: _firestore.collection('products').doc(id),
      };
      final productData = <String, Map<String, dynamic>>{};
      for (final entry in productRefs.entries) {
        final snapshot = await transaction.get(entry.value);
        if (!snapshot.exists) throw Exception('A product in your cart is no longer available.');
        productData[entry.key] = snapshot.data()!;
      }

      final orderItems = <OrderItem>[];
      final quantities = <String, int>{};
      var subtotalCents = 0;
      for (final line in cartLines) {
        final product = productData[line.productId]!;
        final price = product['price'];
        final stock = product['stock'];
        if (product['isActive'] != true) {
          throw Exception('A product in your cart is no longer available.');
        }
        if (price is! num || price <= 0 || stock is! int || stock < 0) {
          throw Exception('A product has invalid price or stock data.');
        }
        final sizes = product['sizes'];
        final colors = product['colors'];
        if (sizes is List && sizes.isNotEmpty && !sizes.contains(line.size)) {
          throw Exception('A selected size is no longer available.');
        }
        if (colors is List && colors.isNotEmpty && !colors.contains(line.color)) {
          throw Exception('A selected color is no longer available.');
        }
        quantities[line.productId] = (quantities[line.productId] ?? 0) + line.quantity;
        final cents = (price.toDouble() * 100).round();
        subtotalCents += cents * line.quantity;
        orderItems.add(OrderItem(
          productId: line.productId,
          name: product['name'] is String ? product['name'] as String : 'Product',
          size: line.size,
          color: line.color,
          quantity: line.quantity,
          unitPrice: cents / 100,
        ));
      }

      for (final entry in quantities.entries) {
        final product = productData[entry.key]!;
        final stock = product['stock'] as int;
        if (stock < entry.value) {
          throw Exception('Not enough stock for ${product['name'] ?? 'a product'}.');
        }
      }

      // All transaction reads are complete. Now perform the writes.
      for (final entry in quantities.entries) {
        final stock = productData[entry.key]!['stock'] as int;
        transaction.update(productRefs[entry.key]!, {'stock': stock - entry.value});
      }

      const shippingThresholdCents = 15000;
      const shippingCents = 999;
      final shipping = subtotalCents >= shippingThresholdCents ? 0 : shippingCents;
      final tax = (subtotalCents * 8 / 100).round();
      final total = subtotalCents + shipping + tax;
      transaction.set(orderRef, {
        'items': orderItems.map((item) => item.toMap()).toList(),
        'total': total / 100,
        'status': 'placed',
        'createdAt': FieldValue.serverTimestamp(),
      });
      for (final line in cartLines) {
        transaction.delete(line.ref);
      }
      return orderRef.id;
    });
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
    final snapshot = await _ordersCol(uid)
        .orderBy('createdAt', descending: true).get();
    return snapshot.docs.map(OrderModel.fromDoc).toList();
  }
}