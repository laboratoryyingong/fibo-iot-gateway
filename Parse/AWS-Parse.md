# Parse Secrets Reference (Sanitized)

Do not store real credentials in repository files.

Use environment variables from local secure storage or a secret manager.

Local setup:

1. Copy `Parse/.env.example` to `Parse/.env`.
2. Fill all `REPLACE_WITH_*` values locally.
3. Never commit `Parse/.env`.

Required variables:

- `PARSE_APP_ID=REPLACE_WITH_PARSE_APP_ID`
- `PARSE_MASTER_KEY=REPLACE_WITH_PARSE_MASTER_KEY`
- `PARSE_FILE_KEY=REPLACE_WITH_PARSE_FILE_KEY`
- `MONGO_ROOT_USER=REPLACE_WITH_MONGO_ROOT_USER`
- `MONGO_ROOT_PASS=REPLACE_WITH_MONGO_ROOT_PASS`
- `MONGO_PARSE_USER=REPLACE_WITH_MONGO_PARSE_USER`
- `MONGO_PARSE_PASS=REPLACE_WITH_MONGO_PARSE_PASS`
- `DASHBOARD_USER=REPLACE_WITH_DASHBOARD_USER`
- `DASHBOARD_PASS=REPLACE_WITH_DASHBOARD_PASS`

Cloud Code AWS bootstrap variables:

- `FIBO_AWS_REGION=us-east-1`
- `FIBO_AWS_IDENTITY_POOL_ID=REPLACE_WITH_COGNITO_IDENTITY_POOL_ID`
- `FIBO_AWS_IDENTITY_PROVIDER=parse.fibo.user`
- `FIBO_AWS_DEVELOPER_TOKEN_MODE=todo`
- `FIBO_IOT_TOPIC_PREFIX_BASE=fibo/v1`

Notes:

1. `FIBO_AWS_DEVELOPER_TOKEN_MODE=todo` means the current Cloud Code only returns the identity bootstrap shape and authorization scope; it does not yet mint real Cognito developer tokens or temporary AWS credentials.
2. When Cognito developer-authenticated identities are wired in, replace the placeholder mode with a real token issuance path in `getAwsIotSession`.
