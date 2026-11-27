import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/product.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Product?> getActiveProduct(String id) async {
    final snapshot = await _firestore.collection('products').doc(id).get();
    final data = snapshot.data();
    if (data == null || data['isActive'] != true) return null;
    return Product.fromMap(snapshot.id, data);
  }

  Stream<List<Product>> getProducts() {
    return _firestore
        .collection('products')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Product.fromMap(doc.id, doc.data());
          }).toList();
        });
  }
}
