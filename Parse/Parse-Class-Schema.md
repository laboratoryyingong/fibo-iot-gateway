# Fibo IoT Gateway: Parse Class Schema (V1)

**Status:** Proposed for implementation  
**Last Updated:** 2026-04-05  
**Companion Model:** `Parse/AWS-IoT-App-Domain-Model.md`

## 1. Purpose

This document defines the concrete Parse classes, core fields, uniqueness rules, and query patterns for the app-domain layer.

These classes support:

- home membership and authorization
- gateway ownership and lookup
- room / space assignment
- device metadata bound to AWS IoT shadow identity
- scene authoring and execution metadata

## 2. Naming Conventions

Use these class names in Parse:

1. `Home`
2. `HomeMember`
3. `Gateway`
4. `Space`
5. `DeviceEndpoint`
6. `Scene`
7. `SceneAction`
8. `SceneExecution`

General rules:

1. Use camelCase for field names.
2. Keep stable business IDs in explicit string fields like `homeId`, `gatewayId`, `sceneId`.
3. Do not use Parse `objectId` as the cross-system business identity.
4. Reference device shadows by `thingName + shadowName`.
5. Never use `nwk` as the stable relation key.

## 3. Class Definitions

## 3.1 `Home`

Purpose:

- logical household / site boundary

Fields:

| Field | Type | Required | Example | Notes |
| --- | --- | --- | --- | --- |
| `homeId` | String | Yes | `home_001` | unique business ID |
| `name` | String | Yes | `Ying Home` | user-facing home label |
| `timezone` | String | Yes | `Australia/Adelaide` | used for schedules |
| `countryCode` | String | No | `AU` | locale support |
| `status` | String | Yes | `active` | enum: `active`, `archived` |
| `defaultGateway` | Pointer<Gateway> | No |  | preferred landing gateway |

Indexes:

- unique: `homeId`

Recommended ACL:

- row readable by active `HomeMember` users
- row writable by `installer` or `admin` members only

## 3.2 `HomeMember`

Purpose:

- normalized membership and role mapping

Fields:

| Field | Type | Required | Example | Notes |
| --- | --- | --- | --- | --- |
| `home` | Pointer<Home> | Yes |  | home scope |
| `user` | Pointer<_User> | Yes |  | member user |
| `role` | String | Yes | `admin` | enum: `installer`, `admin`, `member`, `viewer` |
| `status` | String | Yes | `active` | enum: `invited`, `active`, `suspended` |
| `invitedBy` | Pointer<_User> | No |  | audit |
| `acceptedAt` | Date | No |  | lifecycle |

Indexes:

- unique composite: `home + user`
- query: `user + status`

Recommended ACL:

- readable by the member user and installers/admins in the same home
- writable by `installer` or `admin`

## 3.3 `Gateway`

Purpose:

- app-domain record for one physical gateway

Fields:

| Field | Type | Required | Example | Notes |
| --- | --- | --- | --- | --- |
| `gatewayId` | String | Yes | `gw_001` | unique business ID |
| `thingName` | String | Yes | `gw_gw_001` | AWS IoT Thing name |
| `serialNumber` | String | Yes | `A1B2C3` | hardware label |
| `model` | String | Yes | `FIBO Gateway Pro` | product model |
| `home` | Pointer<Home> | Yes |  | ownership |
| `displayName` | String | Yes | `Living Room Gateway` | editable app label |
| `firmwareVersion` | String | No | `v2.4.1` | cache only |
| `statusSummary` | String | No | `online` | cache only |
| `lastSeenAt` | Date | No |  | cache only |
| `linkedAt` | Date | Yes |  | binding time |

Indexes:

- unique: `gatewayId`
- unique: `thingName`
- unique: `serialNumber`
- query: `home + updatedAt`

Recommended ACL:

- readable by active `HomeMember` users
- writable by `installer` or `admin`

## 3.4 `Space`

Purpose:

- user-defined room / area

Fields:

| Field | Type | Required | Example | Notes |
| --- | --- | --- | --- | --- |
| `spaceId` | String | Yes | `space_001` | unique business ID |
| `home` | Pointer<Home> | Yes |  | scope |
| `name` | String | Yes | `Living Room` | display label |
| `imageUrl` | String | No |  | optional cover |
| `sortOrder` | Number | Yes | `100` | ordering within home |
| `status` | String | Yes | `active` | enum: `active`, `archived` |

Indexes:

- unique: `spaceId`
- query: `home + status + sortOrder`

Recommended ACL:

- readable by active `HomeMember` users
- writable by `installer` or `admin`

## 3.5 `DeviceEndpoint`

Purpose:

- normalized device metadata record bound to one Zigbee endpoint shadow

Fields:

