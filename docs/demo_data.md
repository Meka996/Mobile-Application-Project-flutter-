# VELORA demo catalogue

The demo catalogue contains 18 fictional products: three each in Dresses,
Jackets, Shoes, Bags, Tops, and Pants.

## Images
Product images are bundled under assets/images/products/. Firestore stores
the Flutter asset paths in imagePaths and the app displays them with
Image.asset. No external image URLs or remote image hosts are used.

## Seed Firestore
The products collection is read-only to regular app clients. Run this Admin
SDK script from a trusted developer machine:

1. Install Node.js 22.
2. Authenticate with Google Application Default Credentials, for example:
   gcloud auth application-default login
   Or set GOOGLE_APPLICATION_CREDENTIALS to a service-account JSON file.
3. Never commit service-account credentials.
4. From the repository root, run:

   cd functions
   npm install
   npm run seed:products

The script validates the data and checks every local image before writing.
It uses fixed demo_* IDs, can be safely re-run, and does not delete products
or user data. All names, descriptions, prices and stock counts are fictional.
