# Gateway App Integration TODO

## 1. Current State

### Hardware

Based on [hardware-readme.md](/Users/yingong/Desktop/fibo-iot-gateway/docs/hardware-readme.md), the Zigbee gateway firmware currently provides:

- Zigbee Coordinator capability
- persistent device database
- permit-join / remove / discovery / on-off / lock / curtain / level / OTA commands
- a UART host protocol as the external control interface

Important constraint:

- The firmware currently exposes a `UART` protocol to a host.
- The Flutter app does not currently have a direct transport to that UART interface.
- So the app cannot directly discover, pair, or control the physical gateway yet.

### App

Based on the current Flutter code:

- pairing flow pages exist, but they currently behave more like sub-device pairing demos
- device list and detail pages are also static
- `spaces` device control is driven by `SpaceMockStore`
- no gateway communication service exists yet

Relevant files:

- [main.dart](/Users/yingong/Desktop/fibo-iot-gateway/fibo_gateway_app/lib/main.dart)
- [pairing_start_screen.dart](/Users/yingong/Desktop/fibo-iot-gateway/fibo_gateway_app/lib/screens/pairing_start_screen.dart)
- [pairing_searching_screen.dart](/Users/yingong/Desktop/fibo-iot-gateway/fibo_gateway_app/lib/screens/pairing_searching_screen.dart)
- [pairing_device_found_screen.dart](/Users/yingong/Desktop/fibo-iot-gateway/fibo_gateway_app/lib/screens/pairing_device_found_screen.dart)
- [devices_list_screen.dart](/Users/yingong/Desktop/fibo-iot-gateway/fibo_gateway_app/lib/screens/devices_list_screen.dart)
- [devices_detail_screen.dart](/Users/yingong/Desktop/fibo-iot-gateway/fibo_gateway_app/lib/screens/devices_detail_screen.dart)
- [space_models.dart](/Users/yingong/Desktop/fibo-iot-gateway/fibo_gateway_app/lib/screens/space_models.dart)

### Existing Production Direction

The repo already contains a production-oriented cloud direction in:

- [AWS-IoT-Architecture-Spec.md](/Users/yingong/Desktop/fibo-iot-gateway/Parse/AWS-IoT-Architecture-Spec.md)
- [AWS-IoT-Implementation-Checklist.md](/Users/yingong/Desktop/fibo-iot-gateway/Parse/AWS-IoT-Implementation-Checklist.md)

That direction is:

- App -> Parse -> AWS IoT -> Gateway

This is currently not aligned with the hardware README yet, because the hardware README still describes a UART-facing gateway instead of an MQTT/AWS-IoT-facing gateway.

## 2. Integration Decision We Must Lock First

Before implementation, decide which control path we want:

### Option A. Temporary local bridge

Use a local host bridge process:

- gateway <-> UART <-> bridge service <-> HTTP/WebSocket/MQTT <-> app

Use this if:

- we want the fastest demo/integration path
- the gateway is currently connected to another MCU, Linux board, or local daemon

### Option B. Production path

Extend the gateway or its host side into the existing cloud architecture:

- gateway UART protocol is consumed by a host agent
- host agent connects to AWS IoT
- app talks through Parse + AWS IoT

Use this if:

- we want account binding, remote control, history, OTA, and multi-gateway support

### Option C. Direct app-to-gateway local communication

Only use this if the hardware also supports a phone-friendly transport such as:

- BLE
- SoftAP + HTTP
- local Wi-Fi LAN API

This is not described in `hardware-readme.md`, so it should not be assumed.

## 2.1 Product Boundary Clarification

The app needs two distinct flows:

### Flow A. Pair and manage the gateway itself

This is the missing layer right now.

User goal:

- add a gateway to the account
- see gateway status
- rename/manage/restart/update/remove the gateway

### Flow B. Pair and control Zigbee sub-devices behind that gateway

This is what the current app screens are trying to represent.

User goal:

- open permit-join on a selected gateway
- pair Zigbee end devices to that gateway
- control the paired sub-devices

Important rule:

- gateway onboarding must happen before sub-device pairing
- device control pages should always be scoped to one selected gateway

