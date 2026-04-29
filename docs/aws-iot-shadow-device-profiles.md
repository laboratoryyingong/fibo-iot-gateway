# AWS IoT Shadow Device Profiles

## 1. Scope

This document defines the AWS IoT Shadow model for the devices currently supported by [`esp32h2_zigbee_gateway`](../esp32h2_zigbee_gateway/README.md).

The purpose is to standardize:

- how devices are matched into profiles,
- how endpoint-level named shadows are created,
- how desired state and command-style actions are modeled,
- how control acknowledgements and device state are written back.

This document intentionally ignores the H2-to-S3 transport implementation. It focuses only on the Shadow contract that the cloud side and the bridge side must share.

This document defines the endpoint business shadows only. It does not define the `hub` shadow or the `admin` shadow used for gateway and Zigbee network administration.

## 2. Design Decision

### 2.1 Shadow Granularity

Use **one named shadow per Zigbee endpoint**, not one per physical device.

Reason:

- the current H2 control interface targets `nwk + ep`,
- multi-gang switches and multi-endpoint devices need endpoint-level control,
- button devices also report actions per endpoint.

### 2.2 Thing and Shadow Naming

- One AWS IoT Thing per hub:
  - example: `fibo-hub-001`
- Separate named shadow for gateway and Zigbee network administration:
  - `admin`
- One named shadow per Zigbee endpoint:
  - format: `dev_<ieeehex>_ep<ep>`
  - example: `dev_00158d0001aaaaaa_ep1`

### 2.3 Core Identity Rule

The stable identity is:

- `ieee + ep`

The following are runtime properties only:

- `nwk`
- `online`
- `last_seen_ts`

### 2.4 Incremental Rollout Strategy

Do not implement the full shadow contract in the first iteration.

Use additive stages:

1. Stage 1: minimal remote-control shadow
   - implement only `onoff_actuator` and `dimmable_light`
   - support only `desired.state.power` and `desired.state.level`
   - publish only minimal identity, connectivity, and current state fields by default

2. Stage 2: richer state and read-only devices
   - add `color_light`, `door_lock`, `ias_sensor`, and `multi_sensor`
   - add `reported.telemetry` and `reported.last_event` only where needed

3. Stage 3: command-style operations
   - add `desired.command` and `reported.last_command`
   - enable `curtain` and `button_remote`

Stability rule:

- each new stage may only add fields or profiles
- do not rename `desired.state`
- do not rename `reported.identity`, `reported.connectivity`, or `reported.state`
- if `reported.match` or `reported.capabilities` are later published, keep those names stable too

### 2.5 Boundary with the `admin` Shadow

The following flows do not belong in endpoint business shadows:

- `permit_join`
- `remove_device`
- reboot
- OTA
- bulk maintenance operations

These should live in the `admin` shadow instead.

The `admin` shadow MVP structure is defined in the roadmap document, not in this profile document.

For cloud-side targeting of destructive operations such as `remove_device`:

- use `target_ieee` or `target_shadow`
- do not use `nwk` as the cloud-side identifier

For OTA and batch maintenance:

- use the `admin` shadow only for intent, metadata, and status
- do not put firmware chunks or large maintenance payloads into shadow documents
- the first supported `bulk_maintenance.action` should be `refresh_inventory`

## 3. Current Supported Profiles

These profiles are derived from the current code in:

- [`zbx.c`](../esp32h2_zigbee_gateway/main/zbx.c)
- [`devdb.c`](../esp32h2_zigbee_gateway/main/devdb.c)
- [`gateway.c`](../esp32h2_zigbee_gateway/main/gateway.c)
- [`h2_proto.c`](../esp32h2_zigbee_gateway/main/h2_proto.c)

| Profile | Device class | Match rule | Readable state | Writable state | Command-style action |
| --- | --- | --- | --- | --- | --- |
| `onoff_actuator` | switch, relay, siren, AC power, garage relay | input cluster `0006` | `power` | `power` | none |
| `dimmable_light` | dimmer light | input clusters `0006` + `0008` | `power`, `level` | `power`, `level` | none |
| `color_light` | RGB / tunable white light | input cluster `0300`, usually with `0006` and `0008` | `power`, `level`, `color` | `power`, `level`, `color` | none |
| `curtain` | window covering | input cluster `0102` | `lift_percent` when available | `target_lift_percent` | `open`, `close`, `stop` |
| `door_lock` | smart lock | input cluster `0101` | `locked` when available | `locked` | none |
| `ias_sensor` | generic IAS alarm sensor | input cluster `0500` | `zone_status`, IAS flags | none | none |
| `multi_sensor` | battery multi-sensor | any combination of temp/humidity/illuminance/power/IAS clusters | telemetry fields | none | none |
| `button_remote` | TS004x and similar button devices | model starts with `TS004`, or OnOff switch-style controller endpoint | `last_action`, optional binding list | none | `bind`, `unbind`, `clear_bindings` |

