# OKD Cluster Node Configuration

## Overview
The OKD cluster consists of three Minisforum UM890 mini PCs serving as control plane nodes with worker capabilities. Each node runs Fedora CoreOS (FCOS) and has identical hardware specifications.

## Hardware Specifications

### Minisforum UM890 (All Nodes)
- **Processor**: AMD Ryzen 9 8945HS
- **CPU Cores**: 16 cores per node (48 cores total)
- **Memory**: 64 GiB DDR5 per node (192 GiB total)
- **Storage**: ~545 GB per node (1.63 TB total)
- **Disk Encryption**: LUKS encryption enabled on all nodes
- **Network Interfaces**:
  - 2x 2.5 Gigabit Ethernet ports
  - Primary: Connected to VLAN 20 (OKD-Infra)
  - Secondary: Connected to VLAN 30 (OKD-Storage) - optional

## Node Details

### K81 - Control Plane Node 1

**Network Configuration:**
- **Hostname**: k81.okd.claffey.cloud
- **Primary MAC**: 58:47:ca:7c:33:ae
- **Primary IP**: 10.0.20.100 (VLAN 20 - OKD-Infra)
- **Storage IP**: 10.0.30.100 (VLAN 30 - OKD-Storage) - optional
- **Default Gateway**: 10.0.20.1
- **DNS**: 10.0.20.2, 10.0.1.1

**Roles:**
- Control Plane (master)
- Worker (workloads enabled)

**Cluster Network Allocation:**
- Pod CIDR: 10.128.0.0/23 (example - assigned by OVN)

**DHCP Configuration:**
- Static reservation in Kea DHCP on OPNsense
- MAC: 58:47:ca:7c:33:ae → IP: 10.0.20.100

**Services Running:**
- Kubernetes API Server
- etcd
- Scheduler
- Controller Manager
- Kubelet
- Container Runtime (CRI-O)

---

### K82 - Control Plane Node 2

**Network Configuration:**
- **Hostname**: k82.okd.claffey.cloud
- **Primary MAC**: 58:47:ca:7b:8f:78
- **Primary IP**: 10.0.20.101 (VLAN 20 - OKD-Infra)
- **Storage IP**: 10.0.30.101 (VLAN 30 - OKD-Storage) - optional
- **Default Gateway**: 10.0.20.1
- **DNS**: 10.0.20.2, 10.0.1.1

**Roles:**
- Control Plane (master)
- Worker (workloads enabled)

**Cluster Network Allocation:**
- Pod CIDR: 10.128.2.0/23 (example - assigned by OVN)

**DHCP Configuration:**
- Static reservation in Kea DHCP on OPNsense
- MAC: 58:47:ca:7b:8f:78 → IP: 10.0.20.101

**Services Running:**
- Kubernetes API Server
- etcd
- Scheduler
- Controller Manager
- Kubelet
- Container Runtime (CRI-O)

---

### K83 - Control Plane Node 3

**Network Configuration:**
- **Hostname**: k83.okd.claffey.cloud
- **Primary MAC**: 58:47:ca:7d:ee:43
- **Primary IP**: 10.0.20.102 (VLAN 20 - OKD-Infra)
- **Storage IP**: 10.0.30.102 (VLAN 30 - OKD-Storage) - optional
- **Default Gateway**: 10.0.20.1
- **DNS**: 10.0.20.2, 10.0.1.1

**Roles:**
- Control Plane (master)
- Worker (workloads enabled)

**Roles:**
- Control Plane (master)
- Worker (workloads enabled)

**Cluster Network Allocation:**
- Pod CIDR: 10.128.4.0/23 (example - assigned by OVN)

**DHCP Configuration:**
- Static reservation in Kea DHCP on OPNsense
- MAC: 58:47:ca:7d:ee:43 → IP: 10.0.20.102

**Services Running:**
- Kubernetes API Server
- etcd
- Scheduler
- Controller Manager
- Kubelet
- Container Runtime (CRI-O)

---

## Network Interface Configuration

### Primary Interface (OKD-Infra VLAN 20)
All nodes use their primary NIC for cluster communication:

