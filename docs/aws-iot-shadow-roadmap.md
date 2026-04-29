# AWS IoT Shadow Integration Roadmap

## 1. What This Document Solves

This repository already has the foundations for Zigbee device discovery, control, persistence, and local hardware integration, but it does not yet have a complete end-to-end chain for "cloud digital twin -> local bridge -> Zigbee device execution".

The goal of this document is to:

- explain the current state of the project clearly,
- propose an AWS IoT Shadow architecture that fits this repository,
- break the work down into executable phases that we can implement step by step.

## 2. Conclusions After Reviewing the Project

### 2.1 There Are Currently 3 Main Tracks in the Repository

1. `esp32h2_zigbee_gateway`
   This is the most mature core on the device side. It already implements:
   - Zigbee Coordinator startup and network commissioning
   - device discovery, Simple Descriptor parsing, and Basic cluster info reads
   - persistent device storage in NVS
   - online/offline device tracking
   - a host UART protocol
   - On/Off, Level, Color, Curtain, and Lock controls
   - OTA over UART

2. `s3_matter_bridge`
   This is the best candidate to evolve into the cloud-connected gateway board. It already has:
   - W5500 Ethernet support
   - LVGL display and UI foundations
   - UART validation code
   - button input handling

   But it is still only a scaffold. Most initialization in `app_main` is commented out, so it is not yet a real bridge application.

3. `ili9488_spi`
   This is a standalone LCD demo project, not the core path for remote cloud control.

### 2.2 Key Code-Level Observations

1. H2 is already the Zigbee control plane.
   - Zigbee startup and host UART are in [esp32h2_zigbee_gateway/main/app_main.c](../esp32h2_zigbee_gateway/main/app_main.c)
   - Zigbee control entry points are in [esp32h2_zigbee_gateway/main/gateway.c](../esp32h2_zigbee_gateway/main/gateway.c)
   - the device database and state cache are in [esp32h2_zigbee_gateway/main/devdb.c](../esp32h2_zigbee_gateway/main/devdb.c)
   - the host serial protocol is in [esp32h2_zigbee_gateway/main/h2_proto.c](../esp32h2_zigbee_gateway/main/h2_proto.c)

2. S3 is not yet the cloud bridge plane.
   - The current `app_main` only prints `system started`; the real UI, Ethernet, and UART initialization are not enabled:
     [s3_matter_bridge/main/app_main.c](../s3_matter_bridge/main/app_main.c)
   - The current UART logic is only a `Hello H2` echo test:
     [s3_matter_bridge/main/uart_echo.c](../s3_matter_bridge/main/uart_echo.c)
   - The W5500 Ethernet code is already reusable:
     [s3_matter_bridge/main/eth_w5500.c](../s3_matter_bridge/main/eth_w5500.c)

3. The repository contains two bridge protocol ideas, but only one is actually implemented.
   - The real protocol in use is the H2 binary UART protocol:
     [esp32h2_zigbee_gateway/main/h2_proto.c](../esp32h2_zigbee_gateway/main/h2_proto.c)
   - There is also a JSON-line protocol prototype, but it is not connected to the main execution path:
     [s3_matter_bridge/components/bridge_proto/bridge_proto.h](../s3_matter_bridge/components/bridge_proto/bridge_proto.h)

4. There is currently no AWS IoT, MQTT, or Shadow integration code in the repository.

### 2.3 The Most Important Gaps Right Now

These gaps directly affect the Shadow design:

1. H2 has IEEE addresses internally, but the host protocol does not expose them to S3 in a stable way.
   - `zb_device_t` already includes `ieee[8]`:
     [esp32h2_zigbee_gateway/main/gateway.h](../esp32h2_zigbee_gateway/main/gateway.h)
   - But `CMD_DEVLIST` and `CMD_DEVLIST_INFO` mainly expose `nwk_addr`, online state, manufacturer, and model:
     [esp32h2_zigbee_gateway/main/h2_proto.c](../esp32h2_zigbee_gateway/main/h2_proto.c)

2. The current control path mainly targets devices by `nwk_addr`, but `nwk_addr` is not the right cloud-side primary key.
   - Zigbee short addresses can change after a device rejoins the network.
   - Shadow naming and cloud-side device identity should be anchored to IEEE.

3. S3 does not yet have a local digital twin layer.
   - No local device registry
   - no desired/reported state machine
   - no router that translates cloud delta updates into UART commands