### 3.1 Coverage of H2 Supported Device Types

The table below maps the current `esp32h2_zigbee_gateway/README.md` device list into the shadow profiles in this document.

| H2 supported type | Shadow profile | Coverage | Notes |
| --- | --- | --- | --- |
| Switch / relay | `onoff_actuator` | full | mapped to `state.power` |
| Siren | `onoff_actuator` | full | modeled as on/off actuator |
| AC (power / unit) | `onoff_actuator` | partial | power on/off is covered; thermostat setpoints are not yet modeled |
| Garage door | `onoff_actuator` | partial | relay-style open/close is covered through on/off; barrier-cluster-specific semantics are not yet modeled |
| Dimmer / level | `dimmable_light` | full | mapped to `state.power` and `state.level` |
| Color light / tunable white light | `color_light` | full | mapped to on/off, level, and color control |
| Curtain / window covering | `curtain` | full | mapped to open, close, stop, and goto percent |
| Smart lock | `door_lock` | full | mapped to `state.locked` |
| PIR / mmWave / motion | `ias_sensor` or `multi_sensor` | full | IAS-only devices use `ias_sensor`; combo sensors with telemetry use `multi_sensor` |
| Temperature / humidity / barometric | `multi_sensor` | full | telemetry is published under `reported.telemetry` |
| Light / illuminance sensor | `multi_sensor` | full | illuminance is published under `reported.telemetry` |
| Contact / door-window sensor | `ias_sensor` | partial | IAS Zone path is covered; Binary Input specific mapping is not yet modeled separately |
| Gas / leak sensor | `ias_sensor` | partial | IAS Zone path is covered; vendor-specific non-IAS semantics are not yet split into dedicated profiles |

Current intentional gaps:

- thermostat setpoints for AC devices are not part of the shadow contract yet
- barrier-cluster-specific garage semantics are not part of the shadow contract yet
- Binary Input contact sensors are not yet split into a dedicated shadow profile
- gas and leak sensors are currently represented as generic IAS semantics unless a stable model classification table is added

### 3.2 Next-Stage Expansion Plan for the Current Gaps

The next-stage additive expansion should introduce the following profiles and rules:

| Gap | Next-stage profile | Why it should be separate |
| --- | --- | --- |
| AC thermostat setpoints | `ac_thermostat` | adds HVAC mode and setpoint semantics that do not fit cleanly in `onoff_actuator` |
| Barrier-style garage control | `garage_barrier` | needs barrier-specific door state and stop semantics rather than plain relay on/off |
| Binary Input contact sensors | `contact_sensor` | needs explicit open/closed state instead of generic IAS bitmaps |
| Gas and leak semantics | `safety_sensor` | needs semantic alarm meaning and stable subtype labeling beyond generic IAS |

Stage gate for all four:

- keep the current profiles unchanged until the bridge has a reliable match signal
- add the new profile only when cluster data or a stable model-classification table can distinguish it from the existing generic profile
- keep the old profile as fallback when the stronger specialization signal is absent

## 4. Matching Rules

### 4.1 Input Data Required for Matching

Each endpoint shadow should be created only after the bridge has the following normalized identity data:

```json
{
  "ieee": "00158d0001aaaaaa",
  "ep": 1,
  "nwk": "0x4F32",
  "mfr": "_TZ3000_xxx",
  "model": "TS0505B",
  "device_id": "0x0102",
  "in_clusters": ["0006", "0008", "0300"],
  "out_clusters": []
}
```

### 4.2 Matching Order

Apply matching in this order:

1. Strong model rule:
   - if `model` starts with `TS004`, match `button_remote`

2. Strong cluster rule:
   - cluster `0101` -> `door_lock`
   - cluster `0102` -> `curtain`
   - cluster `0300` -> `color_light`
   - clusters `0006` + `0008` -> `dimmable_light`
   - cluster `0006` only -> `onoff_actuator`
   - cluster `0500` only -> `ias_sensor`

3. Sensor composition rule:
   - if any of `0402`, `0405`, `0400`, `0001`, `0500` appear together, and the endpoint is not a controller, prefer `multi_sensor`

4. Fallback sensor rule:
   - only `0402` -> `temp_sensor` behavior can still be represented under `multi_sensor`
   - only `0405` -> `multi_sensor`
   - only `0400` -> `multi_sensor`

