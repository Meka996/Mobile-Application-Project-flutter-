import 'package:cloud_firestore/cloud_firestore.dart';
import 'order_item.dart';

/// A placed order stored at users/{uid}/orders/{orderId}.
/// Allowed top-level fields: items, total, status, createdAt.
/// status is always 'placed' on creation; UPDATE/DELETE are denied by rules.
class OrderModel {
  final String id; // Firestore document ID
  final List<OrderItem> items;
  final double total;
  final String status; // always 'placed'
  final DateTime createdAt;

  const OrderModel({
    required this.id,
    required this.items,
    required this.total,
    required this.status,
    required this.createdAt,
  });

  factory OrderModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final rawItems = data['items'] as List<dynamic>? ?? [];
    return OrderModel(
      id: doc.id,
      items: rawItems
          .map((e) => OrderItem.fromMap(e as Map<String, dynamic>))
          .toList(),
      total: (data['total'] as num?)?.toDouble() ?? 0.0,
      status: data['status'] as String? ?? 'placed',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}