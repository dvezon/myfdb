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
