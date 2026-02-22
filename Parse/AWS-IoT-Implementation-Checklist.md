# Fibo IoT Gateway: Implementation Checklist (V1)

**Status:** Ready to execute  
**Last Updated:** 2026-02-22  
**Companion Spec:** `Parse/AWS-IoT-Architecture-Spec.md`

## 1. How to Use This Checklist

1. Execute tasks in order by ID.
2. Mark `Status` as:
   - `[ ]` not started
   - `[-]` in progress
   - `[x]` done
3. Do not start a task until all dependencies are completed.
4. Each completed task must produce the listed output artifact.

## 2. Master Checklist Table

| ID | Phase | Task | Owner | Depends On | Output Artifact | Status |
|---|---|---|---|---|---|---|
| P0-01 | Preparation | Confirm AWS account/region strategy for IoT, Cognito, DynamoDB | Cloud | None | Environment decision note | [ ] |
| P0-02 | Preparation | Create naming registry for `accountId`, `gatewayId`, `deviceId` formats | Backend | P0-01 | Naming convention doc | [ ] |
| P0-03 | Preparation | Define topic/shadow prefix constants (`fibo/v1/...`) | Cloud | P0-02 | Topic constants file | [ ] |
| P1-01 | Identity | Create Cognito Identity Pool for developer-auth identities | Cloud | P0-01 | Identity Pool ID | [ ] |
| P1-02 | Identity | Configure IAM role for authenticated app users | Cloud | P1-01 | IAM role ARN | [ ] |
| P1-03 | Identity | Implement Parse Cloud Function `getAwsIotSession` | Backend | P1-01 | Cloud function code | [ ] |
| P1-04 | Identity | Validate Parse session and map `userType` + gateway access list | Backend | P1-03 | Auth mapping module | [ ] |
| P1-05 | Identity | Return temporary AWS credential payload contract to app | Backend | P1-04 | API response schema | [ ] |
| P1-06 | Identity | Integrate app flow to request/refresh Cognito credentials | Mobile | P1-05 | Credential provider service | [ ] |
| P2-01 | IoT Resource | Provision gateway Thing template (`gw_{gatewayId}`) | Cloud | P0-02 | Thing provisioning script | [ ] |
| P2-02 | IoT Resource | Define named shadow scheme (`dev_*_ctrl/cfg/state`) | Cloud | P2-01 | Shadow naming helper | [ ] |
| P2-03 | IoT Policy | Create installer IoT policy template | Cloud | P2-02 | `installer-policy.json` | [ ] |
| P2-04 | IoT Policy | Create user IoT policy template | Cloud | P2-02 | `user-policy.json` | [ ] |
| P2-05 | IoT Policy | Create gateway principal policy template | Cloud | P2-02 | `gateway-policy.json` | [ ] |
| P2-06 | IoT Policy | Add policy tests for forbidden writes (`user` -> `cfg`) | Cloud | P2-03,P2-04 | Access test report | [ ] |
| P3-01 | Contracts | Finalize command payload schema (`requestId`, `expiresAt`, `patch`) | Backend | P0-03 | JSON schema file | [ ] |
| P3-02 | Contracts | Finalize ACK payload schema (`accepted/rejected/expired`) | Backend | P3-01 | ACK schema file | [ ] |
| P3-03 | Contracts | Finalize shadow metadata fields (`_meta` keys) | Backend | P3-01 | Shadow contract doc | [ ] |
| P4-01 | Gateway Core | Subscribe gateway to command topic and shadow delta | Firmware | P3-01 | MQTT subscriber module | [ ] |
| P4-02 | Gateway Core | Implement command validation (role, schema, expiry) | Firmware | P4-01 | Validation module | [ ] |
| P4-03 | Gateway Core | Publish ACK to `.../ack/{requestId}` in <1s target | Firmware | P4-02 | ACK publisher module | [ ] |
| P4-04 | Gateway Core | Implement idempotency with `requestId` cache | Firmware | P4-02 | Idempotency store | [ ] |
| P4-05 | Gateway Core | Apply desired to device bus and update reported | Firmware | P4-03 | Device apply engine | [ ] |
| P4-06 | Gateway Core | Handle offline replay and expired desired skip | Firmware | P4-05 | Replay/expiry handler | [ ] |
| P5-01 | Mobile Core | Build IoT MQTT connection manager (connect/reconnect) | Mobile | P1-06 | IoT client service | [ ] |
| P5-02 | Mobile Core | Implement command sender with `requestId` and 5-min expiry | Mobile | P3-01,P5-01 | Command service | [ ] |
| P5-03 | Mobile Core | Implement ACK subscription + 1s timeout alert | Mobile | P3-02,P5-02 | ACK listener/UI alert | [ ] |
| P5-04 | Mobile Core | Subscribe and render final state from shadow reported | Mobile | P3-03,P5-01 | Shadow state store | [ ] |
| P5-05 | Mobile Core | Ensure app reconnect restores final state only | Mobile | P5-04 | Reconnect behavior test | [ ] |
| P6-01 | Scenes | Model scenes as target-state sets in backend/domain layer | Backend | P3-03 | Scene schema | [ ] |
| P6-02 | Scenes | Implement scene execution -> deterministic desired writes | Backend | P6-01 | Scene executor service | [ ] |
| P6-03 | Scenes | Enforce role rule: user execute only, installer create/update | Backend | P6-01 | Scene ACL tests | [ ] |
| P7-01 | OTA | Define `gw_ota` desired/reported schema | Firmware | P3-03 | OTA schema file | [ ] |
| P7-02 | OTA | Implement S3 package fetch and install lifecycle states | Firmware | P7-01 | OTA state machine | [ ] |
| P7-03 | OTA | Add region gate before OTA apply | Firmware | P7-02 | Region filter module | [ ] |
| P8-01 | History | Create DynamoDB table `fibo_iot_events_v1` + TTL | Cloud | P0-01 | IaC/table creation script | [ ] |
| P8-02 | History | Define IoT Rules from `events/*` topics to DynamoDB | Cloud | P8-01,P0-03 | IoT Rules config | [ ] |
| P8-03 | History | Standardize event envelope (`eventType`, actor, result, payload) | Backend | P8-02 | Event schema | [ ] |
| P8-04 | History | Add backend query APIs for cmd/state/alert/ota/audit | Backend | P8-03 | Query endpoints | [ ] |
| P9-01 | Testing | Build integration tests for installer/user permission boundaries | QA | P2-06,P5-03 | Permission test report | [ ] |
| P9-02 | Testing | Build E2E tests for ACK timeout and final-state convergence | QA | P4-05,P5-04 | E2E report | [ ] |
| P9-03 | Testing | Build failure tests: reconnect replay and expiry enforcement | QA | P4-06,P5-05 | Reliability report | [ ] |
| P10-01 | Release | Define observability dashboard (ACK latency, reject rate, offline replay) | Cloud | P9-01 | Monitoring dashboard | [ ] |
| P10-02 | Release | Run staging soak test with 100 sub-devices per gateway | QA | P10-01 | Soak test summary | [ ] |
| P10-03 | Release | Production readiness review and go-live checklist signoff | All | P10-02 | Go-live approval | [ ] |

