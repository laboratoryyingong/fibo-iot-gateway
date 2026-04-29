# Fibo IoT Gateway: Parse App Domain Model (V1)

**Status:** Proposed for implementation  
**Last Updated:** 2026-04-05  
**Scope:** Back4App / Parse classes for spaces, scenes, device metadata, and app-domain authorization

## 1. Objective

Define which entities belong in Parse for the app business domain, and keep them cleanly separated from AWS IoT Shadow.

This document supplements the AWS IoT architecture documents and partially narrows the older assumption that Parse is only a thin auth layer.

For V1:

- AWS IoT Shadow remains the source of truth for real-time device state and command execution.
- Parse stores the app-domain model: homes, members, gateways, spaces, device metadata, and scenes.
- App-local state is only for transient UI and optimistic interaction.

## 2. Responsibility Split

| Domain | Source of truth | Examples |
| --- | --- | --- |
| Real-time device state | AWS IoT Shadow | `power`, `level`, `locked`, `online`, `last_command` |
| Gateway operational state | AWS IoT Shadow | gateway online, permit-join open, OTA status |
| App business model | Parse | home, space, scene, display name, room assignment, sort order |
| Audit / history | DynamoDB | command history, alert events, OTA history |
| UI draft state | App local only | form edits, slider drag position before submit, temporary filters |

Rules:

1. Do not persist `nwk` as a stable app-side identifier.
2. Do not mirror full shadow documents into Parse.
3. Do not store spaces or scenes in Shadow.
4. Do not depend on a mobile client to execute scheduled automation.

## 3. Parse Data Model

## 3.1 `_User`

Use Parse `_User` for authentication.

Recommended additional fields:

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `displayName` | String | No | app-facing name |
| `avatarUrl` | String | No | profile image |
| `defaultHome` | Pointer<Home> | No | landing context after login |
| `userType` | String | Yes | `installer`, `user`, `admin` |

Do not store gateway lists as the long-term normalized model inside `_User` JSON fields.

## 3.2 `Home`

Represents a logical household / site.

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `homeId` | String | Yes | stable business ID, unique |
| `name` | String | Yes | user-facing name |
| `timezone` | String | Yes | for schedules and automation |
| `countryCode` | String | No | optional locale support |
| `status` | String | Yes | `active`, `archived` |
| `defaultGateway` | Pointer<Gateway> | No | preferred gateway for app landing |

Indexes:

- unique: `homeId`

## 3.3 `HomeMember`

Maps users to homes with explicit role and lifecycle.

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `home` | Pointer<Home> | Yes | owner scope |
| `user` | Pointer<_User> | Yes | member |
| `role` | String | Yes | `installer`, `admin`, `member`, `viewer` |
| `status` | String | Yes | `invited`, `active`, `suspended` |
| `invitedBy` | Pointer<_User> | No | audit |
| `acceptedAt` | Date | No | membership acceptance |

Indexes:

- unique composite: `home + user`

## 3.4 `Gateway`

Represents one physical gateway board and its cloud identity.

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `gatewayId` | String | Yes | stable business ID, unique |
| `thingName` | String | Yes | AWS IoT Thing name |
| `serialNumber` | String | Yes | hardware label |
| `model` | String | Yes | gateway model |
| `home` | Pointer<Home> | Yes | gateway belongs to one home in V1 |
| `displayName` | String | Yes | editable app label |
| `firmwareVersion` | String | No | last known version |
| `statusSummary` | String | No | cached `online`, `offline`, `updating` |
| `lastSeenAt` | Date | No | cached summary only |
| `linkedAt` | Date | Yes | account binding time |

Indexes:

- unique: `gatewayId`
- unique: `thingName`
- unique: `serialNumber`

Note:

- Real-time gateway state still comes from the `hub` shadow.
- Parse stores only a cached summary for app list screens and authorization joins.

## 3.5 `Space`

Represents a room / area defined by the app.

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `spaceId` | String | Yes | stable business ID, unique |
| `home` | Pointer<Home> | Yes | owner scope |
| `name` | String | Yes | user-facing room name |
| `imageUrl` | String | No | optional cover image |
| `sortOrder` | Number | Yes | app ordering |
| `status` | String | Yes | `active`, `archived` |

Indexes:

- unique: `spaceId`
- query: `home + sortOrder`

## 3.6 `DeviceEndpoint`

Represents one controllable or observable Zigbee endpoint as an app-domain record.

