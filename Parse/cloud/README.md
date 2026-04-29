# Parse Cloud Code

Current exported Cloud Functions:

1. `getAwsIotSession`
2. `listHomeGraph`
3. `assignDeviceToSpace`
4. `getSceneDetail`
5. `upsertScene`

Entrypoint:

- `Parse/cloud/main.js`

Current status:

1. Authorization and app-domain data loading are implemented as Cloud Code skeletons.
2. `getAwsIotSession` currently returns authorization scope and AWS bootstrap metadata from environment configuration.
3. Real Cognito developer-auth token issuance and temporary AWS credential exchange are still TODO.

Required environment variables are documented in:

- `Parse/.env.example`
- `Parse/AWS-Parse.md`
