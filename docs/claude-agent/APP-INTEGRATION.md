# App Integration Guide

How a client app (mobile / web / voice) integrates with the smart-home agent service.

> Two ways in: the **chat API** (`/chat`) for an assistant UI, and the **REST device API**
> (`/devices`, `/scenes`, `/rooms`) for a dashboard UI. Both enforce the same safety gate.

---

## 1. Two integration patterns

**Pattern A — Conversational app (chat UI).** The user types/speaks natural language; you
stream the agent's reply. Use the **chat API** (§3).

**Pattern B — Device dashboard (toggles, sliders, grids).** A traditional UI with a control
per device. Use the **REST device API** (§4). Every write goes through the same Rules Engine
gate (confirmation + conflict rules) as the chat path, so safety is identical.

You can mix both (a dashboard with an assistant tab). The "Gaps" section lists what
production deployment still needs (auth, CORS, …).

---

## 2. Base URL & auth

- Base URL: `http://<host>:3000` (port from `PORT`).
- Auth: if the server sets `API_KEY`, **every** route except `GET /health` requires
  `Authorization: Bearer <API_KEY>`. If `API_KEY` is unset, the server is open (dev only).
- ⚠️ The key is a **single shared secret**, not per-user. **Never embed it in a shipped
  client.** Proxy chat calls through your own app backend, which holds the key and adds
  real per-user auth. See Gaps.

---

## 3. Chat & session API (Pattern A)

### `GET /health` (public)
`200 → { "ok": true }`. Use for liveness checks. Does not require the API key.

### `POST /chat` — one-shot (non-streaming)
Request:
```json
{ "message": "turn on the living room light", "session_id": "abc-123", "user_id": "alice" }
```
- `message` (required, non-empty string).
- `session_id` (optional). Omit on the first turn → the server generates one and returns it.
  **Reuse it on every later turn** to keep conversation context.
- `user_id` (optional). Allowed chars `[A-Za-z0-9_.:-]`, ≤80. Defaults to `household`.
  Tags events/ML only — **not an authorization boundary** (see Gaps).

Response `200`:
```json
{
  "session_id": "abc-123",
  "user_id": "alice",
  "reply": "Living room light turned on.",
  "tool_calls": [
    { "name": "control_device",
      "input": { "device_id": "light.living_room", "action": "turn_on" },
      "output": { "ok": true, "current": { "power": "on" }, "converged": true },
      "isError": false }
  ],
  "max_turns_reached": false
}
```
- `reply` — the natural-language answer to show the user.
- `tool_calls` — what the agent did this turn (each: `name`, `input`, `output`, `isError`).
  Use it for an activity log or optimistic UI; ignore it for a plain chat UI.
- Errors: `400` (`{ "error": "message is required" }` / bad `user_id`), `500` (`{ "error": "..." }`).

### `POST /chat/stream` — streaming (Server-Sent Events)
Same request body as `/chat`. Response is `text/event-stream`. Parse SSE events:

| event | data | meaning |
|-------|------|---------|
| `session` | `{ session_id, user_id }` | sent first — capture `session_id` |
| `text` | `{ delta }` | a chunk of the reply — append to the bubble |
| `tool_call` | `{ name, input }` | the agent invoked a tool (e.g. show "turning on…") |
| `tool_result` | `{ name, input, output, isError }` | that tool returned |
| `done` | `{ reply, tool_calls, max_turns_reached }` | final; full reply + summary |
| `error` | `{ message }` | the turn failed |

Notes:
- `text` chunks only stream the model's **prose**. During a tool-use turn there's a pause
  (the model decides a tool → tool runs → then prose streams). Show a "thinking/acting"
  indicator between `tool_call` and the next `text`.
- The stream ends with `done` (or `error`), then the connection closes.
- For browsers, native `EventSource` only does GET; use `fetch` + a streaming body reader
  (or a POST-capable SSE lib) since this is `POST`.

### `GET /sessions` → `{ "sessions": [ ...ids ] }`
### `GET /sessions/:id` → `{ session_id, turns, history }` — full neutral message history.
### `DELETE /sessions/:id` → `{ "ok": true }` — clears that conversation.
### `GET /logs` → `{ "logs": [ ...last 100 tool calls ] }` — diagnostics, not for end users.

---

## 4. REST device API (Pattern B)

Dashboard endpoints. **Reads** hit the gateway directly; **writes** go through the same
Rules Engine gate as the chat tools (confirmation + conflict rules) and are recorded as events.

> **Runnable demo:** start the server and open `http://localhost:3000/app/dashboard.html`
> ([examples/dashboard.html](examples/dashboard.html)) — a single self-contained page that
> lists devices, renders a control per profile, and handles the 428-confirm / 409-conflict
> flows. Copy it as a starting point. It's served same-origin, so it sidesteps the CORS gap.

**Reads**
- `GET /devices` — all devices; filter with `?room=<id>` and/or `?type=<type>`
  → `{ "devices": [ { id, name, type, profile, room, online, dangerous, state }, … ] }`
