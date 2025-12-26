# OPNSense KEA DHCP Configuration by VLAN Name

Quick reference guide organized by friendly VLAN names for easy lookup.

## Prerequisites

- ✅ All VLAN interfaces created and assigned
- ✅ KEA DHCP plugin installed
- ✅ Unbound DNS configured

## Enable KEA DHCP Service

**Location:** Services → Kea DHCP → Settings

1. ☑ **Enable Kea DHCP**
2. Click **Save** → **Apply Changes**

---

## Management VLAN DHCP

**VLAN:** 1  
**Subnet:** 10.0.1.0/24  
**Auto-Detected Interface:** VLAN1 (10.0.1.1)

### Configuration Steps

1. **Location:** Services → Kea DHCP → DHCPv4 → Click **"+"**
2. **Subnet:** `10.0.1.0/24` (CIDR notation)
3. **Description:** `Management - Infrastructure, workstations, living room`

**Note:** KEA DHCP automatically detects the interface based on the subnet. It will use the interface that has an IP address in the 10.0.1.0/24 range (VLAN1 with IP 10.0.1.1). No interface dropdown is needed.

### Pool Configuration

- **Pool Start:** `10.0.1.100`
- **Pool End:** `10.0.1.250`

### Option Data (Click "+" for each)

**Gateway (Routers):**
- Name: `routers`
- Code: `3`
- Type: `IPv4 address`
- Value: `10.0.1.1`

**DNS Servers:**
- Name: `domain-name-servers`
- Code: `6`
- Type: `IPv4 address`
- Value: `10.0.20.2,10.0.1.1`

**Domain Name (Optional):**
- Name: `domain-name`
- Code: `15`
- Type: `String`
- Value: `lab`

### Lease Times
- **Valid Lifetime:** `86400` (24 hours)
- **Max Valid Lifetime:** `172800` (48 hours)

---

## OKD-Infra VLAN DHCP

**VLAN:** 20  
**Subnet:** 10.0.20.0/24  
**Auto-Detected Interface:** VLAN20 (10.0.20.1)

**Note:** This VLAN typically uses static IPs for cluster nodes. DHCP is optional but can be configured if needed.

### Configuration Steps (If Needed)

1. **Location:** Services → Kea DHCP → DHCPv4 → Click **"+"**
2. **Subnet:** `10.0.20.0/24` (CIDR notation)
3. **Description:** `OKD-Infra - Cluster nodes, bootstrap, DNS`

**Note:** KEA automatically uses the interface with IP in the 10.0.20.0/24 range (VLAN20 with IP 10.0.20.1).

### Pool Configuration (If Needed)

- **Pool Start:** `10.0.20.100` (or adjust based on your static IPs)
- **Pool End:** `10.0.20.200` (avoid conflict with static IPs 10.0.20.2-13)

### Option Data

**Gateway (Routers):**
- Name: `routers`
- Code: `3`
- Type: `IPv4 address`
- Value: `10.0.20.1`

**DNS Servers:**
- Name: `domain-name-servers`
- Code: `6`
- Type: `IPv4 address`
- Value: `10.0.20.2,10.0.1.1`

**Domain Name:**
- Name: `domain-name`
- Code: `15`
- Type: `String`
- Value: `okd.lab`

---

## OKD-Storage VLAN DHCP

**VLAN:** 30  
**Subnet:** 10.0.30.0/24  
**Auto-Detected Interface:** VLAN30 (10.0.30.1)

**Note:** This VLAN typically uses static IPs only. DHCP is usually not needed.

---

## Services VLAN DHCP

**VLAN:** 40  
**Subnet:** 10.0.40.0/24  
**Auto-Detected Interface:** VLAN40 (10.0.40.1)

**Note:** This VLAN only contains the HAProxy VIP (10.0.40.10). No DHCP needed.

---

## IoT/Surveillance VLAN DHCP

**VLAN:** 50  
**Subnet:** 10.0.50.0/24  
**Auto-Detected Interface:** VLAN50 (10.0.50.1)

### Configuration Steps

1. **Location:** Services → Kea DHCP → DHCPv4 → Click **"+"**
2. **Subnet:** `10.0.50.0/24` (CIDR notation)
3. **Description:** `IoT/Surveillance - IoT devices, cameras (WiFi SSID: Home-IoT)`

**Note:** KEA automatically uses the interface with IP in the 10.0.50.0/24 range (VLAN50 with IP 10.0.50.1).

### Pool Configuration