```yaml
# Example network configuration for K81
interfaces:
  - name: enp1s0
    type: ethernet
    state: up
    mac-address: 58:47:ca:7c:33:ae
    ipv4:
      enabled: true
      dhcp: true
      address:
        - ip: 10.0.20.100
          prefix-length: 24
      dns-resolver:
        config:
          search:
            - okd.claffey.cloud
            - claffey.cloud
          server:
            - 10.0.20.2
            - 10.0.1.1
    ipv6:
      enabled: false
```

### Secondary Interface (OKD-Storage VLAN 30) - Optional
If using dedicated storage network, configure secondary NIC:

```yaml
# Example storage network configuration
interfaces:
  - name: enp2s0
    type: ethernet
    state: up
    ipv4:
      enabled: true
      address:
        - ip: 10.0.30.100  # K81 example
          prefix-length: 24
      dhcp: false
    ipv6:
      enabled: false
```

**Note**: Storage network is isolated and only accessible from VLAN 20 (OKD-Infra).

## Storage Configuration

### Local Storage
Each node has local storage managed by the Local Storage Operator:

- **Total Capacity**: ~545 GB per node
- **Encryption**: LUKS full-disk encryption
- **Filesystem**: XFS (typically for FCOS)
- **Usage**:
  - OS and system files
  - Container image storage
  - Local persistent volumes (via Local Storage Operator)
  - etcd data

### Network Storage (TrueNAS)
Nodes connect to TrueNAS Scale via VLAN 30 for shared storage:

- **NFS**: For ReadWriteMany (RWX) persistent volumes
- **iSCSI**: For block storage (optional)
- **TrueNAS Storage IP**: 10.0.30.x (on VLAN 30)

## Operating System

### Fedora CoreOS (FCOS)
- **Distribution**: Fedora CoreOS (OKD base OS)
- **Container Runtime**: CRI-O
- **Init System**: systemd
- **Updates**: Automatic updates via rpm-ostree and Zincati
- **Configuration**: Managed via Ignition and Machine Config Operator

### Key FCOS Features:
- Immutable OS design
- Automated atomic updates
- Rollback capability
- Container-optimized kernel

## Cluster Roles

### Control Plane Responsibilities
All three nodes participate in control plane operations:

1. **etcd Cluster**:
   - Distributed key-value store
   - Requires quorum (2 out of 3 nodes)
   - Stores cluster state and configuration

2. **API Server**:
   - Load balanced via VIP 10.0.20.5
   - Handles all API requests
   - Authenticates and authorizes requests

3. **Scheduler**:
   - Assigns pods to nodes
   - Considers resource availability and constraints

4. **Controller Manager**:
   - Runs core control loops
   - Manages node lifecycle, replication, endpoints

### Worker Responsibilities
All nodes also run workloads:

- **Kubelet**: Manages pods on the node
- **Container Runtime**: CRI-O runs containers
- **Kube-proxy**: Network proxy for services
- **OVN Controller**: Handles pod networking

## Resource Allocation

### Per-Node Resources
```yaml
Node: K81 (example - same for K82, K83)
  Capacity:
    cpu: "16"
    memory: 64Gi
    ephemeral-storage: ~545Gi

  Allocatable (after system reservations):
    cpu: ~15
    memory: ~60Gi
    ephemeral-storage: ~500Gi
```

### Cluster Totals
- **Total CPU**: 48 cores
- **Total Memory**: 192 GiB
- **Total Storage**: 1.63 TB (local)

## High Availability Configuration

### etcd Quorum
- **Minimum Nodes for Quorum**: 2 out of 3
- **Can Tolerate**: 1 node failure
- **Recommended**: Keep all 3 nodes running for best reliability

### API Load Balancing
- **VIP**: 10.0.20.5
- **Backend Nodes**: K81:6443, K82:6443, K83:6443
- **Health Check**: TCP port 6443
- **Failover**: Automatic via OPNsense

## Node Access

### SSH Access
```bash
# Access via core user (FCOS default)
ssh core@10.0.20.100  # K81
ssh core@10.0.20.101  # K82
ssh core@10.0.20.102  # K83

# Or via hostname (DNS required)
ssh core@k81.okd.claffey.cloud
ssh core@k82.okd.claffey.cloud
ssh core@k83.okd.claffey.cloud
```

**Note**: SSH authentication should use key-based authentication configured during installation.

### Console Access
Physical console access available via:
- Direct HDMI connection
- Serial console (if configured)

