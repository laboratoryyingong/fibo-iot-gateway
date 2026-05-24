# Integrating with the Smart-Home Chat Agent

> Audience: app developers building a chat-based device-control feature on top of this agent.
> Goal: by the end of this doc you should be able to wire a chat UI to the agent's HTTP API, surface the conversation faithfully, and handle every UX edge case (confirmation, errors, offline devices, streaming).

## 1. What the agent is — and is not

**It is**: a stateful HTTP service. You send a user message in natural language; the agent decides which devices to query or control, calls the appropriate tools, and returns a reply you can show in the chat UI plus a structured `tool_calls` list you can render as inline action chips.

**It is not**: a device registry, a session/user database, or an auth layer. It assumes the caller has already authenticated and authorized the user upstream.

Concretely the agent can:

- List/filter devices (`get_devices`)
- Read state of one device or a whole room (`get_device_status`, `get_room_status`)
- Control a device with a friendly action (`control_device`)
- Run preset scenes (`run_scene`)

It refuses to:

- Operate on devices marked `dangerous: true` (e.g. door locks) without an explicit two-turn confirmation. See §6.
- Operate on profiles whose firmware support isn't shipped yet (currently `ac_thermostat` on the AWS gateway). It returns a structured error you must surface to the user.

## 2. Where your app sits

```
Mobile / web app
      │
      │   HTTPS (your reverse proxy / API gateway)
      ▼
Smart-home agent (this repo)
      │
      ├──► MockGateway          (dev / staging — no real devices)
      │
      └──► AwsShadowGateway     (AWS IoT MQTT Device Shadows — see CLAUDE.md §1)
```

The agent process is single-tenant in v1: one Anthropic API key, one gateway, one device registry (`data/aliases.json`). Multi-tenant fan-out is out of scope for this version — put it behind your own user-routing layer if you need that.

## 3. Deployment expectations

- **Host & port**: configurable via `PORT` (default `3000`). Production: terminate TLS at a reverse proxy in front of the agent. The agent itself speaks plain HTTP.
- **Required env vars**: `ANTHROPIC_API_KEY`. See `.env.example` for the full set including `GATEWAY_KIND`, `MQTT_URL`, `AWS_THING_NAME`.
- **No auth on the agent itself.** Anyone who can reach `/chat` can drive anyone's devices. Put it behind your existing auth.
- **CORS is not configured.** If your app is browser-based and on a different origin, add a CORS middleware in front (Express `cors` or your gateway).
- **Sessions persist to disk** at `data/sessions/<id>.json`. Process restarts do not lose history.

## 4. Endpoint reference

### `POST /chat` — blocking request/response

Send one user message, get the full reply back when the agent is done with all tool calls.

**Request**

```json
{
  "message": "Turn on the living-room light",
  "session_id": "user-42-current"
}
```

| Field        | Type   | Required | Notes                                                                  |
| ------------ | ------ | -------- | ---------------------------------------------------------------------- |
| `message`    | string | yes      | Non-empty natural-language input.                                      |
| `session_id` | string | no       | Continues an existing conversation. Omit to start a new one.           |

**Response** — `200 OK`

```json
{
  "session_id": "user-42-current",
  "reply": "Living-room light is on.",
  "tool_calls": [
    {
      "name": "control_device",
      "input": { "device_id": "light.living_room", "action": "turn_on" },
      "output": {
        "ok": true,
        "device_id": "light.living_room",
        "name": "Living room main light",
        "action": "turn_on",
        "previous": { "power": "off", "brightness": 80, "color_temp": 4000 },
        "current":  { "power": "on",  "brightness": 80, "color_temp": 4000 },
        "converged": true
      },
      "isError": false
    }
  ]
}
```

| Field         | Type           | Notes                                                                 |
| ------------- | -------------- | --------------------------------------------------------------------- |
| `session_id`  | string         | Use this in the next request to continue the conversation.            |
| `reply`       | string         | Final assistant message. Render in the chat.                          |
| `tool_calls`  | array          | In execution order. Each entry has `name`, `input`, `output`, `isError`. Use for inline action chips. |

