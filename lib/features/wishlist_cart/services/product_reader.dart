import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/product_info.dart';

/// Reads `products/{productId}` (read-only for clients).
class ProductReader {
  ProductReader({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Future<ProductInfo?> fetchOne(String productId) async {
    if (!_isValidId(productId)) return null;
    final doc = await _db.collection('products').doc(productId).get();
    final data = doc.data();
    if (!doc.exists || data == null) return null;
    return ProductInfo.fromMap(doc.id, data);
  }

  /// Fetches many products with as few reads as possible.
  /// Ids whose product does not exist are simply missing from the result.
  Future<Map<String, ProductInfo>> fetchByIds(Iterable<String> ids) async {
    final unique = ids.where(_isValidId).toSet().toList();
    final result = <String, ProductInfo>{};

    // Firestore `whereIn` accepts a limited number of values, so use chunks.
    const chunkSize = 10;
    for (var i = 0; i < unique.length; i += chunkSize) {
      final end = i + chunkSize > unique.length ? unique.length : i + chunkSize;
      final chunk = unique.sublist(i, end);
      final snap = await _db
          .collection('products')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final doc in snap.docs) {
        result[doc.id] = ProductInfo.fromMap(doc.id, doc.data());
      }
    }
    return result;
  }

  bool _isValidId(String id) => id.isNotEmpty && !id.contains('/');
}
