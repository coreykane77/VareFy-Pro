// Usage: deno run gen-stream-token.ts <userId>
// Example: deno run gen-stream-token.ts 84e2a45d-0cec-427d-8d2f-30f158a96b6a

const secret = Deno.env.get("STREAM_SECRET") ?? "";
const userId = Deno.args[0];

if (!secret || !userId) {
  console.error("Usage: STREAM_SECRET=<secret> deno run gen-stream-token.ts <userId>");
  Deno.exit(1);
}

function base64url(input: string | Uint8Array): string {
  const str = typeof input === "string"
    ? btoa(unescape(encodeURIComponent(input)))
    : btoa(String.fromCharCode(...input));
  return str.replace(/\+/g, "-").replace(/\//g, "_").replace(/=/g, "");
}

const header  = base64url(JSON.stringify({ alg: "HS256", typ: "JWT" }));
const payload = base64url(JSON.stringify({ user_id: userId }));
const encoder = new TextEncoder();
const key = await crypto.subtle.importKey(
  "raw", encoder.encode(secret),
  { name: "HMAC", hash: "SHA-256" }, false, ["sign"]
);
const sig = await crypto.subtle.sign("HMAC", key, encoder.encode(`${header}.${payload}`));
const token = `${header}.${payload}.${base64url(new Uint8Array(sig))}`;

console.log("\nToken for", userId);
console.log(token);
