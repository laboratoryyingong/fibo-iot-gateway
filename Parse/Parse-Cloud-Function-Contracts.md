# Fibo IoT Gateway: Parse Cloud Function Contracts (V1)

**Status:** Proposed for implementation  
**Last Updated:** 2026-04-05  
**Companion Schema:** `Parse/Parse-Class-Schema.md`

## 1. Purpose

Define the Cloud Function contracts used by the app and backend to:

- load app-domain data
- manage spaces and scenes
- bind device metadata to spaces
- authorize AWS IoT access
- execute scenes reliably from the backend

All Cloud Functions must:

1. require a valid Parse session unless explicitly noted otherwise
2. resolve home membership before returning or mutating data
3. return stable business IDs, not only Parse `objectId`
4. never return master-key credentials or secret values

## 2. Error Envelope

Unless a function has a strong reason to do otherwise, use this error shape:

```json
{
  "code": "forbidden",
  "message": "User does not have access to this home.",
  "details": null
}
```

Recommended codes:

- `unauthenticated`
- `forbidden`
- `invalid_argument`
- `not_found`
- `conflict`
- `rate_limited`
- `internal`

## 3. Cloud Functions

## 3.1 `getAwsIotSession`

Purpose:

- validate the Parse user
- resolve accessible homes and gateways
- return the AWS IoT identity bootstrap payload

Caller:

- mobile app

Input:

```json
{
  "gatewayId": "gw_001"
}
```

Rules:

1. `gatewayId` is optional only if the user has exactly one active gateway.
2. function must verify the user is an active `HomeMember`.
3. function must scope the response to the requested gateway only.

Success response:

```json
{
  "homeId": "home_001",
  "gatewayId": "gw_001",
  "thingName": "gw_gw_001",
  "role": "member",
  "awsIdentity": {
    "identityId": "ap-southeast-2:example",
    "region": "us-east-1",
    "credentials": {
      "accessKeyId": "TEMP",
      "secretAccessKey": "TEMP",
      "sessionToken": "TEMP",
      "expirationEpochMs": 1775388600000
    }
  },
  "iotScope": {
    "allowedShadowPrefixes": [
      "dev_",
      "admin",
      "hub"
    ],
    "allowedTopicPrefix": "fibo/v1/acc_001/gw_001/"
  }
}
```

## 3.2 `listHomeGraph`

Purpose:

- return the app-domain graph used by the home, spaces, and scenes UI

Caller:

- mobile app

Input:

```json
{
  "homeId": "home_001",
  "includeArchived": false
}
```

Success response:

```json
{
  "home": {
    "homeId": "home_001",
    "name": "Ying Home",
    "timezone": "Australia/Adelaide"
  },
  "membership": {
    "role": "admin"
  },
  "gateways": [
    {
      "gatewayId": "gw_001",
      "thingName": "gw_gw_001",
      "displayName": "Living Room Gateway",
      "statusSummary": "online"
    }
  ],
  "spaces": [
    {
      "spaceId": "space_001",
      "name": "Living Room",
      "sortOrder": 100
    }
  ],
  "devices": [
    {
      "endpointKey": "gw_001:00158d0001bbbbbb:ep1",
      "gatewayId": "gw_001",
      "spaceId": "space_001",
      "thingName": "gw_gw_001",
      "shadowName": "dev_00158d0001bbbbbb_ep1",
      "profile": "dimmable_light",
      "displayName": "Bedroom Bulb",
      "iconKey": "bulb",
      "lastKnownOnline": true,
      "lastKnownState": {
        "power": 1,
        "level": 128
      }
    }
  ],
  "scenes": [
    {
      "sceneId": "scene_001",
      "name": "Movie Time",
      "icon": "🎬",
      "enabled": true,
      "executionMode": "manual_only",
      "actionCount": 2
    }
  ]
}
```

Notes:

1. Keep the response compact enough for app startup.
2. `lastKnownState` is optional cache only.
3. The app should still recover final device truth from Shadow.

## 3.3 `upsertSpace`

Purpose:

- create or update a room / area

Caller:

- mobile app

Authorization:

- `installer` or `admin`

Input:

```json
{
  "homeId": "home_001",
  "space": {
    "spaceId": "space_001",
    "name": "Living Room",
    "imageUrl": null,
    "sortOrder": 100,
    "status": "active"
  }
}
```

Rules:

1. if `spaceId` exists, update the existing row in the same home
2. if `spaceId` is absent, create a new one server-side
3. reject duplicate active `name` within the same home when product chooses strict naming

Success response:

```json
{
  "space": {
    "spaceId": "space_001",
    "name": "Living Room",
    "imageUrl": null,
    "sortOrder": 100,
    "status": "active",
    "updatedAt": "2026-04-05T18:50:00.000Z"
  }
}
```

## 3.4 `assignDeviceToSpace`

Purpose:

- attach or detach a `DeviceEndpoint` from a `Space`

Caller:

- mobile app

Authorization:

- `installer` or `admin`

Input:

```json
{
  "homeId": "home_001",
  "endpointKey": "gw_001:00158d0001bbbbbb:ep1",
  "spaceId": "space_001",
  "sortOrder": 120
}
```

Detach example:

```json
{
  "homeId": "home_001",
  "endpointKey": "gw_001:00158d0001bbbbbb:ep1",
  "spaceId": null
}
```

Success response:

```json
{
  "device": {
    "endpointKey": "gw_001:00158d0001bbbbbb:ep1",
    "spaceId": "space_001",
    "sortOrder": 120,
    "updatedAt": "2026-04-05T18:52:00.000Z"
  }
}
```

