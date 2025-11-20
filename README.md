# OKD Homelab Complete Setup Plan

## Hardware Inventory

### Networking Equipment
- **Firewall**: Protectli VP2430 running OPNSense
- **Main Switch**: Smart managed switch (VLAN capable)
- **Downstream Switch**: Living room managed switch
- **WiFi APs**: 2x WiFi Access Points
- **KVM**: Raspberry Pi with GL.iNet Comet (GL-RM1) Remote KVM

### Compute & Storage
- **Storage Node**: Minisforum N5 Pro
  - 96GB RAM
  - 3x 28TB HDD (RAIDZ1/RAIDZ2)
  - 2x 4TB NVMe SSD (mirrored)
  - Running TrueNAS SCALE
  
- **OKD Cluster Nodes**: 3x Minisforum UM890
  - 96GB RAM each
  - 512GB SSD each
  - Role: Control Plane + Worker (compact cluster)

---

## Network Map

# OKD Homelab Network Diagram

```mermaid
graph TB
    subgraph Internet
        WAN[Internet]
    end

    subgraph "Protectli VP2430 - OPNSense Firewall"
        FW[OPNSense<br/>HAProxy Load Balancer<br/>VLAN Router]
        VIP1[VIP: 10.0.20.5<br/>API]
        VIP2[VIP: 10.0.20.6<br/>Apps Internal]
        VIP3[VIP: 10.0.40.10<br/>Apps External]
    end

    subgraph "Main Managed Switch"
        SW1[Core Switch<br/>VLANs: 1,10,20,30,40,50,60,99]
    end

    subgraph "VLAN 1 - Management<br/>10.0.1.0/24"
        SW1M[Switch Mgmt<br/>10.0.1.2]
        SW2M[Living Room SW<br/>10.0.1.3]
        TNM[TrueNAS Mgmt<br/>10.0.1.4]
        PI[Pi + KVM<br/>10.0.1.10<br/>Tailscale]
        AP1M[WiFi AP1<br/>10.0.1.21]
        AP2M[WiFi AP2<br/>10.0.1.22]
    end

    subgraph "VLAN 10 - Homelab<br/>10.0.10.0/24"
        PC[Your Workstation<br/>10.0.10.100]
        DEV[Dev Machines<br/>DHCP]
    end

    subgraph "VLAN 20 - OKD Infrastructure<br/>10.0.20.0/24"
        TN20[TrueNAS<br/>10.0.20.2<br/>DNS/HTTP]
        M1[Master1<br/>10.0.20.11<br/>UM890]
        M2[Master2<br/>10.0.20.12<br/>UM890]
        M3[Master3<br/>10.0.20.13<br/>UM890]
        BOOT[Bootstrap<br/>10.0.20.10<br/>Temporary]
    end

    subgraph "VLAN 30 - Storage Backend<br/>10.0.30.0/24"
        TN30[TrueNAS Storage<br/>10.0.30.2<br/>NFS/iSCSI]
        M1S[Master1 Storage<br/>10.0.30.11]
        M2S[Master2 Storage<br/>10.0.30.12]
        M3S[Master3 Storage<br/>10.0.30.13]
    end

    subgraph "VLAN 40 - Services<br/>10.0.40.0/24"
        SVC[Services VIP<br/>10.0.40.10<br/>HAProxy → OKD Apps]
    end

    subgraph "VLAN 50 - IoT/WiFi<br/>10.0.50.0/24"
        WIFI1[WiFi Clients<br/>DHCP]
        IOT[IoT Devices<br/>DHCP]
    end

    subgraph "VLAN 60 - Living Room<br/>10.0.60.0/24"
        SW2[Living Room Switch]
        LR1[TV/Devices<br/>DHCP]
    end

    subgraph "VLAN 99 - Guest WiFi<br/>10.0.99.0/24"
        GUEST[Guest Devices<br/>DHCP<br/>Isolated]
    end

    subgraph "TrueNAS SCALE - N5 Pro<br/>96GB RAM, 2x4TB NVMe, 3x28TB HDD"
        TNFAST[fast-pool<br/>NVMe Mirror<br/>Containers/VMs]
        TNBULK[bulk-pool<br/>RAIDZ1/RAIDZ2<br/>OKD Storage]
        BIND[Bind9 DNS<br/>Container]
        NGINX[Nginx HTTP<br/>Container]
        NFS[NFS Service]
    end

    subgraph "WiFi Access Points"
        AP1[WiFi AP 1<br/>SSIDs: Home/Guest]
        AP2[WiFi AP 2<br/>SSIDs: Home/Guest]
    end

    subgraph "OKD Cluster Pods"
        POD1[Web Apps]
        POD2[Services]
        POD3[Registry]
    end

    subgraph "Remote Access"
        TS[Tailscale VPN<br/>100.64.0.0/10]
        REMOTE[Remote Users]
    end

    %% Internet Connections
    WAN -->|WAN Port| FW
    
    %% Firewall to Switch
    FW -->|Trunk<br/>All VLANs| SW1
    
    %% Switch to Devices
    SW1 -.->|VLAN 1| SW1M
    SW1 -.->|VLAN 1| TNM
    SW1 -.->|VLAN 1| PI
    SW1 -.->|VLAN 1| AP1M
    SW1 -.->|VLAN 1| AP2M
    SW1 -.->|VLAN 10| PC
    SW1 -.->|VLAN 10| DEV
    SW1 -.->|VLAN 20| TN20
    SW1 -.->|VLAN 20| M1
    SW1 -.->|VLAN 20| M2
    SW1 -.->|VLAN 20| M3
    SW1 -.->|VLAN 30| TN30
    SW1 -.->|VLAN 30| M1S
    SW1 -.->|VLAN 30| M2S
    SW1 -.->|VLAN 30| M3S
    SW1 -.->|VLAN 50| AP1
    SW1 -.->|VLAN 50| AP2
    SW1 -.->|Trunk<br/>VLAN 1,60,99| SW2
    
    %% Living Room Switch
    SW2 -.->|VLAN 60| LR1
    
    %% WiFi APs to Clients
    AP1 -.->|VLAN 50| WIFI1
    AP1 -.->|VLAN 50| IOT
    AP2 -.->|VLAN 50| WIFI1
    AP1 -.->|VLAN 99| GUEST
    AP2 -.->|VLAN 99| GUEST
    
    %% TrueNAS Internal
    TN20 --> BIND
    TN20 --> NGINX
    TN30 --> NFS
    TNFAST --> BIND
    TNFAST --> NGINX
    TNBULK --> NFS
    
    %% HAProxy VIPs
    FW --> VIP1
    FW --> VIP2
    FW --> VIP3
    
    %% HAProxy to Masters
    VIP1 -.->|API<br/>6443| M1
    VIP1 -.->|API<br/>6443| M2
    VIP1 -.->|API<br/>6443| M3
    VIP2 -.->|Ingress<br/>80/443| M1
    VIP2 -.->|Ingress<br/>80/443| M2
    VIP2 -.->|Ingress<br/>80/443| M3
    VIP3 -.->|Ingress<br/>80/443| M1
    VIP3 -.->|Ingress<br/>80/443| M2
    VIP3 -.->|Ingress<br/>80/443| M3
    
    %% Storage Connections
    NFS -.->|NFS<br/>2049| M1S
    NFS -.->|NFS<br/>2049| M2S
    NFS -.->|NFS<br/>2049| M3S
    
    %% Masters to Pods
    M1 --> POD1
    M2 --> POD2
    M3 --> POD3
    
    %% Tailscale
    REMOTE --> TS
    TS -.->|VPN| PI
    TS -.->|Subnet Routes| FW
    
    %% Client Access to Services
    PC -.->|HTTPS| SVC
    WIFI1 -.->|HTTPS| SVC
    LR1 -.->|HTTPS| SVC
    
    %% Styling
    classDef firewall fill:#ff6b6b,stroke:#c92a2a,stroke-width:3px,color:#fff
    classDef switch fill:#4ecdc4,stroke:#087f5b,stroke-width:2px,color:#000
    classDef server fill:#95e1d3,stroke:#0ca678,stroke-width:2px,color:#000
    classDef storage fill:#ffd93d,stroke:#f08c00,stroke-width:2px,color:#000
    classDef client fill:#a8dadc,stroke:#457b9d,stroke-width:2px,color:#000
    classDef vip fill:#b794f4,stroke:#6b46c1,stroke-width:2px,color:#fff
    classDef vlan fill:#e9ecef,stroke:#868e96,stroke-width:1px,color:#000
    classDef remote fill:#f783ac,stroke:#e64980,stroke-width:2px,color:#000
    
    class FW firewall
    class SW1,SW2 switch
    class M1,M2,M3,TN20,TN30 server
    class TNFAST,TNBULK,NFS storage
    class PC,DEV,WIFI1,IOT,LR1,GUEST client
    class VIP1,VIP2,VIP3,SVC vip
    class TS,REMOTE remote


## Network Architecture

### VLAN Design

| VLAN | Name | Subnet | Purpose | Devices |
|------|------|---------|---------|---------|
| 1 | Management | 10.0.1.0/24 | Infrastructure management | OPNSense, Switches, Pi+KVM, TrueNAS UI |
| 10 | Homelab | 10.0.10.0/24 | Admin workstations | Your PC, dev machines |
| 20 | OKD-Infra | 10.0.20.0/24 | OKD cluster nodes | 3x UM890, bootstrap, DNS |
| 30 | OKD-Storage | 10.0.30.0/24 | Storage backend (isolated) | TrueNAS NFS/iSCSI backend |
| 40 | Services | 10.0.40.0/24 | Published OKD services | HAProxy VIP for apps |
| 50 | IoT/WiFi | 10.0.50.0/24 | WiFi clients, IoT devices | WiFi AP clients |
| 60 | Living-Room | 10.0.60.0/24 | Downstream switch | Living room wired devices |
| 99 | Guest-WiFi | 10.0.99.0/24 | Isolated guest network | Guest devices |

### IP Allocation

#### VLAN 1 - Management (10.0.1.0/24)
- Gateway: 10.0.1.1 (OPNSense)
- Main Switch: 10.0.1.2
- Living Room Switch: 10.0.1.3
- TrueNAS Management: 10.0.1.4
- Raspberry Pi + KVM: 10.0.1.10
- WiFi AP 1: 10.0.1.21
- WiFi AP 2: 10.0.1.22

#### VLAN 10 - Homelab (10.0.10.0/24)
- Gateway: 10.0.10.1
- DHCP Range: 10.0.10.100-200
- Your Workstation: 10.0.10.100

#### VLAN 20 - OKD Infrastructure (10.0.20.0/24)
- Gateway: 10.0.20.1
- TrueNAS (Helper): 10.0.20.2 (DNS, HTTP)
- API VIP: 10.0.20.5 (HAProxy)
- Apps VIP (Internal): 10.0.20.6 (HAProxy)
- Bootstrap: 10.0.20.10 (temporary)
- Master1: 10.0.20.11
- Master2: 10.0.20.12
- Master3: 10.0.20.13

#### VLAN 30 - Storage Backend (10.0.30.0/24)
- Gateway: 10.0.30.1
- TrueNAS Storage: 10.0.30.2
- Master1 Storage: 10.0.30.11
- Master2 Storage: 10.0.30.12
- Master3 Storage: 10.0.30.13

#### VLAN 40 - Services (10.0.40.0/24)
- Gateway: 10.0.40.1
- OKD Apps VIP: 10.0.40.10 (HAProxy → OKD Ingress)

#### VLAN 50 - IoT/WiFi (10.0.50.0/24)
- Gateway: 10.0.50.1
- DHCP Range: 10.0.50.100-200

#### VLAN 60 - Living Room (10.0.60.0/24)
- Gateway: 10.0.60.1
- DHCP Range: 10.0.60.100-200

#### VLAN 99 - Guest WiFi (10.0.99.0/24)
- Gateway: 10.0.99.1
- DHCP Range: 10.0.99.100-200

---

## Phase 1: OPNSense Configuration

### 1.1 Create VLANs
- Navigate to: Interfaces → Other Types → VLAN
- Create VLANs: 1, 10, 20, 30, 40, 50, 60, 99
- Parent interface: Main trunk port

### 1.2 Assign VLAN Interfaces
- Navigate to: Interfaces → Assignments
- Assign each VLAN to an interface
- Configure static IPs for each VLAN gateway
- Enable all interfaces

### 1.3 Configure DHCP Services
- Navigate to: Services → DHCPv4
- Enable DHCP on:
  - VLAN 10 (Homelab): 10.0.10.100-200
  - VLAN 50 (IoT/WiFi): 10.0.50.100-200
  - VLAN 60 (Living Room): 10.0.60.100-200
  - VLAN 99 (Guest): 10.0.99.100-200
- Set DNS servers: 10.0.20.2 (TrueNAS), 10.0.1.1 (OPNSense)

### 1.4 Install HAProxy Plugin
- Navigate to: System → Firmware → Plugins
- Search for: `os-haproxy`
- Click install
- Enable HAProxy: Services → HAProxy → Settings

### 1.5 Create Virtual IPs
- Navigate to: Interfaces → Virtual IPs → Settings

**API VIP (VLAN 20):**
- Interface: VLAN20
- Address: 10.0.20.5/24
- Description: OKD API VIP

**Apps VIP Internal (VLAN 20):**
- Interface: VLAN20
- Address: 10.0.20.6/24
- Description: OKD Apps Internal VIP

**Apps VIP Services (VLAN 40):**
- Interface: VLAN40
- Address: 10.0.40.10/24
- Description: OKD Apps External Access

### 1.6 Configure HAProxy Backends
- Navigate to: Services → HAProxy → Settings → Backend

**Backend 1: okd_api_backend**
- Mode: TCP
- Balance: roundrobin
- Health check: SSL
- Servers:
  - bootstrap: 10.0.20.10:6443 (SSL, no verify)
  - master1: 10.0.20.11:6443 (SSL, no verify)
  - master2: 10.0.20.12:6443 (SSL, no verify)
  - master3: 10.0.20.13:6443 (SSL, no verify)

**Backend 2: okd_machine_config_backend**
- Mode: TCP
- Balance: roundrobin
- Health check: SSL
- Servers:
  - bootstrap: 10.0.20.10:22623 (SSL, no verify)
  - master1: 10.0.20.11:22623 (SSL, no verify)
  - master2: 10.0.20.12:22623 (SSL, no verify)
  - master3: 10.0.20.13:22623 (SSL, no verify)

**Backend 3: okd_ingress_http_backend**
- Mode: TCP
- Balance: roundrobin
- Health check: TCP
- Servers:
  - master1: 10.0.20.11:80
  - master2: 10.0.20.12:80
  - master3: 10.0.20.13:80

**Backend 4: okd_ingress_https_backend**
- Mode: TCP
- Balance: roundrobin
- Health check: SSL
- Servers:
  - master1: 10.0.20.11:443 (SSL, no verify)
  - master2: 10.0.20.12:443 (SSL, no verify)
  - master3: 10.0.20.13:443 (SSL, no verify)

### 1.7 Configure HAProxy Frontends
- Navigate to: Services → HAProxy → Settings → Frontend

**Frontend 1: okd_api_frontend**
- Listen: 10.0.20.5:6443
- Type: TCP
- Backend: okd_api_backend

**Frontend 2: okd_machine_config_frontend**
- Listen: 10.0.20.5:22623
- Type: TCP
- Backend: okd_machine_config_backend

**Frontend 3: okd_http_internal_frontend**
- Listen: 10.0.20.6:80
- Type: TCP
- Backend: okd_ingress_http_backend

**Frontend 4: okd_https_internal_frontend**
- Listen: 10.0.20.6:443
- Type: TCP
- Backend: okd_ingress_https_backend

**Frontend 5: okd_http_services_frontend**
- Listen: 10.0.40.10:80
- Type: TCP
- Backend: okd_ingress_http_backend

**Frontend 6: okd_https_services_frontend**
- Listen: 10.0.40.10:443
- Type: TCP
- Backend: okd_ingress_https_backend

### 1.8 Configure Firewall Rules

#### VLAN 1 (Management)
- Allow: SSH to OPNSense (22)
- Allow: Pi KVM (10.0.1.10) to any (full admin access)
- Allow: Access to switch management interfaces
- Block: Everything else by default

#### VLAN 10 (Homelab)
- Allow: TCP to 10.0.40.10:80,443 (OKD Services)
- Allow: TCP to 10.0.20.5:6443 (OKD API for kubectl)
- Allow: TCP to 10.0.1.4:443 (TrueNAS UI)
- Allow: To !RFC1918 (Internet)
- Block: Everything else

#### VLAN 20 (OKD-Infra)
- Allow: Any to VLAN20 net (cluster mesh)
- Allow: TCP to VLAN30 net:2049,111,3260 (NFS/iSCSI)
- Allow: To !RFC1918 (Internet for image pulls)
- Block: Everything else

#### VLAN 30 (Storage)
- Allow: TCP from VLAN20 net:2049,111,3260 (Storage protocols)
- Block: Everything else

#### VLAN 40 (Services)
- Allow: Established/related connections
- (VIP only, no hosts)

#### VLAN 50 (IoT/WiFi)
- Allow: TCP to 10.0.40.10:80,443 (OKD Services)
- Allow: UDP to 10.0.20.2,10.0.1.1:53 (DNS)
- Allow: To !RFC1918 (Internet)
- Block: To RFC1918 (isolate from infrastructure)

#### VLAN 60 (Living Room)
- Allow: TCP to 10.0.40.10:80,443 (OKD Services)
- Allow: UDP to 10.0.20.2,10.0.1.1:53 (DNS)
- Allow: To !RFC1918 (Internet)
- Block: To RFC1918 (isolate from infrastructure)

#### VLAN 99 (Guest)
- Allow: To !RFC1918 (Internet only)
- Block: To RFC1918 (complete isolation)

### 1.9 Configure DNS Forwarding
- Navigate to: Services → Unbound DNS → Overrides
- Add Domain Override:
  - Domain: okd.lab
  - IP: 10.0.20.2
  - Description: Forward to TrueNAS Bind9

### 1.10 Configure NAT/Outbound
- Navigate to: Firewall → NAT → Outbound
- Mode: Hybrid or Manual
- Create outbound NAT rules for each VLAN → WAN

---

## Phase 2: Switch Configuration

### 2.1 Main Switch Setup

**Create VLANs:**
- Create VLANs: 1, 10, 20, 30, 40, 50, 60, 99

**Port Configuration:**

| Port | Device | Mode | VLANs | PVID |
|------|--------|------|-------|------|
| 1 | OPNSense | Trunk | 1,10,20,30,40,50,60,99 | 1 |
| 2 | Living Room Switch | Trunk | 1,60,99 | 1 |
| 3 | TrueNAS N5 Pro | Trunk | 1,20,30,40 | 1 |
| 4 | UM890 Master1 | Trunk | 1,20,30 | 1 |
| 5 | UM890 Master2 | Trunk | 1,20,30 | 1 |
| 6 | UM890 Master3 | Trunk | 1,20,30 | 1 |
| 7 | WiFi AP 1 | Trunk | 1,50,99 | 1 |
| 8 | WiFi AP 2 | Trunk | 1,50,99 | 1 |
| 9 | Raspberry Pi KVM | Access | 1 | 1 |
| 10 | Your Workstation | Access | 10 | 10 |

### 2.2 Living Room Switch Setup

**Create VLANs:**
- Create VLANs: 1, 60, 99

**Port Configuration:**

| Port | Device | Mode | VLANs | PVID |
|------|--------|------|-------|------|
| 1 | Uplink to Main Switch | Trunk | 1,60,99 | 1 |
| 2-8 | Living Room Devices | Access | 60 | 60 |

---

## Phase 3: TrueNAS SCALE Setup

### 3.1 Install TrueNAS SCALE
- Download latest TrueNAS SCALE ISO
- Create bootable USB
- Boot N5 Pro from USB
- Install to one NVMe drive
- Set admin password
- Reboot

### 3.2 Configure Network Interfaces
- Access web UI at initial IP
- Navigate to: Network → Interfaces

**Configure VLANs:**
- VLAN 1: 10.0.1.4/24 (Management)
- VLAN 20: 10.0.20.2/24 (OKD Infra - Gateway: 10.0.20.1)
- VLAN 30: 10.0.30.2/24 (Storage - No gateway)
- VLAN 40: 10.0.40.2/24 (Services - Gateway: 10.0.40.1)

### 3.3 Create ZFS Pools
- Navigate to: Storage → Create Pool

**Pool 1: fast-pool (NVMe)**
- Name: fast-pool
- Layout: Mirror
- Devices: 2x 4TB NVMe drives

**Pool 2: bulk-pool (HDD)**
- Name: bulk-pool
- Layout: RAIDZ1 (or RAIDZ2 for more safety)
- Devices: 3x 28TB HDDs

### 3.4 Create Datasets
- Navigate to: Datasets

**On fast-pool:**
- fast-pool/apps (for containers)
- fast-pool/vms (for future VMs)

**On bulk-pool:**
- bulk-pool/okd-storage (for OKD PVs)
- bulk-pool/okd-registry (for OKD image registry)

**Set properties:**
- Compression: LZ4
- Record Size: 128K

### 3.5 Enable SSH
- Navigate to: System Settings → Services
- Enable SSH service
- Start automatically: Yes

### 3.6 Deploy Helper Services Container
- SSH to TrueNAS: `ssh admin@10.0.20.2`
- Create directory structure:

```bash
sudo mkdir -p /mnt/fast-pool/apps/okd-helper
cd /mnt/fast-pool/apps/okd-helper
mkdir -p bind/config bind/cache haproxy nginx/html nginx/html/okd
```

**Create docker-compose.yml:**
```yaml
version: '3.8'

