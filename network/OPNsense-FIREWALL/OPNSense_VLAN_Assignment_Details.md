# OPNSense VLAN Assignment Details - Section 1.2

This document provides complete field-by-field configuration for assigning and configuring VLAN interfaces in OPNSense after they've been created in Section 1.1.

## Prerequisites

- ✅ All VLAN interfaces have been created (Section 1.1)
- ✅ You should see VLAN interfaces available: `vlan1`, `vlan20`, `vlan30`, `vlan40`, `vlan50`, `vlan60`, `vlan99`

## Step-by-Step: Assigning VLAN Interfaces

### Overview

After creating VLAN interfaces, you need to:
1. Assign each VLAN to an interface slot
2. Enable the interface
3. Configure static IP addresses
4. Configure other interface settings

---

## VLAN 1 - Management Interface Assignment

### Step 1: Assign the Interface

**Location:** Interfaces → Assignments

1. Click the **"+"** button (Add interface)
2. In the dropdown, select: **`vlan1`** (or `VLAN: 1` - Management)
3. Click **Save**

### Step 2: Configure the Interface

**Location:** Interfaces → [VLAN1] (click on the newly assigned interface)

#### General Configuration Tab

| Field | Value | Notes |
|-------|-------|-------|
| **Enable interface** | ☑ Checked | Enable this interface |
| **Lock** | ☐ Unchecked | Leave unchecked (allows interface to be removed) |
| **Description** | `Management - Infrastructure, workstations, living room` | Optional but helpful |
| **IPv4 Configuration Type** | `Static IPv4` | Select from dropdown |
| **IPv4 Address** | `10.0.1.1` | Gateway IP for this VLAN |
| **IPv4 Subnet** | `24` | Select from dropdown (255.255.255.0) |
| **IPv6 Configuration Type** | `None` | Unless you're using IPv6 |
| **Block private networks** | ☐ Unchecked | Not needed (this IS a private network) |
| **Block bogon networks** | ☐ Unchecked | Not needed |

#### Advanced Configuration (Optional - usually defaults are fine)

- **MTU:** Leave default (1500)
- **MSS:** Leave default (auto)
- **Speed and duplex:** Leave default (autoselect)

Click **Save** → **Apply Changes**

---

## VLAN 20 - OKD-Infra Interface Assignment

### Step 1: Assign the Interface

**Location:** Interfaces → Assignments

1. Click the **"+"** button (Add interface)
2. In the dropdown, select: **`vlan20`** (or `VLAN: 20` - OKD-Infra)
3. Click **Save**

### Step 2: Configure the Interface

**Location:** Interfaces → [VLAN20] (click on the newly assigned interface)

#### General Configuration Tab

| Field | Value | Notes |
|-------|-------|-------|
| **Enable interface** | ☑ Checked | Enable this interface |
| **Lock** | ☐ Unchecked | Leave unchecked |
| **Description** | `OKD-Infra - Cluster nodes, bootstrap, DNS` | Optional but helpful |
| **IPv4 Configuration Type** | `Static IPv4` | Select from dropdown |
| **IPv4 Address** | `10.0.20.1` | Gateway IP for this VLAN |
| **IPv4 Subnet** | `24` | Select from dropdown (255.255.255.0) |
| **IPv6 Configuration Type** | `None` | Unless you're using IPv6 |
| **Block private networks** | ☐ Unchecked | Not needed |
| **Block bogon networks** | ☐ Unchecked | Not needed |

Click **Save** → **Apply Changes**

---

## VLAN 30 - OKD-Storage Interface Assignment

### Step 1: Assign the Interface

**Location:** Interfaces → Assignments

1. Click the **"+"** button (Add interface)
2. In the dropdown, select: **`vlan30`** (or `VLAN: 30` - OKD-Storage)
3. Click **Save**

### Step 2: Configure the Interface

**Location:** Interfaces → [VLAN30] (click on the newly assigned interface)

#### General Configuration Tab

| Field | Value | Notes |
|-------|-------|-------|
| **Enable interface** | ☑ Checked | Enable this interface |
| **Lock** | ☐ Unchecked | Leave unchecked |
| **Description** | `OKD-Storage - TrueNAS NFS/iSCSI backend` | Optional but helpful |
| **IPv4 Configuration Type** | `Static IPv4` | Select from dropdown |
| **IPv4 Address** | `10.0.30.1` | Gateway IP for this VLAN |
| **IPv4 Subnet** | `24` | Select from dropdown (255.255.255.0) |
| **IPv6 Configuration Type** | `None` | Unless you're using IPv6 |
| **Block private networks** | ☐ Unchecked | Not needed |
| **Block bogon networks** | ☐ Unchecked | Not needed |

