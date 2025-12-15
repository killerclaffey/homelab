# OPNSense Firewall Configuration

This folder contains detailed configuration documentation for my Protectli VP2430 running OPNSense.

## Configuration Files

### VLAN Configuration
- [OPNSense_VLAN_Configuration_Details.md](OPNSense_VLAN_Configuration_Details.md) - Complete field-by-field VLAN interface creation
- [OPNSense_VLAN_Assignment_Details.md](OPNSense_VLAN_Assignment_Details.md) - Assigning and configuring VLAN interfaces

### DHCP Configuration
- [OPNSense_KEA_DHCP_Configuration.md](OPNSense_KEA_DHCP_Configuration.md) - Complete KEA DHCP v4 setup with all fields
- [OPNSense_KEA_DHCP_By_VLAN_Name.md](OPNSense_KEA_DHCP_By_VLAN_Name.md) - Quick reference organized by VLAN name

### DNS Configuration
- [OPNSense_Unbound_DNS_Configuration.md](OPNSense_Unbound_DNS_Configuration.md) - Unbound DNS resolver setup

### Virtual IPs and Load Balancing
- [OPNSense_Virtual_IP_Configuration.md](OPNSense_Virtual_IP_Configuration.md) - Virtual IP addresses for HAProxy

### Troubleshooting
- [OPNSense_Static_IP_Troubleshooting.md](OPNSense_Static_IP_Troubleshooting.md) - Static IP assignment troubleshooting guide

### Migration Plans
- [DHCP-and-DNS-swap-plan.md](DHCP-and-DNS-swap-plan.md) - Plan for migrating from Dnsmasq to KEA and Unbound

## My OPNSense Setup Overview

### Hardware
- **Device**: Protectli VP2430
- **Ports**: 4x 2.5G Ethernet ports
- **Configuration**:
  - Port 1: WAN (Internet)
  - Port 2: LAN Trunk (to TRENDnet switch)
  - Port 3: Helium Hotspot (direct connection, VLAN 70)
  - Port 4: Available

### VLANs Configured
I have 7 VLANs configured on the trunk port (Port 2):
- VLAN 1 - Management (10.0.1.0/24)
- VLAN 20 - OKD Infrastructure (10.0.20.0/24)
- VLAN 30 - Storage Backend (10.0.30.0/24)
- VLAN 40 - Services (10.0.40.0/24)
- VLAN 50 - IoT/Surveillance (10.0.50.0/24)
- VLAN 60 - Game Consoles (10.0.60.0/24)
- VLAN 99 - Guest WiFi (10.0.99.0/24)

Plus VLAN 70 (Helium Hotspot) on dedicated Port 3.

### Services Running
- **KEA DHCP v4**: Serving DHCP for VLANs 1, 50, 60, 70, 99
- **Unbound DNS**: DNS resolver with forwarding to TrueNAS Bind9
- **HAProxy**: Load balancing for OKD cluster (API and Ingress)
- **Firewall**: Per-VLAN security rules
- **uPNP**: Enabled for VLAN 60 (Game Consoles)

### Virtual IPs (HAProxy)
- **10.0.20.5**: OKD API VIP (load balances API requests)
- **10.0.20.6**: OKD Apps Internal VIP
- **10.0.40.10**: OKD Apps External VIP (published services)

## Configuration Order

I recommend configuring in this order:

1. **VLANs**: Create VLAN interfaces ([VLAN Configuration](OPNSense_VLAN_Configuration_Details.md))
2. **Interfaces**: Assign and configure VLAN interfaces ([VLAN Assignment](OPNSense_VLAN_Assignment_Details.md))
3. **DHCP**: Configure KEA DHCP ([KEA DHCP](OPNSense_KEA_DHCP_Configuration.md))
4. **DNS**: Set up Unbound DNS ([Unbound DNS](OPNSense_Unbound_DNS_Configuration.md))
5. **Virtual IPs**: Create VIPs for HAProxy ([Virtual IPs](OPNSense_Virtual_IP_Configuration.md))
6. **HAProxy**: Configure load balancing (see main README)
7. **Firewall Rules**: Set up per-VLAN firewall rules (see main README)

## Tips

- Always backup your config before making changes: **System → Configuration → Backups**
- Test one VLAN at a time to isolate issues
- Use firewall logs to troubleshoot: **Firewall → Log Files → Live View**
- HAProxy stats are helpful: **Services → HAProxy → Statistics**

## References

- [Main Setup Plan](../../README.md)
- [VLAN Implementation Checklist](../VLANs/VLAN_IMPLEMENTATION_CHECKLIST.md)
- [Switch Configuration](../TRENDnet-SWITCH/)
