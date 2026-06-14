@AGENTS.md

# CLAUDE.md

This file defines how coding agents should work in this repository so delivery stays consistent, safe, and production-oriented.

## 1. Project Scope

- Repository purpose: Zigbee gateway app development with Flutter UI and Parse backend integration.
- Primary app: `fibo_gateway_app/`
- Supporting backend scripts/docs: `Parse/`
- License: Apache 2.0 (`LICENSE`)

## 2. Repository Map

- `fibo_gateway_app/lib/main.dart`: app entry, Parse initialization, and named route registry.
- `fibo_gateway_app/lib/screens/`: screen-level UI.
- `fibo_gateway_app/lib/widgets/`: reusable UI components.
- `fibo_gateway_app/lib/theme/`: design tokens and theme system.
- `fibo_gateway_app/lib/services/`: service/config bridge (Parse config).
- `fibo_gateway_app/design/`: `.pen` design source.
- `fibo_gateway_app/docs/`: internal progress and design-implementation audit docs.
- `fibo_gateway_app/scripts/`: token export and design helper scripts.
- `Parse/`: Parse-related scripts and deployment notes.

## 3. Local Setup Rules

Before running app/test/analyze, ensure local Parse config exists:

1. Copy `fibo_gateway_app/lib/services/parse_config.example.dart`
2. Create `fibo_gateway_app/lib/services/parse_config.local.dart`
3. Fill `serverUrl`, `appId`, and `clientKey` (client key only, never master key)

Do not commit `parse_config.local.dart` (already ignored).

## 4. Non-Negotiable Security Rules

- Never commit secrets, credentials, API keys, dashboard passwords, or database auth.
- Never place Parse `MASTER_KEY` in Flutter client code.
- Never copy values from `Parse/.env` into Flutter app source.
- Any file containing plaintext secrets must be redacted immediately and rotated outside git.
- If a secret leak is detected, stop feature work and raise it as a priority security incident.

## 5. Development Workflow for Agents

1. Read first:
   - `fibo_gateway_app/README.md`
   - `fibo_gateway_app/lib/main.dart`
   - Relevant files under `lib/screens`, `lib/widgets`, `lib/theme`
2. Make minimal scoped changes only for the requested task.
3. Preserve existing visual language:
   - Colors from `AppColors`
   - Typography from `AppTextStyles` / `AuthTextStyles` / pairing tokens
   - Theme wiring in `AppTheme` and dedicated token files (`auth_tokens.dart`, `pairing_tokens.dart`)
4. If adding screen:
   - Create `*_screen.dart` in `lib/screens`
   - Register route in `lib/main.dart`
   - Ensure navigation paths are valid from existing flows
5. If adding shared UI:
   - Prefer `lib/widgets` reusable component over duplicated screen code
   - For auth/pairing, prefer shared widgets in `lib/widgets/auth_*` and `lib/widgets/pairing_*`
6. Keep business logic out of build trees as much as possible; extract helpers/services when complexity grows.

## 6. Coding Standards

- Language: Dart (Flutter), null-safe.
- Naming:
  - Screens: `PascalCase` class + `*_screen.dart`
  - Widgets: `PascalCase` class + semantic filename
  - Constants/tokens: centralized under `lib/theme`
- Avoid hardcoded design values when a token/style exists.
- Keep files focused; avoid mixing routing, data access, and presentation in one place.
- For pixel-calibration work, put constants in token files instead of inline literal values.

## 7. Quality Gates (Required Before Finalizing Work)

Run from `fibo_gateway_app/`:

```bash
flutter analyze
flutter test
```

Do not claim green quality checks unless command output is verified in current branch.

## 8. UI and Product Consistency

- The project is design-driven from:
  - `fibo_gateway_app/design/fibo-gateway-app.pen`
  - `fibo_gateway_app/design/auth.pen`
  - `fibo_gateway_app/design/device-pairing.pen`
  - `fibo_gateway_app/design/token.pen`
- Keep style consistency with existing implementation:
  - Primary color `#FF8400`
  - Background `#F2F3F0`
  - General app fonts: `JetBrains Mono`, `Geist`
  - Auth/Pairing flow fonts: `Manrope` (and `Inter` where explicitly specified)
- When implementing new modules, match spacing/radius/typography conventions already used in current screens.

## 9. Pixel Calibration Workflow

When asked for "像素级校准" or design parity:

1. Use the relevant `.pen` source under `fibo_gateway_app/design/`.
2. Update token files under `lib/theme/` first.
3. Reuse or extract shared widgets under `lib/widgets/`.
4. If token data needs refresh, run:
   - `cd fibo_gateway_app`
   - `./scripts/export_token_pen_tokens.sh`
5. Validate with:
   - `flutter analyze`
   - `flutter test`

## 10. Documentation Maintenance

When scope changes materially, update:

- `fibo_gateway_app/README.md` for architecture or setup changes.
- `fibo_gateway_app/docs/ui-progress-report.md` when screen coverage changes.
- Token export docs in `fibo_gateway_app/docs/` when token source changes.

## 11. Commit and Review Expectations

- Prefer small, reviewable commits grouped by feature/fix.
- Commit messages should be explicit (`feat:`, `fix:`, `refactor:`, `test:`, `docs:`).
- In PR/change summary, include:
  - What changed
  - Why
  - Validation commands and outcomes
  - Follow-up items or risks

---

If any rule conflicts with an explicit user request, follow the user request but call out risk and tradeoffs clearly.