5. Planned specialization rule for the next stage:
   - if an endpoint exposes thermostat semantics and the device is classified as an HVAC or AC unit, prefer `ac_thermostat` over `onoff_actuator`
   - if an endpoint exposes barrier-control semantics and the device is classified as a garage opener, prefer `garage_barrier` over `onoff_actuator`
   - if an endpoint exposes Binary Input semantics and the device is classified as a door/window contact device, prefer `contact_sensor` over `ias_sensor`
   - if a stable model table identifies a gas or leak safety device, prefer `safety_sensor` over generic `ias_sensor`

For the current implementation, keep the public profile list limited to the 8 profiles above. Enable the four next-stage specializations only after the bridge can classify them reliably.

### 4.3 Matching Result

Write the result into:

```json
{
  "reported": {
    "match": {
      "profile": "color_light",
      "confidence": "high",
      "reasons": [
        "cluster:0006",
        "cluster:0008",
        "cluster:0300"
      ]
    }
  }
}
```

## 5. Common Shadow Contract

### 5.1 Stage 1 Minimal Shared Structure

The first implementation should use this smaller structure:

```json
{
  "state": {
    "reported": {
      "schema_version": 1,
      "identity": {},
      "connectivity": {},
      "state": {}
    }
  }
}
```

Rules:

- Stage 1 should support only `onoff_actuator` and `dimmable_light`
- Stage 1 should keep `desired.state` transient and delete it after `reported.state` converges
- Stage 1 should not publish `reported.match` or `reported.capabilities` by default from the MCU
- Stage 1 should not publish `desired.command`
- Stage 1 should not publish `reported.telemetry`, `reported.last_event`, or `reported.last_command`
- Stage 1 should keep the payload small enough to inspect manually in the AWS console and logs

### 5.2 Optional Cloud Metadata After Stage 1

After Stage 1 is stable, add these only if the backend truly needs self-describing shadows:

- `reported.match`
- `reported.capabilities`
- extended `reported.identity` fields such as `nwk`, `mfr`, `device_id`, and cluster lists
- `reported.connectivity.last_seen_ts`

The bridge may keep these fields locally and avoid publishing them from the MCU.

### 5.3 Stage 2 Additive Fields

After Stage 1 is stable, Stage 2 may add:

- `reported.telemetry`
- `reported.last_event`

Use these fields only for profiles that need them.

### 5.4 Stage 3 Additive Fields

After Stage 2 is stable, Stage 3 may add:

- `desired.command`
- `reported.last_command`

Use `desired.command` only for one-shot actions, and omit the field entirely when no command is pending.

### 5.5 Full Structure After All Stages

The full target contract after all stages is:

```json
{
  "state": {
    "desired": {
      "state": {}
    },
    "reported": {
      "schema_version": 1,
      "identity": {},
      "match": {},
      "capabilities": {},
      "connectivity": {},
      "state": {},
      "telemetry": {},
      "last_event": null,
      "last_command": null
    }
  }
}
```

Notes:

- `desired.command` is optional and should appear only while a one-shot command is pending
- `desired.state` is also optional in steady state and may be omitted after the bridge has reconciled the requested write
- when there is no pending command, omit `desired.command`
- sending `desired.command = null` should be treated as deleting that property, not as a stored idle value

### 5.6 Common `reported.identity`

```json
{
  "ieee": "00158d0001aaaaaa",
  "ep": 1,
  "nwk": "0x4F32",
  "mfr": "_TZ3000_xxx",
  "model": "TS0505B",
  "device_id": "0x0102",
  "in_clusters": ["0006", "0008", "0300"],
  "out_clusters": []
}
```

For Stage 1 MCU-friendly cloud payloads, publish only the subset below by default:

```json
{
  "ieee": "00158d0001aaaaaa",
  "ep": 1,
  "model": "TS0505B"
}
```

The bridge should keep `nwk`, `mfr`, `device_id`, and cluster lists locally unless a cloud consumer explicitly requires them.

### 5.7 Common `reported.connectivity`

```json
{
  "online": true
}
```

When a richer cloud view is needed later, extend it to:

```json
{
  "online": true,
  "last_seen_ts": "2026-04-05T10:30:00Z"
}
```

### 5.8 Common `desired.command`

Use `desired.command` only for one-shot actions.

```json
{
  "id": "cmd-20260405-001",
  "op": "stop",
  "args": {},
  "issued_at": "2026-04-05T10:30:00Z"
}
```

Rules:

- `id` must be unique per operation
- repeated delivery of the same `id` must be treated as idempotent
- successful execution must be written to `reported.last_command`
- failed execution must also be written to `reported.last_command`

### 5.9 Common `reported.last_command`

