# Interfaces: Assignments

## Physical Interface Assignments

### Network Interface Cards

| Interface | Device | Name | IP Address | Subnet | Status | Description |
|-----------|--------|------|------------|--------|--------|-------------|
| WAN | igc0 | wan | DHCP/DHCPv6 | - | Enabled | Internet connection |
| LAN | igc1 | lan | 10.0.0.1 | /20 | Enabled | Primary LAN with VLANs |
| OPT1 | igc2 | opt1 | - | - | Disabled | Unused |
| OPT2 | igc3 | opt2 | 172.16.0.1 | /28 | Enabled | Secondary interface |
| Loopback | lo0 | lo0 | 127.0.0.1, ::1 | /8, /128 | Enabled | System loopback |

---

## VLAN Interface Assignments

| Interface | VLAN Device | VLAN ID | Parent | Name | IP Address | Subnet | Status |
|-----------|-------------|---------|--------|------|------------|--------|--------|
| OPT3 | vlan01 | 1 | igc1 | Management | - | - | Assigned |
| OPT4 | vlan02 | 20 | igc1 | OKDInfra | 10.0.20.1 | /24 | Enabled |
| OPT5 | vlan03 | 30 | igc1 | OKDStorage | 10.0.30.1 | /24 | Enabled |
| OPT6 | vlan04 | 40 | igc1 | Services | 10.0.40.1 | /32 | Enabled |
| OPT7 | vlan05 | 50 | igc1 | IOTSurveillance | 10.0.50.1 | /24 | Enabled |
| OPT8 | vlan06 | 60 | igc1 | GameCon | 10.0.60.1 | /24 | Enabled |
| OPT9 | vlan07 | 70 | igc3 | Helium | - | - | Assigned |

See [Interfaces: vLANs](../vLANs/) for detailed VLAN configuration.

---

## Interface Details

### WAN (igc0)
- **Type:** Physical
- **Hardware:** Intel I225/I226 Gigabit Ethernet
- **IPv4 Configuration:** DHCP
- **IPv6 Configuration:** DHCPv6
- **Block Private Networks:** Yes
- **Block Bogon Networks:** Yes
- **DHCPv6 Prefix Delegation:** Disabled (length: 0)

### LAN (igc1)
- **Type:** Physical
- **Hardware:** Intel I225/I226 Gigabit Ethernet
- **IPv4 Address:** 10.0.0.1/20
- **IPv6:** Not configured
- **VLAN Parent:** Yes (hosts 6 VLANs)

### OPT2 (igc3)
- **Type:** Physical
- **Hardware:** Intel I225/I226 Gigabit Ethernet
- **IPv4 Address:** 172.16.0.1/28
- **IPv6:** Not configured
- **VLAN Parent:** Yes (hosts 1 VLAN)

### Loopback (lo0)
- **Type:** Virtual (internal_dynamic)
- **IPv4 Address:** 127.0.0.1/8
- **IPv6 Address:** ::1/128
- **Description:** System loopback interface

---

## Network Topology Summary

```
Physical Layout:
├── igc0 (WAN) - Internet
├── igc1 (LAN) - 10.0.0.1/20
│   ├── vlan01 (Tag 1) - Management
│   ├── vlan02 (Tag 20) - OKDInfra
│   ├── vlan03 (Tag 30) - OKDStorage
│   ├── vlan04 (Tag 40) - Services
│   ├── vlan05 (Tag 50) - IOT/Surveillance
│   └── vlan06 (Tag 60) - GameCon
├── igc2 (OPT1) - Disabled
└── igc3 (OPT2) - 172.16.0.1/28
    └── vlan07 (Tag 70) - Helium
```

---

**Last Updated:** December 26, 2024
**Configuration Source:** config-firewall.claffey.cloud-20251226200007.xml
