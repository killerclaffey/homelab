# TRENDnet TEG-3102WS Switch Configuration Guide

Complete step-by-step guide for configuring the TRENDnet TEG-3102WS 10-port multi-gig switch for VLAN segmentation.

## Switch Overview

- **Model:** TRENDnet TEG-3102WS
- **Ports:** 8x 2.5G ports (Ports 1-8) + 2x 10G ports (Ports 9-10)
- **Management:** Web-based interface
- **VLAN Support:** 802.1Q VLAN tagging
- **Default IP:** 192.168.10.200
- **Management Guide:** [Official TRENDnet Manual](https://downloads.trendnet.com/teg-3102ws/ug/Multi-Gig_Web_Smart_Switch_Series_Users_Guide_060723.pdf)

## Prerequisites

- ✅ Switch is powered on and connected to network
- ✅ Default IP address: **192.168.10.200**
- ✅ Admin credentials available (check switch label or documentation for defaults)
- ✅ OPNSense VLANs are configured (see `OPNSense_VLAN_Configuration_Details.md` and `OPNSense_VLAN_Assignment_Details.md`)

## Current Port Assignments (Your Setup)

| Port | Speed | Device | Purpose | Notes |
|------|-------|--------|---------|-------|
| **1** | 2.5G | OPNSense Firewall | Trunk (All VLANs) | Connection to Protectli VP2430 |
| **2** | 2.5G | Empty | Available | Reserved for future use |
| **3** | 2.5G | TrueNAS | Management VLAN access | 2.5G connection to N5 Pro |
| **4** | 2.5G | Raspberry Pi | Management VLAN access | Pi with GL.iNet KVM |
| **5** | 2.5G | WiFi Access Point | Trunk (Multiple VLANs) | Daisy-chained to other AP + downstairs switch (game consoles) |
| **6** | 2.5G | OKD Node 1 | Management VLAN access | Minisforum UM890 (Control Plane/Worker) |
| **7** | 2.5G | OKD Node 2 | Management VLAN access | Minisforum UM890 (Control Plane/Worker) |
| **8** | 2.5G | OKD Node 3 | Management VLAN access | Minisforum UM890 (Control Plane/Worker) |
| **9** | 10G | Desktop Computer | Management VLAN access | Your workstation |
| **10** | 10G | TrueNAS | Trunk (VLANs 1,20,30,40) | 10G connection to N5 Pro for OKD storage |

**Important Notes:**
- Port 1: All VLANs tagged for OPNSense routing
- Port 5: WiFi AP handles VLAN tagging via OpenWRT, daisy-chains to downstream switches
- Port 10: Trunk for TrueNAS to access multiple VLANs (Management, OKD-Infra, OKD-Storage, Services)
- Ports 3, 4, 6-9: Access ports on Management VLAN (untagged)
- OKD nodes will use VLAN interfaces configured in their OS for VLANs 20 and 30

---

## Step 1: Access Switch Management Interface

### Initial Access

1. **Connect to switch:**
   - Connect your computer to any available switch port via Ethernet (e.g., Port 2 since it's empty)
   - Configure your computer with a static IP in the switch's default network:
     - **IP Address:** 192.168.10.100
     - **Subnet Mask:** 255.255.255.0
     - **Gateway:** 192.168.10.200 (the switch)

2. **Access web interface:**
   - Open web browser
   - Navigate to the switch's default IP: **`http://192.168.10.200`**
   - Login with admin credentials (check the switch label or documentation for default credentials)
   - **Common defaults:** admin/admin or admin/password

3. **Change default password (HIGHLY RECOMMENDED):**
   - Navigate to: **System → Password** or **Administration → Password**
   - Set a strong password
   - Save changes

**Note:** After changing the management IP (Step 2), you'll need to reconfigure your computer's IP to match the new subnet (10.0.1.x/24) to reconnect.

---

## Step 2: Configure Switch Management IP

**Location:** System → IP Configuration or Network → IP Settings or **Network → Management → IP Configuration**

### Static IP Configuration

| Field | Value | Notes |
|-------|-------|-------|
| **IP Configuration Mode** | `Static` | Select static IP (disable DHCP) |
| **IP Address** | `10.0.1.2` | Management VLAN IP |
| **Subnet Mask** | `255.255.255.0` or `/24` | Management subnet |
| **Default Gateway** | `10.0.1.1` | OPNSense Management VLAN gateway |
| **Primary DNS** | `10.0.20.2` | TrueNAS Bind9 DNS |
| **Secondary DNS** | `10.0.1.1` | OPNSense Unbound DNS |

**After Saving:**
1. Click **Apply** or **Save**
2. Wait 30-60 seconds for the switch to apply changes
3. Disconnect your computer from the switch
4. Reconfigure your computer to get IP via DHCP or set static IP in 10.0.1.x range
5. Reconnect to switch using new IP: **`http://10.0.1.2`**

**Troubleshooting:** If you can't connect after changing IP:
- Ensure your computer is on 10.0.1.x subnet
- Try connecting OPNSense first, then access switch through OPNSense's Management VLAN
- Factory reset switch and start over if necessary (hold reset button 10+ seconds)

---

## Step 3: Create VLANs

**Location:** Network → VLAN Settings → 802.1Q VLAN

### Navigation Steps:
1. Click **Network** in the main menu
2. Click **VLAN Settings** in the submenu
3. Click **802.1Q VLAN**
4. Click **Add** or **"+"** button to create new VLANs

### Create Each VLAN

For each VLAN below, click **"Add"** or **"+"** and fill in the fields:

#### VLAN 1 - Management

| Field | Value | Notes |
|-------|-------|-------|
| **VLAN ID** | `1` | Management VLAN |
| **VLAN Name** | `Management` or `default` | Optional but helpful |
| **Description** | `Infrastructure, workstations, living room` | Optional |

#### VLAN 10 - Home

| Field | Value | Notes |
|-------|-------|-------|
| **VLAN ID** | `10` | Home VLAN |
| **VLAN Name** | `Home` | Optional but helpful |
| **Description** | `Home devices network` | Optional |

#### VLAN 20 - OKD-Infra

| Field | Value | Notes |
|-------|-------|-------|
| **VLAN ID** | `20` | OKD Infrastructure VLAN |
| **VLAN Name** | `OKD-Infra` | Optional but helpful |
| **Description** | `OKD cluster nodes, bootstrap, DNS` | Optional |

#### VLAN 30 - OKD-Storage

| Field | Value | Notes |
|-------|-------|-------|
| **VLAN ID** | `30` | OKD Storage backend VLAN |
| **VLAN Name** | `OKD-Storage` | Optional but helpful |
| **Description** | `TrueNAS NFS/iSCSI backend` | Optional |

#### VLAN 40 - Services

| Field | Value | Notes |
|-------|-------|-------|
| **VLAN ID** | `40` | Services VLAN |
| **VLAN Name** | `Services` | Optional but helpful |
| **Description** | `Published OKD services (HAProxy VIP)` | Optional |

#### VLAN 50 - IoT/Surveillance

| Field | Value | Notes |
|-------|-------|-------|
| **VLAN ID** | `50` | IoT/Surveillance VLAN |
| **VLAN Name** | `IoT-Surveillance` | Optional but helpful |
| **Description** | `IoT devices, cameras (WiFi SSID: Home-IoT)` | Optional |

#### VLAN 60 - Game Consoles

| Field | Value | Notes |
|-------|-------|-------|
| **VLAN ID** | `60` | Game Consoles VLAN |
| **VLAN Name** | `Game-Consoles` | Optional but helpful |
| **Description** | `Gaming devices (uPNP enabled)` | Optional |

#### VLAN 99 - Guest-WiFi

| Field | Value | Notes |
|-------|-------|-------|
| **VLAN ID** | `99` | Guest WiFi VLAN |
| **VLAN Name** | `Guest-WiFi` | Optional but helpful |
| **Description** | `Isolated guest network (WiFi SSID: Guest)` | Optional |

**Note:** After creating all VLANs, you should see them listed in the VLAN configuration page.

---

## Step 4: Configure Port VLAN Settings

**Location:** Network → VLAN Settings → VLAN Membership or VLAN → Port VLAN Configuration

**Important:** TRENDnet switches configure port VLAN membership in the VLAN configuration section, not in individual port settings. You'll configure which ports belong to which VLANs.

### Navigation Steps:
1. Click **Network** in the main menu
2. Click **VLAN Settings** in the submenu
3. Click **VLAN Membership** (or similar - may vary by firmware version)
4. You'll see a matrix showing VLANs and ports

---

## Understanding TRENDnet Port Configuration

TRENDnet switches use a **VLAN-centric** approach:
- You configure each VLAN and assign ports to it
- Each port can be: **Tagged**, **Untagged**, or **Not Member**
- **Tagged ports** = Trunk ports (carry multiple VLANs with tags)
- **Untagged ports** = Access ports (single VLAN, no tag)
- **PVID** = Port VLAN ID (the VLAN untagged traffic belongs to)

---

## Step 4A: Configure Port 1 (OPNSense Trunk) - All VLANs

**Location:** VLAN → Port VLAN Configuration

**For EACH VLAN (1, 10, 20, 30, 40, 50, 60, 99), configure Port 1:**

### For VLAN 1 (Management):

1. Navigate to: **VLAN → Port VLAN Configuration**
2. Find **VLAN 1** in the list
3. Click **Edit** or select VLAN 1
4. Find **Port 1** in the port list
5. Set Port 1 to: **Tagged** (or check "Tagged" checkbox)
6. Click **Apply** or **Save**

### For VLAN 10 (Home):

1. Navigate to: **VLAN → Port VLAN Configuration**
2. Find **VLAN 10** in the list
3. Click **Edit** or select VLAN 10
4. Find **Port 1** in the port list
5. Set Port 1 to: **Tagged** (or check "Tagged" checkbox)
6. Click **Apply** or **Save**

### For VLAN 20 (OKD-Infra):

1. Navigate to: **VLAN → Port VLAN Configuration**
2. Find **VLAN 20** in the list
3. Click **Edit** or select VLAN 20
4. Find **Port 1** in the port list
5. Set Port 1 to: **Tagged** (or check "Tagged" checkbox)
6. Click **Apply** or **Save**

### Repeat for VLANs 30, 40, 50, 60, 99:

- For each VLAN (30, 40, 50, 60, 99):
  1. Go to that VLAN's configuration
  2. Set Port 1 to **Tagged**
  3. Save/Apply

**Result:** Port 1 will carry all 8 VLANs as tagged traffic to OPNSense.

---

## Step 4B: Configure Port 1 PVID (Port VLAN ID)

**Location:** Switching → VLAN → PVID & Ingress Filter

**Purpose:** Set the default/untagged VLAN for Port 1

1. Navigate to: **Switching → VLAN → PVID & Ingress Filter**
2. Find **Port 1**
3. Set **PVID (Port VLAN ID)** to: `1`
4. (Optional) Set **Ingress Filter** to: **Enabled** (recommended for security)
5. Click **Apply** or **Save**

**What this does:** Any untagged traffic on Port 1 will be treated as VLAN 1 (Management). Ingress filtering will drop frames that don't belong to the port's allowed VLANs.

---

## Step 4C: Configure Ports 3, 4, 6, 7, 8, 9 (Access Ports - Management VLAN)

**Location:** VLAN → Port VLAN Configuration

**These ports are for devices that only need Management VLAN access:**
- Port 3: TrueNAS (2.5G)
- Port 4: Raspberry Pi
- Port 6: OKD Node 1
- Port 7: OKD Node 2
- Port 8: OKD Node 3
- Port 9: Desktop Computer (10G)

### For VLAN 1 (Management):

1. Navigate to: **VLAN → Port VLAN Configuration**
2. Find **VLAN 1** (Management)
3. Click **Edit** or select VLAN 1
4. For **Ports 3, 4, 6, 7, 8, 9:**
   - Set each port to: **Untagged** (or check "Untagged" checkbox)
5. Click **Apply** or **Save**

### For ALL OTHER VLANs (20, 30, 40, 50, 60, 99):

1. For each VLAN (20, 30, 40, 50, 60, 99):
   - Navigate to that VLAN's configuration
   - For **Ports 3, 4, 6, 7, 8, 9:**
     - Set each port to: **Not Member** (or uncheck all boxes)
   - Click **Apply** or **Save**

**Result:** Ports 3, 4, 6, 7, 8, 9 will only carry VLAN 1 (Management) as untagged traffic.

**Note:** OKD nodes (Ports 6-8) will configure VLAN interfaces within their operating system to access VLANs 20 and 30.

---

## Step 4D: Configure PVID for Access Ports

**Location:** Switching → VLAN → PVID & Ingress Filter

### Navigation Steps:
1. Click **Switching** in the main menu
2. Click **VLAN**
3. Click **PVID & Ingress Filter**

**For EACH access port (2, 3, 4, 6, 7, 8, 9):**

1. Find the port in the list
2. Set **PVID (Port VLAN ID)** to: `1`
3. Set **Ingress Filter** to: **Enabled** (recommended for security)
4. Click **Apply** or **Save**

**Port-specific PVID settings:**
- **Port 2:** PVID = 1 (Empty/Available)
- **Port 3:** PVID = 1 (TrueNAS Management)
- **Port 4:** PVID = 1 (Raspberry Pi)
- **Port 6:** PVID = 1 (OKD Node 1)
- **Port 7:** PVID = 1 (OKD Node 2)
- **Port 8:** PVID = 1 (OKD Node 3)
- **Port 9:** PVID = 1 (Desktop)

**What this does:** Untagged traffic on these ports is assigned to VLAN 1 (Management).

**Ingress Filter:** When enabled, the switch will drop frames that don't belong to the port's allowed VLANs, providing additional security.

---

## Step 4E: Configure Port 5 (WiFi Access Point Trunk) - VLANs 1, 50, 60, 99

**Location:** VLAN → Port VLAN Configuration

**Port 5 connects to your WiFi Access Point** which is daisy-chained to:
- Other WiFi AP
- Downstairs switch (game consoles)

The AP handles VLAN tagging via OpenWRT for different SSIDs.

### For VLAN 1 (Management):

1. Navigate to: **VLAN → Port VLAN Configuration**
2. Find **VLAN 1**
3. Click **Edit** or select VLAN 1
4. Find **Port 5** in the port list
5. Set Port 5 to: **Tagged** (or check "Tagged" checkbox)
6. Click **Apply** or **Save**

### For VLAN 50 (IoT/Surveillance):

1. Navigate to: **VLAN → Port VLAN Configuration**
2. Find **VLAN 50**
3. Click **Edit** or select VLAN 50
4. Find **Port 5** in the port list
5. Set Port 5 to: **Tagged** (or check "Tagged" checkbox)
6. Click **Apply** or **Save**

### For VLAN 60 (Game Consoles):

1. Navigate to: **VLAN → Port VLAN Configuration**
2. Find **VLAN 60**
3. Click **Edit** or select VLAN 60
4. Find **Port 5** in the port list
5. Set Port 5 to: **Tagged** (or check "Tagged" checkbox)
6. Click **Apply** or **Save**

### For VLAN 99 (Guest-WiFi):

1. Navigate to: **VLAN → Port VLAN Configuration**
2. Find **VLAN 99**
3. Click **Edit** or select VLAN 99
4. Find **Port 5** in the port list
5. Set Port 5 to: **Tagged** (or check "Tagged" checkbox)
6. Click **Apply** or **Save**

### For VLANs 20, 30, 40 (NOT needed for WiFi AP):

1. For each VLAN (20, 30, 40):
   - Navigate to that VLAN's configuration
   - Find **Port 5**
   - Set Port 5 to: **Not Member** (or uncheck all boxes)
   - Click **Apply** or **Save**

**Result:** Port 5 will carry VLANs 1, 50, 60, 99 as tagged traffic to the WiFi Access Point.

---

## Step 4E2: Configure Port 5 PVID

**Location:** Switching → VLAN → PVID & Ingress Filter

1. Find **Port 5**
2. Set **PVID (Port VLAN ID)** to: `1`
3. Click **Apply** or **Save**

**What this does:** Any untagged management traffic from the AP will be assigned to VLAN 1.

---

## Step 4F: Configure Port 10 (TrueNAS Trunk) - VLANs 1, 20, 30, 40

**Location:** VLAN → Port VLAN Configuration

**Port 10 is the 10G connection to TrueNAS** for high-speed storage access from OKD cluster.

### For VLAN 1 (Management):

1. Navigate to: **VLAN → Port VLAN Configuration**
2. Find **VLAN 1**
3. Click **Edit** or select VLAN 1
4. Find **Port 10** in the port list
5. Set Port 10 to: **Tagged** (or check "Tagged" checkbox)
6. Click **Apply** or **Save**

### For VLAN 20 (OKD-Infra):

1. Navigate to: **VLAN → Port VLAN Configuration**
2. Find **VLAN 20**
3. Click **Edit** or select VLAN 20
4. Find **Port 10** in the port list
5. Set Port 10 to: **Tagged** (or check "Tagged" checkbox)
6. Click **Apply** or **Save**

### For VLAN 30 (OKD-Storage):

1. Navigate to: **VLAN → Port VLAN Configuration**
2. Find **VLAN 30**
3. Click **Edit** or select VLAN 30
4. Find **Port 10** in the port list
5. Set Port 10 to: **Tagged** (or check "Tagged" checkbox)
6. Click **Apply** or **Save**

### For VLAN 40 (Services):

1. Navigate to: **VLAN → Port VLAN Configuration**
2. Find **VLAN 40**
3. Click **Edit** or select VLAN 40
4. Find **Port 10** in the port list
5. Set Port 10 to: **Tagged** (or check "Tagged" checkbox)
6. Click **Apply** or **Save**

### For VLANs 50, 60, 99 (NOT needed for TrueNAS):

1. For each VLAN (50, 60, 99):
   - Navigate to that VLAN's configuration
   - Find **Port 10**
   - Set Port 10 to: **Not Member** (or uncheck all boxes)
   - Click **Apply** or **Save**

**Result:** Port 10 will carry VLANs 1, 20, 30, 40 as tagged traffic to TrueNAS via 10G connection.

---

## Step 4G: Configure Port 10 PVID

**Location:** Switching → VLAN → PVID & Ingress Filter

1. Find **Port 10**
2. Set **PVID (Port VLAN ID)** to: `1`
3. Click **Apply** or **Save**

---

## Step 4H: Configure Port 2 (Empty/Available)

**Location:** VLAN → Port VLAN Configuration

**Port 2 is currently empty** and available for future use. Configure it as a Management VLAN access port by default.

### For VLAN 1 (Management):

1. Navigate to: **VLAN → Port VLAN Configuration**
2. Find **VLAN 1**
3. Click **Edit** or select VLAN 1
4. Find **Port 2** in the port list
5. Set Port 2 to: **Untagged** (or check "Untagged" checkbox)
6. Click **Apply** or **Save**

### For ALL OTHER VLANs (20, 30, 40, 50, 60, 99):

1. For each VLAN (20, 30, 40, 50, 60, 99):
   - Navigate to that VLAN's configuration
   - Find **Port 2**
   - Set Port 2 to: **Not Member** (or uncheck all boxes)
   - Click **Apply** or **Save**

### Configure Port 2 PVID:

**Location:** Switching → VLAN → PVID & Ingress Filter

1. Find **Port 2**
2. Set **PVID (Port VLAN ID)** to: `1`
3. Click **Apply** or **Save**

**Result:** Port 2 is ready for any device that needs Management VLAN access.

---

## Step 4I: Notes on Downstream Switch (Game Consoles)

**Your Setup:** Port 5 connects to WiFi AP which is daisy-chained to a downstream switch for game consoles.

### Current Configuration:
- **Port 5** on this switch: Trunk with VLANs 1, 50, 60, 99 (tagged)
- **WiFi AP:** Receives tagged VLANs, handles WiFi SSIDs
- **Downstream Switch:** Connected to WiFi AP
- **Game Consoles:** Connected to downstream switch

### Downstream Switch Options:

**Option 1: Layer 2 Unmanaged Switch (Current)**
- Set WiFi AP to output VLAN 60 untagged to downstream switch port
- Game consoles connect to unmanaged switch
- All traffic is VLAN 60 (Game Consoles)

**Option 2: Upgrade to Managed Switch (Recommended)**
- Configure downstream switch with VLANs 1, 60
- Port to WiFi AP: Trunk (tagged VLANs 1, 60)
- Ports to game consoles: Access (VLAN 60, untagged)
- Provides better control and monitoring

**Option 3: Dedicate Port on Main Switch**
If you want to connect game consoles directly to this switch instead of via downstream switch:
1. Use Port 2 (currently empty)
2. Configure as VLAN 60 access port (see "Optional Configuration" below)
3. Connect game console switch to Port 2

### Optional: Configure Port 2 for Game Consoles (VLAN 60)

If you want to move game consoles to the main switch:

**For VLAN 60:**
1. Navigate to: **VLAN → Port VLAN Configuration**
2. Find **VLAN 60**
3. Set **Port 2** to: **Untagged**
4. Save

**Remove from VLAN 1:**
1. Find **VLAN 1**
2. Set **Port 2** to: **Not Member**
3. Save

**Set PVID:**
1. Navigate to: **Switching → VLAN → PVID & Ingress Filter**
2. Set **Port 2 PVID** to: `60`
3. Save

**Result:** Port 2 becomes a dedicated Game Consoles (VLAN 60) access port.

---

## Visual Summary: Port Configuration Matrix

Here's a matrix showing how each port is configured for each VLAN:

| Port | Device | VLAN 1 | VLAN 10 | VLAN 20 | VLAN 30 | VLAN 40 | VLAN 50 | VLAN 60 | VLAN 99 | PVID |
|------|--------|--------|---------|---------|---------|---------|---------|---------|---------|------|
| **1** | OPNSense | Tagged | Tagged | Tagged | Tagged | Tagged | Tagged | Tagged | Tagged | 1 |
| **2** | Empty | Untagged | Not Member | Not Member | Not Member | Not Member | Not Member | Not Member | Not Member | 1 |
| **3** | TrueNAS (2.5G) | Untagged | Not Member | Not Member | Not Member | Not Member | Not Member | Not Member | Not Member | 1 |
| **4** | Raspberry Pi | Untagged | Not Member | Not Member | Not Member | Not Member | Not Member | Not Member | Not Member | 1 |
| **5** | WiFi AP | Tagged | Not Member | Not Member | Not Member | Not Member | Tagged | Tagged | Tagged | 1 |
| **6** | OKD Node 1 | Untagged | Not Member | Tagged | Tagged | Tagged | Not Member | Not Member | Not Member | 1 |
| **7** | OKD Node 2 | Untagged | Not Member | Tagged | Tagged | Tagged | Not Member | Not Member | Not Member | 1 |
| **8** | OKD Node 3 | Untagged | Not Member | Tagged | Tagged | Tagged | Not Member | Not Member | Not Member | 1 |
| **9** | Desktop (10G) | Untagged | Not Member | Not Member | Not Member | Not Member | Not Member | Not Member | Not Member | 1 |
| **10** | TrueNAS (10G) | Tagged | Not Member | Not Member | Tagged | Tagged | Not Member | Not Member | Not Member | 1 |

### 802.1Q PVID & Ingress Filter Configuration

| VLAN ID | VLAN Name | Member Ports | Ingress Filter |
|---------|-----------|--------------|----------------|
| **1** | default | 1-10 | Enabled |
| **10** | Home | 1 | Disabled |
| **20** | OKDInfra | 1, 6-8 | Enabled |
| **30** | OKDstorage | 1, 6-8, 10 | Enabled |
| **40** | Services | 1, 6-8, 10 | Enabled |
| **50** | IOTsurveillance | 1, 5 | Enabled |
| **60** | GAMEcon | 1, 5 | Enabled |
| **99** | GUESTwifi | 1, 5 | Enabled |

**Legend:**
- **Tagged** = Port carries this VLAN with 802.1Q tag (trunk port for multiple VLANs)
- **Untagged** = Port carries this VLAN without tag (access port, single VLAN)
- **Not Member** = Port does not carry this VLAN
- **PVID** = Port VLAN ID (default VLAN for untagged traffic)

**Trunk Ports:**
- **Port 1:** OPNSense firewall - ALL VLANs (1, 10, 20, 30, 40, 50, 60, 99)
- **Port 5:** WiFi Access Point - VLANs for WiFi (1, 50, 60, 99)
- **Port 6-8:** OKD Nodes - Tagged for VLANs 20, 30, 40 (OKD infrastructure VLANs)
- **Port 10:** TrueNAS 10G - Storage VLANs (1, 30, 40)

**Access Ports:**
- **Ports 2-4, 6-9:** Management VLAN only (VLAN 1)

**Special Notes:**
- Port 3 (TrueNAS 2.5G): Management interface only
- Port 10 (TrueNAS 10G): Trunk for VLAN-aware storage operations
- Ports 6-8 (OKD Nodes): Will configure VLAN interfaces in OS for VLANs 20 & 30
- Port 5 (WiFi AP): Daisy-chains to other AP and downstream switch (game consoles)

---

## Step-by-Step Workflow Summary

### Complete Port Configuration Process:

1. **Configure Port 1 (OPNSense Trunk - All VLANs):**
   - For VLANs 1, 10, 20, 30, 40, 50, 60, 99: Set Port 1 to **Tagged**
   - Set Port 1 PVID to **1**
   - **Device:** Protectli VP2430 OPNSense Firewall

2. **Configure Port 2 (Empty/Available):**
   - For VLAN 1: Set Port 2 to **Untagged**
   - For VLANs 20, 30, 40, 50, 60, 99: Set Port 2 to **Not Member**
   - Set Port 2 PVID to **1**
   - **Status:** Available for future use

3. **Configure Ports 3, 4, 6, 7, 8, 9 (Access Ports - Management VLAN):**
   - For VLAN 1: Set ports to **Untagged**
   - For VLANs 20, 30, 40, 50, 60, 99: Set ports to **Not Member**
   - Set PVID to **1** for all these ports
   - **Devices:**
     - Port 3: TrueNAS (2.5G management interface)
     - Port 4: Raspberry Pi with KVM
     - Port 6: OKD Node 1 (UM890)
     - Port 7: OKD Node 2 (UM890)
     - Port 8: OKD Node 3 (UM890)
     - Port 9: Desktop Computer (10G)

4. **Configure Port 5 (WiFi AP Trunk - WiFi VLANs):**
   - For VLANs 1, 50, 60, 99: Set Port 5 to **Tagged**
   - For VLANs 20, 30, 40: Set Port 5 to **Not Member**
   - Set Port 5 PVID to **1**
   - **Device:** WiFi Access Point (daisy-chained to other AP + downstream switch)

5. **Configure Port 10 (TrueNAS Trunk - OKD VLANs):**
   - For VLANs 1, 20, 30, 40: Set Port 10 to **Tagged**
   - For VLANs 50, 60, 99: Set Port 10 to **Not Member**
   - Set Port 10 PVID to **1**
   - **Device:** TrueNAS (10G storage interface for OKD)

---

## Common TRENDnet Interface Locations

Based on the TEG-3102WS manual, the standard menu structure is:

- **VLAN Creation:** Switching → VLAN → 802.1Q VLAN
- **Port VLAN Assignment:** Switching → VLAN → VLAN Membership (or Port VLAN Configuration)
- **PVID Settings:** Switching → VLAN → PVID & Ingress Filter

**Note:** The exact menu names may vary by firmware version. If you can't find these exact menus, look for:
- Anything with "VLAN" in the name under Switching or Network
- "VLAN Membership" or "Port VLAN Configuration"
- "PVID & Ingress Filter" or similar

---

## Step 5: Verify Port Configuration

### Check Port Status

**Location:** Port Status or Interface Status

1. Navigate to port status page
2. Verify:
   - All ports show "Up" or "Active"
   - Link speeds are correct (2.5G or 10G)
   - No errors or collisions

### Test Connectivity

1. **Test Management VLAN:**
   - Connect device to Port 2-8 or 10
   - Device should get IP in 10.0.1.x range
   - Should be able to ping 10.0.1.1 (OPNSense)

2. **Test Trunk Ports:**
   - Port 1 (OPNSense): Should pass all VLANs
   - Port 9 (TrueNAS): Should pass VLANs 1, 20, 30, 40

---

## Step 6: Configure Additional Settings (Optional)

### Spanning Tree Protocol (STP)

**Location:** Switching → STP or Advanced → STP

- **STP Mode:** Enable (recommended to prevent loops)
- **STP Priority:** Default (32768) is fine for single switch

### Port Mirroring (If Needed for Monitoring)

**Location:** Advanced → Port Mirroring

- Usually not needed for homelab
- Can be configured if you need to monitor traffic

### Link Aggregation (LAG) - Not Needed

- Not needed for this setup
- Single links are sufficient

---

## Quick Reference: Port Configuration Summary

### Trunk Ports (Tagged VLANs)

| Port | Speed | Device | Tagged VLANs | PVID | Purpose |
|------|-------|--------|--------------|------|---------|
| 1 | 2.5G | OPNSense Firewall | 1,10,20,30,40,50,60,99 | 1 | All VLANs to Protectli VP2430 |
| 5 | 2.5G | WiFi Access Point | 1,50,60,99 | 1 | WiFi VLANs (Management, IoT, Game, Guest) |
| 6-8 | 2.5G | OKD Nodes | 20,30,40 | 1 | OKD infrastructure VLANs (tagged on node NICs) |
| 10 | 10G | TrueNAS | 1,30,40 | 1 | Storage VLANs to N5 Pro |

### Access Ports (Untagged/Single VLAN)

| Port | Speed | Device | PVID | Purpose |
|------|-------|--------|------|---------|
| 2 | 2.5G | Empty | 1 | Available for future use |
| 3 | 2.5G | TrueNAS | 1 | N5 Pro management interface |
| 4 | 2.5G | Raspberry Pi | 1 | Pi with GL.iNet KVM |
| 6 | 2.5G | OKD Node 1 | 1 | UM890 Control Plane/Worker |
| 7 | 2.5G | OKD Node 2 | 1 | UM890 Control Plane/Worker |
| 8 | 2.5G | OKD Node 3 | 1 | UM890 Control Plane/Worker |
| 9 | 10G | Desktop | 1 | Your workstation |

### Network Topology

```
OPNSense (Port 1) ←→ All VLANs ←→ Router & Firewall
    ↓
WiFi AP (Port 5) ←→ VLANs 1,50,60,99 ←→ Mesh WiFi + Downstream Switch
    ↓
TrueNAS 10G (Port 10) ←→ VLANs 1,20,30,40 ←→ OKD Storage Backend
TrueNAS 2.5G (Port 3) ←→ VLAN 1 ←→ Management Only
    ↓
OKD Nodes (Ports 6-8) ←→ VLAN 1 ←→ OS-level VLAN config for VLANs 20,30
Desktop (Port 9) ←→ VLAN 1 ←→ Workstation
Raspberry Pi (Port 4) ←→ VLAN 1 ←→ KVM & Tailscale
```

---

## Troubleshooting

### "Cannot access switch management interface"
- **Check:** Computer is on same network as switch default IP
- **Try:** Different default IPs (192.168.0.1, 192.168.1.1, etc.)
- **Check:** Switch documentation for default IP
- **Reset:** Use reset button on switch (if available) to restore defaults

### "VLANs not working on trunk port"
- **Verify:** Port is set to Trunk/Tagged mode (not Access)
- **Check:** All required VLANs are tagged on the port
- **Verify:** PVID is set correctly (usually 1)
- **Test:** Check OPNSense can see tagged VLANs

### "Device not getting correct VLAN"
- **Access Port:** Verify PVID matches desired VLAN
- **Trunk Port:** Verify device is sending tagged frames
- **Check:** Device configuration matches switch port configuration

### "Cannot ping devices on other VLANs"
- **Normal:** VLANs are isolated by design
- **Expected:** Devices on different VLANs cannot communicate directly
- **Solution:** Configure firewall rules in OPNSense to allow cross-VLAN communication if needed

### "Port shows as down"
- **Check:** Cable is connected properly
- **Check:** Device on other end is powered on
- **Verify:** Link speed/duplex settings (usually auto-negotiate)
- **Test:** Try different cable or port

### "Switch loses configuration after reboot"
- **Check:** Configuration was saved before reboot
- **Verify:** Switch has non-volatile memory (most managed switches do)
- **Check:** Switch firmware is up to date

---

## Important Notes

1. **Port 1 (OPNSense Trunk):** This is CRITICAL - must be configured as trunk with all VLANs tagged (1,10,20,30,40,50,60,99)
2. **Port 5 (WiFi AP Trunk):** Carries WiFi-related VLANs (1,50,60,99). AP handles VLAN tagging via OpenWRT
3. **Port 10 (TrueNAS 10G Trunk):** Only needs OKD-related VLANs (1,20,30,40) for storage operations
4. **Port 3 vs Port 10 (TrueNAS):**
   - Port 3 (2.5G): Management interface only (untagged VLAN 1)
   - Port 10 (10G): Storage interface with VLAN trunking for OKD
5. **OKD Nodes (Ports 6-8):** Connected to Management VLAN at switch level, but will configure VLAN interfaces in their OS for VLANs 20 and 30
6. **Port 2:** Currently empty, configured for Management VLAN by default
7. **PVID:** Port VLAN ID is the default/untagged VLAN for that port (all set to 1)
8. **Tagged vs Untagged:**
   - **Tagged:** VLAN traffic has 802.1Q tag (for trunk ports carrying multiple VLANs)
   - **Untagged:** VLAN traffic has no tag (for access ports with single VLAN)
9. **Daisy-Chain Topology:** Port 5 feeds WiFi AP which connects to another AP and downstream switch (game consoles)

---

## Switch Interface Terminology

Different switch manufacturers use different terms. Here's what to look for:

| Function | TRENDnet Term | Alternative Terms |
|----------|---------------|-------------------|
| Single VLAN port | Access, Untagged | Access, Port-based VLAN |
| Multiple VLAN port | Trunk, Tagged | Tagged, 802.1Q |
| Default VLAN | PVID | Native VLAN, Untagged VLAN |
| VLAN membership | Tagged/Untagged | Member VLANs |

---

## Configuration Checklist

### Initial Setup
- [ ] Accessed switch management interface at 192.168.10.200
- [ ] Changed default password (SECURITY CRITICAL!)
- [ ] Configured switch management IP (10.0.1.2)

### VLAN Creation
- [ ] Created VLAN 1 (Management/default)
- [ ] Created VLAN 10 (Home)
- [ ] Created VLAN 20 (OKD-Infra)
- [ ] Created VLAN 30 (OKD-Storage)
- [ ] Created VLAN 40 (Services)
- [ ] Created VLAN 50 (IoT/Surveillance)
- [ ] Created VLAN 60 (Game Consoles)
- [ ] Created VLAN 99 (Guest-WiFi)

### Port Configuration
- [ ] Configured Port 1 as Trunk (OPNSense - VLANs 1,10,20,30,40,50,60,99)
- [ ] Configured Port 2 as Access (Empty - VLAN 1)
- [ ] Configured Port 3 as Access (TrueNAS 2.5G - VLAN 1)
- [ ] Configured Port 4 as Access (Raspberry Pi - VLAN 1)
- [ ] Configured Port 5 as Trunk (WiFi AP - VLANs 1,50,60,99)
- [ ] Configured Port 6 as Access (OKD Node 1 - VLAN 1)
- [ ] Configured Port 7 as Access (OKD Node 2 - VLAN 1)
- [ ] Configured Port 8 as Access (OKD Node 3 - VLAN 1)
- [ ] Configured Port 9 as Access (Desktop 10G - VLAN 1)
- [ ] Configured Port 10 as Trunk (TrueNAS 10G - VLANs 1,20,30,40)

### PVID Configuration
- [ ] Set PVID to 1 for all ports (1-10)
- [ ] Enabled Ingress Filter on all access ports (recommended)

### Testing & Verification
- [ ] Verified all ports show as "Up" or "Active"
- [ ] Tested connectivity from Port 1 (OPNSense can reach all VLANs)
- [ ] Tested connectivity from Port 3 (TrueNAS management)
- [ ] Tested connectivity from Port 4 (Raspberry Pi)
- [ ] Tested connectivity from Ports 6-8 (OKD nodes)
- [ ] Tested connectivity from Port 9 (Desktop)
- [ ] Tested connectivity from Port 10 (TrueNAS 10G trunk)
- [ ] Tested WiFi AP trunk (Port 5) - multiple VLANs working
- [ ] Saved configuration (System → Save Config)
- [ ] Backed up configuration (System → Backup/Restore)

---

## Next Steps

After switch configuration:

1. ✅ **Test VLAN connectivity** from devices on different ports
2. ✅ **Verify trunk ports** are passing VLANs correctly
3. ✅ **Configure WiFi Access Points** (Section 4) - connect to access ports
4. ✅ **Test end-to-end** - device on VLAN should get correct IP and access

---

## Backup Switch Configuration

**Location:** System → Backup/Restore or Administration → Configuration

1. Navigate to backup/export configuration
2. Download/export current configuration
3. Save to safe location
4. **Important:** Do this after making changes to have a restore point

---

## Firmware Updates

**Location:** System → Firmware Update or Administration → Firmware

1. Check current firmware version
2. Check TRENDnet website for latest firmware
3. Download firmware file
4. Upload and install (follow switch documentation)
5. **Warning:** Firmware updates may reset configuration - backup first!

---

## Additional Resources

- TRENDnet TEG-3102WS User Manual
- TRENDnet Support: Check manufacturer website
- Switch documentation for specific menu locations (may vary by firmware version)

