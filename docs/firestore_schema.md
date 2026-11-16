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
- Order totals must be verified against trusted prices
  before the system can be considered production-ready.
- All team members must agree on schema changes.
