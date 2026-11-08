# AMD GPU (ROCm k8s-device-plugin)

Deploys the [ROCm k8s-device-plugin](https://github.com/ROCm/k8s-device-plugin) `amd-gpu` Helm chart via the ArgoCD app [`amd-gpu`](../argocd/applications/amd-gpu.yaml). This kustomization only holds the OKD glue (namespace + SCC RoleBindings); chart values live in the Application.

- **Device plugin** advertises `amd.com/gpu` on every node.
- **Node labeller** adds `amd.com/gpu.{family,device-id,vram,cu-count,simd-count}` labels.

## Hardware

Every node is an HP EliteMini with a Radeon 780M-class iGPU (PCI `1002:1900`, `GC_11_0_1` / gfx1103) on the in-tree `amdgpu` driver. No AMD GPU Operator or out-of-tree driver needed.

| Node | System RAM | Dedicated VRAM (BIOS UMA) | GTT (shared) | `amd.com/gpu.vram` label | BIOS |
| ---- | ---------- | ------------------------- | ------------ | ------------------------ | ---- |
| k81  | 86 GiB     | 8 GiB                     | 43 GiB       | `43G`                    | 1.06 |
| k82  | 45 GiB     | 2 GiB                     | 22 GiB       | `22G`                    | 1.06 |
| k83  | 61 GiB     | 2 GiB                     | 30 GiB       | `30G`                    | 1.02 |
| k84  | 13 GiB     | 2 GiB                     | 7 GiB        | `7G`                     | 1.02 |

> [!NOTE]
> On these APUs the labeller's `vram` label reports **GTT**: system RAM the GPU can map, which the kernel caps at ~50% of RAM by default. It does not report the dedicated BIOS carve-out. The labels differ because the nodes have different amounts of RAM, not because anything is misconfigured.

Dedicated VRAM is the BIOS "UMA Frame Buffer Size" setting (k81 = 8 GiB, the rest default to 2 GiB). Check a node with:

```bash
oc debug node/<node> -q -- chroot /host sh -c \
  'd=/sys/class/drm/card0/device; echo vram=$(($(cat $d/mem_info_vram_total)/1048576))MiB gtt=$(($(cat $d/mem_info_gtt_total)/1048576))MiB'
```

## OKD specifics

The chart is not OpenShift-aware:

| Pod           | Problem                                                           | Fix                                                      |
| ------------- | ----------------------------------------------------------------- | -------------------------------------------------------- |
| Device plugin | SELinux denies `container_t` connecting to `kubelet.sock`         | `seLinuxOptions.type: spc_t` + `hostmount-anyuid-v2` SCC |
| Labeller      | Device cgroup blocks opening `/dev/dri/card0` via hostPath `/dev` | `privileged: true` + `privileged` SCC                    |

GPU workloads themselves need no special SCC: `/dev/kfd` (`hsa_device_t`) and `/dev/dri/renderD*` (`dri_device_t`) are usable under `restricted-v2`.

## Using the GPU

```yaml
resources:
  limits:
    amd.com/gpu: 1
env:
  # gfx1103 is not on ROCm's official support list; masquerade as gfx1100
  - name: HSA_OVERRIDE_GFX_VERSION
    value: "11.0.0"
```

Pin memory-hungry workloads (e.g. LLMs) to k81 with `nodeSelector: {kubernetes.io/hostname: k81}`. The `vram` label isn't numeric, so you can't use a `Gt` node-affinity rule on it.

## Verify

```bash
oc get nodes -o custom-columns='NODE:.metadata.name,GPU:.status.allocatable.amd\.com/gpu' -L amd.com/gpu.vram
oc logs -n amd-gpu ds/amd-gpu-device-plugin-daemonset | grep -i registration
```
