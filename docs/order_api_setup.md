# VELORA trusted order API

The Flutter app sends an authenticated request to this Node.js API. The API verifies the Firebase ID token and uses the Firebase Admin SDK to validate the live cart, product prices, variants and stock. Order creation, stock decrements and cart clearing happen in one Firestore transaction.

## Deploy on Render

1. Push this branch to GitHub and create a new **Web Service** in Render.
2. Connect `Meka996/Mobile-Application-Project-flutter-` and select branch `mohamed-integeration-test`.
3. Set the root directory to `functions`.
4. Set build command to `npm install` and start command to `npm start`.
5. Set these environment variables in Render:
   - `NODE_VERSION` = `22`
   - `FIREBASE_PROJECT_ID` = `velora-fashion-store-a181a`
   - `FIREBASE_SERVICE_ACCOUNT_JSON` = the complete service-account JSON, pasted as one value in Render's secret environment-variable field.
6. Deploy. The health endpoint is `/health`; the order endpoint is `POST /orders`.

`render.yaml` contains the same service blueprint. Render's free web services may sleep when idle, so the first order request after inactivity can take longer.

## Firebase service account

Use a dedicated service account for this API, not a key embedded in Flutter or committed to Git. It needs Firestore read/write access for the cart, products and orders, and permission to verify/revoke-check Firebase Authentication ID tokens. Ask the Firebase project owner to create the account and grant only the required roles if your Editor role cannot do so. Store its JSON key only in Render's `FIREBASE_SERVICE_ACCOUNT_JSON` secret. Never paste the private key into chat, source code, GitHub issues or `.env.example`.

## Configure the Flutter app

After Render finishes deploying, copy the service's HTTPS URL. Run Flutter with:

```powershell
flutter pub get
flutter run --dart-define=ORDER_API_BASE_URL=https://YOUR-SERVICE.onrender.com
```

Replace the URL with the real Render service URL. For a local Android emulator, the default is `http://10.0.2.2:3000`; for a physical phone, use the computer's LAN IP and ensure the phone can reach it. Use HTTPS for deployed services.

## Security notes

- The app sends only a Firebase ID token; it does not send a price, total, user ID or order items as trusted input.
- The API derives the user ID from the verified token and reads the user's cart itself.
- Prices, active status, variants and stock are checked from Firestore inside the transaction.
- A successful transaction creates the order, decrements stock and clears the cart atomically. A failed transaction leaves all three unchanged.
- Firestore rules continue to deny client writes to products and orders. The Admin SDK bypasses those rules, so protect the service-account key.
- This demo API does not process payments.

## Local API test

From the `functions` directory, install dependencies, set the three environment variables above, then run:

```powershell
npm install
npm run check
npm start
```

Do not commit a real `.env` file or service-account JSON key.