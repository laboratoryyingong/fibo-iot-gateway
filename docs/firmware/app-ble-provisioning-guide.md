# FIBO Hub Provisioning · App Developer Guide

> Version 1 · 2026-07-19 · Audience: mobile app developers
> Byte-level wire contract: [ble-provisioning-protocol.md](ble-provisioning-protocol.md)
> Reference client (runnable implementation of every flow): `tester/test_ble_prov.py`
> Firmware implementation: `esp32s3_bridge/main/ble_prov.c`

## 1. Architecture in One Sentence

The FIBO Hub is a smart-home gateway with an **Ethernet-first uplink and an
optional 2.4 GHz WiFi fallback**: Ethernet is always preferred; if the cable
is unplugged (no Ethernet IP for ~8 s) and WiFi credentials are stored, the
hub reaches the cloud over WiFi, and switches back automatically when
Ethernet returns. BLE is used for **onboarding only**: discovery, claiming
(binding to a user account), network configuration — including handing the
hub the home WiFi credentials — and factory reset. Once configured the app
disconnects — device control (lights, sensors, …) goes through the cloud
(AWS IoT Shadow), **never over BLE**.

```
Mobile app ──BLE (encrypted)──► FIBO Hub ──Ethernet or WiFi/TLS──► AWS IoT
     │                                                               ▲
     └───────── cloud API (login, token, binding status) ────────────┘
```

## 2. Prerequisites

**Use the official Espressif ESPProvision SDK** — do not implement raw GATT:

- iOS: <https://github.com/espressif/esp-idf-provisioning-ios> (`ESPProvision`)
- Android: <https://github.com/espressif/esp-idf-provisioning-android>

The SDK handles the BLE transport and the security1 encrypted handshake;
the business endpoints exchange JSON through the SDK's custom-endpoint API.

Permissions: Bluetooth (iOS `NSBluetoothAlwaysUsageDescription` /
Android `BLUETOOTH_SCAN` + `BLUETOOTH_CONNECT`). No other network-related
permissions are needed.

## 3. The QR Label (entry point for everything)

Printed on the enclosure at the factory, JSON:

```json
{"v":1,"sn":"FIBO-A1B2C3D4E5F6","ble":"FIBO-D4E5F6","pop":"x7k2mn9p"}
```

| Field | Meaning | How the app uses it |
|---|---|---|
| `v` | label schema version (currently 1) | prompt an app update on unknown versions |
| `sn` | device serial | verify against `hub-info.serial` after connecting; **it is also the AWS IoT thing name** — every later cloud operation (shadow reads/writes, binding-status queries) addresses the device by it |
| `ble` | BLE advertising name | match exactly this device when scanning |
| `pop` | proof-of-possession for the encrypted handshake | pass to the SDK for the security1 session |

> Development boards may have skipped factory provisioning: `serial` is an
> empty string, the PoP is the default `fibo1234`, and the advertising name
> is `FIBO-` + last 6 hex digits of the Bluetooth MAC.

## 4. BLE Connection Parameters

| Item | Value |
|---|---|
| Advertised device name | `FIBO-XXXXXX` (the QR `ble` field) |
| Primary service UUID | `4649424f-2d48-5542-2d50-524f562d3031` (ASCII of "FIBO-HUB-PROV-01") |
| Security | protocomm security1 (Curve25519 + PoP), built into the SDK |
| Concurrent connections | **1 max** — on connect failure, ask the user to retry in a few seconds |
| Protocol version | `proto-ver` returns `{"prov":{"ver":"v1.1","sec_ver":1}}` |

**Platform gotcha (hit in real testing)**: CoreBluetooth on iOS/macOS caches
device names — the OS-level `peripheral.name` may be empty or stale. When
scanning, **filter by the primary service UUID** and take the display name
from the advertisement data, not from the OS-cached name.

## 5. Provisioning Window (when the hub is connectable)