| Field | Type | Required | Example | Notes |
| --- | --- | --- | --- | --- |
| `endpointKey` | String | Yes | `gw_001:00158d0001bbbbbb:ep1` | unique stable key |
| `gateway` | Pointer<Gateway> | Yes |  | owning gateway |
| `home` | Pointer<Home> | Yes |  | denormalized query scope |
| `space` | Pointer<Space> | No |  | room assignment |
| `thingName` | String | Yes | `gw_gw_001` | direct shadow routing |
| `shadowName` | String | Yes | `dev_00158d0001bbbbbb_ep1` | unique execution target |
| `ieee` | String | Yes | `00158d0001bbbbbb` | stable device identity |
| `ep` | Number | Yes | `1` | endpoint number |
| `profile` | String | Yes | `dimmable_light` | profile contract |
| `model` | String | No | `TS0601_dimmer` | vendor model |
| `manufacturer` | String | No | `_TZ3000_xxx` | optional |
| `displayName` | String | Yes | `Bedroom Bulb` | editable label |
| `iconKey` | String | No | `bulb` | app icon mapping |
| `sortOrder` | Number | Yes | `120` | ordering in space |
| `status` | String | Yes | `active` | enum: `active`, `deleted`, `hidden` |
| `lastKnownOnline` | Boolean | No | `true` | cache only |
| `lastSeenAt` | Date | No |  | cache only |
| `lastKnownState` | Object | No | `{"power":1,"level":128}` | compact cache only |

Indexes:

- unique: `endpointKey`
- unique: `shadowName`
- query: `home + status + updatedAt`
- query: `home + space + sortOrder`
- query: `gateway + ieee`

Recommended ACL:

- readable by active `HomeMember` users
- writable by `installer` or `admin`
- system write path may be used by backend inventory sync jobs

Validation rules:

1. `shadowName` must remain stable when `nwk` changes.
2. `space` may be null for unassigned devices.
3. `lastKnownState` must remain compact and omit full shadow metadata.

## 3.6 `Scene`

Purpose:

- top-level scene preset metadata

Fields:

| Field | Type | Required | Example | Notes |
| --- | --- | --- | --- | --- |
| `sceneId` | String | Yes | `scene_001` | unique business ID |
| `home` | Pointer<Home> | Yes |  | scope |
| `name` | String | Yes | `Movie Time` | display label |
| `icon` | String | No | `🎬` | emoji or icon token |
| `enabled` | Boolean | Yes | `true` | enabled state |
| `executionMode` | String | Yes | `manual_only` | enum: `manual_only`, `manual_and_automation` |
| `createdBy` | Pointer<_User> | Yes |  | audit |
| `updatedBy` | Pointer<_User> | No |  | audit |
| `lastExecutedAt` | Date | No |  | summary |
| `status` | String | Yes | `active` | enum: `active`, `archived` |

Indexes:

- unique: `sceneId`
- query: `home + status + updatedAt`

Recommended ACL:

- readable by active `HomeMember` users
- writable by `installer` or `admin`

## 3.7 `SceneAction`

Purpose:

- normalized deterministic writes under one scene

Fields:

| Field | Type | Required | Example | Notes |
| --- | --- | --- | --- | --- |
| `scene` | Pointer<Scene> | Yes |  | parent scene |
| `home` | Pointer<Home> | Yes |  | denormalized scope |
| `order` | Number | Yes | `10` | action ordering |
| `targetDevice` | Pointer<DeviceEndpoint> | Yes |  | stable relation |
| `targetShadowName` | String | Yes | `dev_00158d0001bbbbbb_ep1` | direct target |
| `actionType` | String | Yes | `desired_state` | enum: `desired_state`, `desired_command` |
| `payload` | Object | Yes | see below | normalized target write |
| `status` | String | Yes | `active` | enum: `active`, `disabled` |

Payload examples:

```json
{
  "state": {
    "power": 1,
    "level": 180
  }
}
```

```json
{
  "command": {
    "op": "stop"
  }
}
```

Indexes:

- query: `scene + order`
- query: `home + targetShadowName`

Recommended ACL:

- readable by active `HomeMember` users
- writable by `installer` or `admin`

Validation rules:

1. `toggle` is not allowed.
2. `payload` must be deterministic and replay-safe where possible.
3. `targetShadowName` must match `targetDevice.shadowName`.

## 3.8 `SceneExecution`

Purpose:

- lightweight execution log for app UI and support tooling

Fields:

| Field | Type | Required | Example | Notes |
| --- | --- | --- | --- | --- |
| `executionId` | String | Yes | `sx_001` | unique business ID |
| `scene` | Pointer<Scene> | Yes |  | source scene |
| `home` | Pointer<Home> | Yes |  | scope |
| `actor` | Pointer<_User> | No |  | null for system execution |
| `mode` | String | Yes | `manual` | enum: `manual`, `automation`, `backend_retry` |
| `status` | String | Yes | `started` | enum: `started`, `partial`, `succeeded`, `failed` |
| `resultSummary` | Object | No | `{"successCount":2,"failureCount":0}` | compact summary |
| `startedAt` | Date | Yes |  | start timestamp |
| `completedAt` | Date | No |  | completion timestamp |

Indexes:

- unique: `executionId`
- query: `scene + startedAt`
- query: `home + startedAt`

Recommended ACL:

- readable by active `HomeMember` users
- writable by backend execution path only

## 4. Parse Relations Summary

```text
Home
├── HomeMember -> _User
├── Gateway
├── Space
├── DeviceEndpoint
└── Scene
    ├── SceneAction -> DeviceEndpoint
    └── SceneExecution
```

## 5. Minimal Seed Order

Create classes in this order:

1. `Home`
2. `HomeMember`
3. `Gateway`
4. `Space`
5. `DeviceEndpoint`
6. `Scene`
7. `SceneAction`
8. `SceneExecution`

## 6. V1 Non-Goals

Do not add these Parse classes in the first release:

- shadow mirror classes
- per-device telemetry history classes
- schedule-specific classes before backend automation is ready
- gateway command queue classes that duplicate IoT desired state
