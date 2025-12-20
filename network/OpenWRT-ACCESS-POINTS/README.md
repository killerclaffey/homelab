# OpenWRT Access Points Configuration

## Overview
This directory contains configuration documentation and guides for setting up OpenWRT access points in the homelab network.

## Access Points
- **Device**: 2x Netgear RBK50
- **Firmware**: Voxel firmware (OpenWRT-based)
- **Mode**: Mesh configuration
- **Role**: Wireless access points providing network connectivity across VLANs

### IP Addresses
**WiFi AP 1:**
- Management (VLAN 1): 10.0.1.21
- IoT/Surveillance (VLAN 50): 10.0.50.10

**WiFi AP 2:**
- Management (VLAN 1): 10.0.1.22
- IoT/Surveillance (VLAN 50): 10.0.50.11

## Configuration Tasks

### 1. VLAN Configuration
Configure the access points to support the following VLANs:
- **VLAN 1** - Management (10.0.1.0/24)
- **VLAN 50** - IoT/Surveillance (10.0.50.0/24)
- **VLAN 99** - Guest-WiFi (10.0.99.0/24)

### 2. Wireless SSIDs
Set up three wireless networks across dual bands:

#### SSID 1: YourHomeNetwork
- **VLAN**: 1 (Management)
- **Security**: WPA3/WPA2-Personal (SAE-mixed)
- **Band**: 2.4GHz + 5GHz
- **Purpose**: Primary home network for trusted devices

#### SSID 2: Home-IoT
- **VLAN**: 50 (IoT/Surveillance)
- **Security**: WPA2-Personal
- **Band**: 2.4GHz + 5GHz
- **Isolation**: Optional (enable for security)
- **Purpose**: Smart home devices and security cameras

#### SSID 3: Guest
- **VLAN**: 99 (Guest-WiFi)
- **Security**: WPA2-Personal
- **Band**: 2.4GHz + 5GHz
- **Isolation**: Enabled (required)
- **Purpose**: Guest access with complete network isolation

## Network Integration
- **Gateway**: 10.0.1.1 (OPNsense firewall)
- **DNS**: 10.0.20.2 (Unbound), 10.0.1.1 (OPNsense fallback)
- **Switch Connection**: Trunk ports carrying VLANs 1, 50, 99
- **Mesh**: Configured on VLAN 1 (Management) for seamless roaming

## TODO
- [ ] Document AP MAC addresses
- [ ] Verify trunk ports configured on TRENDnet switch for AP connections
- [ ] Configure VLAN interfaces in OpenWRT (VLANs 1, 50, 99)
- [ ] Configure wireless SSIDs and map to correct VLANs
- [ ] Configure mesh networking between both APs
- [ ] Test connectivity and VLAN isolation
- [ ] Document final configuration settings
- [ ] Create backup of AP configurations

## References
- [OpenWRT VLAN Documentation](https://openwrt.org/docs/guide-user/network/vlan/switch_configuration)
- [OpenWRT Wireless Configuration](https://openwrt.org/docs/guide-user/network/wifi/basic)
- [Voxel Firmware Info](https://www.voxel-firmware.com/) - OpenWRT-based firmware for Netgear devices
- See [../VLANs/](../VLANs/) for complete VLAN design and addressing
- See [../../README.md](../../README.md) Phase 4 for detailed setup instructions
