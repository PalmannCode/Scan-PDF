import {
  errorResponse,
  json,
  preflight,
  requireUser,
} from "../_shared/http.ts";

function base64Url(bytes: Uint8Array | string): string {
  const raw = typeof bytes === "string"
    ? new TextEncoder().encode(bytes)
    : bytes;
  let binary = "";
  for (const byte of raw) binary += String.fromCharCode(byte);
  return btoa(binary).replaceAll("+", "-").replaceAll("/", "_").replaceAll(
    "=",
    "",
  );
}

function decodePart(jws: string): Record<string, unknown> {
  const encoded = jws.split(".")[1].replaceAll("-", "+").replaceAll("_", "/");
  return JSON.parse(
    atob(encoded.padEnd(Math.ceil(encoded.length / 4) * 4, "=")),
  );
}

async function appStoreToken(): Promise<string> {
  const issuer = Deno.env.get("APP_STORE_ISSUER_ID")!;
  const keyId = Deno.env.get("APP_STORE_KEY_ID")!;
  const bundleId = Deno.env.get("APP_STORE_BUNDLE_ID") ??
    "com.futurafund.scanpdf";
  const pem = Deno.env.get("APP_STORE_PRIVATE_KEY")!;
  if (!issuer || !keyId || !pem) {
    throw new Error("App Store Server API credentials are not configured.");
  }
  const header = base64Url(
    JSON.stringify({ alg: "ES256", kid: keyId, typ: "JWT" }),
  );
  const now = Math.floor(Date.now() / 1000);
  const payload = base64Url(
    JSON.stringify({
      iss: issuer,
      iat: now,
      exp: now + 300,
      aud: "appstoreconnect-v1",
      bid: bundleId,
    }),
  );
  const keyBytes = Uint8Array.from(
    atob(pem.replace(/-----[^-]+-----/g, "").replace(/\s/g, "")),
    (char) => char.charCodeAt(0),
  );
  const key = await crypto.subtle.importKey(
    "pkcs8",
    keyBytes,
    { name: "ECDSA", namedCurve: "P-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign(
    { name: "ECDSA", hash: "SHA-256" },
    key,
    new TextEncoder().encode(`${header}.${payload}`),
  );
  return `${header}.${payload}.${base64Url(new Uint8Array(signature))}`;
}

async function transactionInfo(transactionId: string, token: string) {
  for (
    const host of [
      "api.storekit.itunes.apple.com",
      "api.storekit-sandbox.itunes.apple.com",
    ]
  ) {
    const response = await fetch(
      `https://${host}/inApps/v1/transactions/${
        encodeURIComponent(transactionId)
      }`,
      {
        headers: { Authorization: `Bearer ${token}` },
      },
    );
    if (response.ok) return await response.json();
    if (response.status !== 404) {
      console.error(
        "App Store Server API",
        response.status,
        await response.text(),
      );
    }
  }
  throw new Error("The App Store transaction could not be verified.");
}

Deno.serve(async (req) => {
  const options = preflight(req);
  if (options) return options;
  try {
    const { user, admin } = await requireUser(req);
    const { transaction_id } = await req.json();
    if (typeof transaction_id !== "string" || !transaction_id) {
      return json({ error: "transaction_id is required." }, 400);
    }
    const info = await transactionInfo(transaction_id, await appStoreToken());
    const transaction = decodePart(info.signedTransactionInfo as string);
    const bundleId = Deno.env.get("APP_STORE_BUNDLE_ID") ??
      "com.futurafund.scanpdf";
    // Either Plus plan grants the entitlement. APP_STORE_PRODUCT_ID may hold a
    // comma-separated list; it defaults to both configured products.
    const productIds = (Deno.env.get("APP_STORE_PRODUCT_ID") ??
      "scanpdf.plus.weekly,scanpdf.plus.monthly")
      .split(",")
      .map((id) => id.trim())
      .filter((id) => id.length > 0);
    const purchasedProductId = String(transaction.productId ?? "");
    if (
      transaction.bundleId !== bundleId ||
      !productIds.includes(purchasedProductId)
    ) {
      return json(
        { error: "Transaction does not belong to this product." },
        400,
      );
    }
    // One App Store transaction unlocks exactly one account. Without this a
    // single purchase could be replayed to grant Plus on unlimited accounts.
    const originalTransactionId = String(
      transaction.originalTransactionId ?? transaction_id,
    );
    const { data: existingOwner } = await admin
      .from("subscriptions")
      .select("user_id")
      .eq("app_store_transaction_id", originalTransactionId)
      .maybeSingle();
    if (existingOwner && existingOwner.user_id !== user.id) {
      return json(
        { error: "This purchase is already linked to another account." },
        409,
      );
    }
    const expiresMs = Number(transaction.expiresDate ?? 0);
    const revoked = transaction.revocationDate != null;
    const active = !revoked && expiresMs > Date.now();
    const status = active ? "active" : "expired";
    await admin.from("subscriptions").upsert({
      user_id: user.id,
      app_store_transaction_id: originalTransactionId ??
        transaction.transactionId,
      status,
      plan_id: purchasedProductId,
      source: "app_store",
      current_period_start: transaction.purchaseDate
        ? new Date(Number(transaction.purchaseDate)).toISOString()
        : null,
      current_period_end: expiresMs ? new Date(expiresMs).toISOString() : null,
      verified_at: new Date().toISOString(),
    }, { onConflict: "user_id" });
    await admin.from("users").update({ subscription_status: status }).eq(
      "id",
      user.id,
    );
    return json({
      active,
      status,
      current_period_end: expiresMs ? new Date(expiresMs).toISOString() : null,
    });
  } catch (error) {
    return errorResponse(error);
  }
});
