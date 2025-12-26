# Firewall: NAT: Outbound

## Outbound NAT Mode

**Mode:** Automatic outbound NAT rule generation

## How Automatic NAT Works

In automatic mode, OPNsense automatically creates outbound NAT rules for all private networks on internal interfaces. These rules allow internal networks to access the internet through the WAN interface using source NAT (masquerading).

## Automatically Generated NAT Rules

The following NAT rules are automatically created:

### LAN Network
**Source:** 10.0.0.0/20 (LAN subnet)
**Destination:** Any
**Translation:** WAN address (dynamic)
**Description:** Automatic NAT for LAN network

---

### VLAN Networks

**VLAN 1 (Management):**
- Source: VLAN subnet
- Translation: WAN address

**VLAN 20 (OKDInfra):**
- Source: 10.0.20.0/24
- Translation: WAN address

**VLAN 30 (OKDStorage):**
- Source: 10.0.30.0/24
- Translation: WAN address

**VLAN 40 (Services):**
- Source: 10.0.40.0/24 (or /32 for single IP)
- Translation: WAN address

**VLAN 50 (IOT/Surveillance):**
- Source: 10.0.50.0/24
- Translation: WAN address

**VLAN 60 (GameCon):**
- Source: 10.0.60.0/24
- Translation: WAN address

**VLAN 70 (Helium):**
- Source: 10.0.70.0/24
- Translation: WAN address

---

### OPT2 Network
**Source:** 172.16.0.0/28
**Destination:** Any
**Translation:** WAN address

---

## NAT Modes Explained

### Automatic (Current)
- Automatically creates NAT rules for all RFC1918 private networks
- Rules are generated based on interface configuration
- No manual NAT rule management needed
- Best for most scenarios

### Hybrid
- Uses automatic rules as base
- Allows manual rule additions
- Manual rules processed before automatic
- Useful for special cases (1:1 NAT, port-specific NAT)

### Manual
- All NAT rules must be manually configured
- Complete control over NAT behavior
- More complex to manage
- Required for advanced scenarios

### Disabled
- No outbound NAT
- Internal networks cannot access internet
- Only used in special routing scenarios

---

## Port Forwarding / Inbound NAT

**Status:** No port forwards currently configured

Port forwards (inbound NAT) allow external access to internal services.

Common use cases:
- Web servers (80, 443)
- Game servers
- Remote access (SSH, RDP)
- Published OKD/OpenShift services

**Configuration Location:** Firewall > NAT > Port Forward

---

## 1:1 NAT

**Status:** Not configured

1:1 NAT creates bidirectional mappings between external and internal IP addresses. Useful for:
- Hosting multiple public IPs
- DMZ configurations
- Services requiring specific external IPs

---

## NPt (IPv6)

**Status:** Not configured

Network Prefix Translation for IPv6. Used for:
- IPv6 multi-homing
- IPv6 address translation
- Similar to NAT44 but for IPv6

---

## TO DO LIST

1. **Review NAT Mode:** Automatic mode is appropriate for current setup
2. **Port Forwards:** Document required port forwards for:
   - OKD services (VLAN 40)
   - Published applications
   - Remote management
3. **1:1 NAT:** Consider for dedicated public IPs if available
4. **Logging:** Enable NAT logging for troubleshooting if needed

---

**Last Updated:** December 26, 2024
