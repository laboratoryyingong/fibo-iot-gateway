# Fibo Gateway App

Flutter app for a Zigbee gateway dashboard with device management, pairing flow, and basic account authentication.

**Modules**
- Auth: splash, login, sign up, forgot password (pixel-calibrated against `design/auth.pen`)
- Gateway Onboarding: onboarding entry, discovery, bind, list, detail, status
- Home Profile: home, menu, edit profile, members
- Pairing: start, searching, device found, success (pixel-calibrated against `design/device-pairing.pen`)
- Scenes: list, detail, trigger/action builder
- Camera: list, live view, add NVR, channels, playback, settings
- Spaces (WIP): spaces overview, all rooms, room detail, all devices, new room, device control (`design/space.pen` - 300/301/304/305/306/307/308/309/310/313/314/315)
  - Current state source: in-memory interactive mock store (`lib/screens/space_models.dart`, `SpaceMockStore`)

**Tech Stack**
- Flutter
- Parse Server SDK (`parse_server_sdk_flutter`)
- image picker (`image_picker`)
- SVG rendering (`flutter_svg`)

**Project Structure**
- `fibo_gateway_app/lib/screens/`: UI screens
- `fibo_gateway_app/lib/services/`: Parse config
- `fibo_gateway_app/lib/theme/`: colors and typography
- `fibo_gateway_app/lib/widgets/`: shared components
- `fibo_gateway_app/design/`: `.pen` design source
- `fibo_gateway_app/docs/`: token exports and UI calibration references
- `fibo_gateway_app/scripts/`: helper scripts (token export)

**Design Sources**
- `design/fibo-gateway-app.pen`: baseline app pages
- `design/auth.pen`: auth flow UI
- `design/device-pairing.pen`: pairing flow UI
- `design/token.pen`: style guidance and token extraction source

**Design Tokens**
- Auth tokens: `lib/theme/auth_tokens.dart`
- Pairing tokens: `lib/theme/pairing_tokens.dart`
- Exported token docs:
  - `docs/token-style-guidance.tokens.json`
  - `docs/token-style-guidance.tokens.md`
  - `docs/device-pairing.tokens.json`

**Token Export (for pixel calibration)**
```bash
cd fibo_gateway_app
./scripts/export_token_pen_tokens.sh
```

Optional custom input/output:
```bash
cd fibo_gateway_app
./scripts/export_token_pen_tokens.sh design/token.pen docs/token-style-guidance.tokens.json
```

**Local Parse Config**
This project expects a local-only Parse config file that is ignored by git.

1. Copy `fibo_gateway_app/lib/services/parse_config.example.dart` to `fibo_gateway_app/lib/services/parse_config.local.dart`
2. Fill in your real `serverUrl`, `appId`, and `clientKey` values

Note: `parse_config.local.dart` is gitignored on purpose.
Security: never copy Parse `MASTER_KEY` or dashboard credentials into Flutter client code.

**Parse Dashboard (redacted)**
- URL: `<REDACTED_DASHBOARD_URL>`
- User: `<REDACTED_USER>`
- Password: `<REDACTED_PASSWORD>`

**Run**
```bash
cd fibo_gateway_app
flutter pub get
flutter run
```

**Quality Checks**
```bash
cd fibo_gateway_app
flutter analyze
flutter test
```

**Navigation**
- `/gateway/*` -> gateway onboarding and management flow
- `/home` -> unified purple home/profile entry
- `/home/profile/*` -> profile menu, edit, and members flow
- `/home/scenes` -> scenes list from the new home flow
- `/device-detail` -> device control alias to the purple spaces control page
- `/pairing/*` -> pairing flow screens
- `/scenes/*` -> scenes flow screens
- `/camera/*` -> camera center screens
- `/spaces` -> spaces overview screen (WIP)
- `/spaces/devices` -> all devices screen (WIP)
- `/spaces/device-control` -> device control screen by type (WIP)
- `/spaces/new-room` -> new room screen (WIP)
- `/spaces/rooms` -> all rooms screen (WIP)
- `/spaces/room-detail` -> room detail screen (WIP)

**Post-login Entry**
- After splash/login, the app now checks whether the current Parse user has a linked gateway.
- If no gateway is linked, the app routes to `/gateway/onboarding`.
- If a gateway is linked, the app routes to the unified purple home at `/home`.
- Legacy aliases `/user/home` and `/user/device-detail` still resolve to the new purple pages for compatibility.

**Security**
- Do not commit secrets or credentials
- Use `parse_config.local.dart` for local-only settings
- Never use Parse `MASTER_KEY` in mobile app code
