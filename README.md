# HomeLab GitOps

This repository contains the declarative configuration for your OpenShift/OKD homelab cluster (`api.okd.claffey.cloud`), structured in a modular GitOps layout utilizing ArgoCD for continuous reconciliation.

## Repository Structure

```text
.
├── README.md
├── network/                    # Network & AP configurations
└── kubernetes/                 # Kubernetes / OKD workloads
    ├── argocd/                 # ArgoCD Control Plane & Bootstrap
    │   ├── base/               # Namespace, OperatorGroup, Subscription, ArgoCD CR
    │   ├── overlays/okd/       # Environment overlay
    │   └── applications/       # App-of-Apps manifests tracking all workloads
    ├── external-dns/           # Cloudflare DNS integration
    ├── external-secrets/       # Secret operator configurations
    ├── truenas-csi/            # Storage classes & CSI drivers for TrueNAS (iSCSI/NFS)
    ├── monitoring/             # Cluster monitoring custom configurations
    ├── rook-ceph/              # Local storage operator configurations
    ├── uptime-kuma/            # Uptime dashboard with custom SQLite seeder
    ├── gitlab-system/          # Self-hosted GitLab stack
    ├── immich/                 # Photos suite with CloudNativePG database
    ├── mealie/                 # Recipe manager deployment
    ├── quay/                   # Container registry configuration
    ├── vault/                  # HashiCorp Vault secrets management
    ├── velero/                 # Velero backup & disaster recovery
    ├── bikely/                 # Production Bikely workload
    └── bikely-dev/             # Development Bikely workload
```

---

## Bootstrapping Guide

The cluster is configured using the **App-of-Apps** pattern. To bootstrap the cluster and sync all applications:

### Step 1: Deploy ArgoCD Control Plane
Install the ArgoCD Operator and start the instance on the cluster by applying the `okd` overlay:
```bash
oc apply -k kubernetes/argocd/overlays/okd
```
*This creates the `argocd` namespace, logs in the operator, and deploys the self-managed ArgoCD instance.*

Verify status:
```bash
oc get pods -n argocd
oc get route argocd-server -n argocd
```

### Step 2: Push Repository to Git Remotes
Push this configuration to your Git remotes to trigger the App-of-Apps sync:
```bash
# Push to GitHub
git push origin main

# Push to self-hosted GitLab
git push gitlab main
```

### Step 3: Register All Applications (App-of-Apps)
Apply the bootstrap kustomization to tell ArgoCD to start tracking all workloads:
```bash
oc apply -k kubernetes/argocd/applications
```
ArgoCD will automatically create and sync all 13 application controllers.

---

## Core Operations

### TrueNAS CSI Storage
* Uses `quay.io/truenas_solutions/truenas-csi:v1.1.1` to provision persistent volumes.
* Backed by TrueNAS SCALE (`10.0.20.2`) running standard iSCSI targets (port `3260`) and NFS exports.

### Uptime Kuma Declarative Seeding
* Seeding is handled via a custom background script defined in `seeder-configmap.yaml`.
* The script waits for the database tables to be created by Uptime Kuma migrations, and then inserts/updates monitors for the local routes:
  * ArgoCD
  * Mealie
  * Immich
  * GitLab
  * Uptime Kuma (internal poll)