This is the key join point between Parse metadata and Shadow execution.

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `endpointKey` | String | Yes | stable key: `{gatewayId}:{ieee}:ep{ep}` |
| `gateway` | Pointer<Gateway> | Yes | owning gateway |
| `home` | Pointer<Home> | Yes | denormalized for queries |
| `space` | Pointer<Space> | No | current room assignment |
| `thingName` | String | Yes | AWS Thing name |
| `shadowName` | String | Yes | endpoint shadow name |
| `ieee` | String | Yes | stable device identity |
| `ep` | Number | Yes | endpoint number |
| `profile` | String | Yes | e.g. `onoff_actuator`, `dimmable_light` |
| `model` | String | No | vendor model |
| `manufacturer` | String | No | optional app metadata |
| `displayName` | String | Yes | editable app label |
| `iconKey` | String | No | app icon selection |
| `sortOrder` | Number | Yes | list ordering within space |
| `status` | String | Yes | `active`, `deleted`, `hidden` |
| `lastKnownOnline` | Boolean | No | cache only |
| `lastSeenAt` | Date | No | cache only |
| `lastKnownState` | Object | No | small cache only, not full shadow mirror |

Indexes:

- unique: `endpointKey`
- unique: `shadowName`
- query: `home + space + sortOrder`
- query: `gateway + ieee`

Rules:

1. `endpointKey` and `shadowName` must be stable across NWK changes.
2. `space` is app metadata only.
3. `lastKnownState` is optional cache for faster first paint, not the authority.
4. Scene definitions must reference `DeviceEndpoint`, never `nwk`.

## 3.7 `Scene`

Represents a user-defined scene or preset.

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `sceneId` | String | Yes | stable business ID, unique |
| `home` | Pointer<Home> | Yes | owner scope |
| `name` | String | Yes | user-facing name |
| `icon` | String | No | emoji or icon token |
| `enabled` | Boolean | Yes | app enable switch |
| `executionMode` | String | Yes | `manual_only`, `manual_and_automation` |
| `createdBy` | Pointer<_User> | Yes | audit |
| `updatedBy` | Pointer<_User> | No | audit |
| `lastExecutedAt` | Date | No | summary |
| `status` | String | Yes | `active`, `archived` |

Indexes:

- unique: `sceneId`
- query: `home + status + updatedAt`

## 3.8 `SceneAction`

Represents one deterministic target write inside a scene.

Keep actions normalized in their own class instead of embedding large arrays inside `Scene`.

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `scene` | Pointer<Scene> | Yes | owning scene |
| `home` | Pointer<Home> | Yes | denormalized query scope |
| `order` | Number | Yes | action order |
| `targetDevice` | Pointer<DeviceEndpoint> | Yes | stable reference |
| `targetShadowName` | String | Yes | direct execution target |
| `actionType` | String | Yes | `desired_state` or `desired_command` |
| `payload` | Object | Yes | normalized shadow write payload |
| `status` | String | Yes | `active`, `disabled` |

`payload` examples:

Desired state set:

```json
{
  "state": {
    "power": 1,
    "level": 180
  }
}
```

One-shot command:

```json
{
  "command": {
    "op": "stop"
  }
}
```

Rules:

1. Use target-state semantics wherever possible.
2. Do not store imperative macros such as "toggle".
3. `payload` must match the referenced device profile.
4. Prefer `desired_state` for replay-safe operations.

## 3.9 `AutomationRule` (Future)

Do not implement in the first delivery unless scheduled execution is required immediately.

Planned fields:

- `ruleId`
- `home`
- `scene`
- `triggerType`
- `triggerSpec`
- `enabled`
- `lastTriggeredAt`

V1 may keep scenes manual-only and defer automations until the backend executor is ready.

## 3.10 `SceneExecution` (Optional but Recommended)

If execution history is needed in Parse before a richer audit UI is built on DynamoDB, keep a lightweight log.

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `executionId` | String | Yes | stable business ID |
| `scene` | Pointer<Scene> | Yes | source scene |
| `home` | Pointer<Home> | Yes | owner scope |
| `actor` | Pointer<_User> | No | null for system automation |
| `mode` | String | Yes | `manual`, `automation`, `backend_retry` |
| `status` | String | Yes | `started`, `partial`, `succeeded`, `failed` |
| `resultSummary` | Object | No | counts and top-level errors |
| `startedAt` | Date | Yes | start timestamp |
| `completedAt` | Date | No | finish timestamp |

## 4. Source-of-Truth Rules

