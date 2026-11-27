const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");

initializeApp();

const db = getFirestore();
const REGION = "europe-west3";
const MAX_ORDER_LINES = 20;
const FREE_SHIPPING_THRESHOLD_CENTS = 15000;
const SHIPPING_CENTS = 999;
const TAX_RATE_BASIS_POINTS = 800; // 8%

function moneyToCents(value) {
  if (typeof value !== "number" || !Number.isFinite(value) || value <= 0) {
    throw new HttpsError("failed-precondition", "A product has an invalid price.");
  }
  return Math.round(value * 100);
}

function validateVariant(product, size, color) {
  if (Array.isArray(product.sizes) && product.sizes.length > 0 &&
      !product.sizes.includes(size)) {
    throw new HttpsError("failed-precondition", "A selected size is no longer available.");
  }
  if (Array.isArray(product.colors) && product.colors.length > 0 &&
      !product.colors.includes(color)) {
    throw new HttpsError("failed-precondition", "A selected color is no longer available.");
  }
}

exports.placeOrder = onCall({ region: REGION }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign in before placing an order.");
  }

  const uid = request.auth.uid;
  const userRef = db.collection("users").doc(uid);
  const cartRef = userRef.collection("cart");
  const orderRef = userRef.collection("orders").doc();

  try {
    const result = await db.runTransaction(async (transaction) => {
      const cartSnapshot = await transaction.get(cartRef);
      if (cartSnapshot.empty) {
        throw new HttpsError("failed-precondition", "Your cart is empty.");
      }
      if (cartSnapshot.size > MAX_ORDER_LINES) {
        throw new HttpsError("failed-precondition",
          `Orders are limited to ${MAX_ORDER_LINES} different items.`);
      }

      const cartLines = cartSnapshot.docs.map((doc) => {
        const data = doc.data();
        if (typeof data.productId !== "string" || !data.productId ||
            typeof data.size !== "string" || !data.size.trim() ||
            typeof data.color !== "string" || !data.color.trim() ||
            !Number.isInteger(data.quantity) || data.quantity < 1) {
          throw new HttpsError("failed-precondition",
            "Your cart contains an invalid item. Remove it and try again.");
        }
        return { ref: doc.ref, ...data };
      });

      const productRefs = [...new Map(cartLines.map((line) => [
        line.productId, db.collection("products").doc(line.productId),
      ])).values()];
      const productSnapshots = await Promise.all(
        productRefs.map((ref) => transaction.get(ref)),
      );
      const products = new Map();
      productSnapshots.forEach((snapshot) => {
        if (snapshot.exists) products.set(snapshot.id, snapshot.data());
      });

      const orderItems = [];
      let subtotalCents = 0;
      const decrements = new Map();

      for (const line of cartLines) {
        const product = products.get(line.productId);
        if (!product || product.isActive !== true) {
          throw new HttpsError("failed-precondition",
            "A product in your cart is no longer available.");
        }
        if (!Number.isInteger(product.stock) || product.stock < line.quantity) {
          throw new HttpsError("failed-precondition",
            `Not enough stock for ${product.name || "a product"}.`);
        }

        validateVariant(product, line.size, line.color);
        const unitPriceCents = moneyToCents(product.price);
        subtotalCents += unitPriceCents * line.quantity;
        decrements.set(line.productId,
          (decrements.get(line.productId) || 0) + line.quantity);

        orderItems.push({
          productId: line.productId,
          name: typeof product.name === "string" ? product.name : "Product",
          size: line.size,
          color: line.color,
          quantity: line.quantity,
          unitPrice: unitPriceCents / 100,
        });
      }

      for (const [productId, quantity] of decrements.entries()) {
        const productRef = db.collection("products").doc(productId);
        const product = products.get(productId);
        if (product.stock < quantity) {
          throw new HttpsError("failed-precondition",
            `Not enough stock for ${product.name || "a product"}.`);
        }
        transaction.update(productRef, { stock: product.stock - quantity });
      }

      const shippingCents = subtotalCents >= FREE_SHIPPING_THRESHOLD_CENTS
        ? 0 : SHIPPING_CENTS;
      const taxCents = Math.round(subtotalCents * TAX_RATE_BASIS_POINTS / 10000);
      const totalCents = subtotalCents + shippingCents + taxCents;

      transaction.create(orderRef, {
        items: orderItems,
        total: totalCents / 100,
        status: "placed",
        createdAt: FieldValue.serverTimestamp(),
      });
      for (const line of cartLines) {
        transaction.delete(line.ref);
      }

      return {
        orderId: orderRef.id,
        subtotal: subtotalCents / 100,
        shipping: shippingCents / 100,
        tax: taxCents / 100,
        total: totalCents / 100,
      };
    });

    return result;
  } catch (error) {
    if (error instanceof HttpsError) throw error;
    console.error("placeOrder failed", error);
    throw new HttpsError("internal", "Could not place your order. Please try again.");
  }
});