## Node Maintenance

### Cordoning a Node
Before maintenance, drain workloads:

```bash
# Mark node as unschedulable
oc adm cordon k81

# Drain all pods (except DaemonSets)
oc adm drain k81 --ignore-daemonsets --delete-emptydir-data

# Perform maintenance...

# Uncordon when ready
oc adm uncordon k81
```

### Rebooting a Node
```bash
# SSH to the node
ssh core@10.0.20.100

# Reboot
sudo systemctl reboot
```

### Checking Node Status
```bash
# List all nodes
oc get nodes

# Detailed node info
oc describe node k81

# Node resource usage
oc adm top node k81
```

## Monitoring

### Node Health Checks
- **Node Healthcheck Operator**: Monitors node health and remediates issues
- **Fence Agents Remediation**: Provides node fencing for unhealthy nodes
- **Cluster Observability**: Metrics and monitoring for node performance

### Key Metrics to Monitor
- CPU utilization
- Memory usage
- Disk I/O and capacity
- Network throughput
- Pod density
- etcd latency and leader elections

## Troubleshooting

### Node Not Ready
```bash
# Check node status
oc get nodes

# Describe node to see events
oc describe node k81

# Check kubelet logs
ssh core@k81
sudo journalctl -u kubelet -f

# Check CRI-O logs
sudo journalctl -u crio -f
```

### Network Issues
```bash
# Check OVN pods
oc get pods -n openshift-ovn-kubernetes

# Check node networking
ssh core@k81
ip addr show
ip route show
ping 10.0.20.1  # Gateway
ping 10.0.20.5  # API VIP
```

### Storage Issues
```bash
# Check local storage operator
oc get pods -n openshift-local-storage

# Check available storage
ssh core@k81
df -h

# Check NFS connectivity to TrueNAS
showmount -e <truenas-ip>
```

### etcd Health
```bash
# Check etcd cluster health
oc get etcd -o=jsonpath='{range .items[0].status.conditions[?(@.type=="EtcdMembersAvailable")]}{.message}{"\n"}{end}'

# List etcd members
oc rsh -n openshift-etcd <etcd-pod>
etcdctl member list -w table
```

## Backup and Recovery

### Node Backup
- **Configuration**: Managed by Machine Config Operator (MCP)
- **etcd Backup**: Regular etcd snapshots via OADP
- **Local Data**: Not typically backed up (ephemeral)

### Node Recovery
If a node fails:

1. **Temporary Failure**: Cluster continues with remaining nodes (if quorum maintained)
2. **Permanent Failure**: Replace node and rejoin cluster
3. **etcd Recovery**: Restore from etcd backup if needed

## Security

### Disk Encryption
- **Method**: LUKS full-disk encryption
- **Key Management**: Tang/Clevis for automatic unlocking (if configured)
- **Boot**: May require manual unlock if Tang server unavailable

### Network Security
- **Firewall**: OPNsense controls inter-VLAN access
- **Network Policies**: Pod-to-pod communication controlled within cluster
- **TLS**: All cluster communication encrypted

### Access Control
- **SSH**: Key-based authentication only
- **Kubernetes RBAC**: Role-based access control for cluster resources
- **Service Accounts**: Automated access control for pods

## Node-Specific Notes

### Power Management
- Configure BIOS for:
  - Auto-restart on power loss
  - Wake-on-LAN (optional)
  - Disable sleep/hibernate

### BIOS Settings
- **Virtualization**: Enabled (AMD-V/SVM)
- **IOMMU**: Enabled (for OpenShift Virtualization)
- **Secure Boot**: Disabled (typically for FCOS)
- **Boot Order**: Local disk first

## References

- [Fedora CoreOS Documentation](https://docs.fedoraproject.org/en-US/fedora-coreos/)
- [OKD Node Management](https://docs.okd.io/latest/nodes/index.html)
- [Machine Config Operator](https://docs.okd.io/latest/post_installation_configuration/machine-configuration-tasks.html)
- [Node Maintenance Operator](https://docs.okd.io/latest/nodes/nodes/eco-node-maintenance-operator.html)
- [Cluster README](README.md)
- [Network Configuration](Network_Configuration.md)
- [Firewall Configuration](Firewall_Configuration.md)