**Errors** — `400` with `{ "error": "message is required" }` if `message` is missing/blank. `500` with `{ "error": "..." }` if something blows up server-side (rare; logs will have details).

### `POST /chat/stream` — Server-Sent Events

Same input as `/chat`, but the agent streams as it works. Use this for any UI where the user is waiting on the response — it dramatically improves perceived latency.

**Request body**: identical to `/chat`.

**Response**: `Content-Type: text/event-stream`. Events:

| Event           | When                                                  | Data payload                                                                  |
| --------------- | ----------------------------------------------------- | ------------------------------------------------------------------------------ |
| `session`       | First event, always.                                  | `{ "session_id": "..." }`                                                      |
| `text`          | Each text token Claude emits.                         | `{ "delta": "Living-" }` — concatenate to build the reply.                     |
| `tool_call`     | Before each tool runs.                                | `{ "name": "...", "input": {...} }` — render "Calling X…" if you want.         |
| `tool_result`   | After each tool finishes.                             | `{ "name", "input", "output", "isError" }` — flip the chip to ✓ or ✗.          |
| `done`          | Final event, success path.                            | `{ "reply": "...", "tool_calls": [...] }` — same shape as the blocking response. |
| `error`         | Only on server-side failure.                          | `{ "message": "..." }`                                                         |

The connection closes after `done` or `error`. Closing the request from your side aborts cleanly — no orphaned writes.

**Example raw stream:**

```
event: session
data: {"session_id":"a1b2"}

event: tool_call
data: {"name":"control_device","input":{"device_id":"light.living_room","action":"turn_on"}}

event: tool_result
data: {"name":"control_device","input":{...},"output":{"ok":true,...},"isError":false}

event: text
data: {"delta":"Living-"}

event: text
data: {"delta":"room light is on."}

event: done
data: {"reply":"Living-room light is on.","tool_calls":[...]}
```

### Session helpers

```
GET    /sessions             → { "sessions": ["a1b2", "c3d4", ...] }
GET    /sessions/<id>        → { "session_id", "turns", "history": [...] }
DELETE /sessions/<id>        → { "ok": true }
```

`history` is the raw Anthropic-format transcript (alternating `user` / `assistant` with content blocks). Not intended for direct UI display — use it for replaying or debugging.

### `GET /logs`

Returns the last 100 tool calls across all sessions, each as a JSON object with `ts`, `session_id`, `tool`, `input`, `output`, `status` (`ok` / `error` / `blocked`), `duration_ms`. Use for ops dashboards or admin audits.

## 5. The five tools, briefly

Your UI doesn't call these directly — Claude does. But knowing them helps you build sensible action chips.

| Tool                | What it does                                                                                | Renders as                                  |
| ------------------- | ------------------------------------------------------------------------------------------- | ------------------------------------------- |
| `get_devices`       | Lists devices. Optionally filtered by `room` or `type`.                                     | "Looked up devices"                         |
| `get_device_status` | Reads one device's current state.                                                           | "Checked {device}"                          |
| `get_room_status`   | Reads every device in a room.                                                               | "Checked {room}"                            |
| `control_device`    | Sends a command (`turn_on`, `set_brightness`, `lock`, …) to one device. May require `confirm`. | "Turned on living-room light"               |
| `run_scene`         | Executes a preset scene (`sleep` / `home` / `away` / `movie`). May require `confirm`.       | "Activated sleep mode"                      |

Each `tool_result.output` is a JSON object with the actual state delta. See §7 for full examples.

## 6. The confirmation flow (most important UX section)

Some operations require explicit user confirmation **before** the agent will execute them:

- Any device whose alias is flagged `dangerous: true` (currently: `lock.front_door`).
- The `unlock` action on any device, regardless of dangerous flag.
- Any scene whose steps include a dangerous device or an unlock action.

When the user first asks for one of these, the agent **does not call the gateway**. Instead:

1. The dispatcher returns `tool_result.output = { error, requires_confirmation: true }` with `isError: true`.
2. The agent text reply asks the user to confirm in natural language.
3. The user replies "yes" (or equivalent).
4. The agent re-issues the tool call with `confirm: true` in the input, and execution proceeds.