## 3. Recommended Target Architecture

### 3.1 Overall Principle

The recommended model is the following separation of responsibilities. Do not put AWS directly on H2 in the first stage.

- `ESP32-S3` is responsible for:
  - Ethernet or Wi-Fi connectivity
  - TLS and MQTT
  - AWS IoT Thing identity
  - Device Shadow synchronization
  - local UI
  - bridging to H2

- `ESP32-H2` is responsible for:
  - Zigbee Coordinator duties
  - device discovery and interview
  - device control execution
  - sensor, button, and alarm event reporting
  - the local Zigbee device database

- `Zigbee child devices` do not connect to AWS directly.

This is the most natural evolution path for the current repository because:

1. S3 already has the network and UI foundations, so it is the natural cloud gateway.
2. H2 already owns the Zigbee execution layer, so there is no need to add TLS and MQTT there.
3. The responsibility boundary between cloud and device becomes cleaner and easier to debug.

### 3.2 Recommended AWS Resource Model

Use the model "one Hub Thing + multiple named shadows".

#### Thing

- One Thing per S3 gateway
- Suggested `thingName` pattern:
  - `fibo-hub-001`
  - `fibo-hub-<mac-or-serial>`

#### Shadows

Use only named shadows. Do not mix classic and named shadows.

At minimum, define these three types:

1. `hub`
   - Stores the gateway's own state
   - Examples: firmware version, online status, network status, H2 link status, Zigbee network status, device count

2. `admin`
   - Stores gateway and Zigbee network administration commands
   - Examples: `permit_join`, `remove_device`, later `reboot` and OTA-style operations

3. `dev_<ieeehex>_ep<ep>`
   - One named shadow per Zigbee endpoint
   - Example: `dev_00158d0001aaaaaa_ep1`

Benefits:

- Cloud-side device identity is stable and not tied to short addresses.
- Business control and gateway/network administration stay cleanly separated.
- A single Thing can naturally contain multiple Zigbee child devices and multi-endpoint devices.
- This scales better for permissions, indexing, and device management later.

AWS documentation also recommends named shadows when you need multiple state views, instead of starting with a classic shadow and migrating later.

References:

- AWS IoT Device Shadow service  
  https://docs.aws.amazon.com/iot/latest/developerguide/iot-device-shadows.html
- Device Shadow MQTT topics  
  https://docs.aws.amazon.com/iot/latest/developerguide/device-shadow-mqtt.html

### 3.3 Recommended Data Flow

```text
Mobile App / Web / Backend Service
          |
          v
      AWS IoT Core
          |
          | Device Shadow desired/reported
          v
      ESP32-S3 Hub
    (MQTT/TLS + Shadow Sync + Local Twin)
          |
          | UART binary protocol
          v
  ESP32-H2 Zigbee Gateway
          |
          v
      Zigbee Child Devices
```

Control path:

1. The cloud writes `desired` state into a `dev_<ieeehex>_ep<ep>` shadow.
2. S3 receives the `/update/delta`.
3. S3 looks up the local registry and resolves `ieee + ep -> nwk/capability`.
4. S3 converts the delta into an H2 UART command.
5. H2 executes the Zigbee control operation.
6. H2 returns the control result or status event.
7. S3 updates the local twin and writes back `reported`.

State path:

1. A Zigbee device reports new state.
2. H2 updates `devdb`.
3. H2 sends an asynchronous event to S3.
4. S3 updates the local twin.
5. S3 writes throttled updates into the shadow `reported` state.

Admin path:

1. The cloud writes `desired.command` into the `admin` shadow.
2. S3 validates the requested operation and resolves any target device by `ieee` or `target_shadow`.
3. S3 converts the operation into an H2 admin command such as `PERMIT_JOIN` or `REMOVE_DEVICE`.
4. H2 executes the network administration action.
5. S3 writes `admin.reported.last_command`.
6. If the device inventory changed, S3 updates or deletes the affected endpoint shadows.

## 4. Shadow Design Recommendations

### 4.1 `hub` Shadow

The `hub` shadow should store only gateway health and bridge health. It should not contain the full business state of every child device.

Suggested `reported` example:

