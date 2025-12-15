# TRENDnet Switch Configuration

This folder contains configuration documentation for my TRENDnet TEG-3102WS 10-port multi-gigabit switch.

## Configuration Files

- [TRENDnet_TEG3102WS_Switch_Configuration.md](TRENDnet_TEG3102WS_Switch_Configuration.md) - Complete step-by-step switch configuration

## My Switch Setup Overview

### Hardware
- **Model**: TRENDnet TEG-3102WS
- **Ports**: 8x 2.5G + 2x 10G
- **Management IP**: 10.0.1.2/24 (VLAN 1)

### Port Configuration

| Port | Speed | Device | Mode | VLANs | PVID |
|------|-------|--------|------|-------|------|
| 1 | 2.5G | OPNSense | Trunk | 1,20,30,40,50,60,99 | 1 |
| 2-8 | 2.5G | Available | Access | - | 1 |
| 9 | 10G | TrueNAS | Trunk | 1,20,30,40 | 1 |
| 10 | 10G | Desktop | Access | - | 1 |

### VLAN Configuration

My switch handles 7 VLANs:
- **VLAN 1** (Management) - All ports
- **VLAN 20** (OKD-Infra) - Ports 1, 9 (tagged)
- **VLAN 30** (OKD-Storage) - Ports 1, 9 (tagged)
- **VLAN 40** (Services) - Ports 1, 9 (tagged)
- **VLAN 50** (IoT/Surveillance) - Port 1 (tagged)
- **VLAN 60** (Game Consoles) - Port 1 (tagged)
- **VLAN 99** (Guest-WiFi) - Port 1 (tagged)

### Trunk Ports

**Port 1 (OPNSense Trunk)**
- Carries all VLANs to/from firewall
- Tagged: 1, 20, 30, 40, 50, 60, 99
- PVID: 1

**Port 9 (TrueNAS Trunk)**
- Carries VLANs needed by TrueNAS
- Tagged: 1, 20, 30, 40
- PVID: 1

### Access Ports

**Ports 2-8, 10**
- Untagged access ports on VLAN 1 (Management)
- For desktop, WiFi APs, or other management devices
- Can be reconfigured for specific VLANs if needed

## Configuration Steps

1. **Initial Access**: Connect to default IP (usually 192.168.0.1)
2. **Set Management IP**: Configure 10.0.1.2/24 on VLAN 1
3. **Create VLANs**: Add all required VLANs (1, 20, 30, 40, 50, 60, 99)
4. **Configure Trunk Ports**: Set Port 1 and Port 9 as trunks with tagged VLANs
5. **Configure Access Ports**: Set remaining ports as access ports
6. **Test Connectivity**: Verify VLAN tagging is working

## Important Notes

- **WiFi APs**: Connect to access ports (2-8). APs handle VLAN tagging internally via OpenWRT.
- **Game Consoles**: Can dedicate a port by setting PVID to 60 if needed.
- **Link Aggregation**: Not currently used, but supported if I need more bandwidth.
- **Jumbo Frames**: Supported up to 9KB if needed for storage traffic.

## Troubleshooting

### Common Issues
- **No connectivity on VLAN**: Check PVID matches expected VLAN
- **Trunk not passing traffic**: Verify VLAN is in tagged list for trunk port
- **Management access lost**: Connect to default IP or reset switch

### Useful Commands/Checks
- Check VLAN membership for each port
- Verify tagged vs untagged configuration
- Check port link status and speed
- Review MAC address table to see which devices are on which ports

## References

- [Main Setup Plan](../../README.md)
- [OPNSense Configuration](../OPNsense-FIREWALL/)
- [VLAN Implementation Checklist](../VLANs/VLAN_IMPLEMENTATION_CHECKLIST.md)
