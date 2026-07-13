# AGENTS.md — Instructions for AI Coding Agents

This file contains mandatory rules for any AI agent (Copilot, Claude, Cursor, Gemini, etc.)
working in this repository. Read it before making any changes.

---

## 🔐 SECRETS — NEVER COMMIT REAL VALUES

**This is a homelab GitOps repo synced to GitHub (public or private). Real secrets in git
history are a permanent leak risk. Follow these rules without exception.**

### Rules

1. **Never commit real API keys, passwords, tokens, or private keys.** Not in any file,
   not in any commit, not "just temporarily."

2. **Use `REPLACE_ME` as the placeholder value** for any secret field in YAML/config files
   that get committed. Add a comment explaining how to apply the real value.

   ```yaml
   # BAD — never do this:
   apiKey: "3-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

   # GOOD — do this:
   apiKey: "REPLACE_ME"  # Apply with: oc create secret generic ... --from-literal=apiKey=<value>
   ```

3. **Secrets live on the cluster only.** Apply them with `oc apply` or `kubectl apply`
   directly. Do not round-trip them through git.

4. **Never read a secret off the cluster and then write it into a file that will be committed.**
   If you need to look up a secret to understand the schema, fine — but the value goes
   nowhere near the working tree.

5. **kubeconfig files are banned from git.** The `.gitignore` blocks `kubeconfig*` already.
   Never add a `-f` ignore flag to force-add one.

6. **Run gitleaks before committing** if you have added any credential-shaped strings:
   ```bash
   gitleaks protect --staged --config .gitleaks.toml
   ```
   The pre-commit hook does this automatically, but if you're applying commits in bulk,
   run it manually first.

7. **If you accidentally commit a secret**, stop and do the following before pushing:
   - Rewrite history with `git-filter-repo --replace-text`
   - Remove the file with `git-filter-repo --path <file> --invert-paths`
   - Force-push: `git push --force`
   - Rotate the credential immediately even if the repo is private

---

## 📁 Repo Layout

```
kubernetes/          GitOps manifests — Kustomize bases + overlays
  argocd/            ArgoCD Application CRs and app-of-apps kustomizations
  truenas-csi/       Official TrueNAS CSI driver (democratic-csi fork)
  tns-csi/           tns-csi driver (WebSocket-native, side-by-side test)
  velero/            Backup with MinIO backend
  monitoring/        Prometheus + Grafana stack
  ...
okd-cluster/         OKD cluster install docs (NO kubeconfig files here)
```

## 🛠️ Workflow Conventions

- **ArgoCD is the source of truth.** Make changes in git, let ArgoCD sync. Don't `oc apply`
  manifests directly unless bootstrapping or debugging — and if you do, reconcile back to git.

- **Kustomize over raw YAML.** All app manifests use a `kustomization.yaml`. Add new
  resources to the `resources:` list; don't drop bare YAML files without a kustomization.

- **OCI Helm charts in ArgoCD** require `targetRevision` to be an exact semver string
  (e.g., `"0.17.6"`), not `HEAD`. Verify the version exists before committing:
  ```bash
  oc run helm-check --rm --restart=Never -it --image=alpine/helm:3 \
    -- pull oci://registry-1.docker.io/<org>/<chart> --destination /tmp
  ```

- **StorageClasses default to `Immediate` binding** in this cluster. Don't set
  `volumeBindingMode: WaitForFirstConsumer` unless you've verified the CSI driver
  supports topology awareness on OKD.

- **`oc` not `kubectl`** — the cluster is OKD (OpenShift). Most things work with either
  but SCCs, Routes, and ImageStreams need `oc`.

## ⚠️ Known Gotchas

| Area | Gotcha |
|------|--------|
| `truenas-csi` | Must use `--mode=controller` / `--mode=node` explicit flags or nodes deadlock on upgrade |
| Image Registry | Must use NFS PVC storage, not `emptyDir` — images are lost on pod restart otherwise |
| ArgoCD OCI Helm | Register OCI repo via a `Secret` with `enableOCI: "true"` in the `argocd` namespace |
| TrueNAS API | REST API is being removed in TrueNAS 26 — prefer WebSocket-based drivers (`tns-csi`) |
| OKD upgrades | CVO stalls if Image Registry is `Degraded` — always check registry health post-upgrade |