```json
{
  "id": "cmd-20260405-001",
  "op": "stop",
  "status": "succeeded",
  "completed_at": "2026-04-05T10:30:02Z",
  "error": null
}
```

Or:

```json
{
  "id": "cmd-20260405-001",
  "op": "stop",
  "status": "failed",
  "completed_at": "2026-04-05T10:30:02Z",
  "error": {
    "code": "unsupported",
    "message": "stop is not supported by this profile"
  }
}
```

### 5.9 Shadow Topic Behavior

When a client or device updates a shadow:

- every successful update causes `/update/accepted`
- every successful update also causes `/update/documents`
- `/update/delta` is published only when `desired` and `reported` differ
- control execution should be triggered from `/update/delta`, not from every `/update/accepted` or `/update/documents`
- a field under `desired` set to `null` is best treated as a delete operation for that property

## 6. Matching Flow

### 6.1 Discovery to Shadow Flow

1. Bridge receives endpoint inventory from H2.
2. Bridge normalizes:
   - `ieee`
   - `ep`
   - `nwk`
   - `mfr`
   - `model`
   - `device_id`
   - cluster lists
3. Bridge derives `profile`.
4. Bridge derives `capabilities`.
5. Bridge creates or updates named shadow `dev_<ieeehex>_ep<ep>`.
6. Bridge writes at minimum:
   - `reported.identity` using the Stage 1 subset
   - `reported.connectivity`
7. Bridge may additionally write:
   - `reported.match`
   - `reported.capabilities`
   - extended `reported.identity`

### 6.2 Rejoin Handling

If a device rejoins and `nwk` changes:

- keep the same shadow name,
- if `reported.identity.nwk` is being published, update only that field,
- otherwise keep the new `nwk` only in the local registry,
- do not create a new shadow.

## 7. Control Flow

### 7.1 Stage 1 Steady-State Control

In the first implementation, use `desired.state` only for:

- `power`
- `level`

Flow:

1. App writes `desired.state`
2. Bridge reads `/update/delta`
3. Bridge validates requested fields against the local profile table or local capability registry
4. Bridge converts them into H2 commands
5. If command succeeds, bridge updates `reported.state`
6. Bridge then deletes the reconciled `desired.state` fields to keep steady state small
7. Bridge leaves unsupported fields untouched and records the failure

### 7.2 Stage 2 Steady-State Additions

After Stage 1 is stable, extend `desired.state` to include:

- `locked`
- `target_lift_percent`
- color target fields

Keep the structure additive. Do not redesign `desired.state`.

### 7.3 Stage 3 One-Shot Control

Use `desired.command` for:

- curtain `open`
- curtain `close`
- curtain `stop`
- button `bind`
- button `unbind`
- button `clear_bindings`

Flow:

1. App writes `desired.command`
2. Bridge executes by `op`
3. Bridge writes `reported.last_command`
4. Bridge may optionally clear `desired.command` in a follow-up write by deleting that property
5. When no command is pending, omit `desired.command` instead of storing `null`

### 7.4 Pair and Unpair Boundary

Treat these as gateway or Zigbee network administration, not as endpoint business control:

- pair -> `admin.desired.command.op = permit_join`
- unpair -> `admin.desired.command.op = remove_device`
- reboot -> `admin.desired.command.op = reboot`
- OTA -> `admin.desired.command.op = ota_start` or `ota_abort`
- batch maintenance -> `admin.desired.command.op = bulk_maintenance`

Rules:

- do not send `permit_join` through a `dev_<ieeehex>_ep<ep>` shadow
- do not send `remove_device` through a `dev_<ieeehex>_ep<ep>` shadow
- do not send `reboot`, `ota_start`, `ota_abort`, or `bulk_maintenance` through a `dev_<ieeehex>_ep<ep>` shadow
- the first `bulk_maintenance.action` should be `refresh_inventory`
- `remove_device` should target `target_ieee` or `target_shadow`
- after `remove_device` succeeds, the bridge should delete all endpoint shadows for that IEEE address

## 8. Profile Definitions

Implement the profiles in this order:

- Stage 1: `onoff_actuator`, `dimmable_light`
- Stage 2: `color_light`, `door_lock`, `ias_sensor`, `multi_sensor`
- Stage 3: `curtain`, `button_remote`
- Stage 4: `ac_thermostat`, `garage_barrier`, `contact_sensor`, `safety_sensor`

The examples below describe the full target contract for each profile. In early stages, implement only the fields that are enabled by the rollout rules in Section 5 and Section 7.

### 8.1 `onoff_actuator`

#### Match

- input cluster `0006`
- no stronger match from `0101`, `0102`, `0300`, or button model rules

#### Capabilities

```json
{
  "onoff": true
}
```

