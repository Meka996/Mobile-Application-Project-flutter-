const express = require("express");
const helmet = require("helmet");
const rateLimit = require("express-rate-limit");
const { initializeApp, cert, getApps } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");

const PORT = Number(process.env.PORT || 3000);
const PROJECT_ID = process.env.FIREBASE_PROJECT_ID || "velora-fashion-store-a181a";
const MAX_ORDER_LINES = 20;
const FREE_SHIPPING_THRESHOLD_CENTS = 15000;
const SHIPPING_CENTS = 999;
const TAX_RATE_BASIS_POINTS = 800;

function initializeFirebase() {
  if (getApps().length) return;
  const raw = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  if (!raw) throw new Error("FIREBASE_SERVICE_ACCOUNT_JSON is required.");
  let serviceAccount;
  try { serviceAccount = JSON.parse(raw); }
  catch { throw new Error("FIREBASE_SERVICE_ACCOUNT_JSON must be valid JSON."); }
  if (serviceAccount.project_id !== PROJECT_ID) {
    throw new Error("Service account project_id does not match FIREBASE_PROJECT_ID.");
  }
  initializeApp({ credential: cert(serviceAccount), projectId: PROJECT_ID });
}
initializeFirebase();

const db = getFirestore();
const app = express();
app.disable("x-powered-by");
app.set("trust proxy", 1);
app.use(helmet());
app.use(express.json({ limit: "16kb", strict: true }));

const allowedOrigins = (process.env.ALLOWED_ORIGINS || "").split(",").map(v => v.trim()).filter(Boolean);
app.use((req, res, next) => {
  const origin = req.get("origin");
  if (origin && allowedOrigins.length && !allowedOrigins.includes(origin)) {
    return res.status(403).json({ error: "Origin is not allowed." });
  }
  if (origin) { res.setHeader("Access-Control-Allow-Origin", origin); res.setHeader("Vary", "Origin"); }
  res.setHeader("Access-Control-Allow-Headers", "Authorization, Content-Type");
  res.setHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  if (req.method === "OPTIONS") return res.sendStatus(204);
  return next();
});

const orderLimiter = rateLimit({
  windowMs: 60000, limit: 20, standardHeaders: "draft-7", legacyHeaders: false,
  message: { error: "Too many order attempts. Please wait and try again." },
});
function httpError(status, message) { const e = new Error(message); e.status = status; return e; }
function moneyToCents(value) {
  if (typeof value !== "number" || !Number.isFinite(value) || value <= 0) throw httpError(409, "A product has an invalid price.");
  return Math.round(value * 100);
}
function validateVariant(product, size, color) {
  if (Array.isArray(product.sizes) && product.sizes.length && !product.sizes.includes(size)) throw httpError(409, "A selected size is no longer available.");
  if (Array.isArray(product.colors) && product.colors.length && !product.colors.includes(color)) throw httpError(409, "A selected color is no longer available.");
}
async function requireFirebaseUser(req, res, next) {
  try {
    const match = (req.get("authorization") || "").match(/^Bearer\\s+(.+)$/i);
    if (!match) throw httpError(401, "Please sign in before placing an order.");
    req.firebaseUser = await getAuth().verifyIdToken(match[1], true);
    return next();
  } catch (e) {
    if (e.status) return res.status(e.status).json({ error: e.message });
    return res.status(401).json({ error: "Your session is invalid. Please sign in again." });
  }
}
app.get("/health", (_req, res) => res.status(200).json({ status: "ok" }));

app.post("/orders", orderLimiter, requireFirebaseUser, async (req, res) => {
  try {
    const uid = req.firebaseUser.uid;
    const userRef = db.collection("users").doc(uid);
    const cartRef = userRef.collection("cart");
    const orderRef = userRef.collection("orders").doc();
    const result = await db.runTransaction(async transaction => {
      const cartSnapshot = await transaction.get(cartRef);
      if (cartSnapshot.empty) throw httpError(409, "Your cart is empty.");
      if (cartSnapshot.size > MAX_ORDER_LINES) throw httpError(409, "Orders are limited to " + MAX_ORDER_LINES + " different items.");
      const lines = cartSnapshot.docs.map(doc => {
        const d = doc.data();
        if (typeof d.productId !== "string" || !d.productId || typeof d.size !== "string" || !d.size.trim() || typeof d.color !== "string" || !d.color.trim() || !Number.isInteger(d.quantity) || d.quantity < 1) {
          throw httpError(409, "Your cart contains an invalid item. Remove it and try again.");
        }
        return { ref: doc.ref, ...d };
      });
      const refs = [...new Map(lines.map(line => [line.productId, db.collection("products").doc(line.productId)])).values()];
      const snapshots = await Promise.all(refs.map(ref => transaction.get(ref)));
      const products = new Map();
      snapshots.forEach(snapshot => { if (snapshot.exists) products.set(snapshot.id, snapshot.data()); });
      const items = []; const decrements = new Map(); let subtotalCents = 0;
      for (const line of lines) {
        const product = products.get(line.productId);
        if (!product || product.isActive !== true) throw httpError(409, "A product in your cart is no longer available.");
        if (!Number.isInteger(product.stock) || product.stock < line.quantity) throw httpError(409, "Not enough stock for " + (product.name || "a product") + ".");
        validateVariant(product, line.size, line.color);
        const unitPriceCents = moneyToCents(product.price);
        subtotalCents += unitPriceCents * line.quantity;
        decrements.set(line.productId, (decrements.get(line.productId) || 0) + line.quantity);
        items.push({ productId: line.productId, name: typeof product.name === "string" ? product.name : "Product", size: line.size, color: line.color, quantity: line.quantity, unitPrice: unitPriceCents / 100 });
      }
      for (const [productId, quantity] of decrements.entries()) {
        const product = products.get(productId);
        if (product.stock < quantity) throw httpError(409, "Not enough stock for " + (product.name || "a product") + ".");
        transaction.update(db.collection("products").doc(productId), { stock: product.stock - quantity });
      }
      const shippingCents = subtotalCents >= FREE_SHIPPING_THRESHOLD_CENTS ? 0 : SHIPPING_CENTS;
      const taxCents = Math.round(subtotalCents * TAX_RATE_BASIS_POINTS / 10000);
      const totalCents = subtotalCents + shippingCents + taxCents;
      transaction.create(orderRef, { items, total: totalCents / 100, status: "placed", createdAt: FieldValue.serverTimestamp() });
      for (const line of lines) transaction.delete(line.ref);
      return { orderId: orderRef.id, subtotal: subtotalCents / 100, shipping: shippingCents / 100, tax: taxCents / 100, total: totalCents / 100 };
    });
    return res.status(201).json(result);
  } catch (e) {
    if (e.status) return res.status(e.status).json({ error: e.message });
    console.error("placeOrder failed:", e);
    return res.status(500).json({ error: "Could not place your order. Please try again." });
  }
});
app.listen(PORT, "0.0.0.0", () => console.log("VELORA order API listening on port " + PORT));
