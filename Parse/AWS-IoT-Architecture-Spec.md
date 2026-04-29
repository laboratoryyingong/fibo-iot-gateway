# Fibo IoT Gateway: AWS IoT Architecture Specification (V1)

**Status:** Approved for implementation  
**Last Updated:** 2026-04-05  
**Scope:** Mobile App, Parse backend integration, AWS IoT Core, Gateway firmware, Cloud persistence

## 1. Objective

Define the production architecture for communication between the mobile app and physical devices using AWS IoT Core, where Device Shadow is the state synchronization layer between cloud and gateway-managed sub-devices.

## 2. Locked Decisions

1. App connects directly to AWS IoT Core (MQTT over WebSocket).
2. Parse owns auth/session validation, app-domain metadata, and backend scene execution orchestration.
3. AWS temporary credentials are issued via Cognito Identity (developer-authenticated identities).
4. Device model is one gateway with up to 100 sub-devices.
5. Shadow model is one gateway Thing with named shadows for sub-devices.
6. Sub-device shadows are split into 3 domains: `ctrl`, `cfg`, `state`.
7. Command confirmation uses two-stage status:
   - Fast ACK topic (target < 1s).
   - Final convergence from Shadow `reported`.
8. Offline strategy retains `desired`; auto-apply on reconnect.
9. Command expiration is 5 minutes.
10. Conflict strategy is last write wins.
11. Scenes are modeled as target-state sets.
12. OTA package source is S3, rollout by region.
13. History storage starts with DynamoDB only (30-day retention).
14. Multi-gateway account model is required.
15. App recovers by reading final Shadow state only.

## 3. System Context

## 3.1 Components

1. Mobile App (Flutter)
2. Parse Backend (Cloud Functions + app-domain metadata + user/account/gateway authorization mapping)
3. Cognito Identity (temporary credentials)
4. AWS IoT Core (MQTT broker + Shadow service)
5. Gateway Firmware (command executor and shadow reporter)
6. DynamoDB (history and audit persistence)

## 3.2 Data Responsibility

1. App: initiates user actions, subscribes to ACK and state updates.
2. Parse: validates user/session, serves app-domain metadata, and returns AWS identity context.
3. IoT Core: routes messages and stores current shadow state.
4. Gateway: executes device actions, publishes ACK/events, writes reported state.
5. DynamoDB: stores operation/state/alert/ota/audit history with TTL.

## 4. Resource and Naming Model

## 4.1 Thing Naming

- Gateway Thing: `gw_{gatewayId}`

## 4.2 Named Shadow Naming

For sub-device `{deviceId}`:

1. `dev_{deviceId}_ctrl`
2. `dev_{deviceId}_cfg`
3. `dev_{deviceId}_state`

Gateway shadows:

1. `gw_state`
2. `gw_ota`
3. `gw_scenes` (optional in V1)

Naming rule: avoid `/`, use alphanumeric + `_` + `-`.

## 5. Topic Model

## 5.1 AWS Shadow Topics

- `$aws/things/{thingName}/shadow/name/{shadowName}/update`
- `$aws/things/{thingName}/shadow/name/{shadowName}/update/accepted`
- `$aws/things/{thingName}/shadow/name/{shadowName}/update/rejected`
- `$aws/things/{thingName}/shadow/name/{shadowName}/update/delta`
- `$aws/things/{thingName}/shadow/name/{shadowName}/get`
- `$aws/things/{thingName}/shadow/name/{shadowName}/get/accepted`

## 5.2 Custom Topics

1. Command: `fibo/v1/{accountId}/{gatewayId}/cmd/{requestId}`
2. ACK: `fibo/v1/{accountId}/{gatewayId}/ack/{requestId}`
3. Event streams:
   - `fibo/v1/{accountId}/{gatewayId}/events/cmd`
   - `fibo/v1/{accountId}/{gatewayId}/events/state`
   - `fibo/v1/{accountId}/{gatewayId}/events/alert`
   - `fibo/v1/{accountId}/{gatewayId}/events/ota`
   - `fibo/v1/{accountId}/{gatewayId}/events/audit`

## 6. Identity and Authorization

## 6.1 Authentication Flow

1. User logs in to Parse.
2. App calls Parse Cloud Function `getAwsIotSession`.
3. Parse validates session, role, and gateway access list.
4. Parse obtains Cognito developer identity token context.
5. App exchanges identity for temporary AWS credentials.
6. App connects to IoT Core with temporary credentials.

## 6.2 Role Model

1. `installer`
2. `user`
3. `gateway principal` (certificate-based identity)

## 6.3 Permission Matrix (V1)

| Capability | installer | user | gateway principal |
|---|---|---|---|
| Write `dev_*_ctrl` desired | Yes | Yes | No |
| Write `dev_*_cfg` desired | Yes | No | No |
| Write `dev_*_state` desired | No | No | No |
| Write `reported` fields | No | No | Yes |
| Create/update scene definitions | Yes | No | No |
| Execute scenes | Yes | Yes | Yes (executor) |
| Trigger OTA desired updates | Yes | No | No |
| Publish ACK | No | No | Yes |
| Publish event streams | No | No | Yes |

