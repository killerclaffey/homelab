# Project Handoff & Architecture Context: Power Outage Hardening & GitOps Consensus

**Last Updated:** 2026-09-07  
**Branch / Target:** `main` (synchronized across GitLab `origin` and GitHub `github`)  
**Commit Baseline:** `87534b6`  

---

## 1. Executive Summary & Objectives

During a homelab power-outage hardening exercise and SDLC review of the OKD 4.22 bare-metal cluster (`api.okd.claffey.cloud`), several platform degradation events, security exposures, and GitOps divergence issues were diagnosed, audited, and resolved.

This document serves as the persistent architectural handoff for engineers and autonomous agents to resume work without losing operational context.

---

## 2. Cluster Architecture & Current Operational Status

### Node Inventory & Physical Roles
| Node | Hostname / IP | Physical Role | Hardware Model | Status | Notes |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `k81` | `10.0.20.100` | Control Plane + Worker | Bare Metal Master | `Ready` | Quorum healthy, boot gate applied |
| `k82` | `10.0.20.101` | Control Plane + Worker | Bare Metal Master | `Ready` | Quorum healthy, boot gate applied |
| `k83` | `10.0.20.102` | Control Plane + Worker | Bare Metal Master | `Ready` | Quorum healthy, boot gate applied |
| `k84` | `10.0.20.103` | Dedicated Compute Worker | Minisforum Mini PC | `NotReady,SchedulingDisabled` | Kubelet service deadlocked (see Section 3) |

### Cluster Operator Health
- **33 of 34 Cluster Operators** are fully healthy (`Available: True, Progressing: False, Degraded: False`).
- Core infrastructure operators (`etcd`, `kube-apiserver`, `openshift-apiserver`, `authentication`, `network`, `ingress`, `storage`, `image-registry`) are 100% operational.
- Only `machine-config` reports degraded (`ready: 3, unavailable: 1`) exclusively because `k84`'s MachineConfigDaemon pod cannot check in while Kubelet is stopped.

### GitOps State (ArgoCD)
- **All 26 ArgoCD Applications** are reporting `Synced Healthy` (daemons `monitoring` and `truenas-csi` in expected continuous `Progressing` mode).
- Target repo for ArgoCD is GitLab: `origin/main` (`gitlab.apps.okd.claffey.cloud:rclaffey/homelab.git`).

---

## 3. Worker Node `k84` Status & Recovery Runbook

### Root Cause Analysis (The MCO Bootstrap Trap)
1. **Initial Deployment:** The initial version of `99-worker-boot-network-gate` deployed to `k84` contained:
   - A shell syntax typo: `esleep 15` instead of `sleep 15` in `/usr/local/bin/kubelet-prestart-gate.sh`.
   - A strict systemd dependency: `RequiredBy=kubelet.service` in `kubelet-network-gate.service`.
2. **Reboot Failure:** When `k84` booted, `kubelet-network-gate.service` executed and failed with exit code 127 (`esleep: command not found`). Because `RequiredBy` establishes a hard dependency, systemd refused to start `kubelet.service`.
3. **The Catch-22 Loop:**
   - Because `kubelet` is stopped (TCP 10250 connection refused), Kubernetes cannot run any pods on `k84`.
   - The in-node `machine-config-daemon` pod cannot run.
   - Because MCD cannot run, `k84` cannot pull the corrected MachineConfig (`rendered-worker-ac49cd11...`) already waiting in the OKD API server (which contains `WantedBy=kubelet.service` and the fixed script).
   - Because `k84` was cordoned prior to reboot, it remains in `NotReady,SchedulingDisabled`.
   - `oc debug node/k84` cannot execute because debug containers require a functional `kubelet`.

### Recovery Procedure
SSH (TCP port 22) is open on `k84` (`10.0.20.103`). Per `99-worker-ssh`, the authorized key is:
`ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILcGsgLA9+5jZ8iaEzXlbyxp1VnAIgkRh5Kx2dkIqNQ/ rclaffey@Water3`

#### Execution from `Water3` Workstation (Holding the SSH Key)
Run the following single command:
```bash
ssh core@10.0.20.103 "sudo sed -i 's/esleep/sleep/' /usr/local/bin/kubelet-prestart-gate.sh && sudo systemctl restart kubelet"
```

