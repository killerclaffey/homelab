# OpenWRT Wireless Configuration Guide

## Overview
Configure three SSIDs on OpenWRT access points, each mapped to a different VLAN.

## SSID to VLAN Mapping

| SSID Name | VLAN | Network | Band | Security | Purpose |
|-----------|------|---------|------|----------|---------|
| [Primary-SSID] | 20 | Trusted | 2.4 + 5GHz | WPA3/WPA2 | Personal devices |
| [IoT-SSID] | 30 | IoT | 2.4GHz | WPA2 | Smart home devices |
| [Guest-SSID] | 40 | Guest | 2.4 + 5GHz | WPA2 | Guest access |

## Configuration Steps

### 1. Access OpenWRT Web Interface
Navigate to `Network > Wireless`

### 2. Configure SSID 1 - Primary/Trusted Network

#### Create 2.4GHz Interface
1. Click **Add** on the 2.4GHz radio
2. Configure:
   - **ESSID**: `[Your-Primary-SSID]`
   - **Mode**: Access Point
   - **Network**: Select `trusted` (VLAN 20)

3. **Wireless Security** tab:
   - **Encryption**: WPA3-SAE mixed mode (WPA2/WPA3-Personal)
   - **Cipher**: Force CCMP (AES)
   - **Key**: [Strong password]

4. **Advanced Settings**:
   - **Country Code**: US (or your country)
   - **Channel**: Auto (or specific channel)
   - **Width**: 20MHz or 40MHz

#### Create 5GHz Interface
Repeat above for 5GHz radio with same SSID and settings

### 3. Configure SSID 2 - IoT Network

#### Create 2.4GHz Interface
1. Click **Add** on the 2.4GHz radio
2. Configure:
   - **ESSID**: `[Your-IoT-SSID]`
   - **Mode**: Access Point
   - **Network**: Select `iot` (VLAN 30)

3. **Wireless Security** tab:
   - **Encryption**: WPA2-PSK
   - **Cipher**: Force CCMP (AES)
   - **Key**: [Strong password]

4. **Advanced Settings**:
   - Enable **Isolate Clients** (optional, for better security)

### 4. Configure SSID 3 - Guest Network

#### Create 2.4GHz Interface
1. Click **Add** on the 2.4GHz radio
2. Configure:
   - **ESSID**: `[Your-Guest-SSID]`
   - **Mode**: Access Point
   - **Network**: Select `guest` (VLAN 40)

3. **Wireless Security** tab:
   - **Encryption**: WPA2-PSK
   - **Cipher**: Force CCMP (AES)
   - **Key**: [Guest password]

4. **Advanced Settings**:
   - Enable **Isolate Clients** (prevent guest-to-guest communication)

#### Create 5GHz Interface
Repeat above for 5GHz radio

## Complete Wireless Configuration File

Edit `/etc/config/wireless`:

```
config wifi-device 'radio0'
    option type 'mac80211'
    option channel '6'
    option hwmode '11g'
    option path 'platform/qca953x_wmac'
    option htmode 'HT20'
    option country 'US'

config wifi-iface 'trusted_2g'
    option device 'radio0'
    option network 'trusted'
    option mode 'ap'
    option ssid '[Primary-SSID]'
    option encryption 'sae-mixed'
    option key '[password]'

config wifi-iface 'iot_2g'
    option device 'radio0'
    option network 'iot'
    option mode 'ap'
    option ssid '[IoT-SSID]'
    option encryption 'psk2+ccmp'
    option key '[password]'
    option isolate '1'

config wifi-iface 'guest_2g'
    option device 'radio0'
    option network 'guest'
    option mode 'ap'
    option ssid '[Guest-SSID]'
    option encryption 'psk2+ccmp'
    option key '[password]'
    option isolate '1'

config wifi-device 'radio1'
    option type 'mac80211'
    option channel '36'
    option hwmode '11a'
    option path 'pci0000:00/0000:00:00.0'
    option htmode 'VHT80'
    option country 'US'

config wifi-iface 'trusted_5g'
    option device 'radio1'
    option network 'trusted'
    option mode 'ap'
    option ssid '[Primary-SSID]'
    option encryption 'sae-mixed'
    option key '[password]'

config wifi-iface 'guest_5g'
    option device 'radio1'
    option network 'guest'
    option mode 'ap'
    option ssid '[Guest-SSID]'
    option encryption 'psk2+ccmp'
    option key '[password]'
    option isolate '1'
```

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
# From a client device
iwlist scan | grep ESSID
```

### Check Connected Clients
```bash
# On the AP
iwinfo wlan0 assoclist
iwinfo wlan1 assoclist
```

### Test VLAN Connectivity
1. Connect to each SSID
2. Check assigned IP address (should be in correct subnet)
3. Ping gateway
4. Test internet connectivity
5. Verify isolation between networks

## Troubleshooting

### SSID Not Visible
- Check radio is enabled
- Verify channel selection
- Check wireless regional settings
- Restart wireless: `wifi reload`

### Cannot Connect to Network
- Verify password
- Check encryption settings
- Review wireless logs: `logread | grep wlan`

### Connected But No Internet
- Check VLAN configuration
- Verify gateway is correct
- Check OPNsense firewall rules
- Test DNS resolution

## Next Steps
1. Configure DHCP settings on OPNsense for each VLAN
2. Set up firewall rules for inter-VLAN traffic
3. Test and document final configuration
4. Create configuration backup
