# OpenWRT VLAN Configuration Guide

## Network Setup Overview

This guide covers configuring VLANs on OpenWRT access points to work with the OPNsense firewall and managed switch infrastructure.

## Prerequisites
- OpenWRT installed on access points
- Access points connected to trunk ports on the switch
- VLANs configured on OPNsense and switch (VLANs 10, 20, 30, 40)

## VLAN Configuration Steps

### 1. Access the OpenWRT Interface
```bash
# Via SSH
ssh root@[AP-IP-ADDRESS]

# Or via web interface
http://[AP-IP-ADDRESS]
```

### 2. Configure Network Interfaces

Edit `/etc/config/network`:

```
config interface 'lan'
    option type 'bridge'
    option ifname 'eth0'
    option proto 'static'
    option ipaddr '10.10.0.X'  # Management IP in VLAN 10
    option netmask '255.255.255.0'
    option gateway '10.10.0.1'
    option dns '10.10.0.1'

# VLAN 10 - Management
config interface 'mgmt'
    option ifname 'eth0.10'
    option proto 'static'
    option ipaddr '10.10.0.X'
    option netmask '255.255.255.0'

# VLAN 20 - Trusted
config interface 'trusted'
    option ifname 'eth0.20'
    option proto 'none'

# VLAN 30 - IoT
config interface 'iot'
    option ifname 'eth0.30'
    option proto 'none'

# VLAN 40 - Guest
config interface 'guest'
    option ifname 'eth0.40'
    option proto 'none'
```

### 3. Configure Switch Settings

Edit the switch configuration in `/etc/config/network`:

```
config switch
    option name 'switch0'
    option ports '0 1 2 3 6'
    option blinkrate '2'

config switch_vlan
    option device 'switch0'
    option vlan '1'
    option ports '0t 1 2 3 6t'

config switch_vlan
    option device 'switch0'
    option vlan '10'
    option ports '0t 6t'

config switch_vlan
    option device 'switch0'
    option vlan '20'
    option ports '0t 6t'

config switch_vlan
    option device 'switch0'
    option vlan '30'
    option ports '0t 6t'

config switch_vlan
    option device 'switch0'
    option vlan '40'
    option ports '0t 6t'
```

**Note**: Port numbers vary by device. Check your specific OpenWRT device documentation.

### 4. Apply Configuration

```bash
/etc/init.d/network restart
```

## Verification

### Check VLAN Interfaces
```bash
ip link show
```

You should see interfaces like `eth0.10`, `eth0.20`, `eth0.30`, `eth0.40`

### Test Connectivity
```bash
# Ping the gateway
ping 10.10.0.1

# Check routing
ip route show
```

## Troubleshooting

### VLANs Not Working
1. Verify switch port is configured as trunk
2. Check VLAN IDs match across all devices
3. Ensure physical connection is good
4. Review firewall rules on OPNsense

### Cannot Access AP After Configuration
1. Connect directly to AP via LAN cable
2. Factory reset if necessary
3. Reconfigure from scratch

## Next Steps
After VLAN configuration is complete:
1. Proceed to [Wireless_Configuration.md](Wireless_Configuration.md)
2. Map SSIDs to VLANs
3. Test wireless connectivity on each VLAN
