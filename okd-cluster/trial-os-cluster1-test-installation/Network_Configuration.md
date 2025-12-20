# OKD Cluster Network Configuration

## Overview
This document details the network configuration for the OKD cluster at okd.claffey.cloud, including VLAN design, IP addressing, load balancing, and integration with the OPNsense firewall.

## Network Architecture Diagram

```
Internet
    │
    ├─ WAN (igc0)
    │
[OPNsense Firewall - 10.0.1.1]
    │
    ├─ VLAN 1 (Management) - 10.0.1.0/24
    │   ├─ Firewall: 10.0.1.1
    │   ├─ TrueNAS Management: 10.0.0.62
    │   ├─ Switch: 10.0.0.31
    │   └─ Workstations
    │
    ├─ VLAN 20 (OKD-Infra) - 10.0.20.0/24
    │   ├─ Gateway: 10.0.20.1
    │   ├─ DNS (Unbound): 10.0.20.2
    │   ├─ API VIP: 10.0.20.5
    │   ├─ Apps Internal VIP: 10.0.20.6
    │   ├─ K81 (Control Plane): 10.0.20.100
    │   ├─ K82 (Control Plane): 10.0.20.101
    │   └─ K83 (Control Plane): 10.0.20.102
    │
    ├─ VLAN 30 (OKD-Storage) - 10.0.30.0/24
    │   ├─ Gateway: 10.0.30.1
    │   ├─ TrueNAS Storage Interface
    │   └─ Node Storage Interfaces (NFS/iSCSI)
    │
    └─ VLAN 40 (Services) - 10.0.40.0/24
        ├─ Gateway: 10.0.40.1
        └─ Apps External VIP: 10.0.40.10

Internal OKD Networks:
    ├─ Cluster Network: 10.128.0.0/14 (Pod network)
    └─ Service Network: 172.30.0.0/16 (ClusterIP services)
```

## VLAN Configuration

### VLAN 1 - Management
**Purpose**: Infrastructure management and administrative access

- **Subnet**: 10.0.1.0/24
- **Gateway**: 10.0.1.1 (OPNsense)
- **DNS**: 10.0.20.2 (Unbound), 10.0.1.1 (OPNsense)
- **DHCP**: Enabled (Kea DHCP server on OPNsense)

**Key Hosts**:
- 10.0.1.1 - OPNsense Firewall
- 10.0.0.31 - TRENDnet TEG-3102WS Switch
- 10.0.0.62 - TrueNAS Scale Management Interface
- 10.0.1.21 - WiFi AP 1
- 10.0.1.22 - WiFi AP 2

### VLAN 20 - OKD Infrastructure
**Purpose**: OKD cluster nodes, control plane, and internal services

- **Subnet**: 10.0.20.0/24
- **Gateway**: 10.0.20.1 (OPNsense)
- **DNS**: 10.0.20.2 (Unbound)
- **DHCP**: Enabled with static reservations for cluster nodes

**Virtual IPs**:
- 10.0.20.5 - API Load Balancer VIP
- 10.0.20.6 - Internal Apps Ingress VIP

**Cluster Nodes**:
| Hostname | MAC Address | IP Address | Role |
|----------|-------------|------------|------|
| K81 | 58:47:ca:7c:33:ae | 10.0.20.100 | Control Plane + Worker |
| K82 | 58:47:ca:7b:8f:78 | 10.0.20.101 | Control Plane + Worker |
| K83 | 58:47:ca:7d:ee:43 | 10.0.20.102 | Control Plane + Worker |

**Access**:
- Full access from VLAN 1 (Management)
- Can access VLAN 30 (Storage)
- Can access Internet via NAT

### VLAN 30 - OKD Storage Backend
**Purpose**: Isolated storage network for NFS/iSCSI traffic

- **Subnet**: 10.0.30.0/24
- **Gateway**: 10.0.30.1 (OPNsense)
- **DHCP**: No (static IPs only)

**Hosts**:
- TrueNAS Storage Interface
- K81, K82, K83 secondary NICs (storage)

**Security**:
- **Isolated**: Only accessible from VLAN 20 (OKD-Infra)
- No internet access
- No access from other VLANs

**Purpose**: High-performance, isolated storage traffic between cluster nodes and TrueNAS.

### VLAN 40 - Services (External Access)
**Purpose**: Published OKD services and applications