Field-level restrictions are implemented by shadow domain separation (`ctrl/cfg/state`) and IoT topic scope.

## 7. Command and State Lifecycle

## 7.1 Command Contract

```json
{
  "requestId": "uuid",
  "accountId": "acc_001",
  "gatewayId": "gw_001",
  "actor": {
    "userId": "usr_1001",
    "userType": "user"
  },
  "target": {
    "deviceId": "dev_01",
    "domain": "ctrl"
  },
  "issuedAt": 1760000000000,
  "expiresAt": 1760000300000,
  "patch": {
    "power": true,
    "brightness": 70
  }
}
```

## 7.2 ACK Contract

```json
{
  "requestId": "uuid",
  "gatewayId": "gw_001",
  "status": "accepted",
  "reason": null,
  "ackAt": 1760000000200
}
```

Status enum:

1. `accepted`
2. `rejected`
3. `expired`
4. `unauthorized`
5. `invalid`

## 7.3 Sequence

1. App writes command payload (topic or shadow desired metadata).
2. Gateway validates and publishes ACK in under 1 second target.
3. If valid and not expired, gateway executes action.
4. Gateway writes final `reported` state.
5. App updates UI using `reported` final state.
6. If ACK not received in 1 second, app shows timeout alert.

## 8. Shadow Schema Guidelines

## 8.1 `dev_{deviceId}_ctrl`

- Desired: user/installer action targets (`power`, `brightness`, etc.)
- Reported: applied state + metadata (`lastAppliedRequestId`, `appliedAt`)

## 8.2 `dev_{deviceId}_cfg`

- Desired: installer-only configuration (`network`, thresholds, calibration)
- Reported: actual effective configuration

## 8.3 `dev_{deviceId}_state`

- Reported-only runtime telemetry (`online`, `battery`, `signal`, `firmware`, `lastSeenAt`)

## 9. Offline, Expiry, and Conflict Rules

1. Desired state is retained while offline.
2. Gateway applies delta on reconnect.
3. Expired commands (`now > expiresAt`) are acknowledged as `expired` and skipped.
4. Conflict model is last write wins.
5. Every write carries metadata for audit traceability (`requestId`, actor, timestamp).

## 10. Scenes Model

Scenes are authored in Parse and persisted as target-state sets.  
Execution writes deterministic desired states to affected `ctrl` shadows.

Benefits:

1. Idempotent behavior
2. Replay-safe for offline devices
3. Consistent with last-write-wins semantics

## 11. OTA Model

## 11.1 `gw_ota` Desired Fields

1. `targetVersion`
2. `packageUrl` (S3 reference)
3. `rolloutRegion`
4. `schedule`

## 11.2 `gw_ota` Reported Fields

1. `currentVersion`
2. `status` (`idle`, `downloading`, `installing`, `rebooting`, `success`, `failed`)
3. `progress`
4. `lastError`
5. `updatedAt`

## 11.3 Rollout

1. Region-based filtering before apply.
2. OTA events persisted for audit/history.

## 12. History Storage (DynamoDB V1)

## 12.1 Table

- Name: `fibo_iot_events_v1`
- TTL field: `expireAtEpochSec`
- Retention: 30 days

## 12.2 Key Design

- `PK = ACCOUNT#{accountId}#GW#{gatewayId}`
- `SK = TS#{timestamp}#TYPE#{eventType}#REQ#{requestId}`

## 12.3 Core Attributes

1. `eventType`
2. `requestId`
3. `deviceId`
4. `actorUserId`
5. `actorUserType`
6. `payload`
7. `result`
8. `createdAt`
9. `expireAtEpochSec`

## 12.4 Optional GSIs

1. `GSI1PK = ACCOUNT#{accountId}#DEVICE#{deviceId}`, `GSI1SK = TS#{timestamp}`
2. `GSI2PK = ACCOUNT#{accountId}#USER#{actorUserId}`, `GSI2SK = TS#{timestamp}`

## 13. Multi-Gateway Account Model

1. One account owns multiple gateways.
2. Users are scoped to account permissions.
3. Parse returns authorized gateway list in session payload.
4. IoT policies are generated/scoped to authorized gateway namespace.

## 14. NFR Targets

1. ACK latency target: `< 1s` (P95).
2. Gateway supports up to 100 sub-devices.
3. Mobile reconnection recovers from final shadow state.
4. No long-lived AWS credentials in app/firmware.

## 15. Risks and Guardrails

1. Shadow document bloat: enforce per-domain payload size controls.
2. Duplicate command processing: enforce idempotency by `requestId`.
3. Unauthorized writes: strict role-based topic/policy boundaries.
4. Event volume growth: monitor DynamoDB RCU/WCU and TTL effectiveness.

## 16. Versioning

Any contract changes to topics, payload schema, or permission behavior must increment a documented architecture version and migration note.
