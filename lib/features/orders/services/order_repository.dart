import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
}
