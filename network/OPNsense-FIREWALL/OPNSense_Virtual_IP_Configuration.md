# OPNSense Virtual IP (VIP) Configuration - Section 1.7

This document provides complete field-by-field configuration for creating Virtual IPs (VIPs) for HAProxy load balancing.

## Prerequisites

- ✅ All VLAN interfaces have been created and assigned (Sections 1.1 and 1.2)
- ✅ HAProxy plugin is installed (Section 1.6)

## Overview

We need to create 3 Virtual IPs for OKD cluster load balancing:
1. **API VIP** - For OKD API access (VLAN 20)
2. **Apps VIP Internal** - For internal OKD app access (VLAN 20)
3. **Apps VIP Services** - For external OKD app access (VLAN 40)

---

## VIP 1: OKD API VIP

**Purpose:** Load balance OKD API requests across master nodes  
**VLAN:** 20 (OKD-Infra)  
**IP Address:** 10.0.20.5/24

### Configuration Steps

**Location:** Interfaces → Virtual IPs → Settings → Click **"+"** (Add)

| Field | Value | Notes |
|-------|-------|-------|
| **Mode** | `IP Alias` | Select from dropdown - IP Alias allows services to bind to it |
| **Interface** | `OKDInfra` (or `VLAN20`) | Select the OKD-Infra VLAN interface from dropdown |
| **Network / Address** | `10.0.20.5/24` | VIP IP address with subnet mask in CIDR notation |
| **Gateway** | (Leave empty) | Not needed for VLAN interfaces |
| **Deny service binding** | ☐ Unchecked | Allow services (HAProxy) to bind to this VIP |
| **VHID Group** | (Leave empty) | Not needed unless using CARP/HA |
| **No XMLRPC Sync** | ☐ Unchecked | Only needed for HA setups |
| **Description** | `OKD API VIP - Load balances API requests to master nodes` | Optional but helpful |

Click **Save** → **Apply Changes**

---

## VIP 2: OKD Apps VIP Internal

**Purpose:** Load balance internal OKD app requests across master nodes  
**VLAN:** 20 (OKD-Infra)  
**IP Address:** 10.0.20.6/24

### Configuration Steps

**Location:** Interfaces → Virtual IPs → Settings → Click **"+"** (Add)

| Field | Value | Notes |
|-------|-------|-------|
| **Mode** | `IP Alias` | Select from dropdown - IP Alias allows services to bind to it |
| **Interface** | `OKDInfra` (or `VLAN20`) | Select the OKD-Infra VLAN interface from dropdown |
| **Network / Address** | `10.0.20.6/24` | VIP IP address with subnet mask in CIDR notation |
| **Gateway** | (Leave empty) | Not needed for VLAN interfaces |
| **Deny service binding** | ☐ Unchecked | Allow services (HAProxy) to bind to this VIP |
| **VHID Group** | (Leave empty) | Not needed unless using CARP/HA |
| **No XMLRPC Sync** | ☐ Unchecked | Only needed for HA setups |
| **Description** | `OKD Apps VIP Internal - Load balances internal app requests to master nodes` | Optional but helpful |

Click **Save** → **Apply Changes**

---

## VIP 3: OKD Apps VIP Services

**Purpose:** Load balance external OKD app requests (published services)  
**VLAN:** 40 (Services)  
**IP Address:** 10.0.40.10/24

### Configuration Steps

**Location:** Interfaces → Virtual IPs → Settings → Click **"+"** (Add)

| Field | Value | Notes |
|-------|-------|-------|
| **Mode** | `IP Alias` | Select from dropdown - IP Alias allows services to bind to it |
| **Interface** | `Services` (or `VLAN40`) | Select the Services VLAN interface from dropdown |
| **Network / Address** | `10.0.40.10/24` | VIP IP address with subnet mask in CIDR notation |
| **Gateway** | (Leave empty) | Not needed for VLAN interfaces |
| **Deny service binding** | ☐ Unchecked | Allow services (HAProxy) to bind to this VIP |
| **VHID Group** | (Leave empty) | Not needed unless using CARP/HA |
| **No XMLRPC Sync** | ☐ Unchecked | Only needed for HA setups |
| **Description** | `OKD Apps VIP Services - Published OKD services for external access` | Optional but helpful |

Click **Save** → **Apply Changes**

---

## Quick Reference: All VIPs

