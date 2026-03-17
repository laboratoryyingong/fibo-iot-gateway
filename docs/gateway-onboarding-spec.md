# Gateway Onboarding Spec

## 1. Purpose

This document defines the product flow for pairing, claiming, and managing the Zigbee gateway itself inside the app.

This document does not define Zigbee sub-device pairing or device control details. Those belong to the device pairing and control specs.

## 2. Scope

Included:

- gateway onboarding entry
- gateway discovery or claim
- gateway binding to account
- gateway list and current gateway selection
- gateway detail and settings
- gateway lifecycle states and error handling

Excluded:

- Zigbee permit-join flow for sub-devices
- sub-device discovery and metadata enrichment
- per-device control UI
- scene execution

## 3. Product Boundary

The app has two separate layers:

### Layer A. Gateway onboarding and management

User outcome:

- the user adds a gateway into the account
- the user can see whether the gateway is online
- the user can manage gateway-level settings and lifecycle actions

### Layer B. Zigbee sub-device pairing and control

User outcome:

- the user pairs Zigbee end devices to a selected gateway
- the user controls those paired devices

Rule:

- Layer A must complete before Layer B can be used
- all device pairing and control must be scoped to one selected `gatewayId`

## 4. Primary Goals

The first gateway onboarding milestone should let a user:

1. open the app with no gateway and see a clear onboarding path
2. discover or claim a gateway
3. bind the gateway to the current account
4. enter the main app after gateway setup succeeds
5. view the current gateway status later
6. manage the gateway from the app

## 5. Non-Goals For This Phase

- full cloud production architecture lock
- final AWS IoT topic or shadow design
- final UART-to-app bridge implementation details
- multi-home / multi-tenant edge cases beyond basic account ownership
- Zigbee child-device UX

## 6. Assumptions and Constraints

Based on the current repository state:

- the hardware README describes a UART host protocol, not a phone-facing transport
- the current Flutter app is already structured around post-gateway flows
- current pairing screens represent sub-device pairing more than gateway onboarding
- current `Network` and `Settings` screens are candidates for gateway management reuse

Important constraint:

- the app cannot directly pair with the physical gateway unless there is a host bridge, LAN API, BLE path, or cloud path

This spec stays transport-agnostic at product level, but the implementation must later choose one of:

- local bridge path
- cloud path
- direct local phone-to-gateway path

## 7. User Roles

### Installer

Expected permissions:

- add / claim gateway
- rename gateway
- restart gateway
- trigger firmware update
- remove or unbind gateway
- enable device pairing mode

### Admin / Home Owner

Expected permissions:

- view owned gateways
- rename gateway
- view status and network health
- restart gateway
- possibly trigger firmware update
- remove or unbind gateway

### Member / Standard User

Expected permissions:

- view assigned gateway
- see gateway online or offline state
- switch between permitted gateways if multi-gateway is enabled
- no gateway removal
- no installer-only configuration

Open item:

- final role matrix must be aligned with Parse role model and future cloud authorization

## 8. Entry Rules

### Rule 1. No gateway on account

If the account has no claimed gateway:

- app should not drop the user into the normal device-centric home flow
- app should route into gateway onboarding first

Recommended route:

- `/gateway/onboarding`

### Rule 2. At least one gateway exists

If the account already has a usable gateway:

- app can enter the existing home shell
- app must load a selected `gatewayId` before device pages become active

### Rule 3. Gateway required features

If no `gatewayId` is selected:

- device pairing flow must be blocked
- device control pages must not show live controls

## 9. Gateway First-Time Claiming

This part is still product-TBD and must be locked before implementation.

Supported claim methods may include:

- QR code
- serial number entry
- LAN discovery
- BLE discovery
- installer pre-binding

The product flow should support the same conceptual stages regardless of transport:

1. user starts onboarding
2. app searches for or identifies a gateway
3. user confirms the gateway identity
4. app verifies gateway claimability
5. gateway is bound to the account
6. app confirms success and stores selected gateway

### Required validation checks

- gateway exists
- gateway is reachable or known
- gateway is not already bound to another account, or user is explicitly authorized
- gateway firmware is compatible enough for onboarding
- gateway identity is unique and stable

## 10. Gateway Lifecycle States

The app should model the gateway with explicit states.

### `unclaimed`

Meaning:

- gateway exists physically but is not yet bound to this account

UI behavior:

- show claim CTA
- block device features

### `claiming`

Meaning:

- claim or bind process is in progress

UI behavior:

- show blocking progress state
- prevent duplicate actions

### `online`

Meaning:

- gateway is healthy and reachable

UI behavior:

- allow device pairing and management actions

### `offline`

Meaning:

- gateway is known to the account but not reachable now

UI behavior:

- allow view-only data
- block or warn on actions that require live connectivity

### `updating`

Meaning:

- gateway firmware update is active

UI behavior:

- show status and progress if available
- block risky management actions

### `error`

Meaning:

- gateway is in a faulted or incompatible state

UI behavior:

- show actionable error message
- provide retry or support path

### `removed`

Meaning:

- gateway was unbound or deleted from this account

UI behavior:

- clear current selection if needed
- return user to onboarding or gateway list

## 11. Multi-Gateway Model

The product should explicitly support one of these models:

### Model A. Single gateway only

Simpler first release:

- one account owns one gateway
- no gateway switching UI

### Model B. Multiple gateways per account

