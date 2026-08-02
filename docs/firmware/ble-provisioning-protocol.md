# FIBO Hub — BLE Provisioning Protocol (App Team Handoff)

> Version 1 · 2026-07-19 · Firmware: `esp32s3_bridge` (`main/ble_prov.c`)
> Audience: the mobile app team. This document is the complete contract for
> configuring a FIBO hub over BLE. The reference client implementing every
> flow below is `tester/test_ble_prov.py`.
> App developer guide (flows, UI states, error handling):
> [app-ble-provisioning-guide.md](app-ble-provisioning-guide.md)

## 1. Scope

The FIBO hub is an ESP32-S3 gateway with an **Ethernet-first uplink and an
optional 2.4 GHz WiFi fallback**: Ethernet is always preferred; if no
Ethernet IP is available for ~8 s and WiFi credentials are stored, the hub
connects to the cloud over WiFi instead, and switches back automatically
when Ethernet returns. BLE is used only for **onboarding and
configuration** — discovery, claiming, network setup, factory reset. Device
control (lights, sensors, …) is NOT done over BLE; it goes through the
cloud (AWS IoT Shadow) or the LAN.

What the app does over BLE:

1. Find the hub (scan, or direct via the QR label)
2. Establish an encrypted session (proof-of-possession from the QR)
3. Read hub status (`hub-info`, `hub-net`, `hub-wifi`)
4. Store a claim token (`hub-claim`) that later binds the hub to the user's
   account
5. Optionally configure static IP (`hub-net`) and/or WiFi fallback
   credentials (`hub-wifi`)
6. Factory reset (`hub-reset`)

## 2. Transport: Espressif protocomm over BLE GATT

The firmware uses ESP-IDF **protocomm** with the BLE transport — the same
stack as Espressif WiFi provisioning. **Do not implement raw GATT by hand.**
Use the official ESPProvision SDK, which handles session setup and endpoint
I/O:

- iOS: https://github.com/espressif/esp-idf-provisioning-ios (`ESPProvision`)
- Android: https://github.com/espressif/esp-idf-provisioning-android

Key facts:

- **Advertised device name**: `FIBO-XXXXXX` (last 3 bytes of the BT MAC,
  uppercase hex). The exact name is in the QR label (`ble` field).
- **Primary service UUID**: `4649424f-2d48-5542-2d50-524f562d3031`
  (the ASCII bytes of `FIBO-HUB-PROV-01`).
- Each protocomm **endpoint is a GATT characteristic** under that service;
  the characteristic's *User Description descriptor* carries the endpoint
  name. The SDK resolves names → characteristics automatically.
- Endpoint I/O is write-then-read on the characteristic; the SDK exposes it
  as `sendDataToCustomEndPoint(name, data)` (Android) /
  `sendData(path:data:)` (iOS).
- Only **one concurrent BLE connection** is accepted.

## 3. Security

- **Scheme**: protocomm **security1** — Curve25519 key exchange +
  proof-of-possession (PoP), AES-CTR encryption of all endpoint payloads.
  In the ESPProvision SDK: `ESPSecurity.SECURITY_1`.
- **PoP source**: the QR label on the enclosure (`pop` field). Every retail
  unit has a unique PoP injected at the factory. The development default
  (`fibo1234`) exists only on freshly flashed boards.
- A wrong PoP fails the session handshake; no endpoint is usable without a
  session.
- After the session is up, all payloads below are UTF-8 JSON, encrypted by
  the SDK transparently.

## 4. QR Label (version 1)

Printed on the enclosure at the factory:

```json
{"v":1,"sn":"FIBO-A1B2C3D4E5F6","ble":"FIBO-D4E5F6","pop":"x7k2mn9p"}
```

| Field | Meaning |
|---|---|
| `v` | label schema version (currently 1) |
| `sn` | device serial; matches `hub-info.serial` — verify after connecting |
| `ble` | BLE advertising name; connect to exactly this device |
| `pop` | proof-of-possession for the security1 handshake |

## 5. Provisioning Window (when the hub is connectable)

| Hub state | Window behavior |
|---|---|
| **Unclaimed** (out of box, or after factory reset) | Advertises **automatically at boot**, stays open until claimed |
| Claim succeeds | 5-minute countdown starts, then the window closes |
| **Claimed** | Closed by default; user holds **BOOT 3 s** to open a 5-minute window (e.g. to change network config) |
| BOOT 3 s while open | Closes early |
| BOOT 10 s | Factory reset + reboot (same as `hub-reset`) |

