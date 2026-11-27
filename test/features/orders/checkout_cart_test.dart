import 'package:flutter_test/flutter_test.dart';
import 'package:velora/features/orders/services/cart_reader.dart';

void main() {
  test('rounds money to cents and calculates the displayed order total', () {
    final cart = _review({'line': _line(quantity: 3)}, price: 19.995);

    expect(cart.items.single.unitPrice, 20);
    expect(cart.subtotalCents, 6000);
    expect(cart.shippingCents, 999);
    expect(cart.taxCents, 480);
    expect(cart.totalCents, 7479);
    expect(cart.canPlaceOrder, isTrue);

    final freeShipping = _review({'line': _line()}, price: 150);
    expect(freeShipping.shippingCents, 0);
    expect(freeShipping.totalCents, 16200);
  });

  test('excludes missing, inactive, and invalid cart lines', () {
    final cart = _review({
      'valid': _line(),
      'missing': _line(productId: 'missing'),
      'inactive': _line(productId: 'inactive'),
      'invalid': _line(quantity: 0),
    });

    expect(cart.lines.keys, ['valid']);
    expect(cart.issues, hasLength(3));
    expect(cart.canPlaceOrder, isTrue);
  });

  test('blocks overstock across variants and more than 20 lines', () {
    final stockExceeded = _review({
      'small': _line(quantity: 6, size: 'S'),
      'medium': _line(quantity: 5),
    });
    expect(stockExceeded.canPlaceOrder, isFalse);
    expect(stockExceeded.blockingIssue, contains('Only 10'));

    final tooManyLines = _review({
      for (var i = 0; i < 21; i++) 'line-$i': _line(),
    }, stock: 30);
    expect(tooManyLines.canPlaceOrder, isFalse);
    expect(tooManyLines.blockingIssue, contains('20 cart lines'));
  });

  test('detects cart edits, changed prices, and missing reviewed lines', () {
    final initial = _review({'line': _line()});

    expect(initial.matchesReviewedLines(_review({'line': _line()})), isTrue);
    expect(
      initial.matchesReviewedLines(_review({'line': _line(quantity: 2)})),
      isFalse,
    );
    expect(
      initial.matchesReviewedLines(_review({'line': _line(revision: 2)})),
      isFalse,
    );
    expect(
      initial.matchesReviewedLines(_review({'line': _line()}, price: 20)),
      isFalse,
    );
    expect(initial.matchesReviewedLines(_review({})), isFalse);
  });
}

CartSnapshot _review(
  Map<String, Map<String, dynamic>> cart, {
  double price = 25,
  int stock = 10,
}) {
  return CartSnapshot.fromDocuments('student', cart, {
    'top': {'name': 'Top', 'price': price, 'isActive': true, 'stock': stock},
    'inactive': {
      'name': 'Jacket',
      'price': 25,
      'isActive': false,
      'stock': stock,
    },
  });
}

Map<String, dynamic> _line({
  String productId = 'top',
  String size = 'M',
  int quantity = 1,
  int revision = 1,
}) {
  return {
    'productId': productId,
    'size': size,
    'color': 'Pink',
    'quantity': quantity,
    'updatedAt': revision,
  };
}
