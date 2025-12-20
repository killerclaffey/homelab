# OKD Cluster Firewall Configuration

## Overview
This document details the OPNsense firewall configuration for the OKD cluster, including VLAN interfaces, virtual IPs, DHCP reservations, DNS records, and firewall rules.

## OPNsense System Information

### Hardware & Network Interfaces
- **Hostname**: firewall.claffey.cloud
- **Domain**: claffey.cloud
- **Timezone**: America/Detroit
- **Platform**: Intel (with CPU microcode updates enabled)

### Physical Interfaces
| Interface | Device | Description | Configuration |
|-----------|--------|-------------|---------------|
| WAN | igc0 | Internet Connection | DHCP (IPv4), DHCPv6 (IPv6) |
| LAN | igc1 | Internal Network | 10.0.0.1/24 (Base LAN) |
| OPT2 | igc3 | Additional Network | 172.16.0.1/28 |

## VLAN Configuration

All VLANs are configured on the LAN interface (igc1):

| VLAN ID | Interface | Name | Subnet | Description |
|---------|-----------|------|--------|-------------|
| 1 | vlan01 | Management | 10.0.1.0/24 | Infrastructure, workstations, living room |
| 20 | vlan02 | OKDInfra | 10.0.20.0/24 | Cluster nodes, bootstrap, DNS |
| 30 | vlan03 | OKDStorage | 10.0.30.0/24 | TrueNAS NFS/iSCSI backend |
| 40 | vlan04 | Services | 10.0.40.0/24 | Published OKD services (HAProxy VIP) |
| 50 | vlan05 | IOTSurveillance | 10.0.50.0/24 | IoT devices, cameras (WiFi SSID: Home-IoT) |
| 60 | vlan06 | GameCon | 10.0.60.0/24 | Gaming devices (uPNP enabled) |
| 70 | vlan07 | Helium | 10.0.70.0/24 | Helium Hot Spot Iso Network |
| 99 | vlan08 | GuestWifi | 10.0.99.0/24 | Guest network |

### OKD-Related VLAN Interfaces

#### VLAN 20 - OKD Infrastructure
```
Interface: opt4 (vlan02)
Description: OKDInfra
Enabled: Yes
IP Address: 10.0.20.1/24
```

**Purpose**: Cluster nodes, control plane, internal services

#### VLAN 30 - OKD Storage
```
Interface: opt5 (vlan03)
Description: OKDStorage
Enabled: Yes
IP Address: 10.0.30.1/24
```

**Purpose**: Isolated storage network for TrueNAS NFS/iSCSI traffic

#### VLAN 40 - Services
```
Interface: opt6 (vlan04)
Description: Services
Enabled: Yes
IP Address: 10.0.40.1/32
```

**Purpose**: Published OKD services and external application access

## Virtual IP Addresses (VIPs)

Virtual IPs provide high-availability endpoints for the OKD cluster:

### Scrutiny Monitoring (Non-OKD)
```yaml
VIP: 10.0.0.2/24
Interface: lan
Mode: IP Alias
Description: scrutiny
Purpose: HDD health monitoring service
```

### OKD API Load Balancer
```yaml
VIP: 10.0.20.5/24
Interface: opt4 (OKDInfra - VLAN 20)
Mode: IP Alias
Description: OKD API VIP - Load balances API requests to master nodes
Purpose: Kubernetes API endpoint
DNS: api.okd.claffey.cloud, api-int.okd.claffey.cloud
Backends: K81:6443, K82:6443, K83:6443
```

### OKD Apps Internal VIP
```yaml
VIP: 10.0.20.6/24
Interface: opt4 (OKDInfra - VLAN 20)
Mode: IP Alias
Description: OKD Apps Internal VIP - Load balances internal app requests
Purpose: Internal application ingress
DNS: *.apps-int.okd.claffey.cloud
```

### OKD Apps External VIP
```yaml
VIP: 10.0.40.10/24
Interface: opt6 (Services - VLAN 40)
Mode: IP Alias
Description: OKD Apps External Access - Published OKD services
Purpose: External application ingress
DNS: *.apps.okd.claffey.cloud
```

## DHCP Configuration (Kea)

