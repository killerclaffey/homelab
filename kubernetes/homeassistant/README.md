# Home Assistant

Declarative deployment of Home Assistant Core, CloudNativePG PostgreSQL, and Music Assistant on OpenShift/OKD.

---

## Architecture

- **Home Assistant Core (`base/statefulset.yaml`)**: StatefulSet running Home Assistant Core on port `8123`, configured with persistent configuration storage and Prometheus monitoring.
- **Database (`components/cnpg`)**: High-availability CloudNativePG PostgreSQL cluster (`homeassistant`) dedicated to event recorder history.
- **Music Assistant (`components/music`)**: StatefulSet providing multi-room audio orchestration (`music-assistant`) on port `8095`.
- **Ingress (`components/openshift`)**: OpenShift Routes:
  - `home.apps.okd.claffey.cloud` → Home Assistant Core with `reencrypt` TLS termination (OpenShift service CA).
  - `music.apps.okd.claffey.cloud` → Music Assistant with `edge` TLS termination.
- **Security & Network Policies**: Isolated namespace with declarative `NetworkPolicy` resources restricting ingress and pod-to-pod communication.
- **Backup & Recovery**: Persistent volume data is labeled for scheduled Velero / OADP backup snapshots.

---

## Directory Structure

```text
kubernetes/homeassistant/
├── base/                     # Core namespace, StatefulSet, PVCs, Service, and NetworkPolicy
│   ├── config/               # Declarative Home Assistant configuration files
│   ├── kustomization.yaml    # Base Kustomization resource definition
│   ├── limit-range.yaml      # Namespace resource limits
│   ├── namespace.yaml        # Namespace definition with security labels
│   ├── network-policy.yaml   # Pod egress/ingress isolation rules
│   ├── pvc.yaml              # Core configuration volume claim
│   ├── secret.yaml           # Placeholder / ExternalSecret definitions
│   ├── service.yaml          # ClusterIP service for Home Assistant
│   ├── service-account.yaml  # Workload ServiceAccount
│   ├── service-monitor.yaml  # Prometheus metrics scraping configuration
│   ├── statefulset.yaml      # Home Assistant Core workload specification
│   └── velero.yaml           # OADP backup metadata
├── components/
│   ├── cnpg/                 # CloudNativePG Cluster, NetworkPolicy, and PodMonitor
│   ├── music/                # Music Assistant StatefulSet, Service, PVC, and Route
│   └── openshift/            # OpenShift Routes and SCC/RBAC definitions
├── overlays/
│   ├── okd/                  # Production OKD overlay assembling base + components
│   ├── k3s/                  # Experimental / edge K3s overlay
│   └── sno/                  # Single Node OpenShift overlay
└── README.md
```

---

## Deployment & GitOps

This workload is managed continuously by ArgoCD via [`kubernetes/argocd/applications/homeassistant.yaml`](../argocd/applications/homeassistant.yaml) targeting the `overlays/okd` overlay.

To verify deployment and operational status:

```bash
# Check pod rollout status
oc get pods -n homeassistant -l app=homeassistant

# Inspect PostgreSQL cluster health
oc get cluster -n homeassistant

# Verify active ingress routes
oc get routes -n homeassistant
```

---

## References

- [Home Assistant Container Documentation](https://www.home-assistant.io/installation/raspberrypi#install-home-assistant-container)
- [CloudNativePG Operator Documentation](https://cloudnative-pg.io/documentation/)
- [Music Assistant Documentation](https://music-assistant.io/)
