# OpenWRT Access Point Configuration Checklist

## Pre-Configuration

- [ ] Document access point hardware details
  - [ ] Model: 2x Netgear RBK50
  - [ ] Firmware: Voxel firmware (OpenWRT-based)
  - [ ] MAC addresses (document for both APs)
  - [ ] Current firmware version
  - [ ] Physical locations (AP1 and AP2)
- [ ] Backup existing configuration (if any)
- [ ] Update Voxel firmware to latest stable version
- [ ] Assign static IP addresses in VLAN 1 (Management)
  - [ ] AP1: 10.0.1.21
  - [ ] AP2: 10.0.1.22
- [ ] Configure trunk ports on TRENDnet switch for AP connections (VLANs 1, 50, 99)

## Network Configuration

### VLAN Setup
- [ ] Configure VLAN 1 (Management) interface
  - [ ] AP1: Set static IP: 10.0.1.21
  - [ ] AP2: Set static IP: 10.0.1.22
  - [ ] Set gateway: 10.0.1.1
  - [ ] Set DNS: 10.0.20.2 (Unbound), 10.0.1.1 (OPNsense)
- [ ] Configure VLAN 50 (IoT/Surveillance) interface
  - [ ] AP1: Set static IP: 10.0.50.10
  - [ ] AP2: Set static IP: 10.0.50.11
  - [ ] Set gateway: 10.0.50.1
- [ ] Configure VLAN 99 (Guest-WiFi) interface
  - [ ] Protocol: None (bridge only)
  - [ ] No static IP needed on AP
- [ ] Configure switch settings for VLAN tagging
  - [ ] VLAN 1: Management (untagged)
  - [ ] VLAN 50: IoT/Surveillance (tagged)
  - [ ] VLAN 99: Guest-WiFi (tagged)
- [ ] Test VLAN connectivity
  - [ ] Ping OPNsense gateway (10.0.1.1) from Management VLAN
  - [ ] Ping Unbound DNS (10.0.20.2) from Management VLAN
  - [ ] Verify VLAN 50 interface is up
  - [ ] Verify VLAN 99 interface is up
  - [ ] Check routing tables: `ip route show`

## Wireless Configuration

### SSID 1 - YourHomeNetwork (VLAN 1 Management)
- [ ] Configure 2.4GHz interface
  - [ ] Set SSID: YourHomeNetwork
  - [ ] Map to VLAN 1 (lan interface)
  - [ ] Configure WPA3/WPA2-Personal (SAE-mixed) security
  - [ ] Set strong password
  - [ ] Select optimal channel (1, 6, or 11)
  - [ ] Set HT20 mode
- [ ] Configure 5GHz interface
  - [ ] Set SSID: YourHomeNetwork-5G (or same for unified naming)
  - [ ] Map to VLAN 1 (lan interface)
  - [ ] Configure WPA3/WPA2-Personal (SAE-mixed) security
  - [ ] Set same password as 2.4GHz
  - [ ] Select optimal channel (36-48 or 149-165)
  - [ ] Set VHT80 mode

### SSID 2 - Home-IoT (VLAN 50 IoT/Surveillance)
- [ ] Configure 2.4GHz interface
  - [ ] Set SSID: Home-IoT
  - [ ] Map to VLAN 50 (iot interface)
  - [ ] Configure WPA2-PSK security
  - [ ] Set strong password
  - [ ] Optional: Enable client isolation
  - [ ] Select optimal channel (match primary network)
- [ ] Configure 5GHz interface (optional)
  - [ ] Set SSID: Home-IoT
  - [ ] Map to VLAN 50 (iot interface)
  - [ ] Configure WPA2-PSK security
  - [ ] Set same password as 2.4GHz
  - [ ] Optional: Enable client isolation

### SSID 3 - Guest (VLAN 99 Guest-WiFi)
- [ ] Configure 2.4GHz interface
  - [ ] Set SSID: Guest
  - [ ] Map to VLAN 99 (guest interface)
  - [ ] Configure WPA2-PSK security
  - [ ] Set guest password
  - [ ] Enable client isolation (required)
  - [ ] Select optimal channel (match primary network)
- [ ] Configure 5GHz interface
  - [ ] Set SSID: Guest
  - [ ] Map to VLAN 99 (guest interface)
  - [ ] Configure WPA2-PSK security
  - [ ] Set same password as 2.4GHz
  - [ ] Enable client isolation (required)
  - [ ] Select optimal channel

## System Configuration

- [ ] Set hostname for each AP
  - [ ] AP1: openwrt-ap1 (or similar)
  - [ ] AP2: openwrt-ap2 (or similar)
- [ ] Configure timezone (your local timezone)
- [ ] Enable NTP time sync (point to OPNsense at 10.0.1.1)
- [ ] Configure SSH access
  - [ ] Change root password (strong, unique password)
  - [ ] Consider SSH key authentication for security
  - [ ] Restrict SSH to Management VLAN only
- [ ] Disable unnecessary services
- [ ] Configure logging
  - [ ] Set appropriate log level
  - [ ] Consider remote syslog to OPNsense (10.0.1.1)

## Mesh Configuration

- [ ] Configure mesh networking on VLAN 1 (Management)
  - [ ] Ensure both APs use same management VLAN
  - [ ] Verify mesh backhaul settings in Voxel firmware
  - [ ] Test roaming between APs
  - [ ] Ensure SSIDs are identical on both APs for seamless handoff

