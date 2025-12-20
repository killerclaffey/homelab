# OpenWRT Wireless Configuration Guide

## Overview
Configure three SSIDs on Netgear RBK50 access points (Voxel firmware), each mapped to a different VLAN. Both APs should broadcast the same SSIDs for seamless mesh roaming.

## SSID to VLAN Mapping

| SSID Name | VLAN | Network | Band | Security | Purpose |
|-----------|------|---------|------|----------|---------|
| YourHomeNetwork | 1 | Management | 2.4GHz | WPA3/WPA2 | Primary home network |
| YourHomeNetwork-5G | 1 | Management | 5GHz | WPA3/WPA2 | Primary home network (5GHz) |
| Home-IoT | 50 | IoT/Surveillance | 2.4 + 5GHz | WPA2 | IoT devices and cameras |
| Guest | 99 | Guest-WiFi | 2.4 + 5GHz | WPA2 | Isolated guest access |

**Note**: You can use unified SSID naming (same name for 2.4 + 5GHz) or separate them as shown above. Unified naming enables band steering if supported.

## Configuration Steps

### 1. Access OpenWRT Web Interface
Navigate to `http://10.0.1.21` (AP1) or `http://10.0.1.22` (AP2)
Go to `Network > Wireless`

### 2. Configure SSID 1 - YourHomeNetwork (Management VLAN 1)

#### Create 2.4GHz Interface
1. Click **Add** on the 2.4GHz radio (radio0)
2. Configure:
   - **ESSID**: `YourHomeNetwork`
   - **Mode**: Access Point
   - **Network**: Select `lan` (VLAN 1 Management)

3. **Wireless Security** tab:
   - **Encryption**: WPA3-SAE mixed mode (WPA2/WPA3-Personal)
   - **Cipher**: Force CCMP (AES)
   - **Key**: `[PASSWORD]`

4. **Advanced Settings**:
   - **Country Code**: US
   - **Channel**: 1, 6, or 11 (non-overlapping)
   - **Width**: HT20 (20MHz for compatibility)

#### Create 5GHz Interface
1. Click **Add** on the 5GHz radio (radio1)
2. Configure:
   - **ESSID**: `YourHomeNetwork-5G` (or same as 2.4GHz for unified naming)
   - **Mode**: Access Point
   - **Network**: Select `lan` (VLAN 1 Management)

3. **Wireless Security** tab:
   - **Encryption**: WPA3-SAE mixed mode
   - **Cipher**: Force CCMP (AES)
   - **Key**: `[PASSWORD]` (same as 2.4GHz)

4. **Advanced Settings**:
   - **Country Code**: US
   - **Channel**: 36-48 or 149-165 (non-DFS preferred)
   - **Width**: VHT80 (80MHz for performance)

### 3. Configure SSID 2 - Home-IoT (VLAN 50)

#### Create 2.4GHz Interface
1. Click **Add** on the 2.4GHz radio
2. Configure:
   - **ESSID**: `Home-IoT`
   - **Mode**: Access Point
   - **Network**: Select `iot` (VLAN 50)

