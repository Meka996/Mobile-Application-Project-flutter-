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
- imagePaths: List<String> (local Flutter asset paths)
- sizes: List<String>
- colors: List<String>
- stock: Number (Integer)
- isActive: Boolean

Categories: Dresses, Jackets, Shoes, Bags, Tops, Pants

Product images are bundled in the Flutter app under assets/images/products.
Firestore stores their local asset paths; no external image URLs are used.

Products are added manually in the Firebase Console. Use the exact field
names and data types listed above. The imagePaths values must match the
local asset paths bundled with the Flutter app.

## 2. Users

Document: users/{uid}

- name: String
- email: String
- phone: String
- createdAt: Timestamp

The document ID must match the Firebase Auth UID. Never store passwords.

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

Cart item IDs distinguish variants such as different sizes and colors.

## 5. Orders

Collection: users/{uid}/orders/{orderId}

- items: List<Map>
- total: Number
- status: String
- createdAt: Timestamp

Each item contains productId, name, size, color, quantity, and unitPrice.
Initial order status: placed.

## Shared Rules

- Use the exact field names shown above.
- Use Firebase Authentication UID for user documents.
- Store dates as Firestore Timestamps.
- Never store passwords or private credentials.
- Validate quantity, price, and order data.
- The placeOrder callable in functions/index.js is the only client-facing order creation path. It calculates prices from products, validates stock and variants, applies shipping/tax, decrements stock, creates the order and clears cart documents transactionally.
- Firestore client rules deny direct order creation, update and deletion. Admin SDK writes from the callable bypass client rules.
- Deploy both callable and rules: firebase deploy --only functions:placeOrder,firestore:rules.
- Demo checkout: free shipping at $150, otherwise $9.99, plus 8% tax. No payment gateway or real charge is implemented.