```json
{
  "state": {
    "reported": {
      "fw_version": "s3-0.1.0",
      "eth": {
        "link": true,
        "ip": "192.168.1.10"
      },
      "cloud": {
        "connected": true,
        "last_connect_ts": "2026-04-05T10:30:00Z"
      },
      "h2": {
        "connected": true,
        "protocol_version": 2
      },
      "zigbee": {
        "coordinator_ready": true,
        "device_count": 23,
        "permit_join_open": false
      }
    }
  }
}
```

### 4.2 `admin` Shadow

Use a separate named shadow for gateway and Zigbee network administration. Do not mix these operations into endpoint business shadows.

### 4.2.1 Admin MVP Structure

Use this smaller idle structure for the first implementation:

```json
{
  "state": {
    "reported": {
      "schema_version": 1,
      "pairing": {
        "open": false
      }
    }
  }
}
```

MVP rules:

1. In steady state, keep only `reported.pairing.open` plus `reported.schema_version`.
2. Add `reported.ota`, `reported.maintenance`, and `reported.last_command` only when an operation is active or there is a meaningful result to retain.
3. Omit `desired` entirely when no admin command is pending.
4. Do not add `last_joined_device` or `last_removed_device` in the first implementation.
5. Support only one active admin operation at a time.
6. `reported.ota` is operation-centric, not per-controller. The active target is recorded in `reported.ota.target`.
7. `reported.maintenance` is operation-centric. The active or most recent maintenance action is represented by `current_action` and `last_result`.
8. For a resource-limited MCU, the compact idle `admin` shadow should stay under about `128` bytes.

### 4.2.2 Later Optional Admin Fields

These may be added later after the MVP is stable:

- `last_joined_device`
- `last_removed_device`
- per-target detailed OTA status
- richer maintenance history

Suggested command examples:

Open pair mode:

```json
{
  "state": {
    "desired": {
      "command": {
        "id": "admin-20260405-001",
        "op": "permit_join",
        "args": {
          "seconds": 60
        },
        "issued_at": "2026-04-05T10:30:00Z"
      }
    }
  }
}
```

Remove a paired device:

```json
{
  "state": {
    "desired": {
      "command": {
        "id": "admin-20260405-002",
        "op": "remove_device",
        "args": {
          "target_ieee": "00158d0001aaaaaa"
        },
        "issued_at": "2026-04-05T10:32:00Z"
      }
    }
  }
}
```

Reboot a controller:

```json
{
  "state": {
    "desired": {
      "command": {
        "id": "admin-20260405-003",
        "op": "reboot",
        "args": {
          "target": "s3"
        },
        "issued_at": "2026-04-05T10:35:00Z"
      }
    }
  }
}
```

Start OTA:

```json
{
  "state": {
    "desired": {
      "command": {
        "id": "admin-20260405-004",
        "op": "ota_start",
        "args": {
          "target": "h2",
          "artifact_id": "h2-0.2.0"
        },
        "issued_at": "2026-04-05T10:40:00Z"
      }
    }
  }
}
```

Run bulk maintenance:

```json
{
  "state": {
    "desired": {
      "command": {
        "id": "admin-20260405-005",
        "op": "bulk_maintenance",
        "args": {
          "action": "refresh_inventory"
        },
        "issued_at": "2026-04-05T10:45:00Z"
      }
    }
  }
}
```

Admin rules:

1. Treat "pair" as `permit_join`, not as a child-device business state change.
2. Treat "unpair" as `remove_device`, not as a child-device business state change.
3. Use `target_ieee` or `target_shadow` for cloud-side targeting. Do not use `nwk` as the cloud-side identifier.
4. S3 should resolve `target_ieee` to the current `nwk` before sending H2 `REMOVE_DEVICE`.
5. `reboot`, `ota_start`, `ota_abort`, and `bulk_maintenance` also belong in the `admin` shadow.
6. When no admin command is pending, omit `desired.command`.
7. After `remove_device` succeeds, S3 should delete all endpoint shadows that belong to the removed IEEE address.
8. OTA binary chunks, logs, and large payloads must not be carried in the shadow document. Use the shadow only for intent, metadata, and progress/status.
9. For a resource-limited MCU, prefer a short `artifact_id` in `ota_start` and resolve URI, checksum, and size through a local manifest or backend lookup.
10. Long-running operations should update `reported.ota`, `reported.maintenance`, and `reported.last_command` as progress changes.
11. The first implementation should keep admin status operation-centric. Do not model per-target OTA subtrees until there is a concrete need.

Supported `admin` ops:

- `permit_join`
- `remove_device`
- `reboot`
- `ota_start`
- `ota_abort`
- `bulk_maintenance`