#### Shadow Example

```json
{
  "state": {
    "desired": {
      "state": {
        "power": 1
      }
    },
    "reported": {
      "schema_version": 1,
      "identity": {
        "ieee": "00158d0001aaaaaa",
        "ep": 1,
        "nwk": "0x4F32",
        "mfr": "_TZ3000_xxx",
        "model": "TS0001",
        "device_id": "0x0100",
        "in_clusters": ["0006"],
        "out_clusters": []
      },
      "match": {
        "profile": "onoff_actuator",
        "confidence": "high",
        "reasons": ["cluster:0006"]
      },
      "capabilities": {
        "onoff": true
      },
      "connectivity": {
        "online": true,
        "last_seen_ts": "2026-04-05T10:30:00Z"
      },
      "state": {
        "power": 1
      },
      "telemetry": {},
      "last_event": null,
      "last_command": null
    }
  }
}
```

#### Control Mapping

- `desired.state.power = 0/1` -> H2 `CMD_ONOFF`

#### Notes

- This profile intentionally covers simple on/off executors from the H2 device list, including switch/relay, siren, AC power-only control, and relay-style garage door control.
- If AC thermostat setpoints or barrier-cluster-specific garage states are needed later, add a new profile or extend the contract additively instead of overloading `onoff_actuator`.

### 8.2 `dimmable_light`

#### Match

- input clusters `0006` and `0008`
- no color cluster `0300`

#### Capabilities

```json
{
  "onoff": true,
  "level": true
}
```

#### Shadow Example

```json
{
  "state": {
    "desired": {
      "state": {
        "power": 1,
        "level": 128
      }
    },
    "reported": {
      "schema_version": 1,
      "identity": {
        "ieee": "00158d0001bbbbbb",
        "ep": 1,
        "nwk": "0x52ED",
        "mfr": "_TZ3000_xxx",
        "model": "TS0601_dimmer",
        "device_id": "0x0101",
        "in_clusters": ["0006", "0008"],
        "out_clusters": []
      },
      "match": {
        "profile": "dimmable_light",
        "confidence": "high",
        "reasons": ["cluster:0006", "cluster:0008"]
      },
      "capabilities": {
        "onoff": true,
        "level": true
      },
      "connectivity": {
        "online": true,
        "last_seen_ts": "2026-04-05T10:30:00Z"
      },
      "state": {
        "power": 1,
        "level": 128
      },
      "telemetry": {},
      "last_event": null,
      "last_command": null
    }
  }
}
```

#### Control Mapping

- `desired.state.power` -> H2 `CMD_ONOFF`
- `desired.state.level` -> H2 `CMD_LEVEL`

### 8.3 `color_light`

#### Match

- input cluster `0300`

#### Capabilities

```json
{
  "onoff": true,
  "level": true,
  "color_hs": true,
  "color_xy": true,
  "color_temp": true
}
```

#### Shadow Example

```json
{
  "state": {
    "desired": {
      "state": {
        "power": 1,
        "level": 180,
        "color": {
          "mode": "temp_mireds",
          "temp_mireds": 370
        }
      }
    },
    "reported": {
      "schema_version": 1,
      "identity": {
        "ieee": "00158d0001cccccc",
        "ep": 1,
        "nwk": "0x31AF",
        "mfr": "_TZ3000_xxx",
        "model": "TS0505B",
        "device_id": "0x0102",
        "in_clusters": ["0006", "0008", "0300"],
        "out_clusters": []
      },
      "match": {
        "profile": "color_light",
        "confidence": "high",
        "reasons": ["cluster:0300"]
      },
      "capabilities": {
        "onoff": true,
        "level": true,
        "color_hs": true,
        "color_xy": true,
        "color_temp": true
      },
      "connectivity": {
        "online": true,
        "last_seen_ts": "2026-04-05T10:30:00Z"
      },
      "state": {
        "power": 1,
        "level": 180,
        "color": {
          "mode": "temp_mireds",
          "hue": null,
          "saturation": null,
          "x": null,
          "y": null,
          "temp_mireds": 370
        }
      },
      "telemetry": {},
      "last_event": null,
      "last_command": null
    }
  }
}
```

#### Control Mapping

- `desired.state.power` -> H2 `CMD_ONOFF`
- `desired.state.level` -> H2 `CMD_LEVEL`
- `desired.state.color.mode = hs` with `hue/saturation` -> H2 `CMD_COLOR(mode=0)`
- `desired.state.color.mode = xy` with `x/y` -> H2 `CMD_COLOR(mode=1)`
- `desired.state.color.mode = temp_mireds` with `temp_mireds` -> H2 `CMD_COLOR(mode=2)`