This is **enforced server-side** — there is no way to bypass it from the API. The safety gate runs ahead of any gateway call, so an unconfirmed unlock never reaches MQTT or the mock.

### Worked example — unlocking the front door

**Turn 1 — user asks:**

```json
POST /chat
{ "message": "Unlock the front door", "session_id": "u42" }
```

**Agent response — turn 1:**

```json
{
  "session_id": "u42",
  "reply": "Just to confirm: would you like me to unlock the front door?",
  "tool_calls": [
    {
      "name": "control_device",
      "input": { "device_id": "lock.front_door", "action": "unlock" },
      "output": {
        "error": "Running unlock on Front door lock is a sensitive operation. Confirm with the user first, then call again with confirm=true.",
        "requires_confirmation": true
      },
      "isError": true
    }
  ]
}
```

**Turn 2 — user confirms:**

```json
POST /chat
{ "message": "Yes, unlock it", "session_id": "u42" }
```

**Agent response — turn 2:**

```json
{
  "session_id": "u42",
  "reply": "Front door unlocked.",
  "tool_calls": [
    {
      "name": "control_device",
      "input": {
        "device_id": "lock.front_door",
        "action": "unlock",
        "confirm": true
      },
      "output": {
        "ok": true,
        "device_id": "lock.front_door",
        "previous": { "state": "locked", "battery": 87 },
        "current":  { "state": "unlocked", "battery": 87 },
        "converged": true
      },
      "isError": false
    }
  ]
}
```

### What your app should do

- **Always reuse the same `session_id`** across the confirmation turns. Without it, the agent has no context to resolve "yes" against.
- **Render the `requires_confirmation` `tool_result` differently from a hard error.** It is not a failure — it is a pending action. Suggested UI: render the chip with a warning icon and the agent's confirmation question prominently.
- **Do not auto-respond "yes" on the user's behalf.** The whole point is human-in-the-loop. If your app has its own confirm dialog, use it to prompt the user, then send their answer as the next chat message.
- **Cancellation is implicit.** If the user says "never mind" or asks for something else, the agent abandons the pending unlock. No special API for cancel.

## 7. UX flows with full examples

### 7.1 Simple command

User: "Turn on the living-room light."

Stream events you'll see, in order:

1. `session`
2. `tool_call` → `control_device(light.living_room, turn_on)`
3. `tool_result` → ok, previous/current state
4. `text` deltas building "Living-room light is on."
5. `done`

### 7.2 Multi-step from a single user message

User: "Set the bedroom to sleep mode — lights off, AC to 24, curtains closed."

Stream events:

1. `session`
2. `tool_call` → `control_device(light.bedroom, turn_off)` → `tool_result` ✓
3. `tool_call` → `control_device(ac.bedroom, turn_on)` → `tool_result`
   - **On `GATEWAY_KIND=aws`**: `tool_result.isError = true` with message `"ac_thermostat is a Stage-5 firmware profile, not yet shipped..."` (see §9).
   - **On `mock`**: `tool_result.isError = false`.
4. `tool_call` → `control_device(ac.bedroom, set_temperature, {value: 24})` → similar split.
5. `tool_call` → `control_device(curtain.bedroom, close)` → `tool_result`.
6. `text` deltas with a summary.
7. `done`.

App takeaway: **`tool_calls` are not atomic.** Partial success is normal. Render each chip independently with its own status.

### 7.3 Brightness control (translation visible to backend, not user)

User: "Dim the kitchen light to 30%."

- `tool_call.input` = `{ device_id: "light.kitchen", action: "set_brightness", params: { value: 30 } }`
- On AWS path, this becomes shadow `desired.state = { power: 1, level: 76 }` on the wire — but your app never sees the firmware-shape. The friendly state in `tool_result.output.current` will be `{ power: "on", brightness: 30 }`.

The app never needs to translate units. The agent handles it.

### 7.4 Scene execution

User: "Activate sleep mode."

- Single `tool_call` with `name: "run_scene"`, `input: { scene_id: "sleep" }`.
- `tool_result.output`:

