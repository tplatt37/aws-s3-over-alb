require("dotenv").config();
const WebSocket = require("ws");
const { v4: uuidv4 } = require("uuid");

// ─── Configuration from environment variables ───────────────────
const API_ID  = process.env.APPSYNC_API_ID;
const REGION  = process.env.APPSYNC_REGION;
const API_KEY = process.env.APPSYNC_API_KEY;

if (!API_ID || !REGION || !API_KEY) {
  console.error("Missing required environment variables: APPSYNC_API_ID, APPSYNC_REGION, APPSYNC_API_KEY");
  process.exit(1);
}

const HOST    = `${API_ID}.appsync-api.${REGION}.amazonaws.com`;
const WSS_URL = `wss://${API_ID}.appsync-realtime-api.${REGION}.amazonaws.com/graphql`;

const SUBSCRIPTION_QUERY = `
  subscription OnCreateItem {
    onCreateItem {
      id
      name
      createdAt
    }
  }
`;

// ─── Step 1: Build the connection URL ───────────────────────────
const headerB64  = Buffer.from(JSON.stringify({
  host: HOST,
  "x-api-key": API_KEY,
})).toString("base64");

const payloadB64 = Buffer.from(JSON.stringify({})).toString("base64");

const connectionUrl = `${WSS_URL}?header=${headerB64}&payload=${payloadB64}`;

// ─── Step 2: Open WebSocket ─────────────────────────────────────
const ws = new WebSocket(connectionUrl, ["graphql-ws"]);

ws.on("open", () => {
  console.log("[open] Sending connection_init...");
  ws.send(JSON.stringify({ type: "connection_init" }));
});

ws.on("message", (raw) => {
  const msg = JSON.parse(raw);

  switch (msg.type) {
    case "connection_ack": {
      const timeout = msg.payload?.connectionTimeoutMs ?? 0;
      console.log(`[connection_ack] Timeout: ${timeout}ms`);

      // ─── Step 3: Register the subscription ──────────────
      const subId = uuidv4();
      ws.send(JSON.stringify({
        id: subId,
        type: "start",
        payload: {
          data: JSON.stringify({ query: SUBSCRIPTION_QUERY }),
          extensions: {
            authorization: {
              host: HOST,
              "x-api-key": API_KEY,
            },
          },
        },
      }));
      console.log(`[start] Subscription registered (id=${subId})`);
      break;
    }

    case "start_ack":
      console.log(`[start_ack] Subscription ${msg.id} confirmed`);
      break;

    case "data":
      console.log("[data]", JSON.stringify(msg.payload, null, 2));
      break;

    case "ka":
      // Keep-alive — no action needed
      break;

    case "error":
      console.error("[error]", msg.payload);
      break;

    default:
      console.log(`[${msg.type}]`, raw.toString());
  }
});

ws.on("error", (err) => console.error("[error]", err.message));
ws.on("close", (code, reason) =>
  console.log(`[closed] code=${code} reason=${reason}`)
);