## 3. Milestone Gates

| Milestone | Entry Criteria | Exit Criteria |
|---|---|---|
| M1: Identity Ready | P0 complete | P1 complete and app can get temporary credentials |
| M2: Secure IoT Control Plane | M1 complete | P2 + P3 complete and policies validated |
| M3: Functional Control Loop | M2 complete | P4 + P5 complete with ACK <1s in test |
| M4: Product Features | M3 complete | P6 + P7 complete with scene + OTA flows |
| M5: Production Data + Quality | M4 complete | P8 + P9 complete |
| M6: Go Live | M5 complete | P10 complete |

## 4. Weekly Execution Template

| Week | Planned IDs | Owner | Goal | Result |
|---|---|---|---|---|
| Week 1 | P0-01 to P1-06 | Backend/Cloud/Mobile | Identity and credentials flow online | [ ] |
| Week 2 | P2-01 to P4-03 | Cloud/Firmware | Secure control plane + ACK path | [ ] |
| Week 3 | P4-04 to P5-05 | Firmware/Mobile | Complete command loop and final-state UI | [ ] |
| Week 4 | P6-01 to P8-04 | Backend/Firmware/Cloud | Scenes, OTA, and history persistence | [ ] |
| Week 5 | P9-01 to P10-03 | QA/All | Validation, soak, and release signoff | [ ] |

## 5. Immediate Next 10 Tasks (Start Here)

| Priority | Task ID | Task | Status |
|---|---|---|---|
| 1 | P0-01 | Confirm AWS account/region strategy | [ ] |
| 2 | P0-02 | Lock ID naming conventions | [ ] |
| 3 | P1-01 | Create Cognito Identity Pool | [ ] |
| 4 | P1-03 | Implement Parse `getAwsIotSession` | [ ] |
| 5 | P1-06 | Integrate app credential retrieval | [ ] |
| 6 | P2-03 | Installer policy template | [ ] |
| 7 | P2-04 | User policy template | [ ] |
| 8 | P3-01 | Finalize command schema | [ ] |
| 9 | P4-03 | Gateway ACK publisher (<1s) | [ ] |
| 10 | P5-03 | App ACK timeout alert | [ ] |