services:
  bind9:
    image: ubuntu/bind9:latest
    container_name: okd-dns
    network_mode: "host"
    volumes:
      - ./bind/config:/etc/bind
      - ./bind/cache:/var/cache/bind
    restart: unless-stopped
    environment:
      - BIND9_USER=root
      - TZ=America/New_York

  nginx:
    image: nginx:alpine
    container_name: okd-nginx
    network_mode: "host"
    volumes:
      - ./nginx/html:/usr/share/nginx/html:ro
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
    restart: unless-stopped
```

### 3.7 Configure DNS (Bind9)

**bind/config/named.conf:**
```conf
options {
    directory "/var/cache/bind";
    listen-on port 53 { 127.0.0.1; 10.0.20.2; };
    allow-query { localhost; 10.0.20.0/24; 10.0.10.0/24; 10.0.50.0/24; 10.0.60.0/24; };
    recursion yes;
    forwarders { 10.0.20.1; 1.1.1.1; 8.8.8.8; };
    dnssec-validation no;
};

zone "okd.lab" {
    type master;
    file "/etc/bind/okd.lab.zone";
};

zone "20.0.10.in-addr.arpa" {
    type master;
    file "/etc/bind/20.0.10.rev";
};
```

**bind/config/okd.lab.zone:**
```zone
$TTL 86400
@   IN  SOA ns1.okd.lab. admin.okd.lab. (
            2024010101  ; Serial
            3600        ; Refresh
            1800        ; Retry
            604800      ; Expire
            86400 )     ; Minimum TTL

