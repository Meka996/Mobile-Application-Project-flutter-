import 'package:firebase_core/firebase_core.dart';

/// Thrown when an action needs a signed-in user but there is none.
class NotSignedInException implements Exception {
  const NotSignedInException();

  @override
  String toString() => 'Please sign in to continue.';
}

/// Thrown when a product is missing, inactive or out of stock.
class ProductUnavailableException implements Exception {
  const ProductUnavailableException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Turns any error into a short message that is safe to show to the user.
String friendlyError(Object error) {
  if (error is NotSignedInException) return error.toString();
  if (error is ProductUnavailableException) return error.message;
  if (error is ArgumentError) return error.message.toString();
  if (error is FirebaseException) {
    switch (error.code) {
      case 'permission-denied':
        return 'Permission denied. Please sign in again and retry.';
      case 'unavailable':
      case 'deadline-exceeded':
        return 'No connection. Check your internet and try again.';
      default:
        return 'Something went wrong (${error.code}). Please try again.';
    }
  }
  return 'Something went wrong. Please try again.';
}