## 3.5 `upsertScene`

Purpose:

- create or update a `Scene` and replace its `SceneAction` set atomically

Caller:

- mobile app

Authorization:

- `installer` or `admin`

Input:

```json
{
  "homeId": "home_001",
  "scene": {
    "sceneId": "scene_001",
    "name": "Movie Time",
    "icon": "🎬",
    "enabled": true,
    "executionMode": "manual_only",
    "status": "active"
  },
  "actions": [
    {
      "order": 10,
      "targetEndpointKey": "gw_001:00158d0001bbbbbb:ep1",
      "actionType": "desired_state",
      "payload": {
        "state": {
          "power": 1,
          "level": 40
        }
      }
    },
    {
      "order": 20,
      "targetEndpointKey": "gw_001:00158d0001aaaaaa:ep1",
      "actionType": "desired_state",
      "payload": {
        "state": {
          "power": 0
        }
      }
    }
  ]
}
```

Rules:

1. validate every `targetEndpointKey` in the same home
2. validate `payload` against the referenced device profile
3. reject non-deterministic actions such as `toggle`
4. replace the full action set in one transaction-like server flow

Success response:

```json
{
  "scene": {
    "sceneId": "scene_001",
    "name": "Movie Time",
    "enabled": true,
    "executionMode": "manual_only",
    "status": "active",
    "actionCount": 2,
    "updatedAt": "2026-04-05T18:55:00.000Z"
  }
}
```

## 3.6 `getSceneDetail`

Purpose:

- return one scene and its ordered actions for editing

Caller:

- mobile app

Input:

```json
{
  "homeId": "home_001",
  "sceneId": "scene_001"
}
```

Success response:

```json
{
  "scene": {
    "sceneId": "scene_001",
    "name": "Movie Time",
    "icon": "🎬",
    "enabled": true,
    "executionMode": "manual_only",
    "status": "active"
  },
  "actions": [
    {
      "order": 10,
      "targetEndpointKey": "gw_001:00158d0001bbbbbb:ep1",
      "targetShadowName": "dev_00158d0001bbbbbb_ep1",
      "actionType": "desired_state",
      "payload": {
        "state": {
          "power": 1,
          "level": 40
        }
      }
    }
  ]
}
```

## 3.7 `executeScene`

Purpose:

- trigger scene execution from backend for manual execution, automation, or retry

Caller:

- mobile app or backend scheduler

Authorization:

- app: `installer`, `admin`, or `member`
- scheduler: privileged backend path only

Input:

```json
{
  "homeId": "home_001",
  "sceneId": "scene_001",
  "mode": "manual",
  "idempotencyKey": "manual-scene_001-1775388900000"
}
```

Rules:

1. backend loads `SceneAction` rows ordered by `order`
2. backend writes deterministic desired updates to AWS IoT
3. backend creates a `SceneExecution` row
4. repeated `idempotencyKey` must not create duplicate concurrent executions

Success response:

```json
{
  "execution": {
    "executionId": "sx_001",
    "sceneId": "scene_001",
    "status": "started",
    "startedAt": "2026-04-05T19:00:00.000Z"
  }
}
```

Optional synchronous summary:

```json
{
  "execution": {
    "executionId": "sx_001",
    "sceneId": "scene_001",
    "status": "succeeded",
    "startedAt": "2026-04-05T19:00:00.000Z",
    "completedAt": "2026-04-05T19:00:01.200Z"
  },
  "resultSummary": {
    "successCount": 2,
    "failureCount": 0
  }
}
```

## 3.8 `listSceneExecutions`

Purpose:

- lightweight scene history for the app

Caller:

- mobile app

Input:

```json
{
  "homeId": "home_001",
  "sceneId": "scene_001",
  "limit": 20
}
```

Success response:

```json
{
  "executions": [
    {
      "executionId": "sx_001",
      "sceneId": "scene_001",
      "status": "succeeded",
      "mode": "manual",
      "startedAt": "2026-04-05T19:00:00.000Z",
      "completedAt": "2026-04-05T19:00:01.200Z",
      "resultSummary": {
        "successCount": 2,
        "failureCount": 0
      }
    }
  ]
}
```

## 3.9 `syncGatewayInventory`

Purpose:

- reconcile Parse `DeviceEndpoint` rows with the current gateway inventory

Caller:

- installer app or backend admin flow

Authorization:

- `installer` or `admin`

Input:

```json
{
  "homeId": "home_001",
  "gatewayId": "gw_001",
  "mode": "refresh_inventory"
}
```

Rules:

1. backend queries the gateway inventory source
2. create missing `DeviceEndpoint` rows
3. update changed metadata like `model`, `profile`, `shadowName`
4. mark removed rows as `deleted`; do not hard-delete in V1

Success response:

```json
{
  "gatewayId": "gw_001",
  "summary": {
    "created": 2,
    "updated": 3,
    "markedDeleted": 1,
    "unchanged": 24
  }
}
```

## 4. Validation Rules Shared Across Functions

1. `homeId` must always resolve to an active `HomeMember`.
2. `gatewayId` must belong to the same home.
3. `endpointKey` and `sceneId` must be scoped to the same home as the caller input.
4. `SceneAction.payload` must be validated against the `DeviceEndpoint.profile`.
5. Scene writes must use deterministic target values, not toggles.

## 5. Suggested Implementation Order

1. `getAwsIotSession`
2. `listHomeGraph`
3. `upsertSpace`
4. `assignDeviceToSpace`
5. `upsertScene`
6. `getSceneDetail`
7. `executeScene`
8. `syncGatewayInventory`
9. `listSceneExecutions`
