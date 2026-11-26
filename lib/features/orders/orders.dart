/// Entry-point barrel for the orders feature.
/// Mohamed Hassan's router imports from here, not individual files.
///
/// Navigation handshake:
///   - Mount CheckoutScreen on a push from Cart (Task D → Task E)
///   - Mount OrderHistoryScreen as a named route or bottom-nav tab
///   - No top-level route modification required inside lib/main.dart;
///     pass these constructors to your existing Navigator or GoRouter.
library orders;

export 'screens/checkout_screen.dart' show CheckoutScreen;
export 'screens/order_history_screen.dart' show OrderHistoryScreen;
export 'screens/order_confirmation_screen.dart' show OrderConfirmationScreen;
export 'screens/order_detail_screen.dart' show OrderDetailScreen;
export 'services/order_repository.dart' show OrderRepository;
export 'models/order_model.dart' show OrderModel;
export 'models/order_item.dart' show OrderItem;