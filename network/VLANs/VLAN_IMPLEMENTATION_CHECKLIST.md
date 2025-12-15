# Simplified VLAN Network Implementation Checklist

This checklist helps you track progress through the VLAN network setup. Follow the detailed instructions in the plan file.

## Pre-Implementation Notes

- **Current State:** Network is flat (10.0.0.1/24)
- **Target State:** 8 VLANs with proper segmentation
- **Migration Strategy:** Configure OPNSense → Switch → APs → Test

## Phase 1: OPNSense Configuration

### VLAN Setup
- [ ] Create VLAN interfaces (1, 20, 30, 40, 50, 60, 99) on main trunk port
- [ ] Assign VLAN interfaces and configure static IPs:
  - [ ] VLAN 1: 10.0.1.1/24
  - [ ] VLAN 20: 10.0.20.1/24
  - [ ] VLAN 30: 10.0.30.1/24
  - [ ] VLAN 40: 10.0.40.1/24
  - [ ] VLAN 50: 10.0.50.1/24
  - [ ] VLAN 60: 10.0.60.1/24
  - [ ] VLAN 99: 10.0.99.1/24
- [ ] Configure Helium Hotspot interface (separate physical port):
  - [ ] Assign physical 2.5G port
  - [ ] Configure static IP: 10.0.70.1/24

### KEA DHCP v4 Configuration
- [ ] Enable KEA DHCP service (Services → Kea DHCP → Settings)
- [ ] Create DHCP subnet for VLAN 1: 10.0.1.100-250
- [ ] Create DHCP subnet for VLAN 50: 10.0.50.100-200
- [ ] Create DHCP subnet for VLAN 60: 10.0.60.100-200
- [ ] Create DHCP subnet for VLAN 70: 10.0.70.100-200
- [ ] Create DHCP subnet for VLAN 99: 10.0.99.100-200
- [ ] Configure Option Data for each subnet (routers, domain-name-servers)
- [ ] Set DNS servers in Option Data: 10.0.20.2, 10.0.1.1
- [ ] Verify KEA DHCP is running (Services → Kea DHCP → Status)

### Unbound DNS Configuration
- [ ] Enable Unbound DNS (Services → Unbound DNS → General)
- [ ] Configure Network Interfaces (select all VLAN interfaces)
- [ ] Enable DNS Query Forwarding
- [ ] Configure Upstream DNS: 10.0.20.2 (TrueNAS), 1.1.1.1 (Cloudflare)
- [ ] Add Domain Override for okd.lab → 10.0.20.2
- [ ] Test DNS resolution (Services → Unbound DNS → Diagnostics)

### uPNP Configuration
- [ ] Enable UPnP & NAT-PMP service
- [ ] Select VLAN 60 (Game Consoles) interface
- [ ] Enable "Allow UPnP"
- [ ] Enable "Default deny"
- [ ] (Optional) Enable packet logging

### Firewall Rules
- [ ] Configure VLAN 1 (Management) rules
- [ ] Configure VLAN 20 (OKD-Infra) rules
- [ ] Configure VLAN 30 (OKD-Storage) rules
- [ ] Configure VLAN 40 (Services) rules
- [ ] Configure VLAN 50 (IoT/Surveillance) rules
- [ ] Configure VLAN 60 (Game Consoles) rules
- [ ] Configure VLAN 70 (Helium) rules
- [ ] Configure VLAN 99 (Guest) rules

### NAT Configuration
- [ ] Configure outbound NAT for all VLANs → WAN
- [ ] Verify NAT rules are correct

## Phase 2: TRENDnet TEG-3102WS Switch Configuration

### VLAN Creation
- [ ] Access switch management interface
- [ ] Create VLAN 1 (Management)
- [ ] Create VLAN 20 (OKD-Infra)
- [ ] Create VLAN 30 (OKD-Storage)
- [ ] Create VLAN 40 (Services)
- [ ] Create VLAN 50 (IoT/Surveillance)
- [ ] Create VLAN 60 (Game Consoles)
- [ ] Create VLAN 99 (Guest-WiFi)

### Port Configuration
- [ ] Configure Port 1 (OPNSense trunk):
  - [ ] Mode: Trunk/Tagged
  - [ ] Tagged VLANs: 1,20,30,40,50,60,99
  - [ ] PVID: 1
- [ ] Configure Port 9 (TrueNAS):
  - [ ] Mode: Trunk/Tagged
  - [ ] Tagged VLANs: 1,20,30,40
  - [ ] PVID: 1
- [ ] Configure Ports 2-8, 10 (Access ports):
  - [ ] Mode: Access/Untagged
  - [ ] PVID: 1 (Management)
- [ ] (If needed) Configure dedicated Game Console port:
  - [ ] Mode: Access
  - [ ] PVID: 60

## Phase 3: OpenWRT Access Point Configuration

