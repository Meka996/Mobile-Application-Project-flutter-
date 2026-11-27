import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/cart_line.dart';
import '../models/product_info.dart';
import 'product_reader.dart';
import 'wishlist_cart_errors.dart';

/// All Firestore work for `users/{uid}/cart/{cartItemId}`.
///
/// Each cart document has EXACTLY these fields (rules reject extras):
/// productId, size, color, quantity (int > 0), updatedAt.
/// The price is NEVER stored here; it is read live from `products`.
class CartRepository {
  CartRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    ProductReader? products,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _products = products ?? ProductReader(firestore: firestore);

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final ProductReader _products;

  CollectionReference<Map<String, dynamic>> _cart() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw const NotSignedInException();
    return _db.collection('users').doc(uid).collection('cart');
  }

  // ---------------------------------------------------------------- reads

  /// Live cart joined with current product prices/stock.
  Stream<CartSnapshot> watchCart() {
    return _cart().snapshots().asyncMap((snap) async {
      final entries = <CartEntry>[];
      for (final doc in snap.docs) {
        final entry = _entryFromData(doc.id, doc.data());
        if (entry != null) entries.add(entry);
      }
      final products =
          await _products.fetchByIds(entries.map((e) => e.productId));
      return CartSnapshot(
        lines: [
          for (final e in entries)
            CartLine(entry: e, product: products[e.productId]),
        ],
      );
    });
  }

  /// Live number of pieces in the cart, e.g. for a badge on the cart icon.
  Stream<int> watchItemCount() {
    return _cart().snapshots().map((snap) {
      var total = 0;
      for (final doc in snap.docs) {
        total += _readQuantity(doc.data());
      }
      return total;
    });
  }

  // --------------------------------------------------------------- writes

  /// Adds one variant to the cart (used by Product Details).
  ///
  /// If the same product + size + color is already in the cart, its quantity
  /// goes up instead of creating a second line. Pass 'One Size' / a color
  /// name for products without options: size and color are always required.
  Future<void> addToCart({
    required String productId,
    required String size,
    required String color,
    int quantity = 1,
  }) async {
    final cleanSize = size.trim();
    final cleanColor = color.trim();
    if (productId.isEmpty || productId.contains('/')) {
      throw ArgumentError('Invalid product.');
    }
    if (cleanSize.isEmpty) throw ArgumentError('Please choose a size.');
    if (cleanColor.isEmpty) throw ArgumentError('Please choose a color.');
    if (quantity < 1) throw ArgumentError('Quantity must be at least 1.');

    final collection = _cart(); // also checks the user is signed in

    final ref = collection.doc(
      cartItemIdFor(productId: productId, size: cleanSize, color: cleanColor),
    );

    // A transaction re-reads the document and retries if another write
    // happened in between, so fast double taps never lose an increment.
    await _db.runTransaction<void>((tx) async {
      final productSnap = await tx.get(_db.collection('products').doc(productId));
      final snap = await tx.get(ref);
      final productData = productSnap.data();
      if (!productSnap.exists || productData == null ||
          ProductInfo.fromMap(productId, productData).isPurchasable == false) {
        throw const ProductUnavailableException('This product is no longer available or is out of stock.');
      }
      final product = ProductInfo.fromMap(productId, productData);
      final current = snap.exists ? _readQuantity(snap.data()) : 0;
      final next = current + quantity;
      if (next > product.stock) {
        throw ProductUnavailableException('Only ${product.stock} left in stock.');
      }
      tx.set(ref, {
        'productId': productId,
        'size': cleanSize,
        'color': cleanColor,
        'quantity': next,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> increment(String cartItemId, {int? maxQuantity}) =>
      _changeQuantity(cartItemId, 1, maxQuantity: maxQuantity);

  /// Going below 1 deletes the document (rules reject quantity = 0).
  Future<void> decrement(String cartItemId) =>
      _changeQuantity(cartItemId, -1);

  Future<void> removeItem(String cartItemId) {
    if (cartItemId.isEmpty) throw ArgumentError('Invalid cart item.');
    return _cart().doc(cartItemId).delete();
  }

  Future<void> _changeQuantity(
    String cartItemId,
    int delta, {
    int? maxQuantity,
  }) {
    if (cartItemId.isEmpty) throw ArgumentError('Invalid cart item.');
    final ref = _cart().doc(cartItemId);
    return _db.runTransaction<void>((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return; // already removed elsewhere
      final data = snap.data();
      final productId = data?['productId'];
      if (productId is! String || productId.isEmpty) {
        throw const ProductUnavailableException('This cart item is invalid. Remove it and try again.');
      }
      final productSnap = await tx.get(_db.collection('products').doc(productId));
      final productData = productSnap.data();
      if (!productSnap.exists || productData == null) {
        throw const ProductUnavailableException('This product is no longer available.');
      }
      final product = ProductInfo.fromMap(productId, productData);
      if (!product.isPurchasable) {
        throw const ProductUnavailableException('This product is no longer available.');
      }
      final next = _readQuantity(data) + delta;
      if (next <= 0) {
        tx.delete(ref);
        return;
      }
      if (next > product.stock) {
        throw ProductUnavailableException('Only ${product.stock} left in stock.');
      }
      tx.update(ref, {
        'quantity': next,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  // -------------------------------------------------------------- helpers

  int _readQuantity(Map<String, dynamic>? data) {
    final raw = data?['quantity'];
    return raw is num ? raw.toInt() : 0;
  }

  CartEntry? _entryFromData(String id, Map<String, dynamic> data) {
    final productId = data['productId'];
    final size = data['size'];
    final color = data['color'];
    final quantity = _readQuantity(data);
    if (productId is! String || size is! String || color is! String) {
      return null;
    }
    if (quantity < 1) return null;
    return CartEntry(
      id: id,
      productId: productId,
      size: size,
      color: color,
      quantity: quantity,
    );
  }
}