- **Pool Start:** `10.0.50.100`
- **Pool End:** `10.0.50.200`

### Option Data (Click "+" for each)

**Gateway (Routers):**
- Name: `routers`
- Code: `3`
- Type: `IPv4 address`
- Value: `10.0.50.1`

**DNS Servers:**
- Name: `domain-name-servers`
- Code: `6`
- Type: `IPv4 address`
- Value: `10.0.20.2,10.0.1.1`

**Domain Name (Optional):**
- Name: `domain-name`
- Code: `15`
- Type: `String`
- Value: `lab`

### Lease Times
- **Valid Lifetime:** `86400` (24 hours)
- **Max Valid Lifetime:** `172800` (48 hours)

---

## Game Consoles VLAN DHCP

**VLAN:** 60  
**Subnet:** 10.0.60.0/24  
**Auto-Detected Interface:** VLAN60 (10.0.60.1)

### Configuration Steps

1. **Location:** Services → Kea DHCP → DHCPv4 → Click **"+"**
2. **Subnet:** `10.0.60.0/24` (CIDR notation)
3. **Description:** `Game Consoles - Gaming devices (uPNP enabled)`

**Note:** KEA automatically uses the interface with IP in the 10.0.60.0/24 range (VLAN60 with IP 10.0.60.1).

### Pool Configuration

- **Pool Start:** `10.0.60.100`
- **Pool End:** `10.0.60.200`

### Option Data (Click "+" for each)

**Gateway (Routers):**
- Name: `routers`
- Code: `3`
- Type: `IPv4 address`
- Value: `10.0.60.1`

**DNS Servers:**
- Name: `domain-name-servers`
- Code: `6`
- Type: `IPv4 address`
- Value: `10.0.20.2,10.0.1.1`

**Domain Name (Optional):**
- Name: `domain-name`
- Code: `15`
- Type: `String`
- Value: `lab`

### Lease Times
- **Valid Lifetime:** `86400` (24 hours)
- **Max Valid Lifetime:** `172800` (48 hours)

---

## Helium Hotspot VLAN DHCP

**VLAN:** 70  
**Subnet:** 10.0.70.0/24  
**Auto-Detected Interface:** Helium physical interface (10.0.70.1)

### Configuration Steps

1. **Location:** Services → Kea DHCP → DHCPv4 → Click **"+"**
2. **Subnet:** `10.0.70.0/24` (CIDR notation)
3. **Description:** `Helium Hotspot - Helium miner`

**Note:** KEA automatically uses the interface with IP in the 10.0.70.0/24 range (the Helium physical interface with IP 10.0.70.1 assigned in Section 1.3).

### Pool Configuration

- **Pool Start:** `10.0.70.100`
- **Pool End:** `10.0.70.200`

### Option Data (Click "+" for each)

**Gateway (Routers):**
- Name: `routers`
- Code: `3`
- Type: `IPv4 address`
- Value: `10.0.70.1`

**DNS Servers:**
- Name: `domain-name-servers`
- Code: `6`
- Type: `IPv4 address`
- Value: `10.0.20.2,10.0.1.1`

**Domain Name (Optional):**
- Name: `domain-name`
- Code: `15`
- Type: `String`
- Value: `lab`

### Lease Times
- **Valid Lifetime:** `86400` (24 hours)
- **Max Valid Lifetime:** `172800` (48 hours)

---

## Guest-WiFi VLAN DHCP

**VLAN:** 99  
**Subnet:** 10.0.99.0/24  
**Auto-Detected Interface:** VLAN99 (10.0.99.1)

### Configuration Steps

1. **Location:** Services → Kea DHCP → DHCPv4 → Click **"+"**
2. **Subnet:** `10.0.99.0/24` (CIDR notation)
3. **Description:** `Guest-WiFi - Isolated guest network (WiFi SSID: Guest)`

**Note:** KEA automatically uses the interface with IP in the 10.0.99.0/24 range (VLAN99 with IP 10.0.99.1).

### Pool Configuration

- **Pool Start:** `10.0.99.100`
- **Pool End:** `10.0.99.200`

### Option Data (Click "+" for each)

**Gateway (Routers):**
- Name: `routers`
- Code: `3`
- Type: `IPv4 address`
- Value: `10.0.99.1`

**DNS Servers:**
- Name: `domain-name-servers`
- Code: `6`
- Type: `IPv4 address`
- Value: `10.0.20.2,10.0.1.1`

**Domain Name (Optional):**
- Name: `domain-name`
- Code: `15`
- Type: `String`
- Value: `lab`