### VLAN 20 (OKD-Infra) Subnet
```yaml
Subnet: 10.0.20.0/24
DHCP Range: 10.0.20.100 - 10.0.20.200
Gateway: Auto-configured (10.0.20.1)
DNS: Auto-configured
Domain: Auto-configured (claffey.cloud)
```

#### Static DHCP Reservations - OKD Cluster Nodes

**K81 - Control Plane Node 1**
```yaml
MAC Address: 58:47:ca:7c:33:ae
IP Address: 10.0.20.100
Hostname: K81
Description: OKD Control Plane Node 1
```

**K82 - Control Plane Node 2**
```yaml
MAC Address: 58:47:ca:7b:8f:78
IP Address: 10.0.20.101
Hostname: K82
Description: OKD Control Plane Node 2
```

**K83 - Control Plane Node 3**
```yaml
MAC Address: 58:47:ca:7d:ee:43
IP Address: 10.0.20.102
Hostname: K83
Description: OKD Control Plane Node 3
```

### Other VLAN DHCP Configuration

#### VLAN 1 (Management)
```yaml
Subnet: 10.0.1.0/24
DHCP Range: 10.0.1.100 - 10.0.1.250
Domain: claffey.cloud
```

#### VLAN 50 (IoT/Surveillance)
```yaml
Subnet: 10.0.50.0/24
DHCP Range: 10.0.50.100 - 10.0.50.200
```

#### VLAN 99 (Guest WiFi)
```yaml
Subnet: 10.0.99.0/24
DHCP Range: 10.0.99.100 - 10.0.99.200
```

## DNS Configuration (Unbound)

### General Settings
- **Enabled**: Yes
- **Listen Port**: 53
- **Active Interfaces**: lan, opt2
- **DNSSEC**: Enabled
- **Register DHCP Leases**: Yes
- **Register DHCP Static Mappings**: Yes
- **Domain**: claffey.cloud

### DNS Host Overrides

#### Infrastructure Hosts
```dns
firewall.claffey.cloud.     A    10.0.0.1      # OPNsense Firewall
nas.claffey.cloud.          A    10.0.0.62     # TrueNAS Scale
nasweb.claffey.cloud.       A    10.0.0.142    # TrueNAS Web UI
switch.claffey.cloud.       A    10.0.0.31     # TRENDnet TEG-3102WS
scrutiny.claffey.cloud.     A    10.0.0.2      # Scrutiny HAProxy
```

#### OKD Cluster DNS (To Be Added)
```dns
# API Endpoints
api.okd.claffey.cloud.           A    10.0.20.5
api-int.okd.claffey.cloud.       A    10.0.20.5

# Application Ingress
*.apps.okd.claffey.cloud.        A    10.0.40.10
*.apps-int.okd.claffey.cloud.    A    10.0.20.6

# Control Plane Nodes
k81.okd.claffey.cloud.           A    10.0.20.100
k82.okd.claffey.cloud.           A    10.0.20.101
k83.okd.claffey.cloud.           A    10.0.20.102
```

**Note**: Wildcard DNS entries may require additional configuration in Unbound using custom options.

### DNS Forwarders (DNS over TLS)

OPNsense is configured with DNS-over-TLS (DoT) to multiple upstream providers:

#### Cloudflare DNS
```yaml
Primary:
  Server: 1.1.1.1
  Port: 853
  Verify: cloudflare-dns.com
  Enabled: Yes

Secondary:
  Server: 1.0.0.1
  Port: 853
  Verify: cloudflare-dns.com
  Enabled: Yes
```

#### Quad9 DNS
```yaml
Primary:
  Server: 9.9.9.9
  Port: 853
  Verify: dns.quad9.net
  Enabled: Yes

Secondary:
  Server: 149.112.112.112
  Port: 853
  Verify: dns.quad9.net
  Enabled: Yes
```

#### Google DNS
```yaml
Primary:
  Server: 8.8.8.8
  Port: 853
  Verify: dns.google
  Enabled: Yes

Secondary:
  Server: 8.8.4.4
  Port: 853
  Verify: dns.google
  Enabled: Yes
```

### Advanced DNS Settings
- **Private Domain**: claffey.cloud
- **Private Address Ranges**:
  - 0.0.0.0/8, 100.64.0.0/10, 169.254.0.0/16
  - 172.16.0.0/12, 192.0.2.0/24, 192.168.0.0/16
  - 198.18.0.0/15, 198.51.100.0/24, 203.0.113.0/24
  - ::1/128, 2001:db8::/32, fc00::/8, fd00::/8, fe80::/10