#### Execution from Laptop (`fedora`)
If executing from the laptop, load the `Water3` private key first:
```bash
ssh-add /path/to/water3_private_key
ssh core@10.0.20.103 "sudo sed -i 's/esleep/sleep/' /usr/local/bin/kubelet-prestart-gate.sh && sudo systemctl restart kubelet"
```

#### Automated Post-Recovery Events (Expected Cascade)
1. Kubelet starts and posts node status to the API server; `k84` status transitions to `Ready`.
2. `machine-config-daemon-q24fv` pod starts on `k84`.
3. MCD pulls `rendered-worker-ac49cd11e52966a2f36d7345d7f47c11` containing `WantedBy=kubelet.service` and 240s watchdog timeout.
4. MCD applies the final config, verifies health, and uncordons `k84` (`SchedulingDisabled` clears).
5. `oc get mcp worker` transitions to `UPDATED=True`, clearing the final `machine-config` operator alert.

---

## 4. Remediation Audit Trail (Completed Tasks)

All items below were audited, fixed, verified by an independent adversarial review subagent, and committed:

| ID | Category | Component | Remediation Description |
| :--- | :--- | :--- | :--- |
| **SEC-01** | Security | `kubernetes/homeassistant` | Purged `pg_hba: host all all 0.0.0.0/0 trust` and set `enableSuperuserAccess: false` in CNPG cluster manifest. |
| **SRE-01** | SRE / Deadlock | `kubernetes/platform-hardening` | Replaced `RequiredBy=kubelet.service` with `WantedBy=kubelet.service` in `machineconfig-boot-network-gate.yaml`. Wrapped `/dev/tcp` probes in `timeout 2 bash -c ...` to prevent infinite hangs. Aligned timeout to 240s. |
| **SRE-02** | GitOps | `kubernetes/argocd` | Removed orphaned `resources-finalizer` from `platform-hardening.yaml` application definition. |
| **SRE-03** | High Availability | `kubernetes/homeassistant` & `paperless-ngx` | Set `enablePDB: false` on single/HA CNPG clusters during rolling upgrades to eliminate PodDisruptionBudget eviction deadlocks. |
| **SEC-02** | Secrets Hygiene | `kubernetes/bikely-dev` & `bikely` | Replaced hardcoded plaintext `DATABASE_URL` in `bikely-upload-service`. Standardized `POSTGRES_PASSWORD` with `REPLACE_ME` placeholders wired to Secret objects per `AGENTS.md`. |
| **OPS-01** | Cluster Hygiene | `kubernetes/bikely` & `bikely-dev` | Purged ephemeral OpenShift build tokens (`default-dockercfg-*`) from production and dev deployment manifests. |
| **RES-02** | GitOps Drift | `kubernetes/argocd` | Cleaned up obsolete `ignoreDifferences` in `bikely-dev.yaml`. |

---

## 5. Git Remote & Synchronization Strategy

### Remotes Configuration
- **`origin`**: `gitlab.apps.okd.claffey.cloud:rclaffey/homelab.git` (Internal GitLab — ArgoCD source of truth).
- **`github`**: `github.com:killerclaffey/homelab.git` (External GitHub — Public mirror & PR tracking).

### GitHub PR #1 vs PR #2 Resolution
- Pull Request #1 (`feat/power-outage-hardening-sdlc` -> `main`) was merged into GitHub `main` at 18:06 EDT at commit `96045c7`.
- Subsequent security and SRE remediation commits (`30389dd` and `c81d2f1`) were merged into `main` (`87534b6`) and pushed directly to both `github` and `origin`.
- Both remotes are identical and in sync. No outstanding PR merge is blocking deployment.

---

## 6. Action Items for Next Session

1. **Worker Node `k84` Recovery:**
   - Execute the SSH one-liner to repair `/usr/local/bin/kubelet-prestart-gate.sh` and restart `kubelet`.
   - Verify:
     ```bash
     oc get nodes -o wide
     oc get mcp worker
     oc get clusteroperators machine-config
     ```
2. **Vault Secret Architecture Hardening:**
   - Evaluate replacing K8s Secret auto-unseal sidecar with AWS KMS (`seal "awskms"`) or Bitwarden Secrets Manager (BWS) to eliminate circular cluster trust.
   - Restrict Vault `external-secrets` policy scope down to explicit paths (`secret/data/homelab/*`).
3. **TrueNAS CSI Evolution:**
   - Validate `tns-csi` (WebSocket driver) readiness against TrueNAS SCALE to prepare for TrueNAS 26 REST API removal.
