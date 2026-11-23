// Runnable with Node.js 22+ (global WebSocket available); no dependencies.
// Usage:
//   FEISHIN_WS_URL=ws://127.0.0.1:4333 node examples/client.mjs
//   FEISHIN_USER=you FEISHIN_PASS=secret node examples/client.mjs
// Browser use: replace process.env with your own configuration and use btoa().
const url = process.env.FEISHIN_WS_URL ?? 'ws://127.0.0.1:4333';
const user = process.env.FEISHIN_USER;
const pass = process.env.FEISHIN_PASS;
const ws = new WebSocket(url);
let queried = false;
const send = (message) => ws.send(JSON.stringify(message));

ws.addEventListener('open', () => {
  console.log('connected', url);
  // Only authenticate if credentials have been configured in the desktop app.
  if (user !== undefined || pass !== undefined) {
    const header = 'Basic ' + Buffer.from(`${user ?? ''}:${pass ?? ''}`, 'utf8').toString('base64');
    send({event: 'authenticate', header});
  }
});
ws.addEventListener('message', ({data}) => {
  const message = JSON.parse(String(data));
  console.log('received', JSON.stringify(message, null, 2));
  // Initial state is emitted only after successful (or unnecessary) auth.
  if (message.event === 'state' && !queried) {
    queried = true;
    send({event: 'tracks-request', requestId: 'demo-tracks-1', limit: 10, startIndex: 0});
  }
});
ws.addEventListener('error', (error) => console.error('WebSocket error:', error.message ?? error));
ws.addEventListener('close', (ev) => console.log('disconnected', ev.code, ev.reason));
