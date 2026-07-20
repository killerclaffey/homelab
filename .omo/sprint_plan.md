# Sprint Plan: OKD Homelab Hardening & GitOps Consensus

## Executive Summary
This sprint plan outlines the structured SDLC tasks to resolve security vulnerabilities, auto-unseal circular dependencies, secret hygiene inconsistencies, and ArgoCD GitOps tracking for the OKD 4.22 homelab cluster (`api.okd.claffey.cloud`).

---

## Sprint Goals
1. **Security & Least-Privilege**: Eliminate circular trust in Vault auto-unseal, audit Vault policy scoping, and enforce OpenShift Restricted Pod Security Standards.
2. **GitOps Integrity & Compliance**: Standardize secret placeholders (`REPLACE_ME`) per `AGENTS.md`, optimize ArgoCD sync options, and establish clean declarative drift detection.
3. **CSI & Infrastructure Hygiene**: Validate `tns-csi` WebSocket driver readiness in preparation for TrueNAS 26 REST API removal.

---

## Epics & User Stories

### Epic 1: Vault & Secret Management Hardening (Security)
* **STORY-1.1: Restrict Vault Kubernetes Auth Policy Scope**
  * *Description*: Restrict the Vault `external-secrets` policy and `argocd` role from wildcard access down to explicit paths (`secret/data/homelab/*`).
  * *Task*: Update Vault policy via CLI / config map and set short token TTLs (1h default, 4h max).
  * *Status*: Ready for Worker
* **STORY-1.2: Cloud KMS or BWS Auto-Unseal Evaluation & Setup**
  * *Description*: Replace local K8s secret auto-unseal sidecar with AWS KMS (`seal "awskms"`) or Bitwarden Secrets Manager (BWS) machine tokens to eliminate the circular trust model.
  * *Task*: Draft KMS configuration or BWS integration; remove plain unseal keys from K8s environment variables.
  * *Status*: Ready for Worker

### Epic 2: GitOps Compliance & Repository Hygiene (SDLC)
* **STORY-2.1: Secret Placeholder Standardizing (`AGENTS.md` Rule #2)**
  * *Description*: Standardize all secret manifest placeholders across the repo to `REPLACE_ME`.
  * *Files to Update*:
    * `kubernetes/bikely/base/secret.yaml` (change `PLACEHOLDER` -> `REPLACE_ME`)
    * `kubernetes/tns-csi/secret.yaml` (change `REDACTED_API_KEY` -> `REPLACE_ME`)
  * *Status*: Ready for Worker
* **STORY-2.2: ArgoCD Sync Options & Tracking Optimization**
  * *Description*: Add `SkipDryRunOnMissingResource=true` and `RespectIgnoreDifferences=true` across ArgoCD app definitions in `kubernetes/argocd/applications/` to prevent false degraded states for CRDs and injected status fields.
  * *Files to Update*: `kubernetes/argocd/applications/*.yaml`
  * *Status*: Ready for Worker

### Epic 3: OpenShift Security & Storage Readiness
* **STORY-3.1: Enforce Pod Security Standards on Vault Namespace**
  * *Description*: Label the `vault` namespace with explicit restricted Pod Security Standards.
  * *File to Update*: `kubernetes/vault/base/namespace.yaml`
  * *Status*: Ready for Worker
* **STORY-3.2: TrueNAS CSI WebSocket Migration Verification**
  * *Description*: Audit `tns-csi` vs `truenas-csi` side-by-side status to prepare for TrueNAS 26 REST API deprecation.
  * *Status*: Ready for Worker

---

## Execution Instructions for Worker Session
To execute this plan, start a worker session (e.g. `/start-work`) referencing `.omo/sprint_plan.md`.