3. **Wireless Security** tab:
   - **Encryption**: WPA2-PSK (many IoT devices don't support WPA3)
   - **Cipher**: Force CCMP (AES)
   - **Key**: `[PASSWORD]`

4. **Advanced Settings**:
   - **Isolate Clients**: Optional (enable if you don't need IoT devices to communicate with each other)
   - **Channel**: Same as primary network (1, 6, or 11)

#### Create 5GHz Interface (Optional)
Repeat above for 5GHz radio if you have IoT devices that support 5GHz

### 4. Configure SSID 3 - Guest (VLAN 99)

#### Create 2.4GHz Interface
1. Click **Add** on the 2.4GHz radio
2. Configure:
   - **ESSID**: `Guest`
   - **Mode**: Access Point
   - **Network**: Select `guest` (VLAN 99)

3. **Wireless Security** tab:
   - **Encryption**: WPA2-PSK
   - **Cipher**: Force CCMP (AES)
   - **Key**: `[PASSWORD]`

4. **Advanced Settings**:
   - **Isolate Clients**: Enable (required - prevents guest-to-guest communication)
   - **Channel**: Same as primary network

#### Create 5GHz Interface
1. Click **Add** on the 5GHz radio
2. Same configuration as 2.4GHz above
3. Ensure **Isolate Clients** is enabled

## Complete Wireless Configuration File

Edit `/etc/config/wireless` (or configure via web UI as described above):

```
# 2.4GHz Radio Configuration
config wifi-device 'radio0'
    option type 'mac80211'
    option channel '6'
    option hwmode '11g'
    option path 'platform/qca953x_wmac'
    option htmode 'HT20'
    option country 'US'
    option disabled '0'

# Primary Home Network - 2.4GHz
config wifi-iface 'home_2g'
    option device 'radio0'
    option network 'lan'
    option mode 'ap'
    option ssid 'YourHomeNetwork'
    option encryption 'sae-mixed'
    option key '[PASSWORD]'

# IoT Network - 2.4GHz
config wifi-iface 'iot_2g'
    option device 'radio0'
    option network 'iot'
    option mode 'ap'
    option ssid 'Home-IoT'
    option encryption 'psk2+ccmp'
    option key '[PASSWORD]'
    # option isolate '1'  # Uncomment if you want to isolate IoT devices

# Guest Network - 2.4GHz
config wifi-iface 'guest_2g'
    option device 'radio0'
    option network 'guest'
    option mode 'ap'
    option ssid 'Guest'
    option encryption 'psk2+ccmp'
    option key '[PASSWORD]'
    option isolate '1'  # Required for guest isolation

# 5GHz Radio Configuration
config wifi-device 'radio1'
    option type 'mac80211'
    option channel '149'
    option hwmode '11a'
    option path 'pci0000:00/0000:00:00.0'
    option htmode 'VHT80'
    option country 'US'
    option disabled '0'

# Primary Home Network - 5GHz
config wifi-iface 'home_5g'
    option device 'radio1'
    option network 'lan'
    option mode 'ap'
    option ssid 'YourHomeNetwork-5G'
    option encryption 'sae-mixed'
    option key '[PASSWORD]'

# IoT Network - 5GHz (optional)
config wifi-iface 'iot_5g'
    option device 'radio1'
    option network 'iot'
    option mode 'ap'
    option ssid 'Home-IoT'
    option encryption 'psk2+ccmp'
    option key '[PASSWORD]'
    # option isolate '1'

# Guest Network - 5GHz
config wifi-iface 'guest_5g'
    option device 'radio1'
    option network 'guest'
    option mode 'ap'
    option ssid 'Guest'
    option encryption 'psk2+ccmp'
    option key '[PASSWORD]'
    option isolate '1'
```

**Note**: Replace `[PASSWORD]` with your actual passwords. Use different passwords for each network for better security.

## Apply Changes

```bash
wifi reload
# or
/etc/init.d/network restart
```

## Optimization Recommendations

### 2.4GHz Band
- Use channels 1, 6, or 11 (non-overlapping)
- HT20 (20MHz width) for better compatibility
- Lower power if APs are close together

### 5GHz Band
- Use DFS channels for less interference (if supported)
- VHT80 (80MHz width) for better performance
- Higher channels (149-165) often have less interference

### Security Best Practices
- Use WPA3 where possible (Trusted network)
- Use strong, unique passwords for each SSID
- Enable client isolation on IoT and Guest networks
- Disable WPS
- Hide SSID only if really needed (not a strong security measure)

## Testing

### Verify SSID Broadcast
```bash
# From a client device (Linux/Mac)
iwlist scan | grep ESSID

# Or from Windows
netsh wlan show networks

# From the AP itself
iwinfo
```

You should see:
- `YourHomeNetwork` (2.4GHz)
- `YourHomeNetwork-5G` (5GHz)
- `Home-IoT` (both bands)
- `Guest` (both bands)

### Check Connected Clients
```bash
# On the AP via SSH
iwinfo wlan0 assoclist  # 2.4GHz clients
iwinfo wlan1 assoclist  # 5GHz clients
```

### Test VLAN Connectivity
1. **YourHomeNetwork** (VLAN 1):
   - Connect device to SSID
   - Should get IP in 10.0.1.0/24 range
   - Gateway should be 10.0.1.1
   - DNS should be 10.0.20.2 or 10.0.1.1
   - Should have full network access

2. **Home-IoT** (VLAN 50):
   - Connect device to SSID
   - Should get IP in 10.0.50.0/24 range
   - Gateway should be 10.0.50.1
   - Should have internet access only (verify firewall rules)

3. **Guest** (VLAN 99):
   - Connect device to SSID
   - Should get IP in 10.0.99.0/24 range
   - Gateway should be 10.0.99.1
   - Should be completely isolated (no local network access)
   - Internet only

### Verify Commands
```bash
# Check IP address
ip addr show
# Or on Windows: ipconfig

# Ping gateway
ping 10.0.1.1  # For Management VLAN
ping 10.0.50.1  # For IoT VLAN
ping 10.0.99.1  # For Guest VLAN

# Test DNS
nslookup google.com

# Test internet
ping 8.8.8.8
```

### Test Mesh Roaming
1. Connect to YourHomeNetwork on AP1
2. Walk towards AP2
3. Connection should seamlessly transition
4. Check which AP you're connected to via MAC address

## Troubleshooting

### SSID Not Visible
1. Check radio is enabled: `wifi status`
2. Verify channel selection (avoid DFS channels initially)
3. Check wireless regional settings (must be US)
4. Restart wireless: `wifi reload` or `/etc/init.d/network restart`
5. Check for errors: `logread | grep -i wifi`

### Cannot Connect to Network
1. Verify password is correct
2. Check encryption settings match (WPA3/WPA2 vs WPA2)
3. Some devices don't support WPA3 - ensure SAE-mixed mode is enabled
4. Review wireless logs: `logread | grep -i wlan`
5. Try disabling and re-enabling the radio

### Connected But No Internet
1. Check VLAN configuration: `uci show network`
2. Verify gateway is correct for the VLAN
3. Check OPNsense firewall rules for the VLAN
4. Test DNS resolution: `nslookup google.com`
5. Verify physical trunk port on TRENDnet switch
6. Check OPNsense DHCP server for VLAN

### Mesh Not Working
1. Ensure mesh is configured on Management VLAN (VLAN 1)
2. Check both APs have same wireless configuration
3. Verify both APs can communicate via wired network
4. Review Voxel firmware mesh settings

### Client Isolation Not Working
1. Verify `option isolate '1'` is set
2. Check firewall rules aren't allowing inter-client traffic
3. Test with ping between two guest clients (should fail)

## Next Steps
1. Verify DHCP settings on OPNsense are configured for VLANs 1, 50, 99
2. Confirm firewall rules properly isolate IoT and Guest networks
3. Test and document final wireless configuration
4. Create configuration backup via web UI or `sysupgrade -b /tmp/backup.tar.gz`
5. Document actual SSID passwords in secure password manager