- **Subnet**: 10.0.40.0/24
- **Gateway**: 10.0.40.1 (OPNsense)
- **DHCP**: No

**Virtual IPs**:
- 10.0.40.10 - External Apps Ingress VIP

**Access**:
- Accessible from VLAN 1 (Management)
- Published applications use this network for external ingress

**Note**: This VLAN has minimal hosts - primarily used for VIP-based services.

## OKD Internal Networking

### Cluster Network (Pod Network)
- **CIDR**: 10.128.0.0/14
- **Host Prefix**: /23
- **CNI**: OVN-Kubernetes
- **Type**: Overlay network using Geneve encapsulation

**Allocation**:
Each node receives a /23 subnet from the cluster network:
- K81: 10.128.0.0/23 (example)
- K82: 10.128.2.0/23 (example)
- K83: 10.128.4.0/23 (example)

**Purpose**: Pod-to-pod communication within the cluster.

### Service Network (ClusterIP)
- **CIDR**: 172.30.0.0/16
- **Type**: Virtual IPs for Kubernetes services

**Purpose**: Internal cluster services (ClusterIP type). These IPs are only routable within the cluster.

### MetalLB Configuration
MetalLB provides load balancer IPs for services of type LoadBalancer:
- **Mode**: L2 mode (ARP-based)
- **IP Pool**: Uses VIPs configured on OPNsense (10.0.20.6, 10.0.40.10)

## Load Balancing Architecture

### API Load Balancer (10.0.20.5)
**Purpose**: Load balance Kubernetes API requests to control plane nodes

**Configuration**:
- **VIP Location**: VLAN 20 (OKD-Infra)
- **Backend Nodes**:
  - K81: 10.0.20.100:6443
  - K82: 10.0.20.101:6443
  - K83: 10.0.20.102:6443
- **Protocol**: TCP/6443 (HTTPS)
- **Health Check**: TCP connect to port 6443

**DNS Entries**:
- api.okd.claffey.cloud → 10.0.20.5
- api-int.okd.claffey.cloud → 10.0.20.5

### Internal Apps Ingress (10.0.20.6)
**Purpose**: Internal application ingress for cluster services

**Configuration**:
- **VIP Location**: VLAN 20 (OKD-Infra)
- **Backend**: Router pods on cluster nodes
- **Protocol**: HTTP/80, HTTPS/443

**DNS Entries**:
- *.apps-int.okd.claffey.cloud → 10.0.20.6

### External Apps Ingress (10.0.40.10)
**Purpose**: External application ingress accessible from management network

**Configuration**:
- **VIP Location**: VLAN 40 (Services)
- **Backend**: Router pods on cluster nodes via MetalLB
- **Protocol**: HTTP/80, HTTPS/443

**DNS Entries**:
- *.apps.okd.claffey.cloud → 10.0.40.10

## DNS Configuration

### Unbound DNS Server
**Location**: 10.0.20.2 (VLAN 20)

**Required DNS Zones**:

```dns
# API Endpoints
api.okd.claffey.cloud.           A    10.0.20.5
api-int.okd.claffey.cloud.       A    10.0.20.5

# Application Ingress (External)
*.apps.okd.claffey.cloud.        A    10.0.40.10

# Application Ingress (Internal)
*.apps-int.okd.claffey.cloud.    A    10.0.20.6

# Control Plane Nodes
k81.okd.claffey.cloud.           A    10.0.20.100
k82.okd.claffey.cloud.           A    10.0.20.101
k83.okd.claffey.cloud.           A    10.0.20.102

# Reverse DNS for nodes
100.20.0.10.in-addr.arpa.        PTR  k81.okd.claffey.cloud.
101.20.0.10.in-addr.arpa.        PTR  k82.okd.claffey.cloud.
102.20.0.10.in-addr.arpa.        PTR  k83.okd.claffey.cloud.
```

**DNS Forwarders** (configured in Unbound):
- Cloudflare DNS: 1.1.1.1, 1.0.0.1
- Quad9 DNS: 9.9.9.9, 149.112.112.112
- Google DNS: 8.8.8.8, 8.8.4.4

### DNS Over TLS (DoT)
OPNsense Unbound is configured with DNS-over-TLS to upstream providers:
- Cloudflare: cloudflare-dns.com (1.1.1.1:853, 1.0.0.1:853)
- Quad9: dns.quad9.net (9.9.9.9:853, 149.112.112.112:853)
- Google: dns.google (8.8.8.8:853, 8.8.4.4:853)

