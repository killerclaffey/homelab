# OPNSense KEA DHCP v4 Configuration - Section 1.4

This document provides complete field-by-field configuration for setting up KEA DHCP v4 for all VLANs.

## Prerequisites

- ✅ All VLAN interfaces have been created and assigned (Sections 1.1 and 1.2)
- ✅ KEA DHCP plugin is installed (if not, install from System → Firmware → Plugins → os-kea-dhcp)
- ✅ Unbound DNS is configured and running

## Step 1: Enable KEA DHCP Service

**Location:** Services → Kea DHCP → Settings

1. Navigate to: **Services → Kea DHCP → Settings**
2. Check: ☑ **Enable Kea DHCP**
3. Click: **Save**
4. Click: **Apply Changes**

## Step 2: Configure DHCP Subnets for Each VLAN

**Location:** Services → Kea DHCP → DHCPv4

For each VLAN that needs DHCP, you'll create a subnet configuration.

---

### VLAN 1 - Management DHCP Configuration

**Location:** Services → Kea DHCP → DHCPv4 → Click **"+"** (Add)

#### Subnet Configuration

| Field | Value | Notes |
|-------|-------|-------|
| **Subnet** | `10.0.1.0/24` | Management VLAN subnet (CIDR notation) |
| **Description** | `Management - Infrastructure, workstations, living room` | Optional but helpful |

**Note:** KEA DHCP in OPNSense automatically binds to the interface that matches the subnet. The interface is determined by the subnet's network address matching an assigned interface's network. No interface dropdown is needed - KEA will automatically use the interface that has an IP address in the `10.0.1.0/24` range (which should be VLAN1 with IP 10.0.1.1).

#### Pool Configuration

Click **"+"** under Pools to add a pool:

| Field | Value | Notes |
|-------|-------|-------|
| **Pool Start** | `10.0.1.100` | Start of DHCP range |
| **Pool End** | `10.0.1.250` | End of DHCP range |

#### Option Data Configuration

Click **"+"** under Option Data to add options:

**Option 1: Routers (Gateway)**
- **Name:** `routers`
- **Code:** `3` (or select from dropdown)
- **Type:** `IPv4 address`
- **Value:** `10.0.1.1`

**Option 2: Domain Name Servers (DNS)**
- **Name:** `domain-name-servers`
- **Code:** `6` (or select from dropdown)
- **Type:** `IPv4 address`
- **Value:** `10.0.20.2,10.0.1.1` (TrueNAS DNS, OPNSense DNS)

**Option 3: Domain Name (Optional)**
- **Name:** `domain-name`
- **Code:** `15` (or select from dropdown)
- **Type:** `String`
- **Value:** `lab` (or your preferred domain)

#### Lease Configuration

| Field | Value | Notes |
|-------|-------|-------|
| **Valid Lifetime** | `86400` | 24 hours in seconds (default) |
| **Max Valid Lifetime** | `172800` | 48 hours in seconds (default) |

Click **Save**

---

### VLAN 50 - IoT/Surveillance DHCP Configuration

**Location:** Services → Kea DHCP → DHCPv4 → Click **"+"** (Add)

#### Subnet Configuration

| Field | Value | Notes |
|-------|-------|-------|
| **Subnet** | `10.0.50.0/24` | IoT/Surveillance VLAN subnet (CIDR notation) |
| **Description** | `IoT/Surveillance - IoT devices, cameras` | Optional but helpful |

**Note:** KEA automatically uses the interface with IP in the 10.0.50.0/24 range (VLAN50 with IP 10.0.50.1).

#### Pool Configuration

Click **"+"** under Pools:

| Field | Value | Notes |
|-------|-------|-------|
| **Pool Start** | `10.0.50.100` | Start of DHCP range |
| **Pool End** | `10.0.50.200` | End of DHCP range |

#### Option Data Configuration

Click **"+"** under Option Data:

**Option 1: Routers (Gateway)**
- **Name:** `routers`
- **Code:** `3`
- **Type:** `IPv4 address`
- **Value:** `10.0.50.1`

**Option 2: Domain Name Servers (DNS)**
- **Name:** `domain-name-servers`
- **Code:** `6`
- **Type:** `IPv4 address`
- **Value:** `10.0.20.2,10.0.1.1`

**Option 3: Domain Name (Optional)**
- **Name:** `domain-name`
- **Code:** `15`
- **Type:** `String`
- **Value:** `lab`

#### Lease Configuration

| Field | Value | Notes |
|-------|-------|-------|
| **Valid Lifetime** | `86400` | 24 hours |
| **Max Valid Lifetime** | `172800` | 48 hours |

Click **Save**

---

### VLAN 60 - Game Consoles DHCP Configuration