; Name servers
@           IN  NS  ns1.okd.lab.
ns1         IN  A   10.0.20.2

; Infrastructure
helper      IN  A   10.0.20.2
truenas     IN  A   10.0.20.2

; Load Balancer VIPs
api         IN  A   10.0.20.5
api-int     IN  A   10.0.20.5
*.apps      IN  A   10.0.40.10

; Bootstrap
bootstrap   IN  A   10.0.20.10

; Masters
master1     IN  A   10.0.20.11
master2     IN  A   10.0.20.12
master3     IN  A   10.0.20.13

; etcd
etcd-0      IN  A   10.0.20.11
etcd-1      IN  A   10.0.20.12
etcd-2      IN  A   10.0.20.13

; SRV Records for etcd
_etcd-server-ssl._tcp   IN  SRV 0 10 2380 etcd-0.okd.lab.
_etcd-server-ssl._tcp   IN  SRV 0 10 2380 etcd-1.okd.lab.
_etcd-server-ssl._tcp   IN  SRV 0 10 2380 etcd-2.okd.lab.
```

**bind/config/20.0.10.rev:**
```zone
$TTL 86400
@   IN  SOA ns1.okd.lab. admin.okd.lab. (
            2024010101
            3600
            1800
            604800
            86400 )

@       IN  NS  ns1.okd.lab.