Suggested bulk maintenance actions:

- `reinterview_all_devices`
- `reinterview_offline_devices`
- `refresh_inventory`
- `remove_offline_devices`

Implementation note:

- H2 OTA already has a UART command surface in the current codebase
- `reboot` and some bulk maintenance actions may require new bridge-side or host-side commands before they can be executed end-to-end
- the first supported `bulk_maintenance.action` should be `refresh_inventory`
- `refresh_inventory` is the best MVP because it maps to the existing inventory read path and does not require destructive behavior
- on the current codebase, `refresh_inventory` should run a bridge-side inventory sync using H2 `GET_DEVLIST` and `GET_DEVLIST_INFO`
- the first admin reported-state model should remain intentionally small; add richer history only after the control loop is stable

### 4.3 Minimal `dev_<ieeehex>_ep<ep>` Shadow

Do not start with the full final contract.

For the first cloud-connected version, keep the child shadow as small as possible and support only the simplest controllable device types:

- `onoff_actuator`
- `dimmable_light`

Recommended structure for the first delivery:

```json
{
  "state": {
    "reported": {
      "schema_version": 1,
      "identity": {
        "ieee": "00158d0001aaaaaa",
        "ep": 1,
        "model": "TS0505B"
      },
      "connectivity": {
        "online": true
      },
      "state": {
        "power": 1
      }
    }
  }
}
```

Design rules:

1. First delivery should implement only `onoff_actuator` and `dimmable_light`.
2. First delivery steady state should publish only `reported.identity.ieee`, `reported.identity.ep`, `reported.identity.model`, `reported.connectivity.online`, and `reported.state`.
3. `desired.state` should be treated as transient. It should appear only while a write is pending and should be deleted after `reported.state` converges.
4. Keep `reported.match`, `reported.capabilities`, `reported.identity.nwk`, cluster lists, and `connectivity.last_seen_ts` local to the bridge registry unless a cloud consumer truly needs them.
5. Do not add `desired.command`, `reported.telemetry`, `reported.last_event`, or `reported.last_command` in the first delivery.
6. `nwk` is only a runtime property; `ieee + ep` is the stable identity.
7. Later stages may only add fields. Do not rename or move the core fields above.

### 4.3.1 MCU Resource Budget

Measured against the fixture set on `2026-04-05`:

- current `onoff_actuator` fixture: `527` bytes compact
- current `dimmable_light` fixture: `653` bytes compact
- current `admin` fixture: `585` bytes compact
- lean `onoff_actuator` steady state: about `193` bytes compact
- lean `dimmable_light` steady state: about `212` bytes compact
- lean idle `admin` shadow: about `103` bytes compact

Recommended MCU-side budgets:

- endpoint steady-state shadow: target `<= 256` bytes compact
- endpoint pending-write shadow: target `<= 320` bytes compact
- idle `admin` shadow: target `<= 128` bytes compact
- active `admin` command/update payload: target `<= 512` bytes compact
- bridge JSON RX/TX buffer planning budget for the MVP: `1024` bytes per shadow message

Runtime guidance:

- subscribe to `/update/delta` on MCU by default; do not keep `/update/documents` enabled outside debug builds
- do not publish empty objects or `null` placeholders just to preserve a schema shape
- do not mirror the whole shadow document in RAM; keep fixed local structs and serialize on demand

### 4.4 Recommended Expansion Order

After the minimal version is stable, extend the child shadow in this order:

1. Simple remote control
   - `onoff_actuator`
   - `dimmable_light`
   - writable fields: `power`, `level`

2. Richer state and read-only devices
   - `color_light`
   - `door_lock`
   - `ias_sensor`
   - `multi_sensor`
   - add `reported.telemetry` and `reported.last_event` only where needed

3. Command-style operations
   - `curtain`
   - `button_remote`
   - add `desired.command` and `reported.last_command`

4. Operational flows outside the main business shadow
   - permit-join
   - remove device
   - reboot
   - OTA
   - bulk maintenance actions

5. Semantic specialization profiles after the generic rollout is stable
   - `ac_thermostat`
   - `garage_barrier`
   - `contact_sensor`
   - `safety_sensor`
   - add them only when the bridge has reliable cluster or model classification for those devices

### 4.5 Operations That Fit Shadow Well

- power on/off
- brightness
- color temperature and color
- curtain target position
- lock state
- mirrored sensor state