## Firewall Rules

### Default LAN Rules
```yaml
# Allow LAN to any (IPv4)
Type: pass
Protocol: IPv4
Interface: lan
Source: lan network
Destination: any
Description: Default allow LAN to any rule

# Allow LAN to any (IPv6)
Type: pass
Protocol: IPv6
Interface: lan
Source: lan network
Destination: any
Description: Default allow LAN IPv6 to any rule
```

### Required OKD Firewall Rules

#### VLAN 20 (OKD-Infra) Rules
```yaml
# Allow Management VLAN access to OKD-Infra
Type: pass
Interface: opt4 (OKDInfra)
Source: 10.0.1.0/24 (Management)
Destination: 10.0.20.0/24 (OKD-Infra)
Ports: Any
Description: Allow management access to OKD cluster

# Allow OKD-Infra to OKD-Storage
Type: pass
Interface: opt4 (OKDInfra)
Source: 10.0.20.0/24 (OKD-Infra)
Destination: 10.0.30.0/24 (OKD-Storage)
Ports: 2049 (NFS), 3260 (iSCSI)
Description: Allow cluster nodes to access storage

# Allow OKD-Infra to Internet
Type: pass
Interface: opt4 (OKDInfra)
Source: 10.0.20.0/24 (OKD-Infra)
Destination: any
Description: Allow cluster internet access for image pulls and updates

# Allow incoming to API VIP
Type: pass
Interface: opt4 (OKDInfra)
Destination: 10.0.20.5 (API VIP)
Port: 6443
Protocol: TCP
Description: Allow Kubernetes API access

# Allow incoming to Apps Internal VIP
Type: pass
Interface: opt4 (OKDInfra)
Destination: 10.0.20.6 (Apps Internal VIP)
Ports: 80, 443
Protocol: TCP
Description: Allow internal app ingress
```

#### VLAN 30 (OKD-Storage) Rules
```yaml
# DENY all except from OKD-Infra
Type: reject
Interface: opt5 (OKDStorage)
Source: any (except 10.0.20.0/24)
Destination: 10.0.30.0/24
Description: Isolate storage network

# Allow OKD-Infra to Storage
Type: pass
Interface: opt5 (OKDStorage)
Source: 10.0.20.0/24 (OKD-Infra)
Destination: 10.0.30.0/24 (OKD-Storage)
Ports: 2049 (NFS), 3260 (iSCSI)
Protocol: TCP/UDP
Description: Allow NFS and iSCSI from cluster nodes

# DENY internet from Storage VLAN
Type: reject
Interface: opt5 (OKDStorage)
Source: 10.0.30.0/24
Destination: any (external)
Description: Prevent storage network internet access
```

#### VLAN 40 (Services) Rules
```yaml
# Allow Management VLAN to Services
Type: pass
Interface: opt6 (Services)
Source: 10.0.1.0/24 (Management)
Destination: 10.0.40.0/24 (Services)
Description: Allow management access to published services

# Allow incoming to Apps External VIP
Type: pass
Interface: opt6 (Services)
Destination: 10.0.40.10 (Apps External VIP)
Ports: 80, 443
Protocol: TCP
Description: Allow external app ingress
```

## NAT Configuration

### Outbound NAT
```yaml
Mode: Automatic
```

Automatic outbound NAT is configured for all internal VLANs to access the internet via the WAN interface.

### Port Forwarding
No external port forwarding is configured for OKD cluster services. All access is internal-only or via VPN (recommended for security).

## High Availability & Monitoring

### Monit Service Monitoring
```yaml
Enabled: No (currently disabled)
```

### Backup Configuration
```yaml
# Git Backup
Enabled: Yes
Repository: ssh://github.com/killerclaffey/opnsense.git
Branch: main
Automatic Backups: 15 versions retained
```

Firewall configuration is automatically backed up to GitHub repository.

## SSL/TLS Certificates

### ACME Client (Let's Encrypt)
```yaml
Enabled: No (currently disabled)
Account: Lets Encrypt (rclaffey77@gmail.com)
CA: letsencrypt

Certificates:
  - firewall.claffey.cloud
    Status: Active
    Validation: DNS-01 (Cloudflare API)
```