Click **Save** → **Apply Changes**

---

## VLAN 40 - Services Interface Assignment

### Step 1: Assign the Interface

**Location:** Interfaces → Assignments

1. Click the **"+"** button (Add interface)
2. In the dropdown, select: **`vlan40`** (or `VLAN: 40` - Services)
3. Click **Save**

### Step 2: Configure the Interface

**Location:** Interfaces → [VLAN40] (click on the newly assigned interface)

#### General Configuration Tab

| Field | Value | Notes |
|-------|-------|-------|
| **Enable interface** | ☑ Checked | Enable this interface |
| **Lock** | ☐ Unchecked | Leave unchecked |
| **Description** | `Services - Published OKD services (HAProxy VIP)` | Optional but helpful |
| **IPv4 Configuration Type** | `Static IPv4` | Select from dropdown |
| **IPv4 Address** | `10.0.40.1` | Gateway IP for this VLAN |
| **IPv4 Subnet** | `24` | Select from dropdown (255.255.255.0) |
| **IPv6 Configuration Type** | `None` | Unless you're using IPv6 |
| **Block private networks** | ☐ Unchecked | Not needed |
| **Block bogon networks** | ☐ Unchecked | Not needed |

Click **Save** → **Apply Changes**

---

## VLAN 50 - IoT/Surveillance Interface Assignment

### Step 1: Assign the Interface

**Location:** Interfaces → Assignments

1. Click the **"+"** button (Add interface)
2. In the dropdown, select: **`vlan50`** (or `VLAN: 50` - IoT/Surveillance)
3. Click **Save**

### Step 2: Configure the Interface

**Location:** Interfaces → [VLAN50] (click on the newly assigned interface)

#### General Configuration Tab

| Field | Value | Notes |
|-------|-------|-------|
| **Enable interface** | ☑ Checked | Enable this interface |
| **Lock** | ☐ Unchecked | Leave unchecked |
| **Description** | `IoT/Surveillance - IoT devices, cameras (WiFi SSID: Home-IoT)` | Optional but helpful |
| **IPv4 Configuration Type** | `Static IPv4` | Select from dropdown |
| **IPv4 Address** | `10.0.50.1` | Gateway IP for this VLAN |
| **IPv4 Subnet** | `24` | Select from dropdown (255.255.255.0) |
| **IPv6 Configuration Type** | `None` | Unless you're using IPv6 |
| **Block private networks** | ☐ Unchecked | Not needed |
| **Block bogon networks** | ☐ Unchecked | Not needed |

Click **Save** → **Apply Changes**

---

## VLAN 60 - Game Consoles Interface Assignment

### Step 1: Assign the Interface

**Location:** Interfaces → Assignments

1. Click the **"+"** button (Add interface)
2. In the dropdown, select: **`vlan60`** (or `VLAN: 60` - Game Consoles)
3. Click **Save**

### Step 2: Configure the Interface

**Location:** Interfaces → [VLAN60] (click on the newly assigned interface)

#### General Configuration Tab

| Field | Value | Notes |
|-------|-------|-------|
| **Enable interface** | ☑ Checked | Enable this interface |
| **Lock** | ☐ Unchecked | Leave unchecked |
| **Description** | `Game Consoles - Gaming devices (uPNP enabled)` | Optional but helpful |
| **IPv4 Configuration Type** | `Static IPv4` | Select from dropdown |
| **IPv4 Address** | `10.0.60.1` | Gateway IP for this VLAN |
| **IPv4 Subnet** | `24` | Select from dropdown (255.255.255.0) |
| **IPv6 Configuration Type** | `None` | Unless you're using IPv6 |
| **Block private networks** | ☐ Unchecked | Not needed |
| **Block bogon networks** | ☐ Unchecked | Not needed |

Click **Save** → **Apply Changes**

---

## VLAN 99 - Guest-WiFi Interface Assignment

### Step 1: Assign the Interface

**Location:** Interfaces → Assignments

1. Click the **"+"** button (Add interface)
2. In the dropdown, select: **`vlan99`** (or `VLAN: 99` - Guest-WiFi)
3. Click **Save**

### Step 2: Configure the Interface

**Location:** Interfaces → [VLAN99] (click on the newly assigned interface)

#### General Configuration Tab

| Field | Value | Notes |
|-------|-------|-------|
| **Enable interface** | ☑ Checked | Enable this interface |
| **Lock** | ☐ Unchecked | Leave unchecked |
| **Description** | `Guest-WiFi - Isolated guest network (WiFi SSID: Guest)` | Optional but helpful |
| **IPv4 Configuration Type** | `Static IPv4` | Select from dropdown |
| **IPv4 Address** | `10.0.99.1` | Gateway IP for this VLAN |
| **IPv4 Subnet** | `24` | Select from dropdown (255.255.255.0) |
| **IPv6 Configuration Type** | `None` | Unless you're using IPv6 |
| **Block private networks** | ☐ Unchecked | Not needed |
| **Block bogon networks** | ☐ Unchecked | Not needed |

