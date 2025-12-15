# VLAN Documentation

This folder contains VLAN implementation guides and reference documentation.

## Files

- [VLAN_IMPLEMENTATION_CHECKLIST.md](VLAN_IMPLEMENTATION_CHECKLIST.md) - Step-by-step checklist for implementing my VLAN architecture

## My VLAN Architecture

I've designed my homelab with 8 VLANs to segment traffic and improve security:

### VLAN Design Table

| VLAN | Name | Subnet | Gateway | Purpose | DHCP |
|------|------|---------|---------|---------|------|
| 1 | Management | 10.0.1.0/24 | 10.0.1.1 | Infrastructure, workstations, living room | Yes |
| 20 | OKD-Infra | 10.0.20.0/24 | 10.0.20.1 | OKD cluster nodes | No (static) |
| 30 | OKD-Storage | 10.0.30.0/24 | 10.0.30.1 | Storage backend (isolated) | No (static) |
| 40 | Services | 10.0.40.0/24 | 10.0.40.1 | Published OKD services | No (VIP only) |
| 50 | IoT/Surveillance | 10.0.50.0/24 | 10.0.50.1 | IoT devices and cameras | Yes |
| 60 | Game Consoles | 10.0.60.0/24 | 10.0.60.1 | Gaming devices (uPNP) | Yes |
| 70 | Helium Hotspot | 10.0.70.0/24 | 10.0.70.1 | Helium miner (isolated) | Yes |
| 99 | Guest-WiFi | 10.0.99.0/24 | 10.0.99.1 | Guest network (isolated) | Yes |

### VLAN Purposes

**VLAN 1 - Management**
- My workstation
- Switch management interface
- TrueNAS management interface
- WiFi AP management
- Raspberry Pi + KVM
- Living room devices (TV, etc.)

**VLAN 20 - OKD Infrastructure**
- 3x Minisforum UM890 cluster nodes
- Bootstrap node (temporary)
- TrueNAS helper services (DNS, HTTP)
- HAProxy VIPs for API and apps

**VLAN 30 - Storage Backend**
- TrueNAS storage interface
- Cluster nodes storage NICs
- NFS/iSCSI traffic only
- Highly isolated for security

**VLAN 40 - Services**
- HAProxy VIP for published OKD services
- Accessible from Management VLAN
- No actual hosts on this VLAN

**VLAN 50 - IoT/Surveillance**
- IoT devices (smart home, etc.)
- Security cameras
- WiFi SSID: "Home-IoT"
- Internet access only (no infrastructure access)

**VLAN 60 - Game Consoles**
- Gaming consoles (PS5, Xbox, etc.)
- uPNP enabled for automatic port forwarding
- Internet access only (isolated from infrastructure)

**VLAN 70 - Helium Hotspot**
- Helium miner
- Direct connection to OPNSense
- Completely isolated
- Internet access only

**VLAN 99 - Guest WiFi**
- Guest devices
- WiFi SSID: "Guest"
- Client isolation enabled
- Internet access only

## Security Model

### Isolation Levels

**Trusted VLANs** (full infrastructure access):
- VLAN 1 (Management)
- VLAN 20 (OKD-Infra)

**Backend VLANs** (restricted):
- VLAN 30 (Storage) - only accessible from VLAN 20

**Service VLANs** (published services):
- VLAN 40 (Services) - accessible from VLAN 1

**Isolated VLANs** (internet only):
- VLAN 50 (IoT/Surveillance)
- VLAN 60 (Game Consoles)
- VLAN 70 (Helium)
- VLAN 99 (Guest)

### Firewall Rules Summary

My firewall rules enforce the following:

- **Management (1)**: Can access everything
- **OKD-Infra (20)**: Can access storage (30) and internet
- **Storage (30)**: Only accepts connections from OKD-Infra (20)
- **Services (40)**: Accessible from Management (1)
- **IoT (50)**: Internet only, blocked from RFC1918
- **Game Consoles (60)**: Internet only, blocked from RFC1918, uPNP enabled
- **Helium (70)**: Internet only, blocked from RFC1918
- **Guest (99)**: Internet only, blocked from RFC1918

## Implementation Guide

Follow the [VLAN Implementation Checklist](VLAN_IMPLEMENTATION_CHECKLIST.md) for step-by-step instructions.

### Quick Implementation Steps

1. **Plan**: Review VLAN design (this document)
2. **OPNSense**: Configure VLAN interfaces and DHCP
3. **Switch**: Configure trunk and access ports
4. **TrueNAS**: Configure VLAN interfaces
5. **WiFi APs**: Configure SSIDs for VLANs 1, 50, 99
6. **Firewall**: Set up per-VLAN rules
7. **Test**: Verify connectivity and isolation

## Testing Checklist

After implementation, I verify:

- [ ] Devices get correct IPs on each VLAN
- [ ] DNS resolution works from all VLANs
- [ ] Internet access works from all VLANs
- [ ] Isolated VLANs cannot access infrastructure
- [ ] Management VLAN can access all services
- [ ] Storage VLAN is isolated except from OKD-Infra
- [ ] uPNP works on Game Consoles VLAN
- [ ] Guest WiFi is completely isolated

## References

- [Main Setup Plan](../../README.md)
- [OPNSense VLAN Configuration](../OPNsense-FIREWALL/OPNSense_VLAN_Configuration_Details.md)
- [Switch Configuration](../TRENDnet-SWITCH/TRENDnet_TEG3102WS_Switch_Configuration.md)