| VIP Name | Mode | Interface | IP Address | Purpose |
|----------|------|-----------|------------|---------|
| **OKD API VIP** | IP Alias | OKDInfra (VLAN20) | 10.0.20.5/24 | OKD API load balancing |
| **OKD Apps VIP Internal** | IP Alias | OKDInfra (VLAN20) | 10.0.20.6/24 | Internal app load balancing |
| **OKD Apps VIP Services** | IP Alias | Services (VLAN40) | 10.0.40.10/24 | External app access |

---

## Field Explanations

### Mode: IP Alias
- **IP Alias** is the correct choice for HAProxy
- Allows services (like HAProxy) to bind to the VIP
- Proxy ARP cannot be bound to by services, so don't use it for HAProxy VIPs

### Interface
- Select the VLAN interface where the VIP should be created
- For API and Internal VIPs: Select `OKDInfra` or `VLAN20`
- For Services VIP: Select `Services` or `VLAN40`

### Network / Address
- Format: `IP_ADDRESS/SUBNET_MASK`
- Use CIDR notation (e.g., `/24` for 255.255.255.0)
- Must be in the same subnet as the interface's network

### Gateway
- **Leave empty** for VLAN interfaces
- Only needed for PPP/PPPoE/TUN interface types
- Not applicable for standard VLAN interfaces

### Deny service binding
- **Unchecked** (default) = Allow services to bind to this VIP
- **Checked** = Prevent services from binding (not what we want for HAProxy)
- We want HAProxy to bind to these VIPs, so leave unchecked

### VHID Group
- **Leave empty** for single firewall setup
- Only used for CARP (Common Address Redundancy Protocol) in HA setups
- Not needed for a single OPNSense firewall

### No XMLRPC Sync
- **Unchecked** (default) = Include in HA synchronization
- **Checked** = Exclude from HA synchronization
- Only relevant if you have a High Availability (HA) setup with master/backup firewalls
- For single firewall, leave unchecked

### Description
- Optional but highly recommended
- Helps identify the purpose of each VIP
- Not parsed by the system, just for your reference

---

## Verification

After creating all VIPs:

1. **Check VIPs are listed:**
   - Go to: Interfaces → Virtual IPs → Settings
   - You should see all 3 VIPs listed

2. **Verify VIPs are active:**
   - Check that each VIP shows as active/enabled
   - Status should indicate the VIP is bound to the interface

3. **Test VIP connectivity (after HAProxy is configured):**
   ```bash
   # From Management VLAN
   ping 10.0.20.5    # API VIP
   ping 10.0.20.6    # Apps Internal VIP
   ping 10.0.40.10   # Apps Services VIP
   ```

---

## Troubleshooting

### "VIP not showing in interface list"
- **Check:** Interfaces → Virtual IPs → Settings
- **Verify:** VIP was saved and changes were applied
- **Check:** Interface is enabled and has an IP address

### "HAProxy cannot bind to VIP"
- **Verify:** Mode is set to "IP Alias" (not Proxy ARP)
- **Check:** "Deny service binding" is unchecked
- **Verify:** VIP IP is in the correct subnet for the interface

### "VIP IP conflicts with existing IP"
- **Check:** No other device has the VIP IP address
- **Verify:** VIP IP is not in the DHCP pool range
- **Check:** Static IPs don't conflict with VIP IPs

### "Cannot ping VIP"
- **Normal:** VIPs may not respond to ping until HAProxy is configured
- **After HAProxy:** VIPs should respond if HAProxy backends are configured
- **Check:** Firewall rules allow traffic to the VIP

---

## Important Notes

1. **IP Alias Mode:** Always use "IP Alias" for HAProxy VIPs. Proxy ARP cannot be bound to by services.

2. **Interface Selection:** Make sure you select the correct VLAN interface:
   - API and Internal VIPs → OKDInfra (VLAN20)
   - Services VIP → Services (VLAN40)

3. **IP Address Format:** Always use CIDR notation:
   - Correct: `10.0.20.5/24`
   - Incorrect: `10.0.20.5 255.255.255.0`

4. **Gateway Field:** Leave empty for VLAN interfaces. Only needed for PPP/PPPoE/TUN.

5. **Service Binding:** Leave "Deny service binding" unchecked so HAProxy can bind to the VIPs.

6. **HA Setup:** If you have a High Availability setup later, you'll need to configure VHID groups and CARP. For now, leave VHID Group empty.

---

## Next Steps

After creating all VIPs:

1. ✅ **Section 1.8:** Configure HAProxy Backends (points to master nodes)
2. ✅ **Section 1.9:** Configure HAProxy Frontends (listens on VIPs)
3. ✅ **Section 1.10:** Configure Firewall Rules (allow traffic to VIPs)

The VIPs will be used by HAProxy to load balance traffic across your OKD master nodes.

