import 'package:flutter_test/flutter_test.dart';
import 'package:velora/features/wishlist_cart/models/cart_line.dart';
import 'package:velora/features/wishlist_cart/models/product_info.dart';

ProductInfo product({
  String id = 'p1',
  double price = 89,
  bool isActive = true,
  int stock = 10,
}) {
  return ProductInfo(
    id: id,
    name: 'Dress',
    price: price,
    imageUrl: null,
    isActive: isActive,
    stock: stock,
  );
}

CartLine line({
  required ProductInfo? p,
  int quantity = 1,
  String size = 'M',
  String color = 'Pink',
}) {
  return CartLine(
    entry: CartEntry(
      id: cartItemIdFor(productId: 'p1', size: size, color: color),
      productId: 'p1',
      size: size,
      color: color,
      quantity: quantity,
    ),
    product: p,
  );
}

void main() {
  group('cartItemIdFor', () {
    test('same variant gives the same id', () {
      expect(
        cartItemIdFor(productId: 'p1', size: 'M', color: 'Pink'),
        cartItemIdFor(productId: 'p1', size: 'M', color: 'Pink'),
      );
    });

    test('different size or color gives different ids', () {
      final base = cartItemIdFor(productId: 'p1', size: 'M', color: 'Pink');
      expect(base, isNot(cartItemIdFor(productId: 'p1', size: 'L', color: 'Pink')));
      expect(base, isNot(cartItemIdFor(productId: 'p1', size: 'M', color: 'Cream')));
      expect(base, isNot(cartItemIdFor(productId: 'p2', size: 'M', color: 'Pink')));
    });

    test('never contains a slash and does not collide on tricky input', () {
      final a = cartItemIdFor(productId: 'a', size: 'b|c', color: 'd');
      final b = cartItemIdFor(productId: 'a', size: 'b', color: 'c|d');
      expect(a, isNot(b));
      expect(a.contains('/'), isFalse);
      expect(
        cartItemIdFor(productId: 'a/b', size: 'x/y', color: 'z').contains('/'),
        isFalse,
      );
    });
  });

  group('money', () {
    test('formats two decimals', () {
      expect(formatCents(8900), '\$89.00');
      expect(formatCents(5), '\$0.05');
      expect(formatCents(12999), '\$129.99');
    });

    test('toCents avoids floating point drift', () {
      expect(toCents(0.1 + 0.2), 30);
      expect(toCents(89.99), 8999);
    });
  });

  group('CartLine / CartSnapshot', () {
    test('subtotal is unit price x quantity', () {
      expect(line(p: product(price: 89), quantity: 3).subtotalCents, 26700);
    });

    test('total sums only purchasable lines', () {
      final cart = CartSnapshot(lines: [
        line(p: product(price: 89), quantity: 2, size: 'M'),
        line(p: product(price: 129), quantity: 1, size: 'L'),
        line(p: null, quantity: 5, size: 'S'), // product deleted
        line(p: product(isActive: false), quantity: 1, size: 'XL'),
      ]);
      expect(cart.totalCents, 89 * 2 * 100 + 129 * 100);
      expect(cart.itemCount, 9);
      expect(cart.hasProblems, isTrue);
      expect(cart.purchasableLines.length, 2);
    });

    test('problem messages', () {
      expect(line(p: null).problem, isNotNull);
      expect(line(p: product(stock: 0)).problem, 'Out of stock.');
      expect(line(p: product(stock: 2), quantity: 3).problem, 'Only 2 left in stock.');
      expect(line(p: product()).problem, isNull);
    });

    test('cannot increase past stock; checkout blocked when over stock', () {
      expect(line(p: product(stock: 2), quantity: 2).canIncrease, isFalse);
      expect(line(p: product(stock: 5), quantity: 2).canIncrease, isTrue);
      final over = CartSnapshot(lines: [line(p: product(stock: 1), quantity: 3)]);
      expect(over.canCheckout, isFalse);
    });

    test('empty cart has zero total and cannot check out', () {
      const cart = CartSnapshot(lines: []);
      expect(cart.isEmpty, isTrue);
      expect(cart.totalCents, 0);
      expect(cart.canCheckout, isFalse);
    });
  });

  group('ProductInfo.fromMap', () {
    test('reads fields and first image', () {
      final p = ProductInfo.fromMap('p1', {
        'name': 'Blazer',
        'price': 129,
        'imageUrls': ['https://x/1.jpg', 'https://x/2.jpg'],
        'isActive': true,
        'stock': 4,
      });
      expect(p.name, 'Blazer');
      expect(p.price, 129.0);
      expect(p.imageUrl, 'https://x/1.jpg');
      expect(p.isPurchasable, isTrue);
    });

    test('missing or bad fields are treated as unavailable', () {
      final p = ProductInfo.fromMap('p1', {'name': 5, 'price': 'free'});
      expect(p.imageUrl, isNull);
      expect(p.isPurchasable, isFalse);
    });
  });
}
