# OpenWRT VLAN Configuration Guide

## Network Setup Overview

This guide covers configuring VLANs on Netgear RBK50 access points running Voxel firmware (OpenWRT-based) to work with the OPNsense firewall and TRENDnet managed switch infrastructure.

## Prerequisites
- Voxel firmware installed on both Netgear RBK50 access points
- Access points connected to trunk ports on TRENDnet switch
- VLANs configured on OPNsense and switch (VLANs 1, 50, 99)
- Physical access to APs for initial configuration

## Network Architecture
- **VLAN 1** (Management): 10.0.1.0/24 - Infrastructure and primary home network
- **VLAN 50** (IoT/Surveillance): 10.0.50.0/24 - IoT devices and cameras
- **VLAN 99** (Guest-WiFi): 10.0.99.0/24 - Isolated guest access
- **Gateway**: 10.0.1.1 (OPNsense)
- **DNS**: 10.0.20.2 (Unbound), 10.0.1.1 (OPNsense)

## VLAN Configuration Steps

### 1. Access the OpenWRT Interface
```bash
# Via SSH (after initial setup)
ssh root@10.0.1.21  # For AP1
ssh root@10.0.1.22  # For AP2

# Or via web interface (initial access may use 192.168.1.1)
http://10.0.1.21  # For AP1
http://10.0.1.22  # For AP2
```

### 2. Configure Network Interfaces

Edit `/etc/config/network`:

**For AP1 (10.0.1.21):**
```
config interface 'lan'
    option type 'bridge'
    option ifname 'eth0'
    option proto 'static'
    option ipaddr '10.0.1.21'
    option netmask '255.255.255.0'
    option gateway '10.0.1.1'
    option dns '10.0.20.2 10.0.1.1'

# VLAN 1 - Management (default/untagged)
# This is the primary LAN interface above

# VLAN 50 - IoT/Surveillance
config interface 'iot'
    option ifname 'eth0.50'
    option proto 'static'
    option ipaddr '10.0.50.10'
    option netmask '255.255.255.0'
    option gateway '10.0.50.1'

# VLAN 99 - Guest-WiFi
config interface 'guest'
    option ifname 'eth0.99'
    option proto 'none'  # Bridged only, no IP needed on AP
```

**For AP2 (10.0.1.22):**
```
config interface 'lan'
    option type 'bridge'
    option ifname 'eth0'
    option proto 'static'
    option ipaddr '10.0.1.22'
    option netmask '255.255.255.0'
    option gateway '10.0.1.1'
    option dns '10.0.20.2 10.0.1.1'

# VLAN 50 - IoT/Surveillance
config interface 'iot'
    option ifname 'eth0.50'
    option proto 'static'
    option ipaddr '10.0.50.11'
    option netmask '255.255.255.0'
    option gateway '10.0.50.1'

# VLAN 99 - Guest-WiFi
config interface 'guest'
    option ifname 'eth0.99'
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
    option ports '0t 1 2 3 6t'  # Management VLAN (untagged on LAN ports)

config switch_vlan
    option device 'switch0'
    option vlan '50'
    option ports '0t 6t'  # IoT/Surveillance (tagged)

config switch_vlan
    option device 'switch0'
    option vlan '99'
    option ports '0t 6t'  # Guest-WiFi (tagged)
```

**Note**: Port configuration varies by device model. For Netgear RBK50:
- Port 0: WAN (uplink to TRENDnet switch - trunk port)
- Port 6: CPU port (internal)
- 't' suffix indicates tagged/trunk port

Consult your specific device documentation or use `swconfig list` to verify switch configuration.

### 4. Apply Configuration

```bash
/etc/init.d/network restart
```

### 5. Configure Mesh (Optional but Recommended)

For mesh configuration between both APs on VLAN 1 (Management):

```bash
# This is typically configured via the web UI under Wireless → Mesh
# Ensure mesh backhaul uses the Management VLAN for best performance
```

## Verification

### Check VLAN Interfaces
```bash
ip link show
```

You should see interfaces like:
- `eth0` (base interface)
- `eth0.50` (IoT/Surveillance)
- `eth0.99` (Guest-WiFi)

### Test Connectivity
```bash
# Ping the OPNsense gateway
ping 10.0.1.1

# Test DNS resolution
ping 10.0.20.2  # Unbound DNS server

# Check routing
ip route show

# Verify VLAN interfaces are up
ip addr show eth0.50
ip addr show eth0.99
```

### Verify Switch Configuration
```bash
# Check switch VLAN configuration
swconfig dev switch0 show

# List network interfaces
uci show network
```

## Troubleshooting

### VLANs Not Working
1. **Verify trunk port on TRENDnet switch** - Ensure APs are connected to trunk ports carrying VLANs 1, 50, 99
2. **Check VLAN IDs match** - Verify VLAN IDs are identical across OPNsense, switch, and APs
3. **Physical connection** - Ensure Ethernet cable is properly connected and link light is on
4. **Review OPNsense firewall rules** - Check that VLAN interfaces exist and have proper firewall rules
5. **Check interface status**: `ifconfig` or `ip link show`

### Cannot Access AP After Configuration
1. Connect directly to AP via LAN cable on a LAN port (not WAN)
2. Try accessing via original IP (192.168.1.1) or new IP (10.0.1.21/22)
3. If locked out, factory reset:
   - Hold reset button for 10+ seconds
   - Reconfigure from scratch using this guide
4. Use serial console if available

### Mesh Not Working
1. Ensure both APs are on the same management VLAN (VLAN 1)
2. Check mesh configuration in wireless settings
3. Verify signal strength between APs is adequate
4. Review Voxel firmware mesh documentation

### DNS Not Resolving
1. Check DNS settings: `cat /etc/resolv.conf`
2. Verify DNS servers are reachable: `ping 10.0.20.2`
3. Test DNS manually: `nslookup google.com 10.0.20.2`
4. Check OPNsense Unbound service status

## Next Steps
After VLAN configuration is complete:
1. Proceed to [Wireless_Configuration.md](Wireless_Configuration.md)
2. Map SSIDs to VLANs (YourHomeNetwork → VLAN 1, Home-IoT → VLAN 50, Guest → VLAN 99)
3. Test wireless connectivity on each VLAN
4. Verify VLAN isolation between networks