- `GET /devices/:id` → one device (same shape); `404` if unknown.
- `GET /rooms` → `{ "rooms": [ { id, name }, … ] }`
- `GET /rooms/:id` → `{ room, devices }`; `404` if unknown.
- `GET /scenes` → `{ "scenes": [ { id, name, description, steps }, … ] }`

**Writes**
- `POST /devices/:id/control` — body `{ action, params?, confirm? }`
  - `action`: `turn_on` / `turn_off` / `set_brightness` / `set_color_temp` / `set_position` /
    `open` / `close` / `stop` / `lock` / `unlock` / `set_volume` / … (whatever the device's profile supports).
  - `params`: action args, e.g. `{ "value": 30 }` for `set_brightness`.
  - `confirm: true` to authorize a dangerous action (locks/sirens) — see status `428`.
  - `200` → `{ ok, device_id, name, action, previous, current, converged }`.
- `POST /scenes/:id/run` — body `{ confirm? }` → per-step result.

**Status codes** (non-200 body is always `{ "error": "...", … }`):

| code | meaning | app action |
|------|---------|------------|
| `200` | done | render new `current` |
| `400` | bad action/params | fix request |
| `404` | device/room/scene not found | — |
| `409` | blocked by a conflict rule (body has `conflict_rule`) | show `error` |
| `428` | confirmation required (dangerous action) | show confirm dialog → re-POST with `confirm:true` |
| `502` | accepted by the cloud but the device never confirmed | device offline/unresponsive |

```bash
# set the kitchen light to 30%
curl -X POST http://localhost:3000/devices/light.kitchen/control \
  -H 'authorization: Bearer $KEY' -H 'content-type: application/json' \
  -d '{"action":"set_brightness","params":{"value":30}}'

# unlock the front door — two steps
curl ... -d '{"action":"unlock"}'                 # → 428 (confirm required)
curl ... -d '{"action":"unlock","confirm":true}'  # → 200 (unlocked)
```

---

## 5. Conversation model

- **State lives server-side, keyed by `session_id`.** The client only stores the id; the
  server reloads + saves history each turn. One conversation = one `session_id`.
- **Multi-turn is automatic** — send the next user message with the same `session_id`.
- **Confirmation flow (dangerous actions: unlock, siren, anything flagged dangerous):**
  the agent will **not** execute on the first ask. It replies with a question
  (e.g. "Unlock the front door?") and runs **no** tool that turn. The user's next message
  ("yes" / "no") is handled deterministically server-side:
  - affirmative → the action executes, `done`/`tool_calls` shows it.
  - negative → "Okay, I won't do that.", nothing runs.
  So a plain chat UI needs **no special handling** — just relay the yes/no.
  - If you want an explicit "Confirm?" dialog with buttons, note the current API gives no
    dedicated `requires_confirmation` signal on the common path (the model asks in prose,
    without a tool call). Treat the agent's question as the prompt, and send the button
    result as a normal "yes"/"no" message. (A cleaner signal would need a backend change.)
- The agent already enforces safety in the tool layer (the Rules Engine), so a malformed
  or over-eager client cannot bypass confirmation or conflict rules.

---

## 6. Minimal chat client examples

One-shot:
```bash
curl -s http://localhost:3000/chat \
  -H 'authorization: Bearer $KEY' -H 'content-type: application/json' \
  -d '{"message":"turn on the kitchen light","session_id":"u-alice-1"}'
```

Streaming (browser, POST + SSE):
```js
const res = await fetch("/chat/stream", {
  method: "POST",
  headers: { "content-type": "application/json", authorization: `Bearer ${KEY}` },
  body: JSON.stringify({ message, session_id }),
});
const reader = res.body.getReader();
const dec = new TextDecoder();
let buf = "";
for (;;) {
  const { value, done } = await reader.read();
  if (done) break;
  buf += dec.decode(value, { stream: true });
  // split SSE frames on \n\n, parse "event:" and "data:" lines, dispatch
}
```

---

## 7. Gaps to close before production

- **Auth is a single shared key, not per-user.** Don't ship it in a client. Put your app
  backend in front; it holds the key and authenticates users.
- **No per-user / per-device authorization.** `user_id` only tags events; any caller can
  control any device. Real ACLs are needed before multi-tenant use.
- **No CORS headers.** A browser app on another origin will be blocked — the server needs
  CORS enabled (native mobile apps are unaffected).
- **No rate limiting.** Add it at your proxy/gateway.
- **Latency is LLM-bound** (~2–4s per control turn). Always use `/chat/stream` for
  perceived responsiveness; show a "working…" state during tool calls.

---

## 8. Quick reference

| Need | Use |
|------|-----|
| Send a user message, get a reply | `POST /chat` |
| Stream the reply token-by-token | `POST /chat/stream` (SSE) |
| Keep conversation context | reuse `session_id` |
| List devices / one device | `GET /devices` / `GET /devices/:id` |
| Control a device (toggle/slider) | `POST /devices/:id/control` `{ action, params?, confirm? }` |
| Rooms / scenes | `GET /rooms` · `GET /scenes` · `POST /scenes/:id/run` |
| Per-user tagging | `user_id` (not auth) |
| Liveness | `GET /health` |