### 4.6 Operations That Should Not Live in the Main Business Shadow

These are better placed in the `admin` shadow first, and some of the larger or longer-running ones may later migrate to AWS IoT Jobs:

- OTA upgrade
- device reboot
- permit-join window control
- device removal
- bulk re-interview
- large diagnostic tasks

AWS IoT Jobs documentation:  
https://docs.aws.amazon.com/iot/latest/developerguide/iot-jobs.html

## 5. Concrete Changes Recommended for the Current Codebase

### 5.1 Capabilities That Must Be Added on the H2 Side First

This is the highest priority, because without a stable device identity model, Shadow integration becomes awkward immediately.

#### A. Extend the Host Protocol to Expose Stable Device Identity to S3

Add a new device inventory command, for example:

- `CMD_GET_DEVLIST_V2`

At minimum it should return:

- IEEE
- NWK
- endpoint list
- input/output clusters
- manufacturer/model
- online
- capability flags

Reason:

- `devdb` already has this information internally.
- The host side simply cannot build stable shadows without it.

#### B. Add Device Lifecycle Asynchronous Events

Add host-side async events such as:

- `DEVICE_JOINED`
- `DEVICE_UPDATED`
- `DEVICE_LEFT`
- `DEVICE_ONLINE`
- `DEVICE_OFFLINE`

That way S3 does not need to poll the entire inventory frequently.

#### C. Clarify Control ACK Semantics

The current H2 control path already has a control-confirmation capability, which is good for Shadow convergence. But some comments still reflect older "queued" semantics.

The recommendation is to standardize this as:

- `ACK=0` means the control request has been confirmed successfully
- `ACK=1` means failure, timeout, or invalid parameters

#### D. Keep Admin Targeting Stable on the Cloud Side

The current H2 `REMOVE_DEVICE` command targets `nwk`, but the cloud side should not use `nwk` as the primary identifier.

Recommendation:

- the `admin` shadow should target a device by `target_ieee` or `target_shadow`
- S3 should resolve that target into the current `nwk` using the local registry
- later, if needed, add a host-side `REMOVE_DEVICE_BY_IEEE` style command so the bridge no longer depends on runtime address translation for unpair

#### E. Add Admin Operations Beyond Pair/Unpair

To support the full `admin` shadow contract, the bridge side should plan for these capabilities:

- `reboot`
  - S3 reboot can be handled locally on the bridge side
  - H2 reboot may require a new host-side command if direct reboot is needed later
- `ota_start` and `ota_abort`
  - H2 already has an OTA command surface over UART
  - the shadow should carry OTA intent and metadata, not firmware chunks
- `bulk_maintenance`
  - likely requires new bridge-side workflows and, for some actions, new host-side commands
  - the first supported action can be read-only or low-risk, such as `refresh_inventory` or `reinterview_offline_devices`

### 5.2 Modules Recommended on the S3 Side

Turn `s3_matter_bridge` into a real gateway application and split it into these layers:

1. `bridge_uart_client`
   - H2 binary protocol TX/RX
   - frame parsing, CRC, command sending, async event dispatch

2. `device_registry`
   - stores `ieee -> nwk/ep/model/capabilities`
   - persists it to NVS

3. `device_twin_store`
   - local digital twin store
   - manages desired / reported / dirty flags / last_error

4. `aws_iot_transport`
   - TLS, MQTT, and auto-reconnect
   - subscribes and publishes AWS shadow topics

5. `shadow_router`
   - handles `/get/accepted`
   - handles `/update/delta`
   - handles `/update/accepted` and `/update/rejected`

6. `control_mapper`
   - translates shadow desired state into H2 commands
   - translates H2 events into shadow reported state

7. `ui_presenter`
   - the local screen reads only the local twin and does not talk directly to the cloud protocol

### 5.3 Directions That Are Not Recommended

1. Do not put AWS directly on H2 in the first phase.
2. Do not continue with the JSON-line prototype as the main protocol.
3. Do not use `nwk_addr` as the cloud-side device ID.
4. Do not put OTA, binding, operations, and business control into the same shadow from day one.

## 6. Phased Implementation Roadmap

### Phase 0: Freeze the Protocol and Identity Model

Goal:

- confirm that S3 is the only cloud endpoint
- define `thingName`
- define `shadowName`
- define `ieee` as the primary key for Zigbee child devices

Deliverables:

