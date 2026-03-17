## Zigbee Gateway (ESP32‑H2)

**Production‑oriented Zigbee Coordinator + persistent device database**, implemented on top of the **ESP Zigbee SDK** and ESP‑IDF.

The firmware runs as a Zigbee Coordinator, discovers joined devices (endpoints + clusters), keeps a durable device table in NVS, and exposes a simple UART protocol so a host can query devices and trigger actions.

---

## Main Features

- **Zigbee Coordinator**
  - Network formation and steering using ESP Zigbee BDB commissioning.
  - Primary channel mask configured via `GW_PRIMARY_CHANNEL_MASK` in `gateway.h`.
  - Automatic, periodic **permit‑join window** driven by a FreeRTOS timer.

- **Device discovery & ZCL**
  - ZDO **ActiveEP → SimpleDesc** discovery (`zbx.c`).
  - Parses Simple Descriptors, logs input/output clusters, and stores them in the device DB.
  - Handles key ZCL callbacks:
    - Read Attribute Responses (e.g. Basic cluster manufacturer/model).
    - Attribute Reports.
    - Default Responses (with error logging).

- **Persistent device database (`devdb.c`)**
  - In‑memory table `g_devs[ZB_DEV_MAX]` protected by a mutex.
  - NVS‑backed records keyed by IEEE address (preferred) or NWK, with CRC‑protected struct.
  - Deferred flush: dirty devices are written to NVS via a background flush task.
  - Aging model:
    - Tracks `last_seen_ms` and online/offline status.
    - Periodic aging timer marks devices offline after `DEV_OFFLINE_AFTER_MS`.
    - Purges long‑idle devices and removes their NVS records after `DEV_PURGE_AFTER_MS`.
  - Periodic dump task prints a human‑readable summary of all devices.

- **Host UART protocol (`h2_proto.c` + `app_main.c`)**
  - `app_main.c` configures a UART (pins/baud from `gateway.h`) and feeds RX bytes into the protocol parser.
  - Simple framed protocol (SOF + length + command + payload + CRC16) on top of the UART.
  - Current commands:
    - `0x01` – get device list (NWK + online flag for each known device).
    - `0x02` – bind/start discovery for a device (triggers ZDO ActiveEP/SimpleDesc and optional bind/config‑report).
    - `0x03` – On/Off: payload `[nwk, on]` or `[nwk, ep, on]` (switch, siren, AC power, garage door).
    - `0x04` – Permit-join: payload `[seconds]` (0 = close, 1–254 = open for N seconds).
    - `0x05` – Remove device: payload `[nwk_l, nwk_h]` (uint16 LE); coordinator sends leave request, DB updated on LEAVE signal.
    - `0x20` – Curtain / window covering: payload `[action, nwk, ep, percent]` — action 0=open, 1=close, 2=stop, 3=goto percent (0–100).
    - `0x21` – Smart lock: payload `[lock, nwk, ep]` — lock 1=lock, 0=unlock.
    - `0x22` – Level (dimmer, etc.): payload `[nwk, ep, level]` — level 0–254.
    - `0x10` – OTA start (begin firmware update with total size).
    - `0x11` – OTA chunk (send a data block at a given offset).
    - `0x12` – OTA finish (finalize OTA and reboot into new image).
    - `0x13` – OTA status (query OTA state and progress; response `CMD=0x93`).
  - Each command replies with an ACK (`0x80`), with a status byte (`0` on success).

- **Supported device types (control and sensors)**
  - **Switch / relay** – On/Off cluster (CMD `0x03`).
  - **PIR / mmWave / motion** – IAS Zone; reports via Attribute Reports (bind + CIE when `ZB_DISCOVERY_ONLY=0`).
  - **Curtain / window covering** – Window Covering cluster (CMD `0x20`: open, close, stop, goto percent).
  - **Smart lock** – Door Lock cluster (CMD `0x21`: lock/unlock).
  - **Temperature / humidity / barometric** – Temp, Humidity, Pressure clusters; reports via Attribute Reports (bind + config reporting).
  - **Light / illuminance sensor** – Illuminance Measurement cluster (0x0400); bind + configure reporting; reports via Attribute Reports.
  - **Contact / door‑window sensor** – IAS Zone or Binary Input; reports via Attribute Reports.
  - **Gas / leak sensor** – IAS Zone or specific clusters; reports via Attribute Reports.
  - **Siren** – On/Off cluster (CMD `0x03`).
  - **AC (power / unit)** – On/Off for power (CMD `0x03`); thermostat setpoints can be added later.
  - **Garage door** – On/Off or barrier cluster (CMD `0x03` for relay‑style open/close).
  - **Dimmer / level** – Level Control cluster (CMD `0x22`).