### Cloudflare DNS Integration
```yaml
API Token: [CONFIGURED]
Account ID: fb8311a8698a4972173ae881c1c9f97f
```

Used for automated DNS validation when obtaining SSL certificates.

## HAProxy Configuration

### Scrutiny Frontend (Non-OKD)
```yaml
Name: scrutiny_frontend
Bind: 10.0.0.2:80
SSL: Enabled
Mode: HTTP
Backend: scrutiny_backend
```

**Note**: HAProxy can be used to load balance API and Apps traffic to OKD cluster nodes if needed.

## Security Settings

### System Security
- **Bogons Update**: Weekly
- **Disable VLAN Hardware Filter**: Yes
- **Disable Checksum Offloading**: Yes
- **Disable Segmentation Offloading**: Yes
- **Disable Large Receive Offloading**: Yes

### SSH Configuration
```yaml
Enabled: Yes
Interfaces: lan (Management only)
Port: 22
Password Auth: Enabled
Root Login: Enabled
Group: admins
```

### Firewall Optimization
```yaml
Optimization: Conservative
Firewall Maximum States: Default
Firewall Advanced: pf_share_forward enabled
```

## Recommended Configuration Additions

### 1. DNS Host Overrides for OKD
Add the following DNS entries to Unbound:

```bash
# Via OPNsense Web UI: Services → Unbound DNS → Overrides → Host Overrides
api.okd.claffey.cloud         → 10.0.20.5
api-int.okd.claffey.cloud     → 10.0.20.5
k81.okd.claffey.cloud         → 10.0.20.100
k82.okd.claffey.cloud         → 10.0.20.101
k83.okd.claffey.cloud         → 10.0.20.102
```

For wildcard DNS (*.apps.okd.claffey.cloud), add custom Unbound configuration:

```
# System → Settings → Advanced → Custom Options
server:
  local-zone: "apps.okd.claffey.cloud." redirect
  local-data: "apps.okd.claffey.cloud. A 10.0.40.10"

  local-zone: "apps-int.okd.claffey.cloud." redirect
  local-data: "apps-int.okd.claffey.cloud. A 10.0.20.6"
```

### 2. Firewall Rules for OKD
Add specific firewall rules as documented in the "Required OKD Firewall Rules" section above.

### 3. HAProxy for API Load Balancing (Optional)
If using HAProxy for API load balancing instead of VIP-only:

```yaml
Frontend: okd_api_frontend
  Bind: 10.0.20.5:6443
  Mode: TCP
  Backend: okd_api_backend

Backend: okd_api_backend
  Mode: TCP
  Servers:
    - k81: 10.0.20.100:6443
    - k82: 10.0.20.101:6443
    - k83: 10.0.20.102:6443
  Health Check: TCP connection to port 6443
```

## Troubleshooting

### Check VLAN Configuration
```bash
# Via SSH to OPNsense
ifconfig vlan02  # OKD-Infra
ifconfig vlan03  # OKD-Storage
ifconfig vlan04  # Services
```

### Check Virtual IPs
```bash
ifconfig opt4  # Should show 10.0.20.1 and 10.0.20.5, 10.0.20.6
ifconfig opt6  # Should show 10.0.40.10
```

### Check Firewall States
```bash
# Via OPNsense Web UI
Firewall → Diagnostics → States

# Via SSH
pfctl -s state | grep 10.0.20
```

### Test DNS Resolution
```bash
# From OPNsense
dig @10.0.20.2 api.okd.claffey.cloud
nslookup api.okd.claffey.cloud 10.0.20.2

# From cluster node
dig api.okd.claffey.cloud
dig api-int.okd.claffey.cloud
```

### Check DHCP Leases
```bash
# Via OPNsense Web UI
Services → Kea DHCP → Leases

# Look for K81, K82, K83 with correct IPs
```

## References

- [OPNsense Documentation](https://docs.opnsense.org/)
- [OPNsense VLAN Configuration](../network/OPNsense-FIREWALL/OPNSense_VLAN_Configuration_Details.md)
- [Network Configuration](Network_Configuration.md)
- [Main OKD Cluster Documentation](README.md)