2       IN  PTR helper.okd.lab.
2       IN  PTR truenas.okd.lab.
2       IN  PTR ns1.okd.lab.
5       IN  PTR api.okd.lab.
5       IN  PTR api-int.okd.lab.
10      IN  PTR bootstrap.okd.lab.
11      IN  PTR master1.okd.lab.
12      IN  PTR master2.okd.lab.
13      IN  PTR master3.okd.lab.
```

### 3.8 Configure Nginx

**nginx/nginx.conf:**
```nginx
events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    
    server {
        listen 10.0.20.2:8080;
        server_name _;
        
        location /okd/ {
            root /usr/share/nginx/html;
            autoindex on;
        }
    }
}
```

### 3.9 Start Services
```bash
sudo apt update
sudo apt install docker-compose -y
cd /mnt/fast-pool/apps/okd-helper
sudo docker-compose up -d
```

**Test DNS:**
```bash
dig @10.0.20.2 api.okd.lab
dig @10.0.20.2 test.apps.okd.lab
```

### 3.10 Configure NFS Shares
- Navigate to: Shares → Unix Shares (NFS)

**Share 1: OKD Storage**
- Path: /mnt/bulk-pool/okd-storage
- Networks: 10.0.30.0/24
- Maproot User: root
- Maproot Group: root

**Share 2: OKD Registry**
- Path: /mnt/bulk-pool/okd-registry
- Networks: 10.0.30.0/24
- Maproot User: root
- Maproot Group: root

**Enable NFS Service:**
- System Settings → Services → NFS
- Enable and start automatically

### 3.11 Create Auto-start Script
```bash
sudo nano /root/start-okd-helper.sh
```

```bash
#!/bin/bash
cd /mnt/fast-pool/apps/okd-helper
docker-compose up -d
```

```bash
sudo chmod +x /root/start-okd-helper.sh
```

**Add to init scripts:**
- System Settings → Advanced → Init/Shutdown Scripts
- Command: /root/start-okd-helper.sh
- Type: Command
- When: Post Init

---

## Phase 4: WiFi Access Point Configuration

### 4.1 Access AP Management Interface
- Connect to AP on VLAN 1
- Access web UI at 10.0.1.21 and 10.0.1.22

### 4.2 Configure Management Interface
- Set static IP: 10.0.1.21 (or 10.0.1.22)
- Gateway: 10.0.1.1
- DNS: 10.0.20.2, 10.0.1.1

### 4.3 Configure SSIDs

**SSID 1: YourHomeNetwork**
- VLAN: 50
- Security: WPA3/WPA2
- Password: [Your secure password]
- Broadcast: Enabled

**SSID 2: YourHomeNetwork-5G**
- VLAN: 50
- Security: WPA3/WPA2
- Password: [Same as above]
- Band: 5GHz only
- Broadcast: Enabled

**SSID 3: Guest**
- VLAN: 99
- Security: WPA2
- Password: [Guest password]
- Client Isolation: Enabled
- Broadcast: Enabled

---

## Phase 5: Raspberry Pi KVM Setup

### 5.1 Install Pi on Management VLAN
- Connect Pi to switch port configured for VLAN 1
- Configure static IP: 10.0.1.10
- Gateway: 10.0.1.1
- DNS: 10.0.20.2

### 5.2 Install Tailscale
```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up --advertise-routes=10.0.1.0/24
```

### 5.3 Configure Tailscale Admin Console
- Approve the Pi device
- Enable subnet routes for 10.0.1.0/24
- Set device name: pi-kvm

### 5.4 Configure GL.iNet Comet KVM
- Connect to Pi
- Configure KVM access
- Test remote access via Tailscale

---

## Phase 6: OKD Cluster Installation

### 6.1 Download OKD Tools
SSH to TrueNAS and download:

```bash
cd /mnt/fast-pool/apps/okd-helper/nginx/html/okd
export VERSION=4.14.0-0.okd-2024-01-06-084517