## DHCP Configuration

### Kea DHCP Server (OPNsense)
DHCP is provided by Kea DHCP server running on OPNsense.

#### VLAN 20 (OKD-Infra) Configuration
```yaml
Subnet: 10.0.20.0/24
Gateway: 10.0.20.1
DNS Servers: 10.0.20.2, 10.0.1.1
Domain: claffey.cloud
DHCP Range: 10.0.20.100 - 10.0.20.200

Static Reservations:
  - MAC: 58:47:ca:7c:33:ae
    IP: 10.0.20.100
    Hostname: K81

  - MAC: 58:47:ca:7b:8f:78
    IP: 10.0.20.101
    Hostname: K82

  - MAC: 58:47:ca:7d:ee:43
    IP: 10.0.20.102
    Hostname: K83
```

## Firewall Rules

### Inter-VLAN Communication

**VLAN 1 (Management) → OKD VLANs**:
- Allow all traffic to VLAN 20 (OKD-Infra)
- Allow all traffic to VLAN 30 (OKD-Storage)
- Allow all traffic to VLAN 40 (Services)

**VLAN 20 (OKD-Infra) Rules**:
- Allow access to VLAN 30 (OKD-Storage) - NFS/iSCSI
- Allow access to Internet via NAT
- Allow incoming connections on:
  - TCP/6443 (Kubernetes API)
  - TCP/22623 (Machine Config Server)
  - TCP/80, TCP/443 (Router/Ingress)

**VLAN 30 (OKD-Storage) Rules**:
- **DENY** all traffic except from VLAN 20
- **DENY** internet access
- Allow only NFS (TCP/2049, UDP/2049) and iSCSI (TCP/3260) from VLAN 20

**VLAN 40 (Services) Rules**:
- Allow access from VLAN 1 (Management)
- Allow incoming on TCP/80, TCP/443 for published apps
- NAT enabled for internet access

### Port Forwarding
External ports forwarded to the cluster (if needed):
- None configured (internal access only via VPN recommended)

## Network Performance Optimization

### MTU Configuration
- **Physical NICs**: 1500 (default)
- **VLANs**: 1500
- **OVN Geneve Tunnel**: 1400 (to account for overlay overhead)

### Quality of Service (QoS)
- VLAN 30 (Storage): Priority traffic (PCP 0)
- VLAN 20 (OKD-Infra): Normal priority
- VLAN 40 (Services): Normal priority

## Troubleshooting

### Network Connectivity Tests

#### From Cluster Node to Gateway
```bash
# SSH to a node
ssh core@10.0.20.100

# Test gateway
ping 10.0.20.1

# Test DNS
dig api.okd.claffey.cloud
nslookup api.okd.claffey.cloud 10.0.20.2

# Test Internet
ping 8.8.8.8
curl -I https://www.google.com
```

#### From Cluster Node to Storage
```bash
# Test TrueNAS connectivity
ping <truenas-storage-ip>

# Test NFS mount
showmount -e <truenas-storage-ip>

# Test iSCSI
iscsiadm -m discovery -t st -p <truenas-storage-ip>
```

#### From Management Network
```bash
# Test API endpoint
curl -k https://api.okd.claffey.cloud:6443/healthz

# Test Apps ingress
curl http://apps.okd.claffey.cloud
```

### Common Issues

**Issue**: Nodes cannot reach API endpoint
- Check VIP configuration on OPNsense (10.0.20.5)
- Verify DNS resolution for api.okd.claffey.cloud
- Check firewall rules allow TCP/6443

**Issue**: Pods cannot reach internet
- Verify NAT is configured on OPNsense for VLAN 20
- Check default route on nodes: `ip route`
- Test DNS resolution from pod: `oc exec <pod> -- nslookup google.com`

**Issue**: Storage mount failures
- Verify VLAN 30 connectivity from nodes
- Check firewall rules allow NFS/iSCSI from VLAN 20 to VLAN 30
- Verify TrueNAS NFS/iSCSI services are running

## References

- [OPNsense VLAN Configuration](../network/OPNsense-FIREWALL/OPNSense_VLAN_Configuration_Details.md)
- [VLAN Design Document](../network/VLANs/README.md)
- [Firewall Configuration](Firewall_Configuration.md)
- [OKD Networking Documentation](https://docs.okd.io/latest/networking/understanding-networking.html)