LED while the window is open: blue fast blink (WS2812 boards) / fast blink
(single-color LED on the final PCB).

UX note: for out-of-box onboarding the app needs no user action on the hub —
plug in power (+ Ethernet), scan the QR, connect.

## 6. Endpoint Contract

All endpoints exchange JSON (encrypted by the session). Unknown fields must
be ignored by both sides. `0xFFxx` values are the 16-bit characteristic UUIDs
under the primary service.

| Endpoint | UUID | Direction | Purpose |
|---|---|---|---|
| `prov-session` | 0xFF51 | SDK-internal | security1 handshake |
| `proto-ver` | 0xFF52 | read | version info |
| `hub-info` | 0xFF53 | read | identity + status |
| `hub-claim` | 0xFF54 | write | store claim token |
| `hub-net` | 0xFF55 | read/write | Ethernet configuration |
| `hub-reset` | 0xFF56 | write | factory reset |
| `hub-factory` | 0xFF57 | write | factory-station only; refused once claimed |
| `hub-wifi` | 0xFF58 | read/write | 2.4 GHz WiFi fallback credentials |

### 6.1 `proto-ver`

Request: any (the SDK sends a probe string). Response:

```json
{"prov":{"ver":"v1.1","sec_ver":1}}
```

### 6.2 `hub-info` — read status

Request: `{}` · Response:

```json
{
  "fw": "0.1.0",
  "serial": "FIBO-A1B2C3D4E5F6",
  "mac": "a1:b2:c3:d4:e5:f6",
  "eth_link": true,
  "eth_ip": "192.168.1.23",
  "wifi_configured": false,
  "wifi_connected": false,
  "net": "eth",
  "claimed": false
}
```

- `serial` is empty (`""`) on boards that skipped factory provisioning.
- `eth_link` currently reports the got-IP state; `eth_ip` is `"0.0.0.0"`
  when there is no address.
- `net` is the active uplink: `"eth"` | `"wifi"` | `"none"`. The hub is
  cloud-reachable whenever it is not `"none"`.
- After connecting, verify `serial == sn` from the QR before proceeding.

### 6.3 `hub-claim` — store claim token

Request: the raw claim token as the payload body (string, ≤ 256 bytes).
Response:

```json
{"status":"ok"}
```

Errors: `{"status":"invalid_args"}` (empty/oversized),
`{"status":"store_failed"}`.

Semantics:

- The token is persisted on the hub (`hub-info.claimed` flips to `true`).
- On an unclaimed hub, a successful claim arms the 5-minute window
  countdown — finish any `hub-net` configuration within that window.
- Token content is app/cloud-defined (e.g. a signed user-binding token from
  the backend). The hub treats it as opaque. The cloud-side claim API that
  consumes it is a separate work stream (not yet built).

### 6.4 `hub-net` — Ethernet configuration

**Read** — request `{}`:

```json
{"mode":"dhcp","link":true,"active_ip":"192.168.1.23"}
```

or, when a static config is stored:

```json
{"mode":"static","link":true,"active_ip":"192.168.1.50",
 "ip":"192.168.1.50","netmask":"255.255.255.0","gw":"192.168.1.1","dns":"8.8.8.8"}
```

**Write static** — request:

```json
{"mode":"static","ip":"192.168.1.50","netmask":"255.255.255.0",
 "gw":"192.168.1.1","dns":"8.8.8.8"}
```

`dns` is optional (defaults to the gateway). Response: `{"status":"ok"}`.

**Write DHCP** — request `{"mode":"dhcp"}` → `{"status":"ok"}`.

Semantics:

- Changes are applied **immediately** and persisted (re-applied on every
  boot). The BLE session survives the IP change — read back with `{}` to
  show the user the new state.
- Errors: `{"status":"invalid_args"}` (bad IPv4 in any field),
  `{"status":"apply_failed"}`.
- If a stored static config fails to apply at boot, the firmware falls back
  to DHCP for that boot (the stored config is kept).

### 6.5 `hub-wifi` — WiFi fallback credentials