## 4.1 Device State

Authoritative source:

- AWS IoT Shadow

Parse may cache only:

- `lastKnownOnline`
- `lastSeenAt`
- compact `lastKnownState`

Do not treat Parse cached state as authoritative for control.

## 4.2 Space Assignment

Authoritative source:

- Parse `DeviceEndpoint.space`

The gateway and shadow do not need to know room assignment.

## 4.3 Scene Definition

Authoritative source:

- Parse `Scene` + `SceneAction`

The gateway should execute desired writes, but should not be the owner of scene authoring data in V1.

## 5. Execution Flows

## 5.1 Manual Device Control

1. App resolves `DeviceEndpoint` from Parse metadata.
2. App uses `thingName + shadowName` to write AWS IoT Shadow directly.
3. App updates UI from final Shadow `reported` state.
4. Parse is not required in the hot path beyond metadata lookup.

## 5.2 Space Management

1. App creates or edits `Space` in Parse.
2. App updates `DeviceEndpoint.space`.
3. Device control path remains unchanged because shadow identity is independent of room assignment.

## 5.3 Manual Scene Execution

1. App reads `Scene` + `SceneAction` from Parse.
2. App resolves each `targetShadowName`.
3. App writes deterministic shadow updates for each action.
4. App observes convergence from Shadow `reported`.

Manual scene execution may be app-driven in V1.

## 5.4 Scheduled or Automated Scene Execution

1. Trigger definition lives in Parse.
2. Parse Cloud Code or a backend worker resolves the scene.
3. Backend executes the same deterministic writes to AWS IoT Shadow.
4. Mobile clients are not required to be online.

This is the recommended path for any automation that must run reliably.

## 5.5 Device Inventory Sync

Recommended V1 behavior:

1. Gateway remains the authoritative source for endpoint existence.
2. A backend sync job or installer flow creates or updates `DeviceEndpoint` records after inventory refresh.
3. If a device is removed from Zigbee, mark `DeviceEndpoint.status = deleted` or archive it.
4. If `nwk` changes after rejoin, update only cached metadata if needed; never create a new endpoint identity.

## 6. Cloud Functions and Backend Services

Recommended Parse Cloud Functions:

1. `getAwsIotSession`
   - existing auth and gateway authorization context
2. `listHomeGraph`
   - returns home, spaces, gateways, devices, scenes, and member roles
3. `upsertSpace`
   - create or update room metadata
4. `assignDeviceToSpace`
   - update `DeviceEndpoint.space`
5. `upsertScene`
   - create or update `Scene` plus `SceneAction`
6. `executeScene`
   - server-side execution path for automation and reliable retries
7. `syncGatewayInventory`
   - refresh `DeviceEndpoint` records from gateway inventory / backend pipeline

Recommended non-function backend workers:

1. scene executor worker
2. inventory reconciliation worker
3. optional shadow-summary cache updater

## 7. Authorization Rules

Home-level roles should drive Parse ACL and Cloud Function checks.

Recommended V1 policy:

| Capability | installer | admin | member | viewer |
| --- | --- | --- | --- | --- |
| Create/update spaces | Yes | Yes | No | No |
| Assign devices to spaces | Yes | Yes | No | No |
| Create/update scenes | Yes | Yes | No | No |
| Execute scenes | Yes | Yes | Yes | No |
| Execute direct device control | Yes | Yes | Yes | No |
| Remove devices / permit join / OTA | Yes | Yes | No | No |

Notes:

1. Direct shadow authorization still depends on AWS IoT policy scope.
2. Parse authorization decides whether the app may discover metadata and request temporary AWS credentials for a given home / gateway.

## 8. Recommended V1 Delivery Order

1. Normalize `Gateway` and `Home` records in Parse.
2. Introduce `DeviceEndpoint` with stable `endpointKey`.
3. Introduce `Space` and room assignment flow.
4. Introduce `Scene` + `SceneAction` for manual scenes.
5. Add `executeScene` backend path before shipping automation or schedules.
6. Add `SceneExecution` only if product needs execution history in Parse UI.

## 9. Explicit Non-Goals for V1

Do not add these in the first release:

- full shadow mirror documents in Parse
- per-device state history in Parse
- schedule engine inside the mobile app
- scene definitions inside gateway shadow documents
- scene references by `nwk`

## 10. Summary

Use Parse for business structure.
Use Shadow for device truth and control.
Use backend execution for anything that must run without the mobile app online.