Preferred long-term model:

- one account may own multiple gateways
- one gateway is the current active context in app
- device pages always resolve against that selected gateway

Recommended product rule:

- support data model for multi-gateway from the start
- first implementation may expose a simplified UI if only one gateway is active

### Selection rules

If multiple gateways exist:

- remember last selected gateway
- allow switching from a gateway list or account menu
- if selected gateway goes offline, keep selection but show offline state

## 12. Proposed Page Architecture

Recommended page group:

- `gateway_onboarding_intro_screen.dart`
- `gateway_discovery_screen.dart`
- `gateway_claim_screen.dart`
- `gateway_pairing_success_screen.dart`
- `gateway_list_screen.dart`
- `gateway_detail_screen.dart`
- `gateway_settings_screen.dart`

Recommended route group:

- `/gateway/onboarding`
- `/gateway/discovery`
- `/gateway/claim`
- `/gateway/success`
- `/gateway/list`
- `/gateway/detail`
- `/gateway/settings`

## 13. Page Responsibilities

### `gateway_onboarding_intro_screen`

Purpose:

- explain why a gateway is required
- provide first CTA to add gateway

Primary actions:

- start discovery
- enter claim code
- learn more / help

### `gateway_discovery_screen`

Purpose:

- search for claimable gateways or display candidate gateways

Primary states:

- searching
- found
- none found
- permission or transport unavailable

### `gateway_claim_screen`

Purpose:

- confirm gateway identity and bind it to account

Primary data:

- gateway name or model
- serial or short ID
- firmware version if known
- ownership warning if already claimed

### `gateway_pairing_success_screen`

Purpose:

- confirm onboarding success
- continue into main app

Primary actions:

- go to home
- go to gateway detail

### `gateway_list_screen`

Purpose:

- show all gateways available to the account
- select current gateway

### `gateway_detail_screen`

Purpose:

- show current health, firmware, last seen, connectivity, and high-level actions

### `gateway_settings_screen`

Purpose:

- show configurable gateway management actions and danger-zone actions

## 14. Navigation Rules

Recommended information architecture:

1. no gateway:
   - user lands on gateway onboarding
2. gateway claimed:
   - user enters existing home shell
3. gateway management:
   - user opens gateway detail and settings from menu, network, or settings
4. device pairing:
   - user starts only after a gateway is selected

Recommended reuse of existing app areas:

- `Network` tab evolves toward gateway health and topology
- `Settings` tab evolves toward selected gateway settings
- app menu gateway label reflects the selected real gateway
- existing `/pairing/*` flow should be reframed as sub-device pairing

## 15. Gateway Data Model

Minimum app-level `Gateway` fields:

- `gatewayId`
- `name`
- `serialNumber`
- `model`
- `firmwareVersion`
- `connectionState`
- `lastSeenAt`
- `ownerAccountId`
- `claimedAt`
- `isCurrent`
- `supportsDevicePairing`
- `supportsOta`
- `supportsRestart`

Optional future fields:

- `macAddress`
- `ipAddress`
- `transportType`
- `hardwareRevision`
- `otaState`
- `signalOrHealthSummary`

## 16. Shared App State Needed

The app will need a selected gateway context.

Recommended state objects:

- `Gateway`
- `GatewayConnectionState`
- `GatewayClaimState`
- `SelectedGatewayContext`

Minimum responsibilities:

- know whether the account has any gateways
- know which gateway is selected
- expose online or offline state
- gate device pairing and control flows

## 17. Gateway Management Actions

The product should support these gateway-level actions:

- rename gateway
- view status
- view firmware version
- view last seen
- restart gateway
- trigger firmware update
- remove or unbind gateway
- set as current gateway

Each action must later define:

- who is authorized
- whether the gateway must be online
- whether the action is reversible

## 18. Empty and Error States

The onboarding and management flow must cover:

- no gateway on account
- discovery unavailable
- no gateway found
- claim timeout
- gateway already bound to another account
- permission denied
- gateway offline
- firmware incompatible
- update in progress
- transport temporarily unavailable

For each state, the UX should define:

- title
- explanation
- retry path
- fallback path

## 19. Dependencies on Future Interface Contracts

This spec does not fix the implementation transport, but the app will eventually require these abilities:

- discover or identify claimable gateway
- claim gateway to account
- fetch gateway list
- fetch gateway detail
- select current gateway
- observe gateway online or offline state
- execute management actions such as restart or OTA

These abilities may later be provided by:

- local bridge service
- Parse backend
- AWS IoT path
- direct local gateway transport

## 20. Acceptance Criteria

The spec is satisfied when the future product behavior can support all of the following:

1. a user with no gateway sees a dedicated gateway onboarding path
2. a user can complete gateway claim and reach the main app
3. the app can display the current gateway name and status
4. the user can enter gateway detail and settings views
5. the app prevents sub-device pairing when no gateway is selected
6. the app can represent gateway offline and error states clearly

## 21. Open Questions

These must be resolved before implementation starts:

1. What is the first supported claim method: QR code, serial number, LAN discovery, BLE, or installer binding?
2. Does one account support multiple gateways in the first release?
3. Is the first implementation path local bridge or cloud path?
4. Should the existing `Network` and `Settings` screens evolve directly into gateway management pages?
5. Which gateway actions are installer-only versus owner-allowed?
6. Is gateway OTA in scope for the first onboarding and management release?