## 2.2 Proposed Page Architecture

Recommended new page group:

- [ ] `gateway_onboarding_intro_screen.dart`
- [ ] `gateway_discovery_screen.dart`
- [ ] `gateway_claim_screen.dart`
- [ ] `gateway_pairing_success_screen.dart`
- [ ] `gateway_list_screen.dart`
- [ ] `gateway_detail_screen.dart`
- [ ] `gateway_settings_screen.dart`

Recommended route group:

- [ ] `/gateway/onboarding`
- [ ] `/gateway/discovery`
- [ ] `/gateway/claim`
- [ ] `/gateway/success`
- [ ] `/gateway/list`
- [ ] `/gateway/detail`
- [ ] `/gateway/settings`

Recommended information architecture:

1. No gateway yet:
   - app lands on gateway onboarding / empty state
2. Gateway paired:
   - app lands on existing home shell
3. Add Zigbee device:
   - user starts from selected gateway context
4. Manage gateway:
   - user enters gateway detail/settings pages

Recommended reuse of existing screens:

- `Network` tab can evolve into gateway network health and topology
- `Settings` tab can evolve into selected gateway settings
- app menu gateway label should reflect the selected real gateway
- existing `/pairing/*` flow should be reframed as `device pairing`, not `gateway pairing`

## 3. TODO List

## 3.1 Phase 0: Lock the integration architecture

- [ ] Decide whether the first milestone is `local demo bridge` or `production AWS IoT path`
- [ ] Define gateway identity fields: `gatewayId`, `accountId`, `deviceId`
- [ ] Define where gateway-to-app authority lives: local only, Parse, or AWS IoT
- [ ] Define the canonical device model shared by firmware, backend, and app
- [ ] Map current UART commands to product capabilities

Suggested UART mapping baseline:

- `0x01` -> list devices
- `0x02` -> bind/start discovery for joined device
- `0x04` -> permit-join open/close
- `0x05` -> remove device
- `0x03` -> on/off devices
- `0x20` -> curtain control
- `0x21` -> lock/unlock
- `0x22` -> level/brightness
- `0x10-0x13` -> gateway OTA

## 3.2 Phase 1: Make the app able to find the gateway

Goal:

- The user can add a gateway, claim it, and see which gateway is selected and online.

Tasks:

- [ ] Define when the app should block on gateway onboarding
- [ ] Define gateway onboarding flow
- [ ] Define how a phone discovers or claims a gateway the first time
- [ ] Add gateway status model to app and backend
- [ ] Add gateway list / current gateway selection in app
- [ ] Show gateway online/offline, firmware version, last seen, and pairing availability
- [ ] Add gateway empty state when the account has no gateways
- [ ] Add selected gateway context shared across app tabs

If using local bridge:

- [ ] Build a small bridge service that wraps the UART protocol
- [ ] Expose `GET /gateway`, `GET /devices`, `POST /permit-join`, `POST /control`
- [ ] Return stable JSON instead of raw UART frames to the app

If using production cloud path:

- [ ] Implement gateway registration and binding to account
- [ ] Implement Parse function to return allowed gateways
- [ ] Implement AWS IoT connection for gateway-side host agent
- [ ] Sync gateway online/offline state to cloud

UI tasks:

- [ ] Replace hardcoded gateway name in app shell/menu with real gateway data
- [ ] Add gateway onboarding entry screens before `/home` when no gateway exists
- [ ] Add gateway detail page and gateway settings page
- [ ] Add empty/error states: no gateway, gateway offline, permission denied

## 3.3 Phase 2: Discuss and implement Zigbee device pairing

Goal:

- The user can open pairing mode on the selected gateway and add a Zigbee sub-device from the app.

Tasks:

- [ ] Rename the current concept of pairing in the app to `device pairing`
- [ ] Ensure pairing screens always know the active `gatewayId`
- [ ] Define the pairing sequence contract
- [ ] App opens permit-join window via command `0x04`
- [ ] App shows countdown and current pairing state
- [ ] Gateway reports newly joined devices
- [ ] App requests discovery/bind via `0x02`
- [ ] App fetches refreshed device list via `0x01`
- [ ] App lets user rename device and assign room
- [ ] App persists the device assignment and metadata

