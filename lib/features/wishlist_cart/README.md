# Wishlist & Cart (Task D, Mohamed Adel)

Branch: `feature/wishlist-cart`. All code lives in `lib/features/wishlist_cart/`.
No Core files, rules or docs are changed.

## Files
| File | Purpose |
|---|---|
| `models/product_info.dart` | `ProductInfo` (read-only product), `FavoriteItem` |
| `models/cart_line.dart` | `cartItemIdFor`, money helpers, `CartEntry`, `CartLine`, `CartSnapshot` (totals) |
| `services/product_reader.dart` | Reads `products/{id}` (chunked `whereIn`) |
| `services/favorites_repository.dart` | Favorites: stream, toggle (transaction), remove |
| `services/cart_repository.dart` | Cart: stream, `addToCart`, increment/decrement, remove |
| `services/wishlist_cart_errors.dart` | Exceptions + `friendlyError()` |
| `widgets/*` | `AuthGate`, `FavoriteButton`, `CartItemTile`, `ProductImage`, empty/error/loading views |
| `screens/wishlist_screen.dart`, `screens/cart_screen.dart` | The two screens |
| `wishlist_cart.dart` | Single import for other members |
| `test/features/wishlist_cart/cart_logic_test.dart` | Unit tests for IDs, money, totals |

## Firestore touched
- `users/{uid}/favorites/{productId}`: `productId`, `addedAt` (serverTimestamp)
- `users/{uid}/cart/{cartItemId}`: `productId`, `size`, `color`, `quantity` (int > 0), `updatedAt`
- `products/{productId}`: READ only (name, price, imageUrls, isActive, stock)
- `cartItemId` = `encode(productId)|encode(size)|encode(color)` -> same variant increments, variants never collide.
- Decrement at quantity 1 DELETES the doc (rules reject quantity 0). Price is never stored in the cart.
- No new indexes needed.

## Integration (for Mohamed Hassan, Task A)
```dart
import 'package:velora/features/wishlist_cart/wishlist_cart.dart';

// Wishlist tab (index 2) in MainNavigation:
WishlistScreen(
  onOpenProduct: (id) { /* Task C: push ProductDetails(id) */ },
  onShopPressed: () => setState(() => selectedIndex = 1),
  onSignInRequested: () { /* Task B: push Login */ },
)

// Cart (e.g. cart icon in the AppBar):
Navigator.push(context, MaterialPageRoute(builder: (_) => CartScreen(
  onShopPressed: () => Navigator.pop(context),
  onCheckout: (cart) { /* Task E: use cart.purchasableLines, cart.totalCents */ },
  onSignInRequested: () { /* Task B */ },
  onOpenProduct: (id) { /* Task C */ },
)));

// Cart badge: StreamBuilder<int>(stream: CartRepository().watchItemCount(), ...)
```
For Safy (Product Details):
```dart
FavoriteButton(productId: product.id)                       // live heart
await CartRepository().addToCart(productId: id, size: 'M', color: 'Pink');
// products without options: pass 'One Size' for size/color (fields are required).
// addToCart throws; show friendlyError(e) in a SnackBar.
```
The Checkout button is hidden when `onCheckout` is null (no dead buttons).

## Manual QA
1. Signed out -> both screens show the sign-in message, nothing is written.
2. Sign in, heart a product -> `favorites/{productId}` appears in the Console; Wishlist shows it.
3. Un-heart from Wishlist -> doc deleted, heart updates elsewhere.
4. Add same variant twice -> ONE cart doc, quantity 2. Other size/color -> second doc.
5. `+` / `-` update quantity; `-` at 1 deletes the doc; `x` deletes.
6. Total = sum(price x quantity), two decimals. Change a price in the Console -> total follows.
7. Restart the app / sign out and in -> cart and wishlist persist.
8. Delete or deactivate a product in the Console -> row shows a warning, excluded from total.
9. Airplane mode, tap `+` -> error snackbar, no fake success.

## Known limitations
- Not compiled or run in my environment (no Flutter SDK there): run `flutter pub get`, `flutter analyze`, `flutter test` before the PR.
- Cart prices are read live, so there is no "price changed" notice, the total is just always current.
- Transactions need a connection, so favorites/cart writes fail offline instead of queuing (intentional: no false success).
- Rules do not verify stock, so over-ordering is prevented in app code only.