The hub uses these only when Ethernet is down (see §1). 2.4 GHz networks
only — the S3 radio has no 5 GHz support; the app should filter the network
picker accordingly.

**Read status** — request `{}`:

```json
{"configured":true,"ssid":"MyHomeWiFi","connected":false,"ip":"0.0.0.0"}
```

`connected` is only ever `true` while WiFi is the active uplink (Ethernet
down); stored-but-idle credentials report `connected:false`.

**Store credentials** — request:

```json
{"ssid":"MyHomeWiFi","password":"secret123"}
```

Response: `{"status":"ok"}`. `password` may be omitted or `""` for an open
network. Constraints: ssid 1–32 bytes; password 8–64 bytes (or empty).
Violations return `{"status":"invalid_args"}`; NVS failures
`{"status":"store_failed"}`.

Semantics:

- Credentials are persisted and survive reboots; the switch-over logic is
  automatic from then on.
- Storing credentials does **not** make the hub validate them immediately —
  if Ethernet is up, the radio stays off. Reading back `connected` is only
  meaningful when Ethernet is down. The app should set expectations
  accordingly ("will be used if the network cable is unplugged").
- New credentials overwrite the old ones (single profile).
- `{"clear":true}` forgets the stored credentials → `{"status":"ok"}`.

### 6.6 `hub-reset` — factory reset

Request (confirmation is mandatory):

```json
{"confirm":true}
```

Response: `{"status":"ok","rebooting":true}` — the hub reboots ~1.5 s later,
comes back **unclaimed** and auto-advertising. Clears the claim token,
network config, and WiFi credentials; **keeps** the factory serial and PoP
(the QR label stays valid).

Errors: `{"status":"invalid_args", ...}` without `confirm`,
`{"status":"reset_failed"}`.

The app should also surface the hardware fallback to users: hold BOOT 10 s.

### 6.7 `hub-factory` — factory station only

For completeness; the app must never call this. Request
`{"serial":"...","pop":"..."}`; refused with `{"status":"forbidden"}` once
the hub is claimed. See `tester/README.md` for the station flow.

## 7. App Flows

### 7.1 Out-of-box onboarding

```
1. User plugs in the hub (power + Ethernet). Hub advertises automatically.
2. App scans the QR label → {sn, ble, pop}.
3. BLE scan for device named `ble`; connect; security1 session with `pop`.
4. hub-info → verify serial == sn; check `net` (active uplink).
   - If "none": prompt to check the cable, offer static IP via hub-net,
     or offer WiFi setup via hub-wifi (2.4G networks only).
5. Obtain a claim token from the backend (user is logged in).
6. hub-claim (token) → status ok; hub-info.claimed == true.
7. Optional: hub-net static configuration and/or hub-wifi credentials.
8. Done. The window auto-closes 5 minutes after the claim.
   (Cloud-side binding completion is the backend's job — separate stream.)
```

### 7.2 Reconfigure a claimed hub

```
1. Instruct the user: hold BOOT 3 s until the LED blinks the
   provisioning pattern (5-minute window).
2. Connect with the QR `pop` → hub-info / hub-net as needed.
```

### 7.3 Factory reset from the app

```
1. Within a connected session: hub-reset {"confirm":true}.
2. Hub reboots unclaimed and auto-advertises; onboarding can start over.
```

## 8. Error Handling Summary

| Situation | Signal | App action |
|---|---|---|
| Wrong PoP | security1 handshake fails | "Check the QR code / device label" |
| Window closed | device not found in scan | Unclaimed: check power. Claimed: instruct BOOT 3 s |
| Another client connected | connect fails (1 connection max) | Retry after a few seconds |
| `invalid_args` | per-endpoint JSON error | Fix the request; validate IPs client-side first |
| `forbidden` (hub-factory) | claimed hub | Expected — never call it |
| No response mid-session | window timed out (5 min after claim) | Reconnect (may need BOOT 3 s) |

## 9. Reference Implementations

- **Reference client (all flows)**: `tester/test_ble_prov.py` + procedure in
  `tester/README.md` — treat its behavior as the executable spec.
- **Firmware source of truth**: `esp32s3_bridge/main/ble_prov.c`
  (endpoints), `esp32s3_bridge/main/net_config.c` (network persistence).
- Protocol changes will bump `proto-ver` and this document's version; new
  endpoints/fields will be additive.