---

## Code Structure

```text
app_main.c
 ├─ Initialize NVS (required by Zigbee + device DB)
 ├─ Initialize and load device DB from NVS
 ├─ Start Zigbee gateway task
 ├─ Start periodic device dump task
 └─ Initialize H2 UART + protocol, start RX task

gateway.c
 ├─ Configure Zigbee platform (radio + host)
 ├─ Zigbee stack init and start (Coordinator config)
 ├─ BDB commissioning and network formation/steering
 ├─ ZDO signal handler (device announce, leave, permit‑join status, etc.)
 └─ Auto permit‑join periodic timer

zbx.c
 ├─ ZDO device discovery: ActiveEP → SimpleDesc
 ├─ Logs endpoints, clusters, and updates device DB
 ├─ Optional bind + configure reporting + IAS CIE write (when `ZB_DISCOVERY_ONLY == 0`)
 ├─ ZCL handlers: ReadAttrResp / Report / DefaultResp
 └─ Helper to send On/Off commands to devices (`zbx_onoff_send`)

devdb.c
 ├─ In‑memory device table (`g_devs`)
 ├─ NVS persistence layer (CRC‑protected records)
 ├─ Deferred flush timer and background flush task
 ├─ Aging timer (online → offline → purge)
 └─ Periodic dump task printing device list and clusters

h2_proto.c
 ├─ Simple UART frame protocol (SOF, length, cmd, payload, CRC16)
 ├─ Command dispatcher (devlist / bind / onoff)
 └─ Hooks into device DB and Zigbee helpers

ota.c
 ├─ Thin wrapper around ESP-IDF OTA APIs
 ├─ Tracks OTA state (idle/in-progress/error)
 ├─ Receives size + chunks from UART protocol
 └─ Commits new image and switches boot partition, then reboots
```

All modules share a single project header `gateway.h`, which defines common types, configuration macros (channels, UART pins, aging timings, etc.), and imports the ESP Zigbee/ESP‑IDF headers.

---

## Hardware & UART Setup

This firmware is intended for **ESP32‑H2** (or similar Zigbee‑capable targets configured via ESP‑IDF).

- **Radio / Zigbee:**
  - Zigbee radio and host are configured through `esp_zb_platform_config()` in `gateway_start()`.
  - Channel mask and coordinator capacity are configurable via macros in `gateway.h`.

- **Host UART:**
  - One UART is dedicated to the host protocol handled by `h2_proto.c`.
  - Pins, port and baud rate are defined in `gateway.h` (`H2_UART_PORT`, `H2_UART_TX_PIN`, `H2_UART_RX_PIN`, `H2_UART_BAUDRATE`).
  - `app_main.c` sets up UART, installs the driver, and starts a FreeRTOS task that reads bytes and feeds them into `h2_proto_feed()`.

Adapt the exact pin numbers and target chip configuration in `sdkconfig` / `gateway.h` to match your board.

---

## Build & Flash

From this project directory (with ESP‑IDF set up in your environment):

```bash
idf.py set-target <chip>     # e.g. esp32h2, esp32c6, etc.
idf.py build

# Flash and monitor
idf.py -p <PORT> erase-flash
idf.py -p <PORT> flash monitor
```

Exit monitor with `Ctrl+]`.

The partition table includes **OTA slots** (`ota_0`, `ota_1`); use the UART OTA commands to update firmware in the field. Rollback on boot failure is enabled via `CONFIG_BOOTLOADER_APP_ROLLBACK_ENABLE`.

---

## OTA over UART

The gateway exposes a very small OTA protocol on the same UART link used for the host protocol. The host is responsible for:

