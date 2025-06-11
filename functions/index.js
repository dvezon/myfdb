const functions = require("firebase-functions");
const fetch     = require("node-fetch");

exports.proxyExport = functions.https.onRequest(async (req, res) => {
  // ─── CORS headers ────────────────────────────────────
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
  res.set("Access-Control-Allow-Headers", "Content-Type");

  // Pre-flight OPTIONS
  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }

  // Σιγουρέψου ότι το body υπάρχει και έχει uid
  const body = req.body || {};
  console.log("📥 proxyExport invoked with body:", body);

 // if (body.uid !== "oRP8yo3mJcPF03N5kAWfgEwZaj03") {
  //  console.warn("⚠️ Forbidden: invalid uid", body.uid);
  //  res.status(403).send("Forbidden: invalid uid");
 //   return;
 // }

  try {
    const scriptUrl = "https://script.google.com/macros/s/AKfycbxfFmIVUqDDcUiiGbrWvXoD58RBpNIDjHm_5Tps2gfSxG4U6PJOyC3ZNp9_I8OcMiVg/exec";
    console.log("🔗 Forwarding to Apps Script URL:", scriptUrl);

    const response = await fetch(scriptUrl, {
      method : "POST",
      headers: { "Content-Type": "application/json" },
      body   : JSON.stringify(body),
    });

    const text = await response.text();
    console.log("⏳ Apps Script status:", response.status);
    console.log("📨 Apps Script response:", text);

    res.status(response.status).send(text);
  } catch (err) {
    console.error("❌ Proxy Error:", err.stack || err);
    res.status(500).send("Proxy error: " + err.toString());
  }
});
