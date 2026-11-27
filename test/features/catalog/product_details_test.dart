import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velora/core/theme/app_theme.dart';
import 'package:velora/features/catalog/models/product.dart';
import 'package:velora/features/catalog/screens/product_details_screen.dart';

void main() {
  testWidgets('requires a variant and waits for the cart write', (
    tester,
  ) async {
    final cartWrite = Completer<void>();
    String? addedSize;
    String? addedColor;
    final product = Product(
      id: 'top',
      name: 'Test Top',
      description: 'Test description',
      price: 35,
      category: 'Tops',
      imageUrls: [],
      sizes: ['M'],
      colors: ['Pink'],
      stock: 2,
      isActive: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: ProductDetailsScreen(
          product: product,
          onAddToCart: (_, size, color) {
            addedSize = size;
            addedColor = color;
            return cartWrite.future;
          },
        ),
      ),
    );

    expect(find.text('Test Top'), findsOneWidget);
    expect(find.text('Test description'), findsOneWidget);
    expect(find.byIcon(Icons.image_not_supported_outlined), findsOneWidget);
    final add = find.widgetWithText(ElevatedButton, 'Add to Cart');
    expect(tester.widget<ElevatedButton>(add).onPressed, isNull);

    for (final option in ['M', 'Pink']) {
      final chip = find.widgetWithText(ChoiceChip, option);
      await tester.ensureVisible(chip);
      await tester.pumpAndSettle();
      await tester.tap(chip);
      await tester.pumpAndSettle();
    }
    await tester.ensureVisible(add);
    await tester.pumpAndSettle();
    await tester.tap(add);
    await tester.pump();
    expect(addedSize, 'M');
    expect(addedColor, 'Pink');
    expect(find.text('Added to your cart.'), findsNothing);
    expect(
      tester
          .widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, 'Adding to Cart...'),
          )
          .onPressed,
      isNull,
    );

    cartWrite.complete();
    await tester.pumpAndSettle();
    expect(find.text('Added to your cart.'), findsOneWidget);
  });
}
