require("dotenv").config();
const WebSocket = require("ws");
const { v4: uuidv4 } = require("uuid");

// ─── Configuration from environment variables ───────────────────
const API_URL  = process.env.APPSYNC_API_URL;
const REGION  = process.env.APPSYNC_REGION;
const API_KEY = process.env.APPSYNC_API_KEY;

if (!API_URL || !REGION || !API_KEY) {
  console.error("Missing required environment variables: APPSYNC_API_URL, APPSYNC_REGION, APPSYNC_API_KEY");
  process.exit(1);
}

console.log(API_URL);
console.log(REGION);
console.log(API_KEY);

const HOST    = `${API_URL}`;     
//`${API_ID}.appsync-api.${REGION}.amazonaws.com`;

// /ws gives a 404
// /graphql/ws gives a 400
const WSS_URL = `wss://${API_URL}/graphql`;

console.log(HOST);
console.log(WSS_URL);

const SUBSCRIPTION_QUERY = `
  subscription OnCreateItem {
    onCreateItem {
      id
      name
      createdAt
    }
  }
`;

// Private API does not allow normal Headers.  You have to pass via QueryString or use Sec-WebSocket-Protocol
// See here: https://docs.aws.amazon.com/appsync/latest/devguide/real-time-websocket-client.html#handshake-details-to-establish-the-websocket-connection

// ─── Step 1: Build the connection URL ───────────────────────────
const amzDate = new Date().toISOString().replace(/[-:]/g, "").replace(/\.\d{3}/, "");
// Output: "20260302T143025Z"
console.log(amzDate);

const headerB64  = Buffer.from(JSON.stringify({
  "host": "xxxxxxxxxxxxxxxxx.appsync-api.us-east-1.amazonaws.com",
  "x-api-key": API_KEY
  //"x-amz-date": amzDate
})).toString("base64");

// Empty Payload as per: https://docs.aws.amazon.com/appsync/latest/devguide/real-time-websocket-client.html
const payloadB64 = Buffer.from(JSON.stringify({})).toString("base64");
console.log(payloadB64)

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
