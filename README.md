# HomeLab GitOps

This repository contains the declarative configuration for an OpenShift/OKD homelab cluster (`api.okd.claffey.cloud`), structured in a modular GitOps layout utilizing ArgoCD for continuous reconciliation.

---

## Repository Structure

```text
.
├── AGENTS.md                  # Mandatory instructions and guardrails for AI coding agents
├── docs/                      # Architectural designs, topology diagrams, and runbooks
│   └── network/               # 40Gbps Thunderbolt 4 / USB4 mesh & storage topology
├── kubernetes/                # Kubernetes / OKD workloads & GitOps manifests
│   ├── argocd/                # ArgoCD control plane, overlays, and App-of-Apps manifests
│   ├── external-dns/          # Cloudflare DNS integration
│   ├── external-secrets/      # Vault-backed secret synchronization
│   ├── platform-hardening/    # Node boot gates, SCC bindings, and security baselines
│   ├── tns-csi/               # WebSocket-native TrueNAS CSI driver (NVMe-oF / iSCSI / NFS)
│   ├── truenas-csi/           # Legacy TrueNAS CSI driver
│   ├── monitoring/            # Cluster Prometheus & Grafana configurations
│   ├── rook-ceph/             # Local storage operator configurations
│   ├── vault/                 # HashiCorp Vault secrets management
│   ├── velero/                # Backup & disaster recovery with MinIO backend
│   └── <workloads>/           # Application workloads (Immich, Nextcloud, Mealie, etc.)
├── machines/                  # Host bootloader configurations (declarative GRUB/EFI)
├── okd-cluster/               # Cluster installation specs, node configurations, and network plans
├── physical/                  # Physical rackmount layout, hardware inventory, and cabling
├── projects/                  # Engineering context, sprint plans, and decision records
├── scripts/                   # Operational utilities (container image replicator, bootstrap)
└── truenas/                   # Storage configuration backups and automation
```

---

## Bootstrapping Guide

The cluster is managed declaratively using the **App-of-Apps** pattern. To bootstrap the cluster and sync all applications:

### Step 1: Deploy ArgoCD Control Plane

Install the ArgoCD Operator and start the instance on the cluster by applying the `okd` overlay:

```bash
oc apply -k kubernetes/argocd/overlays/okd
```

*This creates the `argocd` namespace, configures the operator, and deploys the self-managed ArgoCD instance.*

Verify status:

```bash
oc get pods -n argocd
oc get route argocd-server -n argocd
```

### Step 2: Push Repository to Git Remotes

Push configuration changes to your Git remotes to trigger the App-of-Apps sync:

```bash
# Push to GitHub
git push origin main

# Push to self-hosted GitLab
git push gitlab main
```

### Step 3: Register All Applications (App-of-Apps)

Apply the bootstrap kustomization to register the root applications catalog:

```bash
oc apply -k kubernetes/argocd/applications
```

ArgoCD will automatically discover, deploy, and reconcile all 31 application workloads across the cluster.

---

## Core Operations

### TrueNAS CSI Storage & High-Speed Mesh

* **Standard Storage (`truenas-csi`)**: Provisions block (iSCSI port `3260`) and file (NFS port `2049`) persistent volumes backed by TrueNAS SCALE (`10.0.20.2`).
* **High-Speed Mesh Storage (`tns-csi`)**: High-performance NVMe-oF and iSCSI storage running over a dedicated 40Gbps Thunderbolt 4 / USB4 mesh network connecting cluster nodes to TrueNAS (`10.0.50.2`).
* See [Thunderbolt Mesh Topology](docs/network/thunderbolt-mesh-topology.md) for network diagrams, bridge persistence, and fio benchmark metrics.

### Uptime Kuma Declarative Seeding

* Seeding is automated via a custom background script defined in [`seeder-configmap.yaml`](kubernetes/uptime-kuma/base/seeder-configmap.yaml).
* The script waits for database tables to initialize after migrations, then idempotently provisions HTTP monitors for cluster routes:
  * ArgoCD
  * Mealie
  * Immich
  * GitLab
  * Uptime Kuma (internal probe)

### Host Boot Management

* Physical control-plane master node boot configurations are versioned under [`machines/`](machines/).
* See [`machines/README.md`](machines/README.md) for details on reconciling EFI partition UUIDs (`bootuuid.cfg`) via PowerShell (`apply-boot-config.ps1`) or Ansible (`apply-boot-config.yml`).
