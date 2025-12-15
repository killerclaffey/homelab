# OpenWRT Access Points Configuration

## Overview
This directory contains configuration documentation and guides for setting up OpenWRT access points in the homelab network.

## Access Points
- **Device**: [List your AP models here]
- **Role**: Wireless access points providing network connectivity across VLANs
- **Firmware**: OpenWRT

## Configuration Tasks

### 1. VLAN Configuration
Configure the access points to support the following VLANs:
- **VLAN 10** - Management
- **VLAN 20** - Trusted
- **VLAN 30** - IoT
- **VLAN 40** - Guest

### 2. Wireless SSIDs
Set up three wireless networks:

#### SSID 1: [Primary Network Name]
- **VLAN**: 20 (Trusted)
- **Security**: WPA3/WPA2
- **Band**: 2.4GHz + 5GHz

#### SSID 2: [IoT Network Name]
- **VLAN**: 30 (IoT)
- **Security**: WPA2
- **Band**: 2.4GHz (for device compatibility)

#### SSID 3: [Guest Network Name]
- **VLAN**: 40 (Guest)
- **Security**: WPA2
- **Band**: 2.4GHz + 5GHz
- **Isolation**: Enabled

## TODO
- [ ] Document current AP hardware models and MAC addresses
- [ ] Configure trunk ports on switch for AP connections
- [ ] Set up VLAN interfaces in OpenWRT
- [ ] Configure wireless networks and map to VLANs
- [ ] Test connectivity and VLAN isolation
- [ ] Document final configuration settings
- [ ] Create backup of AP configurations

## References
- [OpenWRT VLAN Documentation](https://openwrt.org/docs/guide-user/network/vlan/switch_configuration)
- [OpenWRT Wireless Configuration](https://openwrt.org/docs/guide-user/network/wifi/basic)
- See [../VLANs/](../VLANs/) for VLAN design and addressing