1. Fetching the new firmware image (e.g. over the internet),
2. Streaming it to the gateway using the commands below,
3. Handling retries / resume if the link is unstable.

### OTA States

Internally, the firmware tracks:

- `0` – **idle** (no OTA in progress),
- `1` – **in_progress** (OTA session active),
- `2` – **error** (last OTA operation failed).

You can query these via the **OTA STATUS** command.

### OTA Commands

All OTA commands use the same UART frame format as other commands:

```text
SOF (0xAA)
LEN_L
LEN_H                # LEN = 1 (CMD) + payload bytes
CMD
PAYLOAD...
CRC_L, CRC_H         # CRC16 over LEN_L, LEN_H, CMD, PAYLOAD...
```

#### 0x10 – OTA START

- **Direction**: Host → Gateway  
- **Payload**:
  - `[0..3]` `total_size` (uint32, little endian) – total firmware image size in bytes.
- **ACK**:
  - `0` – OK, OTA session started.
  - `1` – error (no OTA partition, esp_ota_begin failed, or OTA already active).

Sequence:

1. Host sends 0x10 with the full image size.
2. Gateway locates the next OTA partition and calls `esp_ota_begin()`.

#### 0x11 – OTA CHUNK

- **Direction**: Host → Gateway  
- **Payload**:
  - `[0..3]` `offset` (uint32, little endian) – byte offset within the firmware image.
  - `[4..]` raw firmware bytes.
- **ACK**:
  - `0` – chunk written successfully.
  - `1` – error (OTA not in progress or esp_ota_write failed).

Notes:

- `offset` is currently used for sanity checks; writes are expected to be sequential.
- Chunk size is limited by the UART frame size (`RX_BUF_MAX`).

#### 0x12 – OTA FINISH

- **Direction**: Host → Gateway  
- **Payload**: none  
- **ACK**:
  - `0` – accepted; gateway will:
    - call `esp_ota_end()`,
    - call `esp_ota_set_boot_partition()` for the new image,
    - log completion and **reboot** into the new firmware.
  - `1` – error (OTA not in progress or esp_ota_end / set_boot_partition failed).

After a successful 0x12, the device will reboot; the host should expect the UART link to drop.

#### 0x13 – OTA STATUS

- **Direction**: Host → Gateway  
- **Payload**: none  
- **ACK**:
  - Always `0` (request accepted).
- **Follow‑up frame**:
  - Gateway sends a separate frame with `CMD=0x93` and payload:
    - `[0]` `state` (0=idle, 1=in_progress, 2=error),
    - `[1..4]` `expected_size` (uint32 LE),
    - `[5..8]` `written_size` (uint32 LE).

This lets the host monitor progress and decide when/if to retry or abort.

---

## Typical Use Cases

- **Zigbee → Wi‑Fi / IP bridge backend**, with a separate host MCU or SoC speaking the UART protocol.
- **Smart home hub firmware base**, where you want a robust coordinator + device DB and will build your own application logic on the host side.
- **Matter bridge backend** that needs a stable view of Zigbee devices and clusters.
- **Industrial or custom gateway** where reliability of device tracking and persistence is more important than UI.

---

## Testing

A **Python test script** exercises the UART protocol (frame build/parse, CRC, and optional serial tests against a running device):

```bash
pip install pyserial
python tests/test_gateway_protocol.py --unit-only           # no device
python tests/test_gateway_protocol.py -p /dev/ttyUSB0       # with device
pytest tests/test_gateway_protocol.py -v
```

Set `GW_TEST_PORT` instead of `-p` for automation. Use `--no-ota` to skip OTA-related serial tests (e.g. to avoid touching OTA state).

---

## Summary

This firmware provides a **commercial‑ready Zigbee Coordinator** with:

- Automatic network formation and **host‑controlled permit‑join** (pairing mode).
- **Persistent, aging‑aware device database** and **immediate removal** on LEAVE or host remove command.
- **UART protocol** for devlist, bind, on/off, permit‑join, remove device, OTA (start/chunk/finish/status).
- **OTA partitions** and rollback on boot failure, plus **task watchdog** for the UART path.

Extend by adding commands in `h2_proto.c`, ZCL logic in `zbx.c`, and tuning aging/persistence in `devdb.c`.
