# OKD Cluster Documentation

## Overview
This directory contains documentation for the OKD (OpenShift Kubernetes Distribution) cluster deployed in the homelab environment at `okd.claffey.cloud`.

## Cluster Specifications

### Basic Information
- **Cluster Address**: okd.claffey.cloud
- **OpenShift Version**: 4.20.5
- **CPU Architecture**: x86_64
- **Installation Type**: User-Managed Networking
- **Network Stack**: IPv4 only

### Hardware Resources
- **Hosts**: 3 control plane nodes (Minisforum UM890)
- **Total CPU Cores**: 48 cores
- **Total Memory**: 192.00 GiB
- **Total Storage**: 1.63 TB
- **Disk Encryption**: Enabled on all control plane nodes

### Node Details
| Hostname | MAC Address | IP Address | Role |
|----------|-------------|------------|------|
| K81 | 58:47:ca:7c:33:ae | 10.0.20.100 | Control Plane |
| K82 | 58:47:ca:7b:8f:78 | 10.0.20.101 | Control Plane |
| K83 | 58:47:ca:7d:ee:43 | 10.0.20.102 | Control Plane |

**Note**: All nodes use DHCP with static reservations configured in OPNsense Kea DHCP server.

## Network Architecture

### VLAN Configuration
The OKD cluster is deployed across multiple VLANs for network segmentation:

| VLAN | Name | Subnet | Purpose |
|------|------|--------|---------|
| 1 | Management | 10.0.1.0/24 | Infrastructure management |
| 20 | OKD-Infra | 10.0.20.0/24 | Cluster nodes, bootstrap, DNS |
| 30 | OKD-Storage | 10.0.30.0/24 | TrueNAS NFS/iSCSI backend (isolated) |
| 40 | Services | 10.0.40.0/24 | Published OKD services (external access) |

### Networking Details

#### Cluster Internal Networking
- **Cluster Network CIDR**: 10.128.0.0/14
  - Pod-to-pod communication
  - Managed by OVN-Kubernetes CNI
- **Cluster Network Host Prefix**: /23
  - Each node receives a /23 subnet from the cluster network
- **Service Network CIDR**: 172.30.0.0/16
  - Internal cluster services (ClusterIP)
- **Networking Type**: Open Virtual Network (OVN)

#### Load Balancer VIPs
The cluster uses virtual IP addresses for high availability:

| VIP Address | Purpose | VLAN | Description |
|-------------|---------|------|-------------|
| 10.0.20.5 | API Load Balancer | 20 (OKD-Infra) | Kubernetes API server access |
| 10.0.20.6 | Apps Internal | 20 (OKD-Infra) | Internal application ingress |
| 10.0.40.10 | Apps External | 40 (Services) | External application ingress |

**Note**: VIPs are configured as IP aliases on OPNsense firewall interfaces.

### DNS Configuration
DNS is provided by OPNsense Unbound on VLAN 1 (Management):
- **Primary DNS**: 10.0.20.2 (Unbound)
- **Secondary DNS**: 10.0.1.1 (OPNsense)
- **Domain**: claffey.cloud

Required DNS entries for OKD:
- `api.okd.claffey.cloud` → 10.0.20.5 (API VIP)
- `api-int.okd.claffey.cloud` → 10.0.20.5 (Internal API)
- `*.apps.okd.claffey.cloud` → 10.0.40.10 (External Apps)
- `*.apps-int.okd.claffey.cloud` → 10.0.20.6 (Internal Apps)

## Storage Configuration

### TrueNAS Integration
Storage is provided by TrueNAS Scale via VLAN 30 (OKD-Storage):
- **TrueNAS Management IP**: 10.0.0.62 (VLAN 1)
- **TrueNAS Storage IP**: Configured on VLAN 30 (10.0.30.x)
- **Storage Protocols**: NFS and iSCSI
- **Storage Network**: Isolated on VLAN 30 for security and performance

### Storage Classes
The cluster uses the Local Storage Operator for persistent volumes.

## Installed Operators

The cluster has the following operators enabled:

### Core Infrastructure
- **Node Maintenance**: Manage node maintenance mode
- **Node Healthcheck**: Automated node health monitoring
- **NUMA Resources**: NUMA-aware workload scheduling
- **Kube Descheduler**: Automated pod rescheduling

### Networking & Load Balancing
- **MetalLB**: Bare-metal load balancer for external services
- **NMState**: Network configuration management

### Storage
- **Local Storage Operator**: Local persistent volume management
- **OADP (OpenShift API for Data Protection)**: Backup and disaster recovery

### Observability
- **Cluster Observability**: Metrics and monitoring
- **Loki Operator**: Log aggregation
- **OpenShift Logging**: Centralized logging

### Virtualization
- **OpenShift Virtualization**: KubeVirt-based VM management
- **Migration Toolkit for Virtualization**: VM migration tools

### High Availability
- **Fence Agents Remediation**: Automated node fencing

## Firewall Configuration

The OKD cluster integrates with OPNsense firewall for:
- VLAN routing and isolation
- NAT for external connectivity
- Virtual IP management for load balancing
- DHCP services (Kea)
- DNS services (Unbound)

See [Firewall_Configuration.md](Firewall_Configuration.md) for detailed firewall rules and configuration.

## Access & Management

### Web Console
- **External**: https://console-openshift-console.apps.okd.claffey.cloud
- **Internal**: Accessible from VLAN 1 (Management) and VLAN 20 (OKD-Infra)

### API Access
- **External API**: https://api.okd.claffey.cloud:6443
- **Internal API**: https://api-int.okd.claffey.cloud:6443

### CLI Access
```bash
# Login to the cluster
oc login https://api.okd.claffey.cloud:6443

# Check cluster status
oc get nodes
oc get co  # Check cluster operators
```

## Security

### Network Security
- **VLAN Isolation**: Storage network (VLAN 30) is isolated from other networks
- **Firewall Rules**: OPNsense enforces inter-VLAN communication policies
- **Disk Encryption**: All control plane nodes have encrypted disks

### Access Control
- **RBAC**: Role-based access control configured
- **Network Policies**: Pod-to-pod communication controlled via NetworkPolicy resources

## Backup & Disaster Recovery

The cluster uses OADP (OpenShift API for Data Protection) for:
- Persistent volume backups
- Cluster resource backups
- Application state preservation

## Documentation Structure

- [README.md](README.md) - This file, cluster overview
- [Network_Configuration.md](Network_Configuration.md) - Detailed network setup
- [Firewall_Configuration.md](Firewall_Configuration.md) - OPNsense firewall configuration
- [Storage_Configuration.md](Storage_Configuration.md) - TrueNAS storage setup
- [Node_Configuration.md](Node_Configuration.md) - Individual node specifications

## References

- [OKD Documentation](https://docs.okd.io/)
- [OpenShift 4.20 Documentation](https://docs.openshift.com/container-platform/4.20/)
- [Main Homelab Documentation](../README.md)
- [VLAN Design](../network/VLANs/README.md)
- [OPNsense Firewall Config](../network/OPNsense-FIREWALL/)
- [TrueNAS Configuration](../storage/TrueNAS/)