sudo wget https://github.com/okd-project/okd/releases/download/${VERSION}/openshift-install-linux-${VERSION}.tar.gz
sudo wget https://github.com/okd-project/okd/releases/download/${VERSION}/openshift-client-linux-${VERSION}.tar.gz

sudo tar xvf openshift-install-linux-${VERSION}.tar.gz
sudo tar xvf openshift-client-linux-${VERSION}.tar.gz

sudo mv openshift-install oc kubectl /usr/local/bin/
```

### 6.2 Download Fedora CoreOS
```bash
cd /mnt/fast-pool/apps/okd-helper/nginx/html/okd
sudo wget https://builds.coreos.fedoraproject.org/prod/streams/stable/builds/39.20240128.3.0/x86_64/fedora-coreos-39.20240128.3.0-live.x86_64.iso
```

### 6.3 Generate SSH Keys
```bash
ssh-keygen -t ed25519 -N '' -f ~/.ssh/id_okd
cat ~/.ssh/id_okd.pub
```

### 6.4 Create Install Config
```bash
mkdir -p ~/okd-install
cd ~/okd-install
```

**install-config.yaml:**
```yaml
apiVersion: v1
baseDomain: lab
compute:
- name: worker
  replicas: 0
controlPlane:
  name: master
  replicas: 3