### 8.4 `curtain`

#### Match

- input cluster `0102`

#### Capabilities

```json
{
  "lift_control": true,
  "stop": true
}
```

#### Shadow Example

```json
{
  "state": {
    "desired": {
      "state": {
        "target_lift_percent": 65
      }
    },
    "reported": {
      "schema_version": 1,
      "identity": {
        "ieee": "00158d0001dddddd",
        "ep": 1,
        "nwk": "0x4411",
        "mfr": "_TZ3000_xxx",
        "model": "WindowCovering",
        "device_id": "0x0202",
        "in_clusters": ["0102"],
        "out_clusters": []
      },
      "match": {
        "profile": "curtain",
        "confidence": "high",
        "reasons": ["cluster:0102"]
      },
      "capabilities": {
        "lift_control": true,
        "stop": true
      },
      "connectivity": {
        "online": true,
        "last_seen_ts": "2026-04-05T10:30:00Z"
      },
      "state": {
        "lift_percent": 65,
        "target_lift_percent": 65
      },
      "telemetry": {},
      "last_event": null,
      "last_command": null
    }
  }
}
```

#### One-Shot Command Example

```json
{
  "state": {
    "desired": {
      "command": {
        "id": "cmd-20260405-stop-001",
        "op": "stop",
        "args": {},
        "issued_at": "2026-04-05T10:30:00Z"
      }
    }
  }
}
```

#### Control Mapping

- `desired.state.target_lift_percent` -> H2 `CMD_CURTAIN(action=3, percent=x)`
- `desired.command.op = open` -> H2 `CMD_CURTAIN(action=0)`
- `desired.command.op = close` -> H2 `CMD_CURTAIN(action=1)`
- `desired.command.op = stop` -> H2 `CMD_CURTAIN(action=2)`

### 8.5 `door_lock`

#### Match

- input cluster `0101`

#### Capabilities

```json
{
  "lock": true
}
```

#### Shadow Example

```json
{
  "state": {
    "desired": {
      "state": {
        "locked": true
      }
    },
    "reported": {
      "schema_version": 1,
      "identity": {
        "ieee": "00158d0001eeeeee",
        "ep": 1,
        "nwk": "0x1288",
        "mfr": "_TZ3000_xxx",
        "model": "DoorLock",
        "device_id": "0x000A",
        "in_clusters": ["0101"],
        "out_clusters": []
      },
      "match": {
        "profile": "door_lock",
        "confidence": "high",
        "reasons": ["cluster:0101"]
      },
      "capabilities": {
        "lock": true
      },
      "connectivity": {
        "online": true,
        "last_seen_ts": "2026-04-05T10:30:00Z"
      },
      "state": {
        "locked": true
      },
      "telemetry": {},
      "last_event": null,
      "last_command": null
    }
  }
}
```

#### Control Mapping

- `desired.state.locked = true/false` -> H2 `CMD_LOCK`

### 8.6 `ias_sensor`

#### Match

- input cluster `0500`
- no stronger actuator match

#### Capabilities

```json
{
  "ias_zone": true,
  "battery": true
}
```

#### Shadow Example

```json
{
  "state": {
    "desired": {
      "state": {}
    },
    "reported": {
      "schema_version": 1,
      "identity": {
        "ieee": "00158d0001ffffff",
        "ep": 1,
        "nwk": "0x61BC",
        "mfr": "_TZ3000_xxx",
        "model": "IASSensor",
        "device_id": "0x0402",
        "in_clusters": ["0500", "0001"],
        "out_clusters": []
      },
      "match": {
        "profile": "ias_sensor",
        "confidence": "high",
        "reasons": ["cluster:0500"]
      },
      "capabilities": {
        "ias_zone": true,
        "battery": true
      },
      "connectivity": {
        "online": true,
        "last_seen_ts": "2026-04-05T10:30:00Z"
      },
      "state": {},
      "telemetry": {
        "zone_status": 1,
        "extended_status": 0,
        "zone_id": 0,
        "delay_qs": 0,
        "battery_voltage_100mv": 28,
        "battery_percentage_half_pct": 160
      },
      "last_event": {
        "type": "ias_zone_change",
        "ts": "2026-04-05T10:30:00Z",
        "active": true
      },
      "last_command": null
    }
  }
}
```

#### Notes

- This is read-only in the current design.
- Higher-level business semantics such as `motion`, `contact_open`, `gas_alarm`, or `leak_alarm` should be derived above this layer unless you add a stable model classification table.
- This profile is the default shadow representation for IAS-backed motion, contact, gas, and leak devices from the H2 supported-device list.
- If a contact sensor is exposed only through Binary Input rather than IAS Zone, add a dedicated match rule or profile later instead of forcing it into the wrong semantics.

