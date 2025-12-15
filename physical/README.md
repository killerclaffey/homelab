# Physical Infrastructure Documentation

This folder contains documentation for my homelab's physical setup, including rack mounting, cabling, and hardware placement.

## Files

- [rackmount-plan.md](rackmount-plan.md) - Detailed rack mounting plan and layout

## My Physical Setup Overview

### Rack Configuration

I'm using a standard 19-inch server rack to organize all my homelab equipment.

### Equipment Layout

My rack is organized from top to bottom for optimal airflow and cable management:

1. **Networking Tier** (Top)
   - TRENDnet TEG-3102WS 10-port switch (1U or shelf)
   - Protectli VP2430 OPNSense firewall (shelf)
   - 2x Netgear RBK50 WiFi APs (shelf or mounted)

2. **Compute Tier** (Middle)
   - 3x Minisforum UM890 (OKD cluster nodes)
   - Minisforum N5 Pro (TrueNAS storage)

3. **Accessories Tier**
   - Raspberry Pi + GL.iNet Comet KVM
   - Cable management

4. **Storage Tier** (Bottom)
   - UPS (if applicable)
   - Heavy equipment at bottom for stability

### Cabling Strategy

**Network Cabling**
- Short patch cables for rack-internal connections
- Color coding by VLAN/purpose:
  - Blue: Management (VLAN 1)
  - Green: Trunk lines
  - Red: Direct connections (Helium)
  - White: General purpose

**Power Cabling**
- All equipment powered through UPS (if available)
- Cable ties and velcro straps for organization
- Leave slack for maintenance

**Storage Cabling**
- 10G connections for TrueNAS to switch
- 2.5G connections for UM890s to switch

### Physical Connections

**OPNSense Protectli VP2430**
- Port 1 (2.5G) → Internet/Modem (WAN)
- Port 2 (2.5G) → Switch Port 1 (Trunk)
- Port 3 (2.5G) → Helium Hotspot (Direct)
- Port 4 (2.5G) → Available

**TRENDnet TEG-3102WS Switch**
- Port 1 (2.5G) → OPNSense Port 2 (Trunk)
- Port 2-8 (2.5G) → Available/Access ports
- Port 9 (10G) → TrueNAS (Trunk)
- Port 10 (10G) → Desktop/Workstation

**TrueNAS N5 Pro**
- 10G NIC → Switch Port 9 (Trunk)
- USB ports → External drives (optional)

**OKD Cluster Nodes (3x UM890)**
- Each node: 2.5G NIC → Switch (Ports 2-4 or via additional ports)
- Multiple NICs per node for VLAN separation (if supported)

**WiFi Access Points**
- AP1: Switch access port → Internal switch handles VLAN tagging
- AP2: Switch access port → Internal switch handles VLAN tagging
- Placed for optimal coverage

**Raspberry Pi + KVM**
- Network: Switch access port (Management VLAN)
- USB/HDMI: To server console ports

## Cable Management

### Best Practices I Follow

1. **Horizontal Cable Management**: Use the back of the rack for vertical runs
2. **Velcro Ties**: Prefer velcro over zip ties for flexibility
3. **Service Loops**: Leave extra cable length for maintenance
4. **Labeling**: Label both ends of each cable
5. **Color Coding**: Use different colors for different purposes

### Cable Labels

I label cables with:
- Source device and port
- Destination device and port
- VLAN/Purpose (if applicable)

Example: "OPNSense P2 → Switch P1 (Trunk)"

## Cooling and Airflow

### Airflow Design
- Cold air intake from front
- Hot air exhaust from rear
- Hottest equipment at top
- Adequate spacing between devices

### Monitoring
- Check temperatures regularly
- Ensure fans are working
- Add cooling if needed (rack fans)

## Physical Security

- Rack in secure location
- Cable lock or rack door (if needed)
- Access control to room

## Maintenance Access

### Regular Maintenance
- Weekly: Visual inspection
- Monthly: Dust cleaning
- Quarterly: Cable management review
- Annually: Deep cleaning

### Emergency Access
- KVM connected to Pi for remote console access
- Tailscale VPN for remote management
- Physical access plan for power issues

## Future Expansion

### Available Rack Space
- Room for additional compute nodes
- Space for UPS
- Space for additional networking equipment

### Upgrade Path
- Additional UM890 nodes for worker pool
- Secondary OPNSense for HA
- Additional switch for more ports
- Dedicated storage expansion

## Documentation

For detailed rack mounting instructions, see:
- [rackmount-plan.md](rackmount-plan.md)

## References

- [Main Setup Plan](../README.md)
- [Network Configuration](../network/)