- this document
- a shadow field draft
- an H2 protocol extension draft

Acceptance criteria:

- the team has no ambiguity about the model "one Hub Thing + multiple named shadows"

### Phase 1: Build the Real S3 <-> H2 Bridge

Goal:

- S3 no longer uses echo mode
- S3 can read the real H2 device inventory and asynchronous events

Tasks:

1. Add `DEVLIST_V2` on H2
2. Add `bridge_uart_client` on S3
3. Build an `ieee -> nwk/ep` registry on S3
4. Perform an inventory sync at boot

Acceptance criteria:

- S3 can print the full device inventory after boot
- when a device rejoins and its NWK changes, S3 still recognizes it as the same device

### Phase 2: Build the Local Digital Twin

Goal:

- make the desired/reported state machine work locally first

Tasks:

1. Add `device_twin_store` on S3
2. Feed H2 asynchronous events into the local twin
3. Route local control through the twin first, then through the mapper into H2
4. Make the UI render directly from the twin

Acceptance criteria:

- even without AWS connected, the local system can still summarize state and write back control results

### Phase 3: Integrate AWS IoT Core and the Hub Shadow

Goal:

- connect the gateway itself to the cloud first

Tasks:

1. Add MQTT and TLS on S3
2. Integrate the `hub` named shadow
3. report gateway network state, H2 link state, and device count
4. implement reconnect and startup synchronization

Acceptance criteria:

- the `hub` shadow is visible and stable in the AWS console
- after cable unplug/replug or device reboot, the shadow recovers correctly

### Phase 4: Add Minimal Named Shadows for Child Devices

Goal:

- publish the smallest stable endpoint shadow first

Tasks:

1. Create or update `dev_<ieeehex>_ep<ep>` for `onoff_actuator` and `dimmable_light`
2. report only the lean steady-state fields: `reported.identity.ieee`, `reported.identity.ep`, `reported.identity.model`, `reported.connectivity.online`, and `reported.state`
3. keep the payload small and stable; do not add command or telemetry fields yet
4. keep shadow creation idempotent when `nwk` changes after rejoin

Acceptance criteria:

- when a supported device joins, the matching endpoint shadow appears in the cloud
- when a device rejoins and `nwk` changes, the same shadow is updated instead of creating a new one
- the cloud payload is small enough that the team can inspect it manually and debug it quickly

### Phase 5: Use Shadow for Simple Remote Control

Goal:

- the cloud changes simple target state and the physical device converges into `reported.state`

Tasks:

1. Subscribe to `/update/delta`
2. Accept only `desired.state.power` and `desired.state.level`
3. Translate those fields into H2 `CMD_ONOFF` and `CMD_LEVEL`
4. Write back `reported.state` on success
5. Keep failure handling simple at first; do not expand the schema just to carry command history

Topic behavior note:

- every successful shadow update causes `/update/accepted`
- every successful shadow update also causes `/update/documents`
- `/update/delta` is the control trigger and appears only when `desired` and `reported` differ

Acceptance criteria:

- changing `desired.state.power` in the AWS console changes the physical device
- changing `desired.state.level` in the AWS console changes a dimmable device
- `reported.state` eventually converges to the real device state

### Phase 6: Expand Profiles and Telemetry

Goal:

- add richer device types only after simple control is stable

Tasks:

1. Add `color_light` and `door_lock`
2. Add read-only `ias_sensor` and `multi_sensor`
3. Add `reported.telemetry` and `reported.last_event` only for profiles that need them
4. Keep all changes additive to the Phase 4 and Phase 5 contract

Acceptance criteria:

- richer profiles can be published without changing the existing `onoff_actuator` and `dimmable_light` payload shape
- sensor data and richer reported state are visible in the cloud

### Phase 7: Command-Style Operations and OTA

Goal:

- add one-shot operations and gateway administration without mixing them into the first business-state rollout

Tasks:

1. Add `desired.command` and `reported.last_command` for endpoint shadows that need one-shot operations
2. Add the `admin` shadow
3. Enable `curtain` actions and `button_remote` binding commands
4. Enable `permit_join` and `remove_device` through the `admin` shadow
5. Add `reboot` through the `admin` shadow
6. Add `ota_start` and `ota_abort` through the `admin` shadow using artifact metadata rather than binary chunks
7. Add `bulk_maintenance` through the `admin` shadow with `refresh_inventory` as the first supported action
8. Resolve `remove_device` targets by `target_ieee` or `target_shadow`, not by cloud-side `nwk`
9. After `remove_device` succeeds, delete the affected endpoint shadows
10. Keep larger or longer-running OTA and maintenance flows eligible for later migration to AWS IoT Jobs

