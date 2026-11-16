# VELORA — Integration Contract

## Project Information

Project: VELORA Fashion Store
Framework: Flutter
Backend: Firebase
Database: Cloud Firestore
Design: Concept A — Soft Pink

## 1. Team Responsibilities

A — Mohamed Hassan
Core Setup, Theme, Navigation, Shared Widgets,
Firebase Initialization, Security and Integration.

B — Miran
Authentication, Registration, Login, Logout,
Input Validation and User Profile.

C — Safy
Product Catalog, Categories, Search, Filters
and Product Details.

D — Mohamed Adel
Favorites, Wishlist, Shopping Cart,
Quantities and Total Calculation.

E — Malak
Checkout, Place Orders and Order History.

## 2. Core Files

lib/main.dart
lib/firebase_options.dart
lib/core/theme/app_theme.dart
lib/core/navigation/main_navigation.dart
lib/core/widgets/velora_button.dart
lib/core/widgets/velora_text_field.dart

Owner: Mohamed Hassan

Changes to shared Core files must be reviewed
before merging.

## 3. Navigation Contract

Bottom Navigation:

Index 0: Home
Index 1: Shop
Index 2: Wishlist
Index 3: Profile

Additional Screens:

Login: Task B
Sign Up: Task B
Product Details: Task C
Cart: Task D
Checkout: Task E
Order History: Task E

The Core owner integrates delivered screens
into the application's navigation.

## 4. Design Contract

Brand: VELORA

Primary: #E8A8B4
Secondary: #FADCE4
Background: #FFF8F9
Buttons: #C45D75

All screens must use AppTheme.lightTheme.

Use shared widgets where appropriate.
Form validation must use suitable
Form and TextFormField validation.

## 5. Firebase Contract

Firebase Project:
velora-fashion-store-a181a

Database:
(default)

Firestore Structure:
See docs/firestore_schema.md

All features must use the agreed collection
paths and field names.

Authentication uses Firebase Authentication.

Product, cart, wishlist, profile and order
data must use Cloud Firestore.

Do not use hardcoded data as the final
source of application data.

## 6. GitHub Workflow

Main Branch: main

Core Branch:
feature/core-integration

Feature Branches:
feature/auth
feature/catalog
feature/wishlist-cart
feature/orders

Each member must:

1. Work on their own branch.
2. Test their feature.
3. Commit their changes.
4. Push to GitHub.
5. Open a Pull Request.
6. Request code review before merging.

Do not push unfinished features directly
to main.

## 7. Integration Requirements

Before integration, each feature must:

- Compile without errors.
- Use the approved theme.
- Follow the Firestore schema.
- Handle loading and error states.
- Handle empty data where applicable.
- Provide working navigation.
- Be understandable to its owner.
- Avoid modifying unrelated features.

## 8. Final Verification

- Sign Up, Login and Logout
- User Input Validation
- Product Categories
- Product Search and Filtering
- Product Details
- Favorites
- Shopping Cart and Quantity Updates
- Total Calculation
- User Profile
- Place Orders
- Order History
- Firebase Data Persistence
- Firestore Security Rules
- Consistent Responsive UI

The project is complete only after all
mandatory requirements are tested.
