# HTTP API Reference

Complete endpoint reference for the smart-home agent service ([src/index.ts](src/index.ts)).
For *how to build an app* (patterns, decisions, gaps) see [APP-INTEGRATION.md](APP-INTEGRATION.md).

- Base URL: `http://<host>:3000` (port from `PORT`).
- Request/response bodies are JSON (`Content-Type: application/json`).
- Device IDs in every request/response are **aliases** (`light.living_room`), never raw
  hardware ids.
- The backend (`GATEWAY_KIND`) and model (`LLM_PROVIDER`) are server config and do **not**
  change this contract.

## Authentication

If the server sets `API_KEY`, every route **except** `GET /health` and `GET /app/*` requires:

```
Authorization: Bearer <API_KEY>
```

Missing/invalid → `401 { "error": "unauthorized: missing or invalid API key" }`.
If `API_KEY` is unset the server is open (dev mode only). The key is a single shared secret,
not per-user — see APP-INTEGRATION.md "Gaps".

## Error & status conventions

Every error response body is `{ "error": "<message>", ... }`. Control errors may add
`requires_confirmation`, `conflict_rule`, and/or `is_error`.

| status | when |
|--------|------|
| `200` | success |
| `400` | invalid request (missing/!valid field, unsupported action, bad params) |
| `401` | missing/invalid API key |
| `404` | device / room / scene not found |
| `409` | control blocked by a conflict rule (body has `conflict_rule`) |
| `428` | control needs confirmation (dangerous action) — resend with `confirm: true` |
| `500` | unexpected server error |
| `502` | control accepted by the cloud but the device never confirmed (offline/unresponsive) |

---

# Chat API

## `POST /chat`
One-shot conversational turn (non-streaming).

**Request**
| field | type | required | notes |
|-------|------|----------|-------|
| `message` | string | yes | non-empty user utterance |
| `session_id` | string | no | omit on first turn → server generates one; reuse it for context |
| `user_id` | string | no | `[A-Za-z0-9_.:-]`, ≤80; default `household`; tags events only |

**Response `200`**
```json
{
  "session_id": "abc-123",
  "user_id": "household",
  "reply": "Living room light turned on.",
  "tool_calls": [
    { "name": "control_device",
      "input": { "device_id": "light.living_room", "action": "turn_on" },
      "output": { "ok": true, "device_id": "light.living_room", "current": { "power": "on" }, "converged": true },
      "isError": false }
  ],
  "max_turns_reached": false
}
```
- `reply` — natural-language answer to display.
- `tool_calls[]` — `{ name, input, output, isError }` for each tool the agent ran this turn.
- `max_turns_reached` — true if the loop hit its turn cap before finishing.

**Errors** `400` (`message is required` / invalid `user_id`), `500`.

## `POST /chat/stream`
Same request body as `/chat`. Response is `text/event-stream` (SSE). Frames:

| event | data | meaning |
|-------|------|---------|
| `session` | `{ session_id, user_id }` | sent first |
| `text` | `{ delta }` | a chunk of the reply (append) |
| `tool_call` | `{ name, input }` | the agent invoked a tool |
| `tool_result` | `{ name, input, output, isError }` | that tool returned |
| `done` | `{ reply, tool_calls, max_turns_reached }` | final summary; stream then ends |
| `error` | `{ message }` | the turn failed |

`text` chunks carry only the model's prose; during a tool-use turn there's a pause between
`tool_call` and the next `text`. The connection closes after `done`/`error`.
Validation errors (`400`) are returned as a normal JSON response before the stream opens.

## `GET /sessions`
`200 → { "sessions": ["abc-123", ...] }` — all persisted session ids.

## `GET /sessions/:id`
`200 → { "session_id", "turns": <n>, "history": [ ...neutral messages ] }`.

## `DELETE /sessions/:id`
`200 → { "ok": true }` — deletes that conversation.

---

# REST Device API

Dashboard-style endpoints. Reads come straight from the gateway snapshot; writes
(`control`, `scenes/:id/run`) pass the **same Rules Engine gate** as the chat tools.

## `GET /devices`
List devices. Optional query filters `?room=<roomId>` and/or `?type=<type>`.

