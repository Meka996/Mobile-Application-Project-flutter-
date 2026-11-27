import 'package:flutter/material.dart';

import '../../../core/theme/app_layout.dart';
import '../../../shared/shared.dart';
import 'order_history_screen.dart';

/// Shown only after [OrderRepository.placeOrder] completes successfully.
/// Displays order ID and placed status; never shown before Firestore write
/// finishes.
class OrderConfirmationScreen extends StatelessWidget {
  const OrderConfirmationScreen({
    super.key,
    required this.orderId,
    this.onShopPressed,
  });

  final String orderId;
  final VoidCallback? onShopPressed;

  @override
  Widget build(BuildContext context) {
    final shortId = orderId.length >= 8
        ? orderId.substring(0, 8).toUpperCase()
        : orderId.toUpperCase();

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppLayout.page),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppLayout.formMaxWidth,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: scheme.primaryContainer,
                    foregroundColor: scheme.onPrimaryContainer,
                    child: const Icon(Icons.check_rounded, size: 48),
                  ),
                  const SizedBox(height: AppLayout.page),
                  Text(
                    'Order Placed!',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: AppLayout.small),
                  Text('Order #$shortId', style: theme.textTheme.bodyLarge),
                  const SizedBox(height: AppLayout.small),
                  SelectableText(
                    'Full ID: $orderId',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppLayout.section),
                  VeloraButton(
                    text: 'View My Orders',
                    icon: Icons.receipt_long_outlined,
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              OrderHistoryScreen(onShopPressed: onShopPressed),
                        ),
                        (route) => route.isFirst,
                      );
                    },
                  ),
                  TextButton(
                    onPressed:
                        onShopPressed ??
                        () =>
                            Navigator.of(context)
                                .popUntil((route) => route.isFirst),
                    child: const Text('Continue Shopping'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