### 8.7 `multi_sensor`

#### Match

- any combination of:
  - `0402` temperature
  - `0405` humidity
  - `0400` illuminance
  - `0001` power config
  - `0500` IAS zone

#### Capabilities

```json
{
  "temperature": true,
  "humidity": true,
  "illuminance": true,
  "battery": true,
  "ias_zone": true
}
```

#### Shadow Example

```json
{
  "state": {
    "desired": {
      "state": {}
    },
    "reported": {
      "schema_version": 1,
      "identity": {
        "ieee": "00158d0001222222",
        "ep": 1,
        "nwk": "0x7188",
        "mfr": "_TZ3000_xxx",
        "model": "MultiSensor",
        "device_id": "0x0402",
        "in_clusters": ["0402", "0405", "0400", "0001", "0500"],
        "out_clusters": []
      },
      "match": {
        "profile": "multi_sensor",
        "confidence": "high",
        "reasons": [
          "cluster:0402",
          "cluster:0405",
          "cluster:0400",
          "cluster:0001",
          "cluster:0500"
        ]
      },
      "capabilities": {
        "temperature": true,
        "humidity": true,
        "illuminance": true,
        "battery": true,
        "ias_zone": true
      },
      "connectivity": {
        "online": true,
        "last_seen_ts": "2026-04-05T10:30:00Z"
      },
      "state": {},
      "telemetry": {
        "temperature_centi_c": 2350,
        "humidity_centi_pct": 5025,
        "illuminance_raw": 12345,
        "battery_voltage_100mv": 29,
        "battery_percentage_half_pct": 180,
        "zone_status": 0
      },
      "last_event": null,
      "last_command": null
    }
  }
}
```

#### Notes

- Keep this profile read-only.
- If `reported.capabilities` is published, the UI or backend can still render sub-features from it.
- This profile is the default shadow representation for temperature, humidity, barometric, illuminance, and combined environmental sensors from the H2 supported-device list.
- If a PIR/mmWave device also reports environmental telemetry, it may be represented as `multi_sensor` instead of plain `ias_sensor`.

### 8.8 `button_remote`

#### Match

- `model` starts with `TS004`
- or endpoint looks like an On/Off switch controller endpoint

#### Capabilities

```json
{
  "button_events": true,
  "bindings": true
}
```

#### Shadow Example

```json
{
  "state": {
    "desired": {
      "state": {}
    },
    "reported": {
      "schema_version": 1,
      "identity": {
        "ieee": "00158d0001333333",
        "ep": 2,
        "nwk": "0x2301",
        "mfr": "_TZ3000_aj4etlbk",
        "model": "TS0044",
        "device_id": "0x0000",
        "in_clusters": ["0006", "E000"],
        "out_clusters": []
      },
      "match": {
        "profile": "button_remote",
        "confidence": "high",
        "reasons": ["model:TS0044"]
      },
      "capabilities": {
        "button_events": true,
        "bindings": true
      },
      "connectivity": {
        "online": true,
        "last_seen_ts": "2026-04-05T10:30:00Z"
      },
      "state": {},
      "telemetry": {},
      "last_event": {
        "type": "button_action",
        "action": "double",
        "ts": "2026-04-05T10:30:00Z"
      },
      "last_command": null
    }
  }
}
```

#### Binding Command Example

```json
{
  "state": {
    "desired": {
      "command": {
        "id": "bind-20260405-001",
        "op": "bind",
        "args": {
          "cluster": "onoff",
          "target_shadow": "dev_00158d0001bbbbbb_ep1"
        },
        "issued_at": "2026-04-05T10:30:00Z"
      }
    }
  }
}
```

#### Supported Command Ops

- `bind`
- `unbind`
- `clear_bindings`

#### Control Mapping

- `bind` -> H2 `CMD_BIND_DEVICES`
- `unbind` -> H2 `CMD_REMOVE_BINDING`
- `clear_bindings` -> H2 `CMD_CLEAR_BINDINGS`

### 8.9 Planned Next-Stage Specialization Profiles

The profiles in this section are not part of the first implementation. They are the recommended additive extensions for the four intentional gaps documented earlier.

### 8.9.1 `ac_thermostat`

#### Match

- endpoint has AC or HVAC model classification
- and thermostat semantics are present on the endpoint

#### Capabilities

```json
{
  "onoff": true,
  "hvac_mode": true,
  "local_temperature": true,
  "heat_setpoint": true,
  "cool_setpoint": true
}
```

#### Target State Shape

```json
{
  "power": 1,
  "mode": "cool",
  "local_temp_centi_c": 2650,
  "target_heat_centi_c": 2000,
  "target_cool_centi_c": 2400
}
```

