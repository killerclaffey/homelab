# 🏗️ Home Lab Rack Build: Project "Minisforum Core" (v2.0)

## 1. Project Overview
**Goal:** Build a consolidated 19-inch network rack with "Crash Cart" functionality (front-facing Video/USB) for a high-performance NAS, Compute Cluster, and 2.5G/10G network.
**Rack Size Target:** 15U Open Frame
**Power Budget:** 1x 15A Circuit

---

## 2. Rack Diagram (Visual Layout)

**Total Height Used:** ~14U (leaving 1U for spare/cable management).

```text
[ TOP OF RACK ]
=============================================================================
[ U15 ] | [ Hive Tech Mount ] Surfboard SB8200 Modem                        |
        |   - Custom 3D Printed Mount ($79.11)                              |
-----------------------------------------------------------------------------
[ U14 ] | [ Vented Shelf ] Security & Management Layer                      |
        |   - Protectli Firewall                                            |
        |   - Raspberry Pi 4                                                |
        |   - GL.iNet KVM                                                   |
-----------------------------------------------------------------------------
[ U13 ] | [ Switch ] TRENDnet TEG-3102WS                                    |
        |   - 8x 2.5GBASE-T Ports                                           |
-----------------------------------------------------------------------------
[ U12 ] | [ Multimedia Patch Panel ] "The Command Center"                   |
        |   - Ports 1-6:  HDMI / USB / USB-C (For local control)            |
        |   - Ports 7-24: Ethernet (Network connections)                    |
-----------------------------------------------------------------------------
[ U11 ] | [ Custom Mount ] Compute Cluster                                  |
        |   - Minisforum UM890 Pro (Node 1)                                 |
[ U10 ] |   - Minisforum UM890 Pro (Node 2)                                 |
        |   - Minisforum UM890 Pro (Node 3)                                 |
-----------------------------------------------------------------------------
[ U09 ] | ( AIR GAP / NAS VERTICAL CLEARANCE )                              |
[ U08 ] | The Minisforum N5 Pro is ~9.9" tall.                              |
[ U07 ] | It sits on the shelf at U03 but occupies space up to U09.         |
[ U06 ] |                                                                   |
[ U05 ] |            [ Minisforum N5 Pro NAS ]                              |
[ U04 ] |                                                                   |
-----------------------------------------------------------------------------
[ U03 ] | [ Heavy Duty Shelf ] Main NAS Support Shelf                       |
        |   - Must support 25lb+ weight                                     |
-----------------------------------------------------------------------------
[ U02 ] | [ Cable Management ] Brush Strip or Horizontal Manager (Optional) |
-----------------------------------------------------------------------------
[ U01 ] | [ PDU ] Power Distribution Unit (Surge Protector)                 |
=============================================================================
[ BOTTOM OF RACK ]
```

---

## 3. The "Command Center" Patch Panel Configuration (U12)

We will dedicate the first block of ports to multimedia so you can plug a monitor and keyboard directly into the front of the rack.

| Port 1 | Port 2 | Port 3 | Port 4 | Port 5 | Port 6 | Ports 7-24 |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **HDMI** | **HDMI** | **USB 3.0** | **USB 3.0** | **USB-C** | **USB-C** | **Ethernet** |
| *(Pi 4 Video)* | *(Main Node)* | *(Keyboard)* | *(Mouse/Drive)* | *(Data)* | *(Data)* | *(Network)* |

*   **Spacing Note:** Multimedia keystones are wide. You may need to skip a slot (leave it empty) between HDMI/USB ports if they are too tight, or arrange them 1-3-5-7.

---

## 4. Cost Analysis & Bill of Materials (BOM)

*Prices are estimates based on current market data.*

### A. Core Hardware (Already Owned/Selected)
| Item | Price | Status |
| :--- | :--- | :--- |
| **Modem Mount (Hive Tech)** | $79.11 | **Owned** |
| **Switch (TRENDnet)** | $123.82 | **Selected** |
| **Protectli Firewall Shelf** | $49.00 | **Selected** |

### B. Infrastructure Needed (To Buy)
| Item | Est. Cost | Notes |
| :--- | :--- | :--- |
| **15U Open Frame Rack** | $145.00 | *StarTech 15U Open Frame or Echogear* |
| **3x Mini PC Mount (2U)** | ~$95.00 | *Etsy "Minisforum UM890 Rack Mount 3-slot"* |
| **Heavy Duty Shelf (For NAS)** | $38.00 | *NavePoint 1U Vented 4-Post Shelf* |
| **24-Port Patch Panel** | $18.00 | *Cable Matters 24-Port Keystone Blank* |
| **Rack Mount PDU** | $45.00 | *CyberPower or Tripp Lite 1U PDU* |

### C. Connectivity & Multimedia (The "Crash Cart" Kit)
| Item | Est. Cost | Notes |
| :--- | :--- | :--- |
| **2x HDMI Keystones** | $14.00 | *4K/60Hz Rated (Female-to-Female)* |
| **2x USB 3.0 Keystones** | $12.00 | *Type-A (Female-to-Female)* |
| **2x USB-C Keystones** | $20.00 | *Type-C 3.1 (Data Pass-through)* |
| **18x RJ45 Couplers** | $20.00 | *Cat6 Network Keystones* |
| **Internal HDMI/USB Cables** | $30.00 | *Short (1-3ft) cables to connect devices to keystones inside* |
| **Slim Network Cables** | $25.00 | *20-pack SlimRun Cat6 (6-inch & 1ft)* |
| **Power Ext. Cords** | $15.00 | *For bulky power bricks* |

### **Total Estimated Project Cost: ~$728.93**
*(Includes all racking, mounts, cabling, and multimedia ports. Excludes PC hardware.)*

---

## 5. Wiring & Configuration Plan

### **Multimedia Wiring (Internal)**
To make the front ports work, you must wire the inside:
1.  **HDMI:** Connect a 3ft HDMI cable from the **Raspberry Pi 4** (U14) to the back of **Port 1** on the Patch Panel.
2.  **USB:** Connect a 3ft USB Extension cable from the **GL.iNet KVM** or **Mini PC** to the back of **Port 3** on the Patch Panel.
3.  **USB-C:** Connect a USB-C to USB-C cable from the back of a **UM890 Pro** to **Port 5**.

### **Network Wiring**
1.  **Rear:** Ethernet cables run from devices -> Back of Patch Panel.
2.  **Front:** Short 6" patch cables run from Patch Panel -> Switch.

---

## 6. Action Items Checklist

- [ ] **Order Rack:** Purchase 15U Open Frame rack.
- [ ] **Verify Mounts:** Confirm the Hive Tech mount for the UM890 supports **3 units**.
- [ ] **Buy Multimedia Keystones:** Ensure HDMI is 4K rated and USB-C supports 10Gbps.
- [ ] **Buy Internal Cables:** Don't forget the HDMI and USB cables that go *inside* the rack!
- [ ] **Plan Spacing:** When installing the patch panel, check if the USB/HDMI keystones fit side-by-side. If not, space them out (Port 1, 3, 5).
