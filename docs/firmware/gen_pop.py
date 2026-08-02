#!/usr/bin/env python3
"""FIBO hub PoP generator (factory tooling).

Formula:  pop = base32(HMAC-SHA256(FACTORY_KEY, serial))[:8], lowercase.

The factory key is read from the FIBO_FACTORY_KEY environment variable and
must NEVER be committed to git, embedded in firmware, or shipped in the app.
Anyone holding the key can derive every device's PoP.

Usage:
  export FIBO_FACTORY_KEY='...'          # from your secrets manager
  python3 gen_pop.py FIBO-24EC4A1A9E4A   # prints pop + QR label JSON
  python3 gen_pop.py FIBO-24EC4A1A9E4A --qr my-hub-qr.png
"""
import base64
import hashlib
import hmac
import json
import os
import sys


def derive_pop(factory_key: str, serial: str) -> str:
    digest = hmac.new(
        factory_key.encode(), serial.strip().upper().encode(), hashlib.sha256
    ).digest()
    return base64.b32encode(digest).decode().lower()[:8]


def ble_name_from_serial(serial: str) -> str:
    # Serial embeds the full BT MAC (FIBO-<12 hex>); the advertising name is
    # FIBO- + the last 3 bytes.
    mac_hex = serial.strip().upper().removeprefix("FIBO-")
    return f"FIBO-{mac_hex[-6:]}"


def main() -> None:
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    serial = sys.argv[1].strip().upper()
    key = os.environ.get("FIBO_FACTORY_KEY", "")
    if not key:
        sys.exit("Set FIBO_FACTORY_KEY first (never hardcode it).")

    pop = derive_pop(key, serial)
    label = {
        "v": 1,
        "sn": serial,
        "ble": ble_name_from_serial(serial),
        "pop": pop,
    }
    print("serial :", serial)
    print("ble    :", label["ble"])
    print("pop    :", pop)
    print("label  :", json.dumps(label, separators=(",", ":")))

    if "--qr" in sys.argv:
        out = sys.argv[sys.argv.index("--qr") + 1]
        import qrcode

        qrcode.make(json.dumps(label, separators=(",", ":"))).save(out)
        print("qr     :", out)


if __name__ == "__main__":
    main()
