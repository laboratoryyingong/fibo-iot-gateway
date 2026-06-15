# Deploy: live IoT shadow auth (`getAwsIotSession`)

The app reads/controls `fibo-hub-001` shadows over MQTT-WSS using temporary AWS
credentials from Cognito. For **production (per-user, read+control)** the Parse
server must mint a developer-auth token. The **dev path** (guest, read-only) in
the app needs none of this — set `IotConfig.useGuestIdentity = true`.

## Already provisioned in AWS (account 407802776533, ap-southeast-2)
- Cognito Identity Pool: `ap-southeast-2:286dcf12-333c-4226-b7bf-691f0e0d3ac0`
  (developer provider `parse.fibo.user`)
- IAM roles: `fibo-app-iot-auth` (read+control), `fibo-app-iot-unauth` (read-only)
- **AWS IoT policy `fibo-app-iot-policy`** — authenticated Cognito identities
  need an IoT policy attached to the identity (in addition to the IAM role) to
  access shadows; the cloud function attaches it per user. (Verified end-to-end:
  read + control both work once attached.)
- IAM user `fibo-parse-server` — the Parse server's credentials
  (`GetOpenIdTokenForDeveloperIdentity` + `iot:AttachPolicy`).

> NOTE: The stack is self-hosted via `Parse/docker-compose.yml`. The Parse
> Dashboard CANNOT deploy Cloud Code — it goes onto the server running Docker.
> The compose `parse` service was NOT loading cloud code before; the volume
> mount + `PARSE_SERVER_CLOUD` have now been added.

Run everything below **on the host that runs `docker compose` for this stack**
(the box your `DOMAIN` points at). Get the updated repo there first
(`git pull` / `scp` / `rsync`).

## 1. Install the cloud dependency (creates `cloud/node_modules`)
The `:ro` volume mount expects `node_modules` to exist on the host. `@aws-sdk`
is pure JS, so a host install works inside the Linux container.
```
cd Parse/cloud && npm install
```

## 2. Add to `Parse/.env` (note the region — pool is in ap-southeast-2)
```
FIBO_AWS_REGION=ap-southeast-2
FIBO_AWS_IDENTITY_POOL_ID=ap-southeast-2:286dcf12-333c-4226-b7bf-691f0e0d3ac0
FIBO_AWS_IDENTITY_PROVIDER=parse.fibo.user
FIBO_IOT_POLICY_NAME=fibo-app-iot-policy
AWS_ACCESS_KEY_ID=<fibo-parse-server key>
AWS_SECRET_ACCESS_KEY=<secret>
```

## 3. Server AWS credentials permission
The `fibo-parse-server` IAM user (already created) holds these — no action
needed unless you rotate the key. Its permissions:
```json
{ "Effect": "Allow",
  "Action": "cognito-identity:GetOpenIdTokenForDeveloperIdentity",
  "Resource": "arn:aws:cognito-identity:ap-southeast-2:407802776533:identitypool/ap-southeast-2:286dcf12-333c-4226-b7bf-691f0e0d3ac0" }
{ "Effect": "Allow", "Action": ["iot:AttachPolicy"], "Resource": "*" }
```

## 4. Recreate the Parse container (picks up the cloud mount + env)
```
cd Parse
docker compose up -d parse
docker compose logs -f parse        # confirm it boots with cloud code, no errors
```
`getAwsIotSession` now returns `awsIdentity.identityId` + `awsIdentity.developerToken`.

## 5. Flip the app to authenticated mode
In `fibo_gateway_app/lib/services/iot_config.dart` set:
```dart
static const bool useGuestIdentity = false;
```
The app then calls `getAwsIotSession` (requires a signed-in Parse user whose
gateway/home resolves to `fibo-hub-001`) and connects with the **read+control**
role.

## 5b. Populate Parse structure from the gateway (Route A)
The app's Spaces/Home/Scenes read *structure* from Parse (`Space` +
`DeviceEndpoint`) and overlay *live state* from the shadow. After deploying,
run `syncGatewayInventory` **once** (as an installer/admin user) to import the
gateway's rooms + devices from its `admin` shadow into Parse:
```
curl -X POST "$BASE/functions/syncGatewayInventory" \
  -H "X-Parse-Application-Id: $APPID" -H "X-Parse-Session-Token: $SESSION" \
  -H "Content-Type: application/json" -d '{"homeId":"home-001"}'
```
- Requires: `@aws-sdk/client-iot-data-plane` (added; `npm install` covers it),
  and the `fibo-parse-server` user now also has `iot:GetThingShadow` (granted).
- Optional env (defaults to this account's endpoint):
  `FIBO_IOT_DATA_ENDPOINT=a2y0p1i6czv1i9-ats.iot.ap-southeast-2.amazonaws.com`
- Re-run any time devices/rooms change. It never overwrites a `displayName` or
  room a user customised in the app (those are set only on first import).
- Then `listHomeGraph` returns the rooms + devices.

## 6. Lock down the guest identity (before production)
The unauthenticated identity allows anyone with the pool id to read this hub's
shadows. Once auth is live, disable it:
```
aws cognito-identity update-identity-pool \
  --identity-pool-id ap-southeast-2:286dcf12-333c-4226-b7bf-691f0e0d3ac0 \
  --identity-pool-name fibo_app_pool \
  --no-allow-unauthenticated-identities --region ap-southeast-2
```
