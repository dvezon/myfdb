// -------------------------------------------
// functions/index.js  –  Cloud Functions v2
// Proxy που προωθεί το αίτημα στο Apps Script URL
// -------------------------------------------
//  ➤ Runtime: Node 18  (global fetch διαθέσιμο)
//  ➤ firebase-functions v4 – χρησιμοποιούμε v2 HTTPS API
// -------------------------------------------

import { onRequest } from "firebase-functions/v2/https";
import { logger } from "firebase-functions";

// Επιτρεπτοί hosts (basic security)
const ALLOWED_HOSTS = ["script.google.com"];

export const proxyExport = onRequest(
  {
    region: "us-central1",
    timeoutSeconds: 60,
    memory: "256MiB",
    cors: true, // Αυτόματα CORS για *
  },
  async (req, res) => {
    if (req.method === "OPTIONS") {
      // CORS pre‑flight handled by 'cors: true' αλλά κρατάμε fallback
      return res.status(204).send("");
    }

    const body = req.body || {};
    const { scriptUrl } = body;

    if (!scriptUrl) {
      return res.status(400).send("Missing scriptUrl in body");
    }

    // --- Host έλεγχος --------------------------------------------------
    try {
      const host = new URL(scriptUrl).host;
      const allowed = ALLOWED_HOSTS.some((h) => host.endsWith(h));
      if (!allowed) {
        logger.warn("Host not allowed:", host);
        return res.status(400).send("Host not allowed");
      }
    } catch (err) {
      return res.status(400).send("Invalid scriptUrl");
    }

    try {
      logger.info("Forwarding request to", scriptUrl);

      const response = await fetch(scriptUrl, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(body),
      });

      const text = await response.text();
      logger.info("Script responded", response.status);
      return res.status(response.status).send(text);
    } catch (err) {
      logger.error("Proxy error", err);
      return res.status(500).send("Proxy error: " + err);
    }
  }
);

/*const functions = require("firebase-functions");
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
    const scriptUrl = "https://script.google.com/macros/s/AKfycbxEmDBWKZrEpDmKPg5cckGm5EfGRpF1dyQfJ9Kb22e0tuTUs2djtlKvy2G3Q3aoSfqv/exec";
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
});*/
