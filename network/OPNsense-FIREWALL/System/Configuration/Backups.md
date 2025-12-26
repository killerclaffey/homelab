# System: Configuration: Backups

## Backup Settings Overview

### Local Backup Configuration
- **Backup Count:** 150 configurations retained in local cache Takes up minimal space on disk might as well retain as much as possible
- **RRD Data Backup:** Disabled

### Backup Options
- Download configuration in XML format
- Option to exclude RRD data from backup
- Option to encrypt configuration file
- Reboot after successful restore available
- Console settings can be excluded from import
- Full local configuration history flush available

### Restore Areas Available
The following system areas can be selectively restored:

- Aliases
- Authentication Servers
- BIND domain name service
- Bridge Devices
- Captive Portal
- Certificates and Authorities
- Cron
- DHCRelay
- Dnsmasq DNS/DHCP
- Firewall Categories
- Firewall Groups
- Firewall Log Templates
- Firewall Rules
- Firewall Schedules
- GIF Devices
- HAProxy Load Balancer
- Interfaces
- Intrusion Detection
- IPsec
- ISC DHCPv4
- ISC DHCPv6
- Kea DHCP
- LAGG Devices
- Monit System Monitoring
- NAT
- Netflow / Insight
- Network Time
- OpenDNS
- OpenSSH
- OpenVPN
- Point-to-Point Devices
- RRD Data
- Shaper
- Static Routes
- System logging
- System Tunables
- Unbound DNS
- Users and Groups
- Virtual IPs
- VLAN Devices
- Web GUI
- WireGuard
- Wireless Devices

---

## Git Backup Configuration

**Status:** Enabled

### Repository Settings
- **URL:** `ssh://github.com/killerclaffey/opnsense.git`
- **Branch:** `main`
- **Force Push:** Disabled
- **User Name:** `git`
- **Authentication:** SSH private key (OpenSSH ED25519)

### Git Backup Details
The os-git-backup plugin automatically commits and pushes configuration changes to the GitHub repository. This provides:
- Version control for all configuration changes
- Off-site backup storage
- Change tracking and history
- Easy rollback capability

**Last Updated:** December 27, 2024 at 19:43:39 UTC

