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