| Hub state | Window behavior |
|---|---|
| **Unclaimed** (out of box, or after factory reset) | Advertises **automatically at boot**, stays open until claimed |
| Claim succeeds | 5-minute countdown starts, then the window closes |
| **Claimed** | Closed by default; the user holds the **BOOT button 3 s** to open a 5-minute window |
| BOOT 3 s while open | Closes early |
| BOOT **10 s** | Factory reset + reboot (same as `hub-reset`) |

**LED indication** (use in onboarding copy): window open = **fast blink**
(blue fast blink on WS2812 boards); Ethernet offline = slow blink; normal
operation = solid on.

For out-of-box onboarding the user never touches any button on the hub:
plug in power + Ethernet, scan the QR, connect.

## 6. Out-of-Box Onboarding (main flow)

```
① Scan the QR label          → get {sn, ble, pop}
② BLE scan                   → filter by service UUID, advertising name == ble
③ Establish encrypted session→ SDK security1 with pop
④ Read hub-info              → verify serial == sn; check net (active uplink)
⑤ (only if net == "none")    → prompt to check the cable, configure static IP,
                               or send home WiFi credentials via hub-wifi
⑥ Request claim token        → user is logged in; backend issues a one-time token
⑦ Write hub-claim(token)     → {"status":"ok"}; hub-info.claimed flips to true
⑧ Poll backend binding state → backend confirms the hub↔account binding (§10)
⑨ Done                       → disconnect BLE; the window auto-closes after 5 min

Recommended UX: even when Ethernet is up, offer an optional "backup WiFi"
step during onboarding — credentials stored now mean the hub survives a
cable/router change later without re-provisioning.
```

Decision points and failure branches:

- **② Nothing found**: an unclaimed hub should always be advertising. Ask
  the user to check power and the LED: fast blink = window open (should be
  discoverable); slow blink = network down but window open (still
  connectable); solid = window closed (for a claimed hub, instruct
  BOOT 3 s).
- **③ Handshake fails**: essentially only one cause — wrong PoP. Show
  "please re-scan the QR code on the device".
- **④ Serial mismatch**: connected to someone else's hub (possible when
  several advertise at once). Matching the exact `ble` name avoids this;
  on mismatch, disconnect and rescan.
- **④ net is "none"**: the hub has no uplink. Offer three paths: check the
  cable / router DHCP, open the static-IP screen (§8), or send WiFi
  credentials (`hub-wifi`; the WiFi takeover starts ~8 s after Ethernet is
  seen down — re-read `hub-info` until `net` becomes `"wifi"`). **Do not
  proceed to ⑥⑦ while net is "none"** — a claimed hub that cannot reach
  the cloud helps nobody.
- **⑦ Returns invalid_args**: empty token or > 256 bytes — an app/backend
  bug, not a user error.

## 7. Reconfiguring a Claimed Hub

Scenario: new router, static IP change.

1. Instruct the user: hold the hub's BOOT button for 3 s until the LED
   fast-blinks
2. Then same as the main flow: scan → session with the QR `pop` →
   `hub-info` / `hub-net`
3. The window stays open only 5 minutes; if it times out, press again

## 8. Endpoint Quick Reference (all payloads)

All endpoints exchange JSON (encrypted by the session). Unknown fields must
be ignored by both sides.

### hub-info (read status)

Request `{}` → response:

```json
{"fw":"0.1.0","serial":"FIBO-A1B2C3D4E5F6","mac":"a1:b2:c3:d4:e5:f6",
 "eth_link":true,"eth_ip":"192.168.1.23",
 "wifi_configured":false,"wifi_connected":false,"net":"eth","claimed":false}
```

`net` is the active uplink: `"eth"` | `"wifi"` | `"none"` — the hub is
cloud-reachable whenever it is not `"none"`.

### hub-claim (store the claim token)

Request: the raw token as the payload body (string, ≤ 256 bytes; the app
treats it as opaque — never parse or modify it)
→ `{"status":"ok"}` | `{"status":"invalid_args"}` | `{"status":"store_failed"}`

### hub-net (network configuration)