#### Control Mapping

- `desired.state.power` -> H2 `CMD_ONOFF`
- `desired.state.mode` -> future thermostat mode write on H2
- `desired.state.target_heat_centi_c` -> future thermostat heat setpoint write on H2
- `desired.state.target_cool_centi_c` -> future thermostat cool setpoint write on H2

#### Notes

- Do not overload `onoff_actuator` with thermostat fields once a real HVAC-capable profile is introduced.
- Keep this profile disabled until the bridge can read thermostat attributes and write setpoints end-to-end.
- If only power control is available, keep the device on `onoff_actuator`.

### 8.9.2 `garage_barrier`

#### Match

- endpoint has garage-opener model classification
- and barrier-control semantics are present on the endpoint

#### Capabilities

```json
{
  "open_close": true,
  "stop": true,
  "barrier_state": true
}
```

#### Target State Shape

```json
{
  "door_state": "closed",
  "target_door_state": "closed",
  "obstruction_detected": false
}
```

#### Command Shape

```json
{
  "id": "cmd-20260405-garage-stop-001",
  "op": "stop",
  "args": {},
  "issued_at": "2026-04-05T10:30:00Z"
}
```

#### Control Mapping

- `desired.state.target_door_state = open|closed` -> future barrier open/close write on H2
- `desired.command.op = stop` -> future barrier stop command on H2

#### Notes

- Keep relay-style garage devices on `onoff_actuator`; use `garage_barrier` only when the endpoint exposes real barrier semantics.
- `door_state` should be one of `open`, `closed`, `opening`, `closing`, `stopped`, or `unknown`.
- Add obstruction or contact fields only when they can be reported reliably by the device.

### 8.9.3 `contact_sensor`

#### Match

- endpoint exposes Binary Input semantics
- and the device is classified as a door/window contact sensor

#### Capabilities

```json
{
  "contact": true,
  "battery": true
}
```

#### Target State Shape

```json
{
  "open": false
}
```

#### Event Shape

```json
{
  "type": "contact_change",
  "open": false,
  "ts": "2026-04-05T10:30:00Z"
}
```

#### Notes

- This profile is read-only.
- Use `contact_sensor` for explicit door/window semantics instead of forcing Binary Input devices into generic `ias_sensor`.
- IAS-backed contact sensors may remain on `ias_sensor` until the specialization rule is fully enabled.

### 8.9.4 `safety_sensor`

#### Match

- device is classified by model table as `gas` or `leak`
- or dedicated non-IAS safety semantics are exposed on the endpoint

#### Capabilities

```json
{
  "alarm": true,
  "battery": true,
  "tamper": true
}
```

#### Target State Shape

```json
{
  "alarm_active": false
}
```

#### Identity Extension

```json
{
  "safety_kind": "gas"
}
```

#### Event Shape

```json
{
  "type": "alarm_change",
  "alarm_active": true,
  "alarm_kind": "gas",
  "ts": "2026-04-05T10:30:00Z"
}
```

#### Notes

- This profile is read-only.
- `reported.identity.safety_kind` should be `gas` or `leak`.
- Keep generic or unknown IAS alarm devices on `ias_sensor`; enable `safety_sensor` only when the model classification is stable enough for UI and automation logic.

## 9. Validation Rules

The bridge should reject writes under these conditions:

1. `desired.state` contains fields that are not allowed by the local profile table or capability registry
2. `desired.command.op` is not supported by the profile
3. required command args are missing
4. target shadow in a binding command cannot be resolved to a valid endpoint
5. endpoint shadows receive gateway-admin operations such as `permit_join`, `remove_device`, `reboot`, `ota_start`, `ota_abort`, or `bulk_maintenance`
6. writes target a next-stage specialization profile whose required classifier or H2 capability is not enabled yet

If Stage 3 command support is not implemented yet, reject `desired.command` at the router layer instead of partially handling it.

On rejection, update `reported.last_command` with:

- `status = failed`
- an explicit `error.code`
- an explicit `error.message`

## 10. Recommended Error Codes

Use a stable small set:

- `unsupported`
- `invalid_args`
- `device_offline`
- `target_not_found`
- `timeout`
- `transport_error`
- `execution_failed`

## 11. Recommended Next Step

Use this document as the contract for:

1. bridge-side shadow creation
2. cloud-side device UI rendering
3. cloud-side desired state writes
4. bridge-side validation and command routing

The next concrete implementation task should be to turn the Stage 1 profiles, `onoff_actuator` and `dimmable_light`, into code-side validation tables in the S3 bridge layer first, and only then add the later stages.
