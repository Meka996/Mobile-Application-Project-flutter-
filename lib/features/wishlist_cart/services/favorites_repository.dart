import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/product_info.dart';
import 'product_reader.dart';
import 'wishlist_cart_errors.dart';

/// All Firestore work for `users/{uid}/favorites/{productId}`.
///
/// Each document has EXACTLY two fields (the security rules reject anything
/// else): `productId` (must equal the document ID) and `addedAt`.
class FavoritesRepository {
  FavoritesRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    ProductReader? products,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _products = products ?? ProductReader(firestore: firestore);

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final ProductReader _products;

  /// The signed-in user's favorites collection. Never uses a hardcoded UID.
  CollectionReference<Map<String, dynamic>> _favorites() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw const NotSignedInException();
    return _db.collection('users').doc(uid).collection('favorites');
  }

  /// Live set of favorite product IDs (useful for filled/empty hearts).
  Stream<Set<String>> watchFavoriteIds() {
    return _favorites()
        .snapshots()
        .map((snap) => snap.docs.map((doc) => doc.id).toSet());
  }

  /// Live "is this product a favorite?" flag for one heart button.
  Stream<bool> watchIsFavorite(String productId) {
    return _favorites().doc(productId).snapshots().map((doc) => doc.exists);
  }

  /// Live list of favorites, newest first, joined with product details.
  Stream<List<FavoriteItem>> watchFavorites() {
    return _favorites()
        .orderBy('addedAt', descending: true)
        .snapshots()
        .asyncMap((snap) async {
      final ids = snap.docs.map((doc) => doc.id).toList();
      final products = await _products.fetchByIds(ids);
      return [
        for (final id in ids) FavoriteItem(productId: id, product: products[id]),
      ];
    });
  }

  /// Adds the favorite if missing, removes it if present.
  /// Returns true when the product is a favorite AFTER the call.
  Future<bool> toggleFavorite(String productId) {
    _checkId(productId);
    final ref = _favorites().doc(productId);
    return _db.runTransaction<bool>((tx) async {
      final snap = await tx.get(ref);
      if (snap.exists) {
        tx.delete(ref);
        return false;
      }
      tx.set(ref, {
        'productId': productId,
        'addedAt': FieldValue.serverTimestamp(),
      });
      return true;
    });
  }

  Future<void> removeFavorite(String productId) {
    _checkId(productId);
    return _favorites().doc(productId).delete();
  }

  void _checkId(String productId) {
    if (productId.isEmpty || productId.contains('/')) {
      throw ArgumentError('Invalid product.');
    }
  }
}