metadata:
  name: okd
networking:
  clusterNetwork:
  - cidr: 10.128.0.0/14
    hostPrefix: 23
  networkType: OVNKubernetes
  serviceNetwork:
  - 172.30.0.0/16
platform:
  none: {}
pullSecret: '{"auths":{"fake":{"auth":"REPLACE_ME_AUTH"}}}'
sshKey: 'ssh-ed25519 AAAA... [paste your public key]'
```

### 6.5 Generate Ignition Configs
```bash
cp install-config.yaml install-config.yaml.backup

openshift-install create manifests --dir=.

# Make masters schedulable
sed -i 's/mastersSchedulable: false/mastersSchedulable: true/' \
  manifests/cluster-scheduler-02-config.yml

openshift-install create ignition-configs --dir=.
```

### 6.6 Host Ignition Files
```bash
sudo cp *.ign /mnt/fast-pool/apps/okd-helper/nginx/html/okd/
sudo chmod 644 /mnt/fast-pool/apps/okd-helper/nginx/html/okd/*.ign

# Test
curl http://10.0.20.2:8080/okd/bootstrap.ign
```

### 6.7 Prepare UM890 Nodes
**BIOS Configuration (all 3 nodes):**
- Enable virtualization (VT-x/AMD-V)
- Disable Secure Boot
- Set boot order: Network/USB first

**Network Configuration:**
- Primary NIC: VLAN 20 (OKD Infra)
- Secondary NIC: VLAN 30 (Storage)
- Management: VLAN 1

### 6.8 Install Bootstrap Node
**Option A: Temporary VM on one UM890**
**Option B: Temporary node**

Boot from Fedora CoreOS ISO, press TAB at boot:
```
coreos.inst.install_dev=/dev/nvme0n1 
coreos.inst.ignition_url=http://10.0.20.2:8080/okd/bootstrap.ign 
ip=10.0.20.10::10.0.20.1:255.255.255.0:bootstrap.okd.lab:enp1s0:none 
nameserver=10.0.20.2
```

### 6.9 Install Master Nodes

**Master 1:**
Boot from Fedora CoreOS ISO, press TAB:
```
coreos.inst.install_dev=/dev/nvme0n1 
coreos.inst.ignition_url=http://10.0.20.2:8080/okd/master.ign 
ip=10.0.20.11::10.0.20.1:255.255.255.0:master1.okd.lab:enp1s0:none 
nameserver=10.0.20.2
```

**Master 2:**
```
coreos.inst.install_dev=/dev/nvme0n1 
coreos.inst.ignition_url=http://10.0.20.2:8080/okd/master.ign 
ip=10.0.20.12::10.0.20.1:255.255.255.0:master2.okd.lab:enp1s0:none 
nameserver=10.0.20.2
```

**Master 3:**
```
coreos.inst.install_dev=/dev/nvme0n1 
coreos.inst.ignition_url=http://10.0.20.2:8080/okd/master.ign 
ip=10.0.20.13::10.0.20.1:255.255.255.0:master3.okd.lab:enp1s0:none 
nameserver=10.0.20.2
```

### 6.10 Monitor Bootstrap
```bash
cd ~/okd-install
openshift-install wait-for bootstrap-complete --log-level=debug
```

Wait 15-30 minutes. Once complete, remove bootstrap from HAProxy backends.

### 6.11 Complete Installation
```bash
export KUBECONFIG=~/okd-install/auth/kubeconfig
openshift-install wait-for install-complete
```

Wait another 15-30 minutes. Save the kubeadmin credentials displayed.

---

## Phase 7: Post-Installation Configuration

### 7.1 Configure NFS Storage Class
```bash
export KUBECONFIG=~/okd-install/auth/kubeconfig

kubectl create namespace nfs-provisioner

# Deploy NFS provisioner (see full YAML in original plan)
# Or use Helm:
helm repo add nfs-subdir-external-provisioner \
  https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/

helm install nfs-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
  --namespace nfs-provisioner \
  --set nfs.server=10.0.30.2 \
  --set nfs.path=/mnt/bulk-pool/okd-storage \
  --set storageClass.defaultClass=true
```

### 7.2 Configure Image Registry
```bash
# Create PVC
oc create -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: image-registry-storage
  namespace: openshift-image-registry
spec:
  accessModes:
  - ReadWriteMany
  resources:
    requests:
      storage: 100Gi
  storageClassName: nfs-storage
EOF

# Configure registry
oc patch configs.imageregistry.operator.openshift.io cluster \
  --type merge \
  --patch '{"spec":{"storage":{"pvc":{"claim":"image-registry-storage"}}}}'

oc patch configs.imageregistry.operator.openshift.io cluster \
  --type merge \
  --patch '{"spec":{"managementState":"Managed"}}'
```

### 7.3 Access Web Console
From your workstation (VLAN 10):

Add to /etc/hosts:
```
10.0.40.10  console-openshift-console.apps.okd.lab
10.0.40.10  oauth-openshift.apps.okd.lab
```

Navigate to: https://console-openshift-console.apps.okd.lab

Login:
- Username: kubeadmin
- Password: [from auth/kubeadmin-password]

### 7.4 Create Admin User (Optional)
```bash
htpasswd -c -B -b users.htpasswd admin 'YourPassword'

oc create secret generic htpass-secret \
  --from-file=htpasswd=users.htpasswd \
  -n openshift-config

cat <<EOF | oc apply -f -
apiVersion: config.openshift.io/v1
kind: OAuth
metadata:
  name: cluster
spec:
  identityProviders:
  - name: htpasswd_provider
    mappingMethod: claim
    type: HTPasswd
    htpasswd:
      fileData:
        name: htpass-secret
EOF

oc adm policy add-cluster-role-to-user cluster-admin admin
```

### 7.5 Verify Cluster Health
```bash
oc get nodes
oc get co
oc get pods --all-namespaces
```

### 7.6 Remove Bootstrap from HAProxy
- Edit HAProxy backends on OPNSense
- Comment out or remove bootstrap server entries
- Reload HAProxy
- Power down bootstrap node

---

## Phase 8: Testing & Validation

### 8.1 Test DNS Resolution
From various VLANs:
```bash
# From workstation (VLAN 10)
dig api.okd.lab
dig console-openshift-console.apps.okd.lab

# Should resolve to correct IPs
```

### 8.2 Test Cross-VLAN Access
**From Homelab VLAN (10):**
```bash
curl -k https://console-openshift-console.apps.okd.lab
# Should connect
```

**From WiFi VLAN (50):**
- Connect to WiFi
- Browse to https://console-openshift-console.apps.okd.lab
- Should access web console

**From Living Room VLAN (60):**
- Access any OKD app via browser
- Should work

**From Guest VLAN (99):**
- Should NOT access internal services
- Should have internet only

### 8.3 Test Storage
```bash
# Create test PVC
oc create -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-pvc
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: nfs-storage
EOF

oc get pvc
# Should show Bound status
```

### 8.4 Deploy Test Application
```bash
oc new-project test-app
oc new-app --name=nginx --docker-image=nginx:alpine
oc expose svc/nginx
oc get route

# Access from browser: http://nginx-test-app.apps.okd.lab
```

### 8.5 Test Remote Access via Tailscale
- Connect to Tailscale VPN
- Access: https://console-openshift-console.apps.okd.lab
- Should work from anywhere

---

## Timeline Estimate

| Phase | Task | Estimated Time |
|-------|------|----------------|
| 1 | OPNSense Configuration | 3-4 hours |
| 2 | Switch Configuration | 2-3 hours |
| 3 | TrueNAS Setup | 4-6 hours |
| 4 | WiFi AP Configuration | 1-2 hours |
| 5 | Pi KVM + Tailscale | 1-2 hours |
| 6 | OKD Installation | 3-4 hours |
| 7 | Post-Installation | 2-3 hours |
| 8 | Testing & Validation | 2-3 hours |
| **Total** | | **18-27 hours** |

*Note: Includes learning time and troubleshooting*

---

## Troubleshooting Guide

### DNS Issues
```bash
# Test from TrueNAS
dig @10.0.20.2 api.okd.lab

# Check Bind9 logs
sudo docker logs okd-dns

# Restart DNS
cd /mnt/fast-pool/apps/okd-helper
sudo docker-compose restart bind9
```

### HAProxy Issues
- Check OPNSense: Services → HAProxy → Statistics
- Verify backend health checks
- Check firewall logs: Firewall → Log Files → Live View

### Cross-VLAN Access Issues
```bash
# On OPNSense
tcpdump -i vlan50 host 10.0.40.10

# Check firewall rule hit counts
# Firewall → Rules → [VLAN] → Check packet counters
```

### OKD Issues
```bash
# Check cluster operators
oc get co

# Check node status
oc get nodes

# Check pod status
oc get pods --all-namespaces

# Check specific operator
oc describe co [operator-name]
```

### Storage Issues
```bash
# Check NFS exports on TrueNAS
showmount -e 10.0.30.2

# Check NFS provisioner
oc get pods -n nfs-provisioner
oc logs -n nfs-provisioner [pod-name]

# Check PVs
oc get pv
```

---

## Security Checklist

- [ ] Change all default passwords
- [ ] Enable firewall logging
- [ ] Restrict management VLAN access
- [ ] Enable WiFi encryption (WPA3/WPA2)
- [ ] Enable client isolation on guest WiFi
- [ ] Configure Tailscale ACLs
- [ ] Regular OPNSense updates
- [ ] Regular TrueNAS updates
- [ ] Regular OKD updates
- [ ] Backup OPNSense config
- [ ] Backup TrueNAS config
- [ ] Backup OKD etcd

---

## Maintenance Tasks

### Weekly
- Check HAProxy stats for backend health
- Review firewall logs for anomalies
- Check OKD cluster operator status

### Monthly
- Update OPNSense
- Update TrueNAS SCALE
- Review storage usage
- Test backups

### Quarterly
- Update OKD cluster
- Review and update firewall rules
- Update AP firmware
- Review Tailscale access

---

## Backup Strategy

### OPNSense
- System → Configuration → Backups
- Download config.xml weekly
- Store offsite

### TrueNAS
- Scheduled snapshots of datasets
- Replication to external storage (optional)
- Export config: System → General → Save Config

### OKD
- etcd backups
- PV snapshots (ZFS)
- Config backup:
```bash
oc get all --all-namespaces -o yaml > cluster-backup.yaml
```

---

## Future Enhancements

### Optional Additions
- [ ] Second OPNSense for HA (CARP/VRRP)
- [ ] Additional worker nodes
- [ ] Rook-Ceph for distributed storage
- [ ] GitOps with ArgoCD
- [ ] CI/CD with Tekton/OpenShift Pipelines
- [ ] Service Mesh (Istio)
- [ ] Monitoring stack (Prometheus/Grafana)
- [ ] Logging stack (EFK)
- [ ] Backup solution (Velero)
- [ ] External certificate management (cert-manager)

---

## Access Summary

### From Different VLANs to OKD Services

| Source VLAN | Can Access | Via | Notes |
|-------------|------------|-----|-------|
| Management (1) | Everything | Direct | Full admin access |
| Homelab (10) | API + Services | 10.0.20.5, 10.0.40.10 | Full dev access |
| OKD-Infra (20) | Cluster mesh | Internal | Backend only |
| Storage (30) | None | - | Backend only |
| Services (40) | N/A | VIP only | No hosts |
| IoT/WiFi (50) | Web services only | 10.0.40.10:80,443 | Limited access |
| Living Room (60) | Web services only | 10.0.40.10:80,443 | Limited access |
| Guest (99) | None | - | Internet only |

---

## Support Resources

- OKD Documentation: https://docs.okd.io/
- OPNSense Documentation: https://docs.opnsense.org/
- TrueNAS SCALE Docs: https://www.truenas.com/docs/scale/
- Tailscale Documentation: https://tailscale.com/kb/
- Kubernetes Documentation: https://kubernetes.io/docs/

---

## Notes

- All passwords should be strong and unique
- Keep this document updated as you make changes
- Document any deviations from the plan
- Take snapshots before major changes
- Test backups regularly
