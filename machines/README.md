# Declarative Host Boot Configuration (Kustomize Structure)

This directory manages the declarative boot configurations for the physical control-plane master nodes in the OKD cluster (`k81`, `k82`, `k83`). It is structured similarly to Kustomize to isolate shared code from node-specific values.

---

## 1. Directory Structure

```text
machines/
├── README.md
├── apply-boot-config.ps1       # PowerShell automation script (compiles base + overlay and pushes to node)
├── base/
│   └── grub.cfg                # Shared redirect bootloader script (common to all nodes)
└── overlays/                   # Node-specific variables/overlays
    ├── k81/
    │   └── bootuuid.cfg        # Partition UUID for k81 boot partition
    ├── k82/
    │   └── bootuuid.cfg        # Partition UUID for k82 boot partition
    └── k83/
        └── bootuuid.cfg        # Partition UUID for k83 boot partition
```

---

## 2. Config Components

### Base: `base/grub.cfg`
The stub configuration placed on the EFI system partition (`/dev/nvme0n1p2`) under `/EFI/centos/grub.cfg`. It automatically locates the core boot partition (`/dev/nvme0n1p3`) using the UUID defined in `bootuuid.cfg` and hands off execution to the full boot menu config:
```grub
if [ -e (md/md-boot) ]; then
  set prefix=md/md-boot
else
  if [ -f ${config_directory}/bootuuid.cfg ]; then
    source ${config_directory}/bootuuid.cfg
  fi
  if [ -n "${BOOT_UUID}" ]; then
    search --fs-uuid "${BOOT_UUID}" --set prefix --no-floppy
  else
    search --label boot --set prefix --no-floppy
  fi
fi
if [ -d ($prefix)/grub2 ]; then
  set prefix=($prefix)/grub2
  configfile $prefix/grub.cfg
else
  set prefix=($prefix)/boot/grub2
  configfile $prefix/grub.cfg
fi
boot
```

### Overlays: `overlays/<node>/bootuuid.cfg`
Contains the local block device filesystem UUID for `/dev/nvme0n1p3` (the `/boot` partition) on each respective node:
* **`k81`:** `93d26952-ba0b-4647-acab-05b3eb75708e`
* **`k82`:** `8f3990dc-d30d-4330-a192-8f5542079e1a`
* **`k83`:** `1cdef842-7f5a-44a1-a9a0-409006f0f23f`

---

## 3. Security & Secrets Policy

> [!NOTE]
> **No secrets are contained in this folder.** 
> Filesystem UUIDs (`BOOT_UUID`) are hardware partition markers and do not constitute sensitive credentials or private keys. The GRUB configuration consists entirely of public boot scripting. 
> If any sensitive configuration parameters are introduced in the future, they must be encrypted using `ansible-vault` or managed via HashiCorp Vault.

---

## 4. How to Apply Configurations (Lifecycle & Reconciliation)

To push the declarative configurations from this repository onto a live host's EFI partition, you can use either the PowerShell script or the Ansible playbook.

### Option A: Using PowerShell (Local Workstation via `oc debug`)
This script uses standard cluster API access via `oc debug` to write the files:
```powershell
# Reconcile node k83 bootloader config
.\apply-boot-config.ps1 -Node k83

# Reconcile node k81 bootloader config
.\apply-boot-config.ps1 -Node k81
```

### Option B: Using Ansible (Direct SSH to Hosts)
The playbook targets the master nodes directly via SSH. Ensure you have your inventory file set up (with host names `k81`, `k82`, `k83` in the `masters` group):
```bash
# Run against all master nodes
ansible-playbook -i inventory.ini apply-boot-config.yml

# Run against a specific node (e.g., k83)
ansible-playbook -i inventory.ini apply-boot-config.yml --limit k83
```

