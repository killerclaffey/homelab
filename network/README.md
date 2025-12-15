# Network Configuration Documentation

This folder contains all network configuration documentation for my homelab.

## Folder Contents

### [OPNsense-FIREWALL/](OPNsense-FIREWALL/)
Configuration documentation for my Protectli VP2430 running OPNSense:
- VLAN interface configuration
- KEA DHCP server setup
- Unbound DNS configuration
- Virtual IP (VIP) configuration for HAProxy
- Static IP troubleshooting guides

### [TRENDnet-SWITCH/](TRENDnet-SWITCH/)
Configuration documentation for my TRENDnet TEG-3102WS 10-port multi-gig switch:
- VLAN trunk port configuration
- Access port configuration
- Port assignments and PVID settings

### [VLANs/](VLANs/)
VLAN implementation guides and checklists:
- Step-by-step VLAN implementation checklist
- VLAN design documentation
- Cross-VLAN access rules

## Network Architecture Overview

My homelab uses a fully segmented VLAN architecture with 8 VLANs:

| VLAN | Name | Subnet | Purpose |
|------|------|---------|---------|
| 1 | Management | 10.0.1.0/24 | Infrastructure and workstations |
| 20 | OKD-Infra | 10.0.20.0/24 | OKD cluster nodes |
| 30 | OKD-Storage | 10.0.30.0/24 | Storage backend (isolated) |
| 40 | Services | 10.0.40.0/24 | Published OKD services |
| 50 | IoT/Surveillance | 10.0.50.0/24 | IoT devices and cameras |
| 60 | Game Consoles | 10.0.60.0/24 | Gaming devices (uPNP enabled) |
| 70 | Helium Hotspot | 10.0.70.0/24 | Helium miner (isolated) |
| 99 | Guest-WiFi | 10.0.99.0/24 | Guest network (isolated) |

## Quick Start

1. Start with the [VLAN Implementation Checklist](VLANs/VLAN_IMPLEMENTATION_CHECKLIST.md)
2. Configure OPNSense using guides in [OPNsense-FIREWALL/](OPNsense-FIREWALL/)
3. Configure the switch using [TRENDnet-SWITCH/](TRENDnet-SWITCH/)

## Key Services

- **DHCP**: KEA DHCP v4 on OPNSense
- **DNS**: Unbound on OPNSense → Bind9 on TrueNAS
- **Load Balancing**: HAProxy on OPNSense
- **Firewall**: OPNSense with per-VLAN rules

## References

- [Main Setup Plan](../README.md)
- [Physical Infrastructure](../physical/)