`200 → { "devices": [ Device, ... ] }` (see [Device](#device)).

## `GET /devices/:id`
`200 → Device`. `404` if the alias is unknown.

## `POST /devices/:id/control`
**Request**
| field | type | required | notes |
|-------|------|----------|-------|
| `action` | string | yes | per the device's profile — see [Action reference](#action-reference) |
| `params` | object | depends | action args, e.g. `{ "value": 30 }` |
| `confirm` | boolean | for dangerous actions | `true` authorizes a flagged/unlock action |
| `user_id` | string | no | tags the event |

**Response `200`**
```json
{ "ok": true, "device_id": "light.kitchen", "name": "Kitchen light",
  "action": "set_brightness", "previous": { "power": "off", "brightness": 0 },
  "current": { "power": "on", "brightness": 30 }, "converged": true }
```
**Errors** `400` (unsupported action / bad params), `404` (unknown device),
`409` (`{ error, conflict_rule }`), `428` (`{ error, requires_confirmation: true }` —
resend with `confirm: true`), `502` (accepted but device didn't confirm).

## `GET /rooms` · `GET /rooms/:id`
- `GET /rooms` → `{ "rooms": [ { "id", "name" }, ... ] }`
- `GET /rooms/:id` → `{ "room": { id, name }, "devices": [ Device, ... ] }`; `404` if unknown.

## `GET /scenes` · `POST /scenes/:id/run`
- `GET /scenes` → `{ "scenes": [ Scene, ... ] }`
- `POST /scenes/:id/run` — body `{ "confirm"?: boolean }` → `200` [SceneResult](#sceneresult).
  Same `409`/`428` gating as `control` if any step is dangerous/conflicting.

---

# Action reference

`params.value` unless noted. Sensors are read-only (no controllable actions).

| profile | type | actions (params · range) |
|---------|------|--------------------------|
| `onoff_actuator` | tv, plug | `turn_on`, `turn_off` |
| `dimmable_light` | light | `turn_on`, `turn_off`, `set_brightness` (`value` 0–100) |
| `color_light` | light | `turn_on`, `turn_off`, `set_brightness` (`value` 0–100), `set_color_temp` (`value` 2200–6500 K) |
| `curtain` | curtain | `open`, `close`, `stop`, `set_position` (`value` 0–100) |
| `door_lock` ⚠️ | lock | `lock`, `unlock` — **dangerous, needs `confirm`** |
| `siren_actuator` ⚠️ | siren | `turn_on`, `turn_off`, `set_volume` (0–2), `set_melody` (0–18), `set_duration` (`value` s, 0–1800) — **dangerous** |
| `mmwave_sensor` | sensor | `set_sensitivity` (0–9), `set_range` (`min_cm`,`max_cm` 0–1000), `set_detection_delay` (`value`), `set_fading_time` (`value`) |
| `ias_sensor`, `multi_sensor`, `button_remote`, `smoke_alarm` | sensor | read-only |
| `ac_thermostat` | — | planned / not shipped (refused) |

⚠️ = `dangerous`: the first control returns `428`; resend with `confirm: true`. `unlock` is
always treated as dangerous regardless of the flag.

---

# Data types

### Device
```json
{ "id": "light.living_room", "name": "Living room main light", "type": "light",
  "profile": "color_light", "room": "living_room", "online": true,
  "dangerous": false, "state": { "power": "on", "brightness": 71, "color_temp": 4000 } }
```
`state` keys depend on the profile (e.g. `power`/`brightness`/`color_temp`, `position`,
`state` (lock), `alarm`/`volume`/`melody`, sensor telemetry like `temperature`/`motion`/`presence`).

### Room
`{ "id": "living_room", "name": "Living room" }`

### Scene
```json
{ "id": "movie", "name": "Movie mode", "description": "...",
  "steps": [ { "device_id": "light.living_room", "action": "set_brightness", "params": { "value": 20 } }, ... ] }
```

### SceneResult
```json
{ "scene": Scene,
  "results": [ { "step": 1, "device_id": "light.living_room", "action": "turn_on", "ok": true }, ... ] }
```
A failed step has `"ok": false, "error": "<message>"` and does not abort later steps unless a
gate rejects the whole scene (then the request fails with `409`/`428`).

### ToolCall (in `tool_calls[]`)
`{ "name": string, "input": object, "output": any, "isError": boolean }`

---

# Operations endpoints

- `GET /health` (public) → `{ "ok": true }`.
- `GET /logs` → `{ "logs": [ ...last 100 tool calls ] }` — diagnostics (input/output/status/duration).
- `GET /app/dashboard.html` (public) → the demo dashboard ([examples/dashboard.html](examples/dashboard.html)).

## ML / automation

Eight ML tools (`check_anomalies`, `get_habit_suggestions`, `predict_next_actions`, …) are
exposed **through the chat agent only** (no REST endpoints). They proxy the Python ML service
at `ML_SERVICE_URL`; if it's down they return `is_error` and the device API is unaffected.