Command-field note:

- when there is no pending one-shot command, omit `desired.command`
- use `null` only when intentionally deleting that property in a follow-up update

Acceptance criteria:

- the cloud can open and close permit-join through the `admin` shadow
- the cloud can remove a device by stable identity rather than by `nwk`
- the cloud can request bridge reboot through the `admin` shadow
- the cloud can start and abort OTA through the `admin` shadow without storing firmware chunks in shadow documents
- the cloud can run `bulk_maintenance.action = refresh_inventory` through the `admin` shadow
- after a device is removed, its endpoint shadows are also removed from the cloud

### Phase 8: Add Specialized Profiles for the Remaining Device Gaps

Goal:

- close the remaining semantic gaps without breaking the earlier generic profile rollout

Tasks:

1. Add `ac_thermostat` for AC or HVAC endpoints that expose thermostat semantics
2. Add `garage_barrier` for garage openers that expose barrier semantics rather than simple relay control
3. Add `contact_sensor` for Binary Input or otherwise explicitly classified door/window contact devices
4. Add `safety_sensor` for model-classified gas and leak sensors
5. Keep `onoff_actuator` as the fallback for AC power-only devices and relay-style garage devices
6. Keep `ias_sensor` as the fallback for unclassified IAS contact, gas, or leak devices
7. Add any required bridge-side classifier table or inventory metadata needed to distinguish these specializations reliably
8. Add any required H2 protocol support for thermostat mode/setpoint writes and barrier-specific control before enabling cloud writes for those profiles

Acceptance criteria:

- AC devices with thermostat semantics no longer need to be overloaded onto `onoff_actuator`
- barrier-style garage devices expose `door_state` and `target_door_state` rather than plain `power`
- Binary Input contact devices expose `state.open`
- gas and leak devices expose stable semantic identity through `safety_kind`
- devices that cannot yet be classified reliably continue to work through the older generic profiles

## 7. What I Recommend We Do Next

Start with Phase 1, not with AWS code.

The reasoning is straightforward:

1. S3 still cannot read complete and stable device identity data.
2. Without a real local bridge client, Shadow integration has nowhere reliable to land.
3. If we first complete the H2 <-> S3 bridge, the later AWS work becomes stable instead of forcing repeated model redesign.

## 8. Immediate Next Implementation Items

The next eight concrete tasks should be:

1. Extend the H2 inventory protocol to return IEEE + endpoints + clusters + manufacturer/model
2. Replace `uart_echo` on S3 with a real H2 protocol client
3. Add a local `device_registry` on S3
4. Build a serial inventory dump first to validate that S3 can read the full Zigbee topology
5. Freeze the minimal Phase 4 child-shadow contract for `onoff_actuator` and `dimmable_light` before adding any richer profiles
6. Freeze the `admin` shadow contract for `permit_join`, `remove_device`, `reboot`, `ota_start`, `ota_abort`, and `bulk_maintenance`
7. Freeze `bulk_maintenance.action = refresh_inventory` as the first supported admin maintenance action before building a larger workflow set
8. Design the classifier and H2 capability additions needed for the future `ac_thermostat`, `garage_barrier`, `contact_sensor`, and `safety_sensor` profiles before enabling them in shadow

## 9. Official AWS References

- Device Shadow service  
  https://docs.aws.amazon.com/iot/latest/developerguide/iot-device-shadows.html
- Device Shadow MQTT topics  
  https://docs.aws.amazon.com/iot/latest/developerguide/device-shadow-mqtt.html
- Using shadows in devices  
  https://docs.aws.amazon.com/iot/latest/developerguide/device-shadow-comms-device.html
- UpdateThingShadow API  
  https://docs.aws.amazon.com/iot/latest/apireference/API_iotdata_UpdateThingShadow.html
- Fleet provisioning by claim  
  https://docs.aws.amazon.com/iot/latest/developerguide/provision-wo-cert.html
- Device provisioning MQTT API  
  https://docs.aws.amazon.com/iot/latest/developerguide/fleet-provision-api.html
- AWS IoT Jobs  
  https://docs.aws.amazon.com/iot/latest/developerguide/iot-jobs.html
