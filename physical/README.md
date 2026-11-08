# Physical Infrastructure Documentation

This directory documents the homelab physical infrastructure, including rack mounting, equipment layout, cabling standards, and power delivery.

---

## Files

- [rackmount-plan.md](rackmount-plan.md) - Detailed 15U rack mounting layout and bill of materials

---

## Physical Setup Overview

### Rack Configuration

Equipment is housed in a standard 19-inch open-frame rack organized into dedicated tiers to ensure optimal airflow, thermal management, and accessible cabling runs.

### Equipment Layout

The rack is structured from top to bottom:

1. **Networking Tier (Top)**
   - TRENDnet TEG-3102WS 10-port multi-gigabit switch (1U / shelf)
   - Protectli VP2430 OPNsense firewall appliance
   - 2x Netgear RBK50 WiFi access points (mesh configuration)

2. **Compute Tier (Middle)**
   - 4x Minisforum UM890 Pro mini PCs (OKD cluster nodes: `k81`, `k82`, `k83`, `k84`)
   - Minisforum N5 Pro storage appliance (TrueNAS SCALE)

3. **Management & Console Tier**
   - Raspberry Pi 4 + GL.iNet Comet KVM for out-of-band crash cart access
   - 24-port keystone patch panel (multimedia + RJ45 pass-through)

4. **Storage & Power Tier (Bottom)**
   - Rackmount Power Distribution Unit (PDU) / UPS
   - Heavy chassis equipment positioned at base for center-of-gravity stability

---

## Cabling Strategy

### Network Cabling

- Short Cat6 patch cables utilized for intra-rack connections.
- Color coding standards by VLAN and traffic profile:
  - **Blue**: Management traffic (VLAN 1)
  - **Green**: Multi-VLAN trunk links
  - **Red**: Dedicated direct links (Helium hotspot, WAN)
  - **White**: General purpose access ports

### Power Cabling

- All active compute and networking equipment is fed through surge protection and UPS backup.
- Power bricks are secured with velcro ties with service loops maintained for device servicing.

### Storage & Interconnect Cabling

- **Thunderbolt 4 / USB4 Mesh**: 40Gbps passive cables interconnected in a dual-homed ring between cluster nodes and TrueNAS storage.
- **Ethernet Uplinks**:
  - 10G SFP+ connection between TrueNAS and TRENDnet switch port 9.
  - 2.5GbE connections between Minisforum UM890 Pro nodes and switch access ports.

---

## Physical Port Assignments

### OPNsense Protectli VP2430

- Port 1 (2.5G) → Internet / Cable Modem (WAN)
- Port 2 (2.5G) → Switch Port 1 (Trunk)
- Port 3 (2.5G) → Helium Hotspot (Direct)
- Port 4 (2.5G) → Available / Diagnostics

### TRENDnet TEG-3102WS Switch

- Port 1 (2.5G) → OPNsense Port 2 (Trunk)
- Ports 2–5 (2.5G) → OKD Cluster Nodes (`k81`, `k82`, `k83`, `k84`)
- Ports 6–8 (2.5G) → Access points and management devices
- Port 9 (10G SFP+) → TrueNAS Storage (Trunk)
- Port 10 (10G SFP+) → Workstation Uplink

### TrueNAS N5 Pro

- 10G SFP+ → Switch Port 9 (Trunk)
- Thunderbolt 4 Ports 0 & 1 → Ring connections to `k81` and `k84`

### OKD Cluster Nodes (4x Minisforum UM890 Pro)

- Primary 2.5GbE NIC → Switch Ports 2–5 (VLAN 20 OKD-Infra)
- Dual USB4 / Thunderbolt 4 Ports → Inter-node mesh network (`tb-br0`)

### Out-of-Band KVM & Management

- Raspberry Pi 4 Ethernet → Switch access port (Management VLAN)
- Front multimedia patch panel: HDMI and USB keystones routed directly to console ports

---

## Cable Management Standards

1. **Structured Vertical Routing**: Cables run vertically along rear rack posts to preserve front airflow.
2. **Hook-and-Loop Fasteners**: Velcro straps are used exclusively in place of zip ties to prevent jacket compression.
3. **Service Loops**: A minimum 6-inch service loop is maintained at all termination endpoints.
4. **Dual-End Labeling**: Both ends of every patch cable are labeled with:
   - Source device and physical port
   - Destination device and physical port
   - Subnet or VLAN assignment

---

## Environmental & Thermal Management

### Airflow Design

- Cold aisle intake occurs across the front panel of all chassis.
- Exhaust air discharges out the rear.
- Device spacing maintains vertical clearance between higher-wattage nodes and storage arrays.

### Monitoring & Maintenance

- Ambient temperatures and chassis sensors are monitored continuously via Prometheus node exporters.
- Quarterly visual inspection and dust filter cleaning.

---

## References

- [Rackmount Build Plan](rackmount-plan.md)
- [Main Setup Guide](../README.md)
- [Thunderbolt 4 / USB4 Mesh Network](../docs/network/thunderbolt-mesh-topology.md)
- [Cluster Network Configuration](../okd-cluster/trial-os-cluster1-test-installation/Network_Configuration.md)
