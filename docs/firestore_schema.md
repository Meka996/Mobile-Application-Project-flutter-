# VELORA — Firestore Database Schema

Firebase Project: velora-fashion-store-a181a
Database: (default)
Region: europe-west3

## 1. Products

Collection: products/{productId}

- name: String
- description: String
- price: Number
- category: String
- imageUrls: List<String>
- sizes: List<String>
- colors: List<String>
- stock: Number (Integer)
- isActive: Boolean

Categories:
Dresses, Jackets, Shoes, Bags, Tops, Pants

## 2. Users

Document: users/{uid}

- name: String
- email: String
- phone: String
- createdAt: Timestamp

The document ID must match the Firebase Auth UID.
Never store user passwords in Firestore.

## 3. Favorites

Collection: users/{uid}/favorites/{productId}

- productId: String
- addedAt: Timestamp

## 4. Shopping Cart

Collection: users/{uid}/cart/{cartItemId}

- productId: String
- size: String
- color: String
- quantity: Number (Integer)
- updatedAt: Timestamp

Cart item IDs must distinguish product variants,
such as different sizes and colors.

## 5. Orders

Collection: users/{uid}/orders/{orderId}

- items: List<Map>
- total: Number
- status: String
- createdAt: Timestamp

Each item contains:

- productId: String
- name: String
- size: String
- color: String
- quantity: Number (Integer)
- unitPrice: Number

Initial order status: placed

## Shared Rules

- Use the exact field names shown above.
- Use Firebase Authentication UID for user documents.
- Store product images as URLs.
- Store dates as Firestore Timestamps.
- Never store passwords or private credentials.
- Validate quantity, price, and order data.
- The `placeOrder` callable in `functions/index.js` is the only client-facing order creation path. It calculates item prices from `products`, validates stock and variants, applies shipping/tax, decrements stock, creates the order and clears cart documents transactionally.
- Firestore client rules deny direct order creation, update and deletion. Admin SDK writes from the callable bypass client rules.
- Deploy both the callable and Firestore rules before testing: `firebase deploy --only functions:placeOrder,firestore:rules`.
- Current demo checkout policy: free shipping at $150, otherwise $9.99, plus 8% tax. No payment gateway or real charge is implemented.
- All team members must agree on schema changes.
