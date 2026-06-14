// Template Claude agent configuration.
// Copy this file to `agent_config.local.dart` and edit values.
//
// Platform notes:
//   - iOS simulator       -> http://localhost:3000
//   - Android emulator    -> http://10.0.2.2:3000  (10.0.2.2 = host machine)
//   - Real device (LAN)   -> http://<your-LAN-IP>:3000
//   - iOS device + plain HTTP also requires an NSAppTransportSecurity
//     exception in Info.plist; Android needs `usesCleartextTraffic="true"`.
//   - Production must terminate TLS in front of the agent.
const String baseUrl = 'http://localhost:3000';

// Shared secret for the agent's `Authorization: Bearer <key>` header. Leave
// empty when the server runs open (no API_KEY set). NEVER commit a real key —
// this file's local copy is gitignored. See APP-INTEGRATION.md §2 & §7.
const String apiKey = '';

// Set true to drive the Spaces dashboard from the live REST device API
// (/devices, /control, ...) instead of the bundled mock store. Requires a
// reachable baseUrl. See APP-INTEGRATION.md §4.
const bool useLiveDevices = false;
