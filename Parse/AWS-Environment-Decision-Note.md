# Fibo IoT Gateway: AWS Environment Decision Note (P0-01)

**Task ID:** P0-01  
**Status:** Completed  
**Date:** 2026-02-22  
**Related Docs:**  
- `Parse/AWS-IoT-Architecture-Spec.md`  
- `Parse/AWS-IoT-Implementation-Checklist.md`

## 1. Decision Summary

| Area | Decision |
|---|---|
| AWS account strategy | Two-account model: one Non-Prod account (`dev` + `staging`) and one Prod account (`prod`) |
| AWS region strategy | Single primary region for V1: `us-east-1` for AWS IoT Core, Cognito Identity, and DynamoDB |
| Environment isolation | Resource names, IAM roles/policies, and data stores are isolated by `env` prefix/suffix |
| Multi-region | Not enabled in V1 (deferred) |
| OTA region rollout | Region-based rollout remains an application-level attribute (device/gateway metadata), independent of AWS multi-region deployment |

## 2. Account Strategy

## 2.1 Accounts

1. **Non-Prod Account**
   - Purpose: development, integration testing, staging validation.
   - Environments: `dev`, `staging`.
2. **Prod Account**
   - Purpose: production workloads only.
   - Environment: `prod`.

## 2.2 Why

1. Reduces blast radius between test and production.
2. Keeps operational complexity lower than a full 3-account model.
3. Supports a clean migration path to stricter multi-account governance later.

## 3. Region Strategy

## 3.1 Primary Region (V1)

- `us-east-1` for:
  1. AWS IoT Core
  2. Cognito Identity Pool
  3. DynamoDB (`fibo_iot_events_v1`)

## 3.2 Why

1. Simplifies direct-connect app implementation.
2. Keeps latency and infrastructure routing predictable for V1.
3. Minimizes cross-region operational overhead during initial rollout.

## 3.3 Deferred

1. Cross-region failover
2. Active-active regional architecture
3. Cross-region data replication for history

## 4. Environment Naming Baseline

Use explicit environment tags in all resource names:

1. IoT Thing: `gw_{gatewayId}` (logical), associated with env-tagged registry metadata.
2. IoT Topic prefix: `fibo/v1/{accountId}/{gatewayId}/...` with environment enforced by IAM policy scope.
3. DynamoDB:
   - Non-Prod: `fibo_iot_events_v1_nonprod`
   - Prod: `fibo_iot_events_v1_prod`
4. Cognito Identity Pool:
   - `fibo-iot-identity-nonprod`
   - `fibo-iot-identity-prod`

## 5. IAM and Access Boundary Rules

1. Mobile temporary credentials in non-prod cannot access prod IoT topics/shadows.
2. Prod credentials are issued only from prod Parse environment.
3. Gateway principals are scoped to their own gateway namespace.
4. Installer/User permissions remain role-based and constrained by shadow domain (`ctrl/cfg/state`).

## 6. Exit Criteria for P0-01

P0-01 is considered complete with the following locked:

1. Account split: **Non-Prod + Prod**.
2. Primary region: **`us-east-1`**.
3. V1 service placement: IoT Core + Cognito Identity + DynamoDB in same primary region.
4. Multi-region explicitly deferred to post-V1.

## 7. Next Task Enablement

This decision unblocks:

1. **P0-02** naming registry finalization.
2. **P1-01** Cognito Identity Pool creation.
3. **P8-01** DynamoDB table provisioning.

