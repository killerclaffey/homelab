# System: Settings: General

## Basic Settings

**Hostname:** firewall
**Domain:** claffey.cloud
**FQDN:** firewall.claffey.cloud

**Timezone:** Etc/UTC
**Language:** en_US
**Theme:** opnsense-dark

## DNS Servers

Primary and secondary DNS servers for the firewall itself:

| Priority | IP Address | Description |
|----------|------------|-------------|
| 1 | 2606:4700:4700::1111 | Cloudflare IPv6 Primary |
| 2 | 2606:4700:4700::1001 | Cloudflare IPv6 Secondary |
| 3 | 1.1.1.1 | Cloudflare IPv4 Primary |
| 4 | 1.0.0.1 | Cloudflare IPv4 Secondary |

**DNS Override:** Enabled
**Gateway Assignment:** None (all set to "none")

## Time Servers (NTP)

| Server | Description |
|--------|-------------|
| 162.159.200.1 | Primary NTP |
| 162.159.200.123 | Secondary NTP |
| 216.239.35.0 | Tertiary NTP |
| 216.239.35.4 | Quaternary NTP |

## System Optimization

**Optimization Mode:** normal

## Hardware Settings

**Console Settings:**
- Primary console: Video
- Serial speed: 115200 baud
- Disable console menu: Yes
- Use virtual terminal: Yes

**Network Hardware Offloading:**
All hardware offloading features are disabled for stability:
- VLAN hardware filtering: Disabled
- Checksum offloading: Disabled
- Segmentation offloading: Disabled
- Large receive offloading: Disabled

**Power Management:**
- AC mode: hadp (Heuristic Adaptive)
- Battery mode: hadp
- Normal mode: hadp

## Network Settings

**IPv6:** Enabled
**NAT Reflection:** Disabled
**Bogon Networks:**
- Update interval: Monthly
- Block on WAN: Yes

**Packet Filter:**
- Share forward: Enabled
- Sticky connections: Enabled

---

**Last Updated:** December 26, 2024
**Configuration Source:** config-firewall.claffey.cloud-20251226200007.xml