Click **Save** → **Apply Changes**

---

## Quick Reference: All VLAN IP Addresses

| VLAN | Interface Name | IP Address | Subnet |
|------|----------------|------------|--------|
| 1 | VLAN1 | 10.0.1.1 | /24 (255.255.255.0) |
| 20 | VLAN20 | 10.0.20.1 | /24 (255.255.255.0) |
| 30 | VLAN30 | 10.0.30.1 | /24 (255.255.255.0) |
| 40 | VLAN40 | 10.0.40.1 | /24 (255.255.255.0) |
| 50 | VLAN50 | 10.0.50.1 | /24 (255.255.255.0) |
| 60 | VLAN60 | 10.0.60.1 | /24 (255.255.255.0) |
| 99 | VLAN99 | 10.0.99.1 | /24 (255.255.255.0) |

---

## Complete Workflow Summary

### For Each VLAN (1, 20, 30, 40, 50, 60, 99):

1. **Go to:** Interfaces → Assignments
2. **Click:** "+" (Add interface button)
3. **Select:** The VLAN interface from dropdown (e.g., `vlan1`)
4. **Click:** Save
5. **Click:** On the newly created interface name (e.g., "VLAN1")
6. **Configure:**
   - ☑ Enable interface
   - Description: (see table above)
   - IPv4 Configuration Type: Static IPv4
   - IPv4 Address: (see table above)
   - IPv4 Subnet: 24
   - IPv6 Configuration Type: None
7. **Click:** Save
8. **Click:** Apply Changes (if prompted)

### After All VLANs Are Assigned:

You should see in **Interfaces → Assignments**:
- WAN (igc0) - your internet connection
- LAN (or OPT1) - might be your old flat network (can be removed later)
- VLAN1 - Management
- VLAN20 - OKD-Infra
- VLAN30 - OKD-Storage
- VLAN40 - Services
- VLAN50 - IoT/Surveillance
- VLAN60 - Game Consoles
- VLAN99 - Guest-WiFi

---

## Visual Guide: Interface Assignment Screen

```
Interfaces → Assignments

┌─────────────────────────────────────────────────────────┐
│ Available network ports                                  │
├─────────────────────────────────────────────────────────┤
│                                                           │
│  [igc0]  WAN                                             │
│  [igc1]  Available                                       │
│  [igc2]  Available                                       │
│  [igc3]  Available                                       │
│  [igc4]  Available                                       │
│                                                           │
│  [+ Add]  ← Click this to add new interface              │
│                                                           │
└─────────────────────────────────────────────────────────┘

After clicking [+ Add], you'll see a dropdown with:
  - vlan1 (VLAN: 1 - Management)
  - vlan20 (VLAN: 20 - OKD-Infra)
  - vlan30 (VLAN: 30 - OKD-Storage)
  - vlan40 (VLAN: 40 - Services)
  - vlan50 (VLAN: 50 - IoT/Surveillance)
  - vlan60 (VLAN: 60 - Game Consoles)
  - vlan99 (VLAN: 99 - Guest-WiFi)
```

---

## Troubleshooting

### "Interface not found in dropdown"
- **Cause:** VLAN interface wasn't created in Section 1.1
- **Solution:** Go back to Interfaces → Other Types → VLAN and create the missing VLAN

### "Cannot assign interface"
- **Cause:** Interface might already be assigned
- **Solution:** Check Interfaces → Assignments to see if it's already there

### "Interface shows as down/No carrier"
- **Cause:** This is normal for VLAN interfaces - they're virtual
- **Solution:** As long as the parent interface (igc1) is up, VLANs will work

### "Cannot ping gateway after assignment"
- **Cause:** Firewall rules not configured yet
- **Solution:** This is expected - proceed to Section 1.10 (Firewall Rules) after completing assignments

### "Interface assignment disappears after save"
- **Cause:** Need to click "Apply Changes" after saving
- **Solution:** Always click "Apply Changes" button after configuring each interface

---

## Next Steps

After completing all VLAN assignments:

1. ✅ **Section 1.3:** Configure Helium Hotspot Interface (separate physical port)
2. ✅ **Section 1.4:** Configure DHCP Services
3. ✅ **Section 1.5:** Enable uPNP for Game Consoles VLAN
4. ✅ **Section 1.10:** Configure Firewall Rules (critical!)

**Important:** Don't configure firewall rules until all interfaces are assigned and enabled, as firewall rules reference these interfaces.