**Location:** Services → Kea DHCP → DHCPv4 → Click **"+"** (Add)

#### Subnet Configuration

| Field | Value | Notes |
|-------|-------|-------|
| **Subnet** | `10.0.60.0/24` | Game Consoles VLAN subnet (CIDR notation) |
| **Description** | `Game Consoles - Gaming devices (uPNP enabled)` | Optional but helpful |

**Note:** KEA automatically uses the interface with IP in the 10.0.60.0/24 range (VLAN60 with IP 10.0.60.1).

#### Pool Configuration

Click **"+"** under Pools:

| Field | Value | Notes |
|-------|-------|-------|
| **Pool Start** | `10.0.60.100` | Start of DHCP range |
| **Pool End** | `10.0.60.200` | End of DHCP range |

#### Option Data Configuration

Click **"+"** under Option Data:

**Option 1: Routers (Gateway)**
- **Name:** `routers`
- **Code:** `3`
- **Type:** `IPv4 address`
- **Value:** `10.0.60.1`

**Option 2: Domain Name Servers (DNS)**
- **Name:** `domain-name-servers`
- **Code:** `6`
- **Type:** `IPv4 address`
- **Value:** `10.0.20.2,10.0.1.1`

**Option 3: Domain Name (Optional)**
- **Name:** `domain-name`
- **Code:** `15`
- **Type:** `String`
- **Value:** `lab`

#### Lease Configuration

| Field | Value | Notes |
|-------|-------|-------|
| **Valid Lifetime** | `86400` | 24 hours |
| **Max Valid Lifetime** | `172800` | 48 hours |

Click **Save**

---

### VLAN 70 - Helium Hotspot DHCP Configuration

**Location:** Services → Kea DHCP → DHCPv4 → Click **"+"** (Add)

#### Subnet Configuration

| Field | Value | Notes |
|-------|-------|-------|
| **Subnet** | `10.0.70.0/24` | Helium Hotspot VLAN subnet (CIDR notation) |
| **Description** | `Helium Hotspot - Helium miner` | Optional but helpful |

**Note:** KEA automatically uses the interface with IP in the 10.0.70.0/24 range (the Helium physical interface with IP 10.0.70.1 assigned in Section 1.3).

#### Pool Configuration

Click **"+"** under Pools:

| Field | Value | Notes |
|-------|-------|-------|
| **Pool Start** | `10.0.70.100` | Start of DHCP range |
| **Pool End** | `10.0.70.200` | End of DHCP range |

#### Option Data Configuration

Click **"+"** under Option Data:

**Option 1: Routers (Gateway)**
- **Name:** `routers`
- **Code:** `3`
- **Type:** `IPv4 address`
- **Value:** `10.0.70.1`

**Option 2: Domain Name Servers (DNS)**
- **Name:** `domain-name-servers`
- **Code:** `6`
- **Type:** `IPv4 address`
- **Value:** `10.0.20.2,10.0.1.1`

**Option 3: Domain Name (Optional)**
- **Name:** `domain-name`
- **Code:** `15`
- **Type:** `String`
- **Value:** `lab`

#### Lease Configuration

| Field | Value | Notes |
|-------|-------|-------|
| **Valid Lifetime** | `86400` | 24 hours |
| **Max Valid Lifetime** | `172800` | 48 hours |

Click **Save**

---

### VLAN 99 - Guest-WiFi DHCP Configuration

**Location:** Services → Kea DHCP → DHCPv4 → Click **"+"** (Add)

#### Subnet Configuration

| Field | Value | Notes |
|-------|-------|-------|
| **Subnet** | `10.0.99.0/24` | Guest-WiFi VLAN subnet (CIDR notation) |
| **Description** | `Guest-WiFi - Isolated guest network` | Optional but helpful |

**Note:** KEA automatically uses the interface with IP in the 10.0.99.0/24 range (VLAN99 with IP 10.0.99.1).

#### Pool Configuration

Click **"+"** under Pools:

| Field | Value | Notes |
|-------|-------|-------|
| **Pool Start** | `10.0.99.100` | Start of DHCP range |
| **Pool End** | `10.0.99.200` | End of DHCP range |

#### Option Data Configuration

Click **"+"** under Option Data:

**Option 1: Routers (Gateway)**
- **Name:** `routers`
- **Code:** `3`
- **Type:** `IPv4 address`
- **Value:** `10.0.99.1`

**Option 2: Domain Name Servers (DNS)**
- **Name:** `domain-name-servers`
- **Code:** `6`
- **Type:** `IPv4 address`
- **Value:** `10.0.20.2,10.0.1.1`

**Option 3: Domain Name (Optional)**
- **Name:** `domain-name`
- **Code:** `15`
- **Type:** `String`
- **Value:** `lab`