```json
{
  "scene": { "id": "sleep", "name": "Sleep mode", "description": "...", "steps": [...] },
  "results": [
    { "step": 1, "device_id": "light.living_room", "action": "turn_off", "ok": true },
    { "step": 2, "device_id": "light.bedroom",     "action": "turn_off", "ok": true },
    { "step": 3, "device_id": "light.kitchen",     "action": "turn_off", "ok": true },
    { "step": 4, "device_id": "tv.living_room",    "action": "turn_off", "ok": true },
    { "step": 5, "device_id": "ac.bedroom",        "action": "turn_on",
      "ok": false, "error": "ac_thermostat is a Stage-5 firmware profile..." },
    { "step": 6, "device_id": "ac.bedroom",        "action": "set_temperature",
      "ok": false, "error": "ac_thermostat is a Stage-5 firmware profile..." },
    { "step": 7, "device_id": "curtain.living_room","action": "close",    "ok": true }
  ]
}
```

App takeaway: a scene `tool_call` summarizes a batch. Each step has its own `ok` / `error`. The agent's `reply` will mention which steps failed; render the per-step results if you want a detail drawer.

### 7.5 Failure modes

| Cause                                   | What you see                                                                                                                                                  |
| --------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Unknown device id**                   | `tool_result.output = { error: "device not found: X" }`, `isError: true`. Agent replies honestly ("I couldn't find a device named X.").                       |
| **Device offline**                      | `tool_result.output = { error: "device X is offline" }`, `isError: true`. Agent surfaces it.                                                                  |
| **Action not supported by the profile** | `tool_result.output = { error: "device X does not support action: Y" }`. Common when Claude guesses wrong; usually it self-corrects on the next turn.        |
| **Profile not shipped by firmware**     | See §9. Stable error string contains `not yet shipped`.                                                                                                       |
| **Gateway timeout (AWS path)**          | `tool_result.output = { error: "gateway timeout (3000ms): ..." }`. Means MQTT round-trip failed. Surface as a transient error.                                |
| **Server crash**                        | `/chat`: HTTP 500 with `{ error }`. SSE: emits an `error` event then closes.                                                                                  |

In every case, the agent's `reply` text is your primary UI surface — it will explain in user-friendly language. The structured `tool_result` is for diagnostic chips and analytics.

## 8. Session management strategy

Recommended:

- **One session per conversation thread per user.** If your app supports multiple parallel chats, use one `session_id` per thread.
- **Generate the id client-side** (UUID v4) so you control the namespace. Pass it on every request.
- **Don't reset on app reload.** The agent has the history on disk; resuming a stale session "just works" up to the model's context limit.
- **Clear when the user starts a new conversation** by sending `DELETE /sessions/<id>` or just rotating to a fresh id (the old file is harmless until cleaned up by a cron).
- **Don't share a session across users.** There is no authorization separation server-side; whoever has the `session_id` sees the history.

### Long-session caveat

There is no history-trimming yet (tracked in `CLAUDE.md` §11). For long-running threads, the per-turn input grows linearly. Practical recommendations:

- Cap each user's working session to ~50 turns. Beyond that, start a new session.
- If you need a "summary" feature, generate it client-side from `GET /sessions/<id>` and the message history.

## 9. The `ac_thermostat` situation

The firmware team has not yet shipped the AC thermostat profile. Until they do:

- On `GATEWAY_KIND=mock`: AC control works fully (in-memory).
- On `GATEWAY_KIND=aws`: any `control_device` on an AC device returns an immediate error containing the substring `"not yet shipped"`. The error fires **before** any MQTT publish, so it's fast.

What to do in the app:

- **Don't hide AC devices** from listings — they show up in `get_devices` regardless of backend.
- **Detect the substring** `not yet shipped` in `tool_result.output.error` and render with a "Coming soon" badge rather than as a hard failure, if you want.

This is the only profile with this status today. When firmware ships Stage 5, the agent code does not change — just flip `status: "planned"` → `"supported"` in `src/gateway/profiles/ac_thermostat.ts`. Your app does not need to know.

## 10. Internationalization

The agent replies in the **user's language**, detected from the input. Default is English when the input is ambiguous. Tested with English, Chinese, Japanese; works with any language Claude handles natively.

