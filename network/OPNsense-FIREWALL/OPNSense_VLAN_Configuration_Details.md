# OPNSense VLAN Configuration Details - Section 1.1

This document provides complete field-by-field configuration for creating VLAN interfaces in OPNSense.

## Prerequisites

- Identify your main trunk interface (the 2.5G port connected to the TRENDnet switch)
- This is typically named something like `igc1`, `igc2`, `igc3`, or `igc4` (depending on your Protectli VP2430 port numbering)
- The WAN interface is typically `igc0` (as shown in your example)

## VLAN Interface Configuration

### VLAN 1 - Management

**Location:** Interfaces → Other Types → VLAN → Add

| Field | Value | Notes |
|-------|-------|-------|
| **Device** | (Leave empty - auto-generate) | Will create something like `vlan1` |
| **Parent** | `igc1` (or your main trunk interface) | Select the 2.5G port connected to switch |
| **VLAN tag** | `1` | Management VLAN |
| **VLAN priority** | Best Effort (0, default) | Standard priority |
| **Edit Vlan** | Auto | Use default 802.1Q |
| **Description** | `Management - Infrastructure, workstations, living room` | For reference |

---

### VLAN 20 - OKD-Infra

**Location:** Interfaces → Other Types → VLAN → Add

| Field | Value | Notes |
|-------|-------|-------|
| **Device** | (Leave empty - auto-generate) | Will create something like `vlan20` |
| **Parent** | `igc1` (or your main trunk interface) | Same parent as VLAN 1 |
| **VLAN tag** | `20` | OKD Infrastructure VLAN |
| **VLAN priority** | Best Effort (0, default) | Standard priority |
| **Edit Vlan** | Auto | Use default 802.1Q |
| **Description** | `OKD-Infra - Cluster nodes, bootstrap, DNS` | For reference |

---

### VLAN 30 - OKD-Storage

**Location:** Interfaces → Other Types → VLAN → Add

| Field | Value | Notes |
|-------|-------|-------|
| **Device** | (Leave empty - auto-generate) | Will create something like `vlan30` |
| **Parent** | `igc1` (or your main trunk interface) | Same parent as VLAN 1 |
| **VLAN tag** | `30` | OKD Storage backend VLAN |
| **VLAN priority** | Best Effort (0, default) | Standard priority |
| **Edit Vlan** | Auto | Use default 802.1Q |
| **Description** | `OKD-Storage - TrueNAS NFS/iSCSI backend` | For reference |

---

### VLAN 40 - Services

**Location:** Interfaces → Other Types → VLAN → Add

| Field | Value | Notes |
|-------|-------|-------|
| **Device** | (Leave empty - auto-generate) | Will create something like `vlan40` |
| **Parent** | `igc1` (or your main trunk interface) | Same parent as VLAN 1 |
| **VLAN tag** | `40` | Services VLAN for HAProxy VIP |
| **VLAN priority** | Best Effort (0, default) | Standard priority |
| **Edit Vlan** | Auto | Use default 802.1Q |
| **Description** | `Services - Published OKD services (HAProxy VIP)` | For reference |

---

### VLAN 50 - IoT/Surveillance

**Location:** Interfaces → Other Types → VLAN → Add

| Field | Value | Notes |
|-------|-------|-------|
| **Device** | (Leave empty - auto-generate) | Will create something like `vlan50` |
| **Parent** | `igc1` (or your main trunk interface) | Same parent as VLAN 1 |
| **VLAN tag** | `50` | IoT and Surveillance devices |
| **VLAN priority** | Best Effort (0, default) | Standard priority |
| **Edit Vlan** | Auto | Use default 802.1Q |
| **Description** | `IoT/Surveillance - IoT devices, cameras (WiFi SSID: Home-IoT)` | For reference |

---

### VLAN 60 - Game Consoles

**Location:** Interfaces → Other Types → VLAN → Add

| Field | Value | Notes |
|-------|-------|-------|
| **Device** | (Leave empty - auto-generate) | Will create something like `vlan60` |
| **Parent** | `igc1` (or your main trunk interface) | Same parent as VLAN 1 |
| **VLAN tag** | `60` | Game Consoles with uPNP |
| **VLAN priority** | Best Effort (0, default) | Standard priority |
| **Edit Vlan** | Auto | Use default 802.1Q |
| **Description** | `Game Consoles - Gaming devices (uPNP enabled)` | For reference |

---

### VLAN 99 - Guest-WiFi

**Location:** Interfaces → Other Types → VLAN → Add

| Field | Value | Notes |
|-------|-------|-------|
| **Device** | (Leave empty - auto-generate) | Will create something like `vlan99` |
| **Parent** | `igc1` (or your main trunk interface) | Same parent as VLAN 1 |
| **VLAN tag** | `99` | Guest WiFi network |
| **VLAN priority** | Best Effort (0, default) | Standard priority |
| **Edit Vlan** | Auto | Use default 802.1Q |
| **Description** | `Guest-WiFi - Isolated guest network (WiFi SSID: Guest)` | For reference |

---

## Important Notes

### Identifying Your Trunk Interface

To identify which interface is your main trunk (connected to the switch):

1. **Check physical connections:**
   - WAN is typically `igc0` (connected to your internet)
   - One of `igc1`, `igc2`, `igc3`, or `igc4` is connected to your TRENDnet switch
   - Another one (likely `igc2` or `igc3`) is connected directly to your Helium hotspot

2. **Check current interface assignments:**
   - Go to: Interfaces → Assignments
   - Look for interfaces that are already assigned
   - The one connected to your switch should show link status

3. **Test method:**
   - Temporarily disconnect the switch
   - Check which interface shows "No carrier" or link down
   - That's your trunk interface

### VLAN Priority Notes

- **Best Effort (0)** is the default and appropriate for all VLANs
- Higher priorities (1-7) are for QoS/CoS purposes
- For a homelab, default priority is fine unless you have specific QoS requirements

### After Creating VLANs

Once you create all VLAN interfaces, you'll need to:

1. **Assign them** (Section 1.2):
   - Go to: Interfaces → Assignments
   - Click "+" for each VLAN
   - Select the VLAN interface (e.g., `vlan1`, `vlan20`, etc.)
   - Configure IP addresses

2. **Enable them:**
   - Each assigned interface needs to be enabled
   - Configure static IPs as specified in Section 1.2

## Example: Complete VLAN Creation Workflow

1. Navigate to: **Interfaces → Other Types → VLAN**
2. Click **"+"** (Add) button
3. Fill in fields for VLAN 1 (Management):
   - Device: (leave empty)
   - Parent: Select `igc1` (or your trunk interface)
   - VLAN tag: `1`
   - VLAN priority: Best Effort (0, default)
   - Edit Vlan: Auto
   - Description: `Management - Infrastructure, workstations, living room`
4. Click **Save**
5. Repeat for VLANs 20, 30, 40, 50, 60, 99
6. After all VLANs are created, proceed to Section 1.2 (Assign VLAN Interfaces)

## Troubleshooting

- **"Parent interface not found":** Make sure you're selecting the correct physical interface connected to your switch
- **"VLAN tag already in use":** Check if you've already created this VLAN
- **"Device name conflict":** If you manually set a device name, ensure it follows the naming convention (e.g., `vlan1`, `vlan20`)