### AP1 Configuration
- [ ] Access AP1 management interface
- [ ] Configure Management interface (VLAN 1):
  - [ ] Static IP: 10.0.1.21/24
  - [ ] Gateway: 10.0.1.1
  - [ ] DNS: 10.0.20.2, 10.0.1.1
- [ ] Configure VLANs on switch interface:
  - [ ] VLAN 1 (untagged on CPU)
  - [ ] VLAN 50 (tagged)
  - [ ] VLAN 99 (tagged)
- [ ] Create VLAN 50 interface:
  - [ ] Static IP: 10.0.50.10/24
  - [ ] Gateway: 10.0.50.1
- [ ] Create VLAN 99 interface (or bridge without IP)
- [ ] Configure WiFi SSIDs:
  - [ ] YourHomeNetwork (2.4GHz) → VLAN 1
  - [ ] YourHomeNetwork-5G (5GHz) → VLAN 1
  - [ ] Home-IoT (2.4GHz) → VLAN 50
  - [ ] Home-IoT-5G (5GHz) → VLAN 50 (if needed)
  - [ ] Guest (2.4GHz) → VLAN 99
  - [ ] Guest-5G (5GHz) → VLAN 99
- [ ] Configure firewall rules (if needed)
- [ ] Configure mesh (if using mesh mode)

### AP2 Configuration
- [ ] Access AP2 management interface
- [ ] Configure Management interface (VLAN 1):
  - [ ] Static IP: 10.0.1.22/24
  - [ ] Gateway: 10.0.1.1
  - [ ] DNS: 10.0.20.2, 10.0.1.1
- [ ] Configure VLANs on switch interface:
  - [ ] VLAN 1 (untagged on CPU)
  - [ ] VLAN 50 (tagged)
  - [ ] VLAN 99 (tagged)
- [ ] Create VLAN 50 interface:
  - [ ] Static IP: 10.0.50.11/24
  - [ ] Gateway: 10.0.50.1
- [ ] Create VLAN 99 interface (or bridge without IP)
- [ ] Configure WiFi SSIDs (same as AP1)
- [ ] Configure firewall rules (if needed)
- [ ] Configure mesh (if using mesh mode)

## Phase 4: Testing & Validation

### Basic Connectivity
- [ ] From Management VLAN, ping all gateways:
  - [ ] 10.0.1.1 (Management)
  - [ ] 10.0.20.1 (OKD-Infra)
  - [ ] 10.0.50.1 (IoT)
  - [ ] 10.0.60.1 (Game Consoles)
  - [ ] 10.0.70.1 (Helium)
  - [ ] 10.0.99.1 (Guest)

### WiFi Testing
- [ ] Connect to "YourHomeNetwork" → Verify IP in 10.0.1.x range
- [ ] Connect to "Home-IoT" → Verify IP in 10.0.50.x range
- [ ] Connect to "Guest" → Verify IP in 10.0.99.x range

### Isolation Testing
- [ ] From Guest WiFi: Verify cannot ping 10.0.1.1
- [ ] From Guest WiFi: Verify cannot ping 10.0.50.1
- [ ] From Guest WiFi: Verify can access internet (8.8.8.8)
- [ ] From IoT WiFi: Verify cannot access 10.0.40.10 (Services)
- [ ] From IoT WiFi: Verify can access internet

### uPNP Testing
- [ ] Connect game console to VLAN 60 port
- [ ] Verify console gets IP in 10.0.60.x range
- [ ] Check OPNSense UPnP status page
- [ ] Start a game that requires port forwarding
- [ ] Verify port mappings appear automatically
- [ ] Verify console cannot ping other VLANs

### Helium Hotspot Testing
- [ ] Verify Helium hotspot gets IP in 10.0.70.x range
- [ ] Verify internet connectivity
- [ ] Verify cannot access other VLANs

### Services Access Testing
- [ ] From Management VLAN: Access OKD console (should work)
- [ ] From IoT VLAN: Try to access OKD console (should fail)
- [ ] From Guest VLAN: Try to access OKD console (should fail)

## Post-Implementation

- [ ] Update README.md with any deviations from plan
- [ ] Document any custom configurations
- [ ] Backup OPNSense configuration
- [ ] Backup switch configuration (if possible)
- [ ] Test all critical services
- [ ] Verify all devices can access required resources

## Troubleshooting Notes

- **VLANs not working:** Check switch port configuration (trunk vs access)
- **WiFi SSID not getting correct VLAN:** Check OpenWRT bridge configuration
- **uPNP not working:** Check OPNSense UPnP service is enabled and VLAN 60 is selected
- **Can't access internet from VLAN:** Check firewall rules and NAT configuration
- **Devices can't get IP:** Check DHCP is enabled on correct VLAN interface

## Important Reminders

1. **Backup before changes:** Always backup OPNSense config before making changes
2. **Test incrementally:** Test each phase before moving to the next
3. **Document deviations:** Note any changes from the plan
4. **Keep access:** Ensure you maintain access to management interfaces during migration