- You do not need to pass a locale. Don't try — there's no field for it.
- Device names in `tool_result` (e.g. `"Living room main light"`) come from `data/aliases.json` and are static. If you need them localized, do it client-side from a translation table, keyed on the alias id.
- The `reply` text is what to show in the chat bubble.
- Scene names (`"Sleep mode"`, `"Welcome home"`, etc.) are also static; same treatment as device names.

## 11. Performance and latency expectations

- **Model**: defaults to Claude Haiku 4.5 for cost and latency. Single-tool turns typically resolve in 1–3 seconds. Multi-tool turns (scenes, ambiguous queries that need a lookup first) can take 3–8 seconds.
- **Prompt caching is enabled** for system + tools, which cuts input billing after the first call in a 5-min window. The user should still perceive normal latency on the first request after idle — subsequent requests are faster.
- **AWS path adds ~50–500 ms per device round-trip.** Local broker (dev) is at the low end; real AWS IoT will be at the high end. The agent's per-request timeout is **3 seconds** per gateway operation by default.
- **Streaming is strongly recommended** for UX. The `text` deltas start arriving well before the final `done`, so the perceived latency drops by 50%+.
- **Concurrent requests on the same session**: serialized server-side via the gateway snapshot, but no explicit lock. Your app should debounce send-while-pending to avoid races (also a good chat-UI default).

## 12. Suggested chat-UI affordances

- Render `tool_call` events as inline "action chips" inside the assistant message bubble, in arrival order. Update each chip when its matching `tool_result` arrives.
- Show a different style for `tool_result.isError: true` AND `requires_confirmation: true` — it is a question to the user, not a failure.
- Show device names from `output.name` (already localized at the data level).
- Show before/after state from `output.previous` / `output.current` in an expandable detail drawer if you have one.
- Provide a "View backend log" admin link that fetches `GET /logs`.
- Don't render the raw error message verbatim for user-facing errors — Claude's `reply` field already does that in the user's language. Use the structured error only for chip styling and analytics.

## 13. Versioning and stability

- The five tool names and their inputs are a contract. They will not change without a major version bump. Add new actions inside an existing tool over time.
- The response shape (`reply`, `tool_calls`, `session_id`) is stable.
- The SSE event names (`session`, `text`, `tool_call`, `tool_result`, `done`, `error`) are stable.
- The internal device taxonomy may evolve (more profiles); `get_devices` may surface new `type` values. Treat the `type` enum as open-ended.

## 14. What is out of scope for the agent (so your app must handle)

- User authentication & authorization.
- Per-user device permissions / ACLs (e.g. kids can't unlock doors).
- Push notifications when device state changes outside the chat.
- Real-time device-state subscriptions for non-chat UI surfaces (e.g. a dashboard).
- Voice input/output transcription.
- Image/video understanding.

The agent is a chat-driven control surface. Anything else is your app's job.

## 15. Quick-start sanity check for your integration

Run this end-to-end before declaring the integration done. All against a non-prod agent.

1. New session, simple read: send "What devices are online?" — expect a `get_devices` tool call and a list in `reply`.
2. Simple write: send "Turn on the living-room light" — expect one `control_device` chip and a 1-sentence reply.
3. Confirmation flow: send "Unlock the front door" — expect a `requires_confirmation` chip and a question in `reply`. Then send "Yes" with the same session_id — expect a successful re-call.
4. Scene: send "Activate sleep mode" — expect one `run_scene` chip with multi-step results.
5. Failure surfacing: send "Turn off the spaceship" — expect `device not found` surfaced in `reply`.
6. Streaming: same scenarios via `POST /chat/stream` — verify text deltas, tool_call/result events, and clean `done`.
7. Session resume: send a new message with the previous session_id after a process restart — verify context is preserved.

If all seven pass, your app is wired correctly.

## 16. Need help?

- Architecture and internal contracts: read [CLAUDE.md](CLAUDE.md).
- Run instructions, env-var matrix, and local broker setup: [README.md](README.md).
- Firmware shadow contract and profile catalog: [docs/aws-iot-shadow-device-profiles.md](docs/aws-iot-shadow-device-profiles.md).
- Anything bug-shaped: send a `GET /logs` excerpt plus the `session_id` and `tool_calls` from the failing turn.
