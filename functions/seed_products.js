const fs = require("fs");
const path = require("path");
const { applicationDefault, initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");

const PROJECT_ID = "velora-fashion-store-a181a";
const DATA_FILE = path.resolve(__dirname, "../data/demo_products.json");

function validateProduct(product) {
  for (const field of ["id", "name", "description", "category"]) {
    if (typeof product[field] !== "string" || !product[field].trim()) {
      throw new Error("Missing valid " + field + " in a product.");
    }
  }
  if (typeof product.price !== "number" || product.price <= 0) throw new Error(product.id + ": price must be positive.");
  if (!Number.isInteger(product.stock) || product.stock < 0) throw new Error(product.id + ": stock must be a non-negative integer.");
  if (typeof product.isActive !== "boolean") throw new Error(product.id + ": isActive must be boolean.");
  if (!Array.isArray(product.imagePaths) || product.imagePaths.length === 0) throw new Error(product.id + ": imagePaths must not be empty.");
  for (const imagePath of product.imagePaths) {
    if (typeof imagePath !== "string" || /^https?:/i.test(imagePath)) throw new Error(product.id + ": only local asset paths are allowed.");
    if (!fs.existsSync(path.resolve(__dirname, "..", imagePath))) throw new Error(product.id + ": missing local image " + imagePath);
  }
  for (const field of ["sizes", "colors"]) {
    if (!Array.isArray(product[field]) || product[field].length === 0) throw new Error(product.id + ": " + field + " must be a non-empty array.");
  }
}

async function main() {
  const products = JSON.parse(fs.readFileSync(DATA_FILE, "utf8"));
  if (!Array.isArray(products) || products.length !== 18) throw new Error("Expected exactly 18 demo products.");
  const ids = new Set();
  for (const product of products) {
    validateProduct(product);
    if (!product.id.startsWith("demo_") || ids.has(product.id)) throw new Error("Invalid or duplicate demo product ID: " + product.id);
    ids.add(product.id);
  }
  initializeApp({ credential: applicationDefault(), projectId: PROJECT_ID });
  const db = getFirestore();
  const writer = db.bulkWriter();
  for (const product of products) {
    const { id, ...document } = product;
    writer.set(db.collection("products").doc(id), document, { merge: true });
  }
  await writer.close();
  console.log("Seeded " + products.length + " demo products into " + PROJECT_ID + ".");
  console.log("Only fixed demo_* documents were written. No documents were deleted.");
}
main().catch(error => { console.error("Demo product seed failed:", error); process.exitCode = 1; });