- Read: `{}` → `{"mode":"dhcp","link":true,"active_ip":"192.168.1.23"}`
  (static mode adds `ip/netmask/gw/dns` fields)
- Write static: `{"mode":"static","ip":"192.168.1.50","netmask":"255.255.255.0","gw":"192.168.1.1","dns":"8.8.8.8"}`
  (`dns` optional, defaults to the gateway) → `{"status":"ok"}`
- Write DHCP: `{"mode":"dhcp"}` → `{"status":"ok"}`
- Changes apply **immediately** and persist across reboots. The BLE session
  survives the IP change — read back with `{}` and show the user the new
  state. Validate IPv4 fields client-side first to avoid `invalid_args`
  round trips.

### hub-wifi (WiFi fallback credentials)

- Read status: `{}` →
  `{"configured":true,"ssid":"MyHomeWiFi","connected":false,"ip":"0.0.0.0"}`
- Store: `{"ssid":"MyHomeWiFi","password":"secret123"}` → `{"status":"ok"}`
  (`password` omitted/`""` = open network; ssid 1–32 bytes, password 8–64
  or empty)
- Forget: `{"clear":true}` → `{"status":"ok"}`

App-relevant semantics:

- **2.4 GHz only** — filter the network picker; the hub's radio has no 5 GHz.
- Storing does **not** validate the credentials immediately: while Ethernet
  is up the radio stays off (`connected` stays `false`). Set expectations in
  the UI: "will be used if the network cable is unplugged". A live
  validation is only observable when Ethernet is actually down.
- Single profile — new credentials overwrite the old ones.

### hub-reset (factory reset)

The request must carry confirmation: `{"confirm":true}` →
`{"status":"ok","rebooting":true}`. The hub reboots ~1.5 s later and comes
back unclaimed + auto-advertising. Clears the claim, network config, and
WiFi credentials, **keeps** the serial and PoP (the QR label stays valid).
Also surface the hardware fallback in the UI: hold BOOT 10 s.

### hub-factory

Factory-station only — **the app must never call it**. A claimed hub
refuses it (`forbidden`).

## 9. Error Handling Map

| Symptom | Cause | App behavior |
|---|---|---|
| Scan finds nothing | Window not open / missing Bluetooth permission | LED guidance per §6 ②; check permissions |
| security1 handshake fails | Wrong PoP | "Please re-scan the QR code on the device" |
| Connect fails (device was found) | Another client is connected (1 max) | Retry after a few seconds |
| Endpoint returns `invalid_args` | Malformed request JSON | Validate client-side; report as a bug |
| No response mid-session | Window timed out (5 min after claim) | Reconnect (may need BOOT 3 s) |
| `hub-factory` returns `forbidden` | Hub already claimed | Expected — never call it |

## 10. Cloud Binding (what happens after the claim)

Writing the token is only the first half of the binding. The full loop:

1. The backend issues the token, tied to the logged-in user — one-time use,
   short expiry
2. The hub presents the token to the cloud over its own certificate-based
   connection (via `reported.claim` on the `hub` shadow — **this firmware
   step is not implemented yet; the final interface will be fixed during
   integration**)
3. The backend validates the token → creates the `thing(=sn) ↔ user account`
   binding → invalidates the token
4. **All the app needs to do**: after step ⑦, poll (or subscribe to) the
   backend's "binding status" API and enter the success screen once bound;
   suggest a 60 s timeout with a retry entry point

The backend's token-issuing and binding-status APIs are defined by the
cloud team and are out of scope for this document.

## 11. Integration and Self-Testing

- The reference implementation for every firmware-side flow is
  `tester/test_ble_prov.py` — **whatever passes there must pass from the
  app**; when behavior differs, run the script first to compare.
- Development boards may lack a factory-injected identity (`serial == ""`,
  PoP = `fibo1234`). Tolerating an empty serial (skipping the sn check) is
  acceptable **in development builds only**.
- The hub allows a single BLE connection: during debugging make sure tools
  like nRF Connect are not holding the connection.