#### Lease Configuration

| Field | Value | Notes |
|-------|-------|-------|
| **Valid Lifetime** | `86400` | 24 hours |
| **Max Valid Lifetime** | `172800` | 48 hours |

Click **Save**

---

## Quick Reference: All DHCP Subnets

| VLAN | Subnet | Auto-Detected Interface | Pool Range | Gateway | DNS Servers |
|------|--------|------------------------|------------|---------|-------------|
| 1 | 10.0.1.0/24 | VLAN1 (10.0.1.1) | 10.0.1.100-250 | 10.0.1.1 | 10.0.20.2, 10.0.1.1 |
| 50 | 10.0.50.0/24 | VLAN50 (10.0.50.1) | 10.0.50.100-200 | 10.0.50.1 | 10.0.20.2, 10.0.1.1 |
| 60 | 10.0.60.0/24 | VLAN60 (10.0.60.1) | 10.0.60.100-200 | 10.0.60.1 | 10.0.20.2, 10.0.1.1 |
| 70 | 10.0.70.0/24 | Helium Interface (10.0.70.1) | 10.0.70.100-200 | 10.0.70.1 | 10.0.20.2, 10.0.1.1 |
| 99 | 10.0.99.0/24 | VLAN99 (10.0.99.1) | 10.0.99.100-200 | 10.0.99.1 | 10.0.20.2, 10.0.1.1 |

**Note:** KEA DHCP automatically detects which interface to use based on the subnet. It matches the subnet's network to an interface that has an IP address in that network range. No manual interface selection is needed.

---

## Step 3: Verify KEA DHCP is Running

**Location:** Services → Kea DHCP → Status

1. Navigate to: **Services → Kea DHCP → Status**
2. Verify that:
   - KEA DHCP service is running
   - All configured subnets are listed
   - No errors are shown

---

## Step 4: Test DHCP (Optional but Recommended)

1. Connect a device to VLAN 1 (Management)
2. Verify the device receives an IP in the range `10.0.1.100-250`
3. Verify the device can resolve DNS (try `ping google.com`)
4. Verify the device's default gateway is `10.0.1.1`

---

## Static DHCP Reservations (Optional)

If you need to reserve specific IPs for devices:

**Location:** Services → Kea DHCP → Reservations

1. Click **"+"** to add a reservation
2. Configure:
   - **Subnet:** Select the appropriate subnet (e.g., VLAN1)
   - **IP Address:** The reserved IP (e.g., `10.0.1.100`)
   - **HW Address:** MAC address in format `aa:bb:cc:dd:ee:ff`
   - **Hostname:** Optional but recommended
3. Click **Save**

---

## Troubleshooting

### "KEA DHCP not starting"
- **Check:** Services → Kea DHCP → Status for error messages
- **Verify:** All VLAN interfaces are enabled and have IP addresses assigned
- **Check:** System → Log Files → General for KEA errors

### "Devices not getting IP addresses"
- **Verify:** KEA DHCP is enabled in Settings
- **Verify:** Subnet is configured for the correct interface
- **Verify:** Pool range doesn't conflict with static IPs
- **Check:** Firewall rules allow DHCP traffic (UDP port 67/68)

### "Devices getting wrong DNS servers"
- **Verify:** Option Data → domain-name-servers is configured correctly
- **Check:** DNS servers are reachable from the VLAN
- **Test:** From a device, run `nslookup` to see which DNS servers are being used

### "DHCP leases not showing"
- **Check:** Services → Kea DHCP → Leases
- **Note:** KEA may not show leases in the same way as traditional DHCP
- **Verify:** Devices are actually getting IPs (check device network settings)

---

## Important Notes

1. **DNS Servers:** All VLANs use `10.0.20.2` (TrueNAS Bind9) as primary DNS and `10.0.1.1` (OPNSense Unbound) as secondary
2. **Lease Times:** Default 24-hour leases are appropriate for most homelab use cases
3. **Pool Ranges:** Make sure pool ranges don't overlap with static IPs you've assigned
4. **Interface Auto-Detection:** KEA DHCP automatically detects which interface to use based on the subnet's network matching an interface's IP address. Ensure each VLAN interface has the correct IP address assigned (e.g., VLAN1 = 10.0.1.1, VLAN50 = 10.0.50.1, etc.)
5. **Subnet Format:** Use CIDR notation (e.g., `10.0.1.0/24`) for the subnet field

---

## Next Steps

After configuring KEA DHCP:

1. ✅ **Section 1.5:** Enable uPNP for Game Consoles VLAN
2. ✅ **Section 1.11:** Configure Unbound DNS forwarding (if not already done)
3. ✅ **Section 1.10:** Configure Firewall Rules (critical for network isolation)