## Security Hardening

- [ ] Disable WPS on all interfaces (YourHomeNetwork, Home-IoT, Guest)
- [ ] Change default admin password (strong, unique)
- [ ] Restrict web UI access to Management VLAN (VLAN 1) only
- [ ] Disable unused wireless radios (if any)
- [ ] Review and minimize running services
- [ ] Set up firewall rules on AP (if needed)
- [ ] Verify WPA3 is enabled for primary network (SAE-mixed mode)
- [ ] Document all passwords in secure password manager

## Testing and Validation

### Connectivity Tests
- [ ] Test YourHomeNetwork SSID (both 2.4GHz and 5GHz)
  - [ ] Verify IP in 10.0.1.0/24 range
  - [ ] Gateway: 10.0.1.1
  - [ ] DNS: 10.0.20.2 or 10.0.1.1
  - [ ] Full network access
- [ ] Test Home-IoT SSID
  - [ ] Verify IP in 10.0.50.0/24 range
  - [ ] Gateway: 10.0.50.1
  - [ ] Internet access only (no local network access per firewall rules)
- [ ] Test Guest SSID (both 2.4GHz and 5GHz)
  - [ ] Verify IP in 10.0.99.0/24 range
  - [ ] Gateway: 10.0.99.1
  - [ ] Complete isolation (internet only)
- [ ] Verify DHCP from OPNsense working on all VLANs
- [ ] Test DNS resolution on each network: `nslookup google.com`
- [ ] Test internet connectivity on each network: `ping 8.8.8.8`
- [ ] Verify wireless roaming between AP1 and AP2

### Security Tests
- [ ] Verify client isolation on Home-IoT network (optional)
- [ ] Verify client isolation on Guest network (required)
  - [ ] Two guest devices cannot ping each other
- [ ] Test VLAN isolation
  - [ ] Guest cannot access 10.0.1.0/24 (Management)
  - [ ] Guest cannot access 10.0.50.0/24 (IoT)
  - [ ] IoT cannot access 10.0.1.0/24 (Management) per firewall rules
- [ ] Verify OPNsense firewall rules work as expected
- [ ] Test that guest network cannot access local resources
- [ ] Verify WPA3 devices can connect to YourHomeNetwork

### Performance Tests
- [ ] Run speed tests on each SSID
  - [ ] YourHomeNetwork: Full ISP speed expected
  - [ ] Home-IoT: Adequate for cameras/IoT
  - [ ] Guest: Internet access working
- [ ] Check for channel interference: `iwinfo` or WiFi analyzer app
- [ ] Test signal strength in various locations
- [ ] Verify no packet loss: `ping -c 100 10.0.1.1`
- [ ] Check for wireless dropouts
- [ ] Test mesh roaming performance

## Documentation

- [ ] Document final configuration settings
  - [ ] IP addresses (AP1: 10.0.1.21, 10.0.50.10; AP2: 10.0.1.22, 10.0.50.11)
  - [ ] SSID names (YourHomeNetwork, YourHomeNetwork-5G, Home-IoT, Guest)
  - [ ] Passwords (store in secure password manager)
  - [ ] Channel assignments (2.4GHz and 5GHz)
  - [ ] VLAN mappings (VLAN 1: Management, VLAN 50: IoT, VLAN 99: Guest)
- [ ] Create network diagram with AP physical locations
- [ ] Document any custom firewall rules on APs
- [ ] Note any troubleshooting steps taken during deployment
- [ ] Document mesh configuration settings

## Backup and Maintenance

- [ ] Create configuration backup for both APs
  - [ ] AP1: Download from web UI or CLI: `sysupgrade -b /tmp/backup-ap1.tar.gz`
  - [ ] AP2: Download from web UI or CLI: `sysupgrade -b /tmp/backup-ap2.tar.gz`
  - [ ] Save to secure location (network storage or offline)
  - [ ] Document backup date and firmware version
- [ ] Set up automatic backup schedule (weekly recommended)
- [ ] Document maintenance schedule
  - [ ] Voxel firmware update policy (check monthly)
  - [ ] Configuration review schedule (quarterly)
  - [ ] Security audit schedule (semi-annually)
  - [ ] Wireless channel optimization (as needed)

## Post-Deployment

- [ ] Monitor logs for errors: `logread` or via web UI
- [ ] Check client connection statistics on both APs
- [ ] Adjust channels if interference detected (use WiFi analyzer)
- [ ] Optimize transmit power levels (reduce if APs are close)
- [ ] Create operational runbook
  - [ ] How to access APs (10.0.1.21, 10.0.1.22)
  - [ ] How to restart network: `/etc/init.d/network restart`
  - [ ] How to restart wireless: `wifi reload`
  - [ ] Common troubleshooting steps
- [ ] Train users on network access
  - [ ] YourHomeNetwork: Primary home network (trusted devices)
  - [ ] Home-IoT: For smart home devices and cameras
  - [ ] Guest: For visitors (isolated, internet only)
- [ ] Verify integration with OPNsense firewall
- [ ] Verify integration with TRENDnet switch trunk ports
- [ ] Verify DNS resolution through Unbound (10.0.20.2)

## Notes and Issues
```
[Use this space to document any issues encountered, workarounds, or special configurations]




```