Recommended pairing sequence:

1. User selects gateway.
2. App sends `permit-join` for 60 seconds.
3. User puts sub-device into pairing mode.
4. Gateway receives join and stores the device in DB.
5. App/bridge triggers discovery `0x02` for the new NWK address.
6. Gateway resolves endpoints/clusters and enriches device info.
7. App displays the found device with model/manufacturer/type guess.
8. User confirms name + room.
9. App stores metadata and device becomes controllable.

Needed model work:

- [ ] Add canonical sub-device fields: `nwk`, `ieee`, `endpoints`, `clusters`, `online`, `lastSeen`
- [ ] Add app-level fields: `name`, `roomId`, `icon`, `capabilities`, `gatewayId`
- [ ] Add capability inference from discovered clusters

Important gap:

- Current `0x01` device list described in the README returns only `NWK + online flag`.
- For a good UI we will likely also need:
  - IEEE address
  - endpoint list
  - input/output clusters
  - manufacturer/model
  - inferred device type/capabilities

That means one of these is needed:

- extend the UART protocol response, or
- let the bridge combine `0x01` with discovery cache/state into richer JSON

## 3.4 Phase 3: Control the gateway-managed devices

Goal:

- The app can send actions to a specific Zigbee sub-device and render final state.

Tasks:

- [ ] Create a gateway command service in Flutter
- [ ] Replace mock device lists with real gateway-backed device data
- [ ] Replace static detail pages with capability-driven controls
- [ ] Handle optimistic UI, ACK, failure, and refresh
- [ ] Refresh device state after command execution

Command coverage:

- [ ] On/off via `0x03`
- [ ] Brightness/level via `0x22`
- [ ] Curtain actions via `0x20`
- [ ] Lock/unlock via `0x21`
- [ ] Remove device via `0x05`

State/rendering work:

- [ ] Define per-device capability renderer
- [ ] Map clusters/capabilities to widgets
- [ ] Show online/offline and stale state
- [ ] Show unsupported-but-discovered devices in a safe generic card

Recommended control model in app:

- `GatewayRepository`
- `GatewayTransport`
- `GatewayDevice`
- `GatewayCommand`
- `GatewayCommandResult`

## 3.5 Phase 4: Reliability and operations

- [ ] Add retries/timeouts for gateway commands
- [ ] Add command correlation IDs end-to-end
- [ ] Add event logging for pairing/control/remove
- [ ] Add gateway OTA screen if OTA is in scope now
- [ ] Add device health/offline aging UI
- [ ] Add integration tests against the Python protocol test harness

## 4. Recommended First Iteration

To reduce risk, do this first:

1. Do not start with full Parse + AWS IoT integration.
2. First build a thin bridge around the existing UART protocol.
3. First milestone should be:
   - app can list gateways
   - app can open permit-join
   - app can see newly discovered devices
   - app can send on/off to one supported device type

This gives us:

- a real hardware-in-the-loop integration path
- validation that the UART contract is enough
- a clean base for later migration to AWS IoT

## 5. Immediate Next Work Items

- [ ] Define the gateway onboarding screens and route structure
- [ ] Confirm the gateway-side transport available to the phone or cloud host
- [ ] Decide whether we are building a local bridge first
- [ ] Define the JSON contract between app and bridge
- [ ] Add an app state rule: no selected gateway -> show gateway onboarding instead of home shell
- [ ] Implement a fake bridge or stub service so Flutter can stop using mock data
- [ ] Replace pairing auto-advance screens with real async states
- [ ] Replace device detail static controls with one real command path: on/off

## 6. Open Questions

- Does this gateway have any non-UART uplink already, such as Wi-Fi, Ethernet, BLE, or another host MCU?
- Is the mobile app expected to control the gateway locally on the same LAN, or remotely through cloud?
- How should a user claim a gateway the first time: QR code, serial number, LAN discovery, BLE, or installer binding?
- Which device type should be the first real end-to-end control target: light, curtain, or lock?
