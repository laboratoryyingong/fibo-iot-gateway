# Fibo Gateway App

Flutter app for a Zigbee gateway dashboard with device management, pairing flow, and basic account authentication.

**Modules**
- Auth: splash, login, sign up, forgot password
- Dashboard: home overview, quick access, metrics
- Devices: list, detail
- Network: status overview
- Settings: gateway and system sections
- Pairing: start, searching, device found, success
- Scenes: list, detail, trigger/action builder
- Camera: list, live view, add NVR, channels, playback, settings
- User Role: user dashboard, devices, device detail, scenes, settings

**Tech Stack**
- Flutter
- Parse Server SDK (`parse_server_sdk_flutter`)

**Project Structure**
- `fibo_gateway_app/lib/screens/`: UI screens
- `fibo_gateway_app/lib/services/`: Parse config
- `fibo_gateway_app/lib/theme/`: colors and typography
- `fibo_gateway_app/lib/widgets/`: shared components
- `fibo_gateway_app/design/`: `.pen` design source

**Local Parse Config**
This project expects a local-only Parse config file that is ignored by git.

1. Copy `fibo_gateway_app/lib/services/parse_config.example.dart` to `fibo_gateway_app/lib/services/parse_config.local.dart`
2. Fill in your real `serverUrl`, `appId`, and `clientKey` values

Note: `parse_config.local.dart` is gitignored on purpose.

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

**Navigation**
- `/home` -> bottom tabs: Home, Devices, Scenes, Network, Settings
- `/user/home` -> user bottom tabs: Home, Devices, Scenes, Settings
- `/device-detail` -> device detail page (no footer)
- `/pairing/*` -> pairing flow screens
- `/scenes/*` -> scenes flow screens
- `/camera/*` -> camera center screens

**Security**
- Do not commit secrets or credentials
- Use `parse_config.local.dart` for local-only settings
