# HomeLab

This repository contains the declarative configuration for your OpenShift/OKD homelab cluster, structured in a modular GitOps layout mirroring [ArthurVardevanyan/HomeLab](https://github.com/ArthurVardevanyan/HomeLab).

## Repository Structure

```
.
├── .gitignore
├── README.md
└── kubernetes/
    ├── argocd/                 # ArgoCD Control Plane & Bootstrap
    │   ├── base/               # Base namespace, operator sub, and ArgoCD CR specs
    │   │   ├── namespace.yaml
    │   │   ├── operator-group.yaml
    │   │   ├── subscription.yaml
    │   │   ├── argocd.yaml
    │   │   └── kustomization.yaml
    │   ├── overlays/
    │   │   └── okd/            # Environment specific overlays (references base)
    │   │       └── kustomization.yaml
    │   └── applications/       # Declarative ArgoCD Application CRDs
    │       ├── mealie.yaml     # Tracks the Mealie app configuration
    │       └── kustomization.yaml
    └── mealie/                 # App Deployment manifests
        ├── base/               # Raw Mealie specs (Deployments, Services, ConfigMaps)
        │   ├── namespace.yaml
        │   ├── configmap-config.yaml
        │   ├── configmap-sw-patch.yaml
        │   ├── pvc.yaml
        │   ├── service.yaml
        │   ├── route.yaml
        │   ├── secret.yaml     # Template/placeholder for credentials
        │   ├── deployment.yaml
        │   └── kustomization.yaml
        └── overlays/
            └── okd/
                └── kustomization.yaml
```

---

## Bootstrapping Guide

To migrate your cluster to this ArgoCD GitOps flow, follow these steps:

### Step 1: Install the ArgoCD Operator and Control Plane
Deploy the community ArgoCD Operator and start the instance on your cluster by applying the `okd` overlay:
```bash
oc apply -k kubernetes/argocd/overlays/okd
```
*This will create the `argocd` namespace, install the operator subscription, and deploy the ArgoCD instance. The operator will automatically create an OpenShift Route to expose the web console.*

Verify the deployment:
```bash
oc get pods -n argocd
oc get route argocd-server -n argocd
```

### Step 2: Push this Repository to your Git Hosting Server
Create a repository on your preferred Git host (e.g., GitHub or your self-hosted GitLab instance) and push this repository:
```bash
git add .
git commit -m "feat: initial homelab structure with argocd and mealie"
git remote add origin <your-git-remote-url>
git branch -M main
git push -u origin main
```

> [!WARNING]
> Before pushing, check [secret.yaml](file:///C:/Users/rclaf/sync/HomeLab/kubernetes/mealie/base/secret.yaml) to ensure no actual credentials are committed in plain text. You should replace the values with dummy values and configure SealedSecrets or Vault, or load the secret separately.

### Step 3: Update the ArgoCD Application Repo URL
Edit [mealie.yaml](file:///C:/Users/rclaf/sync/HomeLab/kubernetes/argocd/applications/mealie.yaml) and update the `repoURL` to point to your new Git repository:
```yaml
spec:
  source:
    repoURL: <your-git-remote-url>
```
Commit and push this change to Git.

### Step 4: Register the Mealie Application in ArgoCD
Apply the application resource to tell ArgoCD to start tracking Mealie via GitOps:
```bash
oc apply -f kubernetes/argocd/applications/mealie.yaml
```
ArgoCD will now watch the `kubernetes/mealie/overlays/okd` directory and automatically sync any changes you push to your Git repo.