### Lease Times
- **Valid Lifetime:** `86400` (24 hours)
- **Max Valid Lifetime:** `172800` (48 hours)

---

## Quick Reference Table

| VLAN Name | VLAN # | Subnet | Auto-Detected Interface | Pool Range | Gateway | DNS Servers |
|-----------|--------|--------|------------------------|------------|---------|-------------|
| **Management** | 1 | 10.0.1.0/24 | VLAN1 (10.0.1.1) | 10.0.1.100-250 | 10.0.1.1 | 10.0.20.2, 10.0.1.1 |
| **OKD-Infra** | 20 | 10.0.20.0/24 | VLAN20 (10.0.20.1) | (Optional) | 10.0.20.1 | 10.0.20.2, 10.0.1.1 |
| **OKD-Storage** | 30 | 10.0.30.0/24 | VLAN30 (10.0.30.1) | (Not needed) | 10.0.30.1 | N/A |
| **Services** | 40 | 10.0.40.0/24 | VLAN40 (10.0.40.1) | (Not needed) | 10.0.40.1 | N/A |
| **IoT/Surveillance** | 50 | 10.0.50.0/24 | VLAN50 (10.0.50.1) | 10.0.50.100-200 | 10.0.50.1 | 10.0.20.2, 10.0.1.1 |
| **Game Consoles** | 60 | 10.0.60.0/24 | VLAN60 (10.0.60.1) | 10.0.60.100-200 | 10.0.60.1 | 10.0.20.2, 10.0.1.1 |
| **Helium Hotspot** | 70 | 10.0.70.0/24 | Physical (10.0.70.1) | 10.0.70.100-200 | 10.0.70.1 | 10.0.20.2, 10.0.1.1 |
| **Guest-WiFi** | 99 | 10.0.99.0/24 | VLAN99 (10.0.99.1) | 10.0.99.100-200 | 10.0.99.1 | 10.0.20.2, 10.0.1.1 |

**Note:** KEA DHCP automatically detects which interface to use based on the subnet. It matches the subnet's network to an interface that has an IP address in that network range. No manual interface selection is needed.

---

## Common Option Data Values

All VLANs use the same Option Data structure. Here's a quick copy-paste reference:

### Routers (Gateway)
- **Name:** `routers`
- **Code:** `3`
- **Type:** `IPv4 address`
- **Value:** `[VLAN_GATEWAY_IP]` (e.g., 10.0.1.1 for Management)

### Domain Name Servers (DNS)
- **Name:** `domain-name-servers`
- **Code:** `6`
- **Type:** `IPv4 address`
- **Value:** `10.0.20.2,10.0.1.1` (same for all VLANs)

### Domain Name
- **Name:** `domain-name`
- **Code:** `15`
- **Type:** `String`
- **Value:** `lab` (or `okd.lab` for OKD-Infra VLAN)

---

## Verification Checklist

After configuring each VLAN:

- [ ] Subnet created with correct network (CIDR notation)
- [ ] Interface auto-detected correctly (verify interface has IP in subnet range)
- [ ] Pool range configured
- [ ] Gateway option added (routers)
- [ ] DNS servers option added (domain-name-servers)
- [ ] Domain name option added (optional)
- [ ] Lease times configured
- [ ] Saved and applied changes
- [ ] Tested from a device on that VLAN

---

## Troubleshooting

### "Device not getting IP address"
- Verify KEA DHCP is enabled in Settings
- Check subnet is configured for correct interface
- Verify pool range doesn't conflict with static IPs
- Check firewall allows DHCP (UDP 67/68)

### "Wrong gateway or DNS servers"
- Verify Option Data is configured correctly
- Check option codes match (3 for routers, 6 for DNS)
- Verify IP addresses are correct
- Test from device: `ipconfig /all` (Windows) or `ip addr` (Linux)

### "KEA not binding to correct interface"
- Verify the VLAN interface has an IP address in the subnet's network range
- Example: For subnet 10.0.1.0/24, ensure VLAN1 has IP 10.0.1.1
- Check Interfaces → Assignments to verify interface IPs are correct
- KEA automatically matches subnets to interfaces based on IP addresses

---

## Next Steps

After configuring all DHCP subnets:

1. ✅ Verify KEA DHCP is running (Services → Kea DHCP → Status)
2. ✅ Test DHCP from devices on each VLAN
3. ✅ Configure static DHCP reservations if needed (Services → Kea DHCP → Reservations)
4. ✅ Continue to Section 1.5 (uPNP configuration)

