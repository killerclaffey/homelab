# OpenWRT Access Point Configuration Checklist

## Pre-Configuration

- [ ] Document access point hardware details
  - [ ] Model number(s)
  - [ ] MAC addresses
  - [ ] Current firmware version
  - [ ] Physical locations
- [ ] Backup existing configuration
- [ ] Update OpenWRT to latest stable version
- [ ] Assign static IP addresses in VLAN 10 (Management)
- [ ] Configure trunk ports on TRENDnet switch for AP connections

## Network Configuration

### VLAN Setup
- [ ] Configure VLAN 10 (Management) interface
  - [ ] Set static IP: 10.10.0.X
  - [ ] Set gateway: 10.10.0.1
  - [ ] Set DNS: 10.10.0.1
- [ ] Configure VLAN 20 (Trusted) interface
- [ ] Configure VLAN 30 (IoT) interface
- [ ] Configure VLAN 40 (Guest) interface
- [ ] Configure switch settings for VLAN tagging
- [ ] Test VLAN connectivity
  - [ ] Ping gateway from each VLAN
  - [ ] Verify routing tables

## Wireless Configuration

### SSID 1 - Primary/Trusted (VLAN 20)
- [ ] Configure 2.4GHz interface
  - [ ] Set SSID name
  - [ ] Map to VLAN 20
  - [ ] Configure WPA3/WPA2 security
  - [ ] Set strong password
  - [ ] Select optimal channel
- [ ] Configure 5GHz interface
  - [ ] Same SSID as 2.4GHz
  - [ ] Map to VLAN 20
  - [ ] Configure WPA3/WPA2 security
  - [ ] Set same password as 2.4GHz
  - [ ] Select optimal channel

### SSID 2 - IoT (VLAN 30)
- [ ] Configure 2.4GHz interface
  - [ ] Set SSID name
  - [ ] Map to VLAN 30
  - [ ] Configure WPA2 security
  - [ ] Set strong password
  - [ ] Enable client isolation
  - [ ] Select optimal channel

### SSID 3 - Guest (VLAN 40)
- [ ] Configure 2.4GHz interface
  - [ ] Set SSID name
  - [ ] Map to VLAN 40
  - [ ] Configure WPA2 security
  - [ ] Set guest password
  - [ ] Enable client isolation
  - [ ] Select optimal channel
- [ ] Configure 5GHz interface
  - [ ] Same SSID as 2.4GHz
  - [ ] Map to VLAN 40
  - [ ] Configure WPA2 security
  - [ ] Set same password as 2.4GHz
  - [ ] Enable client isolation
  - [ ] Select optimal channel

## System Configuration

- [ ] Set hostname for each AP
- [ ] Configure timezone
- [ ] Enable NTP time sync (point to OPNsense)
- [ ] Configure SSH access
  - [ ] Change root password
  - [ ] Consider SSH key authentication
- [ ] Disable unnecessary services
- [ ] Configure logging
  - [ ] Set log level
  - [ ] Consider remote syslog to OPNsense

## Security Hardening

- [ ] Disable WPS on all interfaces
- [ ] Change default admin password
- [ ] Restrict web UI access to management VLAN only
- [ ] Disable unused wireless radios (if any)
- [ ] Review and minimize running services
- [ ] Set up firewall rules on AP (if needed)

## Testing and Validation

### Connectivity Tests
- [ ] Test each SSID with multiple devices
- [ ] Verify correct IP assignment (DHCP from OPNsense)
- [ ] Verify gateway connectivity for each VLAN
- [ ] Test DNS resolution on each network
- [ ] Test internet connectivity on each network
- [ ] Verify wireless roaming between APs (if multiple)

### Security Tests
- [ ] Verify client isolation on IoT network
- [ ] Verify client isolation on Guest network
- [ ] Test VLAN isolation (no cross-VLAN access where restricted)
- [ ] Verify firewall rules work as expected
- [ ] Test that guest network cannot access local resources

### Performance Tests
- [ ] Run speed tests on each SSID
- [ ] Check for channel interference
- [ ] Test signal strength in various locations
- [ ] Verify no packet loss
- [ ] Check for wireless dropouts

## Documentation

- [ ] Document final configuration settings
  - [ ] IP addresses
  - [ ] SSID names and passwords
  - [ ] Channel assignments
  - [ ] VLAN mappings
- [ ] Create network diagram with AP locations
- [ ] Document any custom firewall rules
- [ ] Note any troubleshooting steps taken

## Backup and Maintenance

- [ ] Create configuration backup
  - [ ] Download from web UI
  - [ ] Save to secure location
  - [ ] Document backup date
- [ ] Set up automatic backup schedule
- [ ] Document maintenance schedule
  - [ ] Firmware update policy
  - [ ] Configuration review schedule
  - [ ] Security audit schedule

## Post-Deployment

- [ ] Monitor logs for errors
- [ ] Check client connection statistics
- [ ] Adjust channels if interference detected
- [ ] Optimize transmit power levels
- [ ] Create operational runbook
- [ ] Train users on network access

## Notes and Issues
```
[Use this space to document any issues encountered, workarounds, or special configurations]




```
