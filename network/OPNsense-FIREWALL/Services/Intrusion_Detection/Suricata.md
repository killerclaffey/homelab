# Services: Intrusion Detection: Suricata

## Status

**IDS/IPS:** Disabled (configured but not active)

## Basic Configuration

**Interface:** WAN (igc0)
**Mode:** IDS (Intrusion Detection System)
**IPS Mode:** Disabled
**Promiscuous Mode:** Enabled

## Home Networks

The following networks are defined as "home networks" for Suricata rule evaluation:

- 192.168.0.0/16 (RFC1918 Class B private)
- 10.0.0.0/8 (RFC1918 Class A private)
- 172.16.0.0/12 (RFC1918 Class B private)

**Purpose:** Traffic to/from these networks is considered internal and evaluated differently by IDS rules.

## Pattern Matching

**Pattern Matcher:** Hyperscan (default, high-performance)

## Rule Configuration

**Status:** Not actively configured
**Rule Sets:** None selected
**Custom Rules:** None defined

## Logging

**EVE Log:** Enabled (default)
**Log Level:** Not specified (using default)
**Alert Details:** Not configured

## Performance Tuning

**Default Settings:**
- No custom performance tuning applied
- Using default thread and buffer settings
- No custom memcap settings

## Why Disabled?

The IDS/IPS system is configured but disabled, likely due to:
1. **Performance Impact:** Running IDS on hardware firewall can impact throughput
2. **Alert Fatigue:** Homelab environments may generate many false positives
3. **Upstream Protection:** ISP or edge device may provide IDS/IPS
4. **Testing Phase:** Configuration exists for future enablement when needed

## Enabling Suricata

To enable Suricata IDS:

1. Navigate to **Services > Intrusion Detection > Administration**
2. Check "Enable" box
3. Select desired rule sets (ET Open, Abuse.ch, etc.)
4. Configure alert actions
5. Apply changes
6. Monitor **Services > Intrusion Detection > Alerts** for detections

## Recommended Rule Sets for Homelab

- **Emerging Threats Open:** Free, community-maintained rules
- **Abuse.ch:** Malware and botnet indicators
- **ET/LUAJIT:** Lua-based detection scripts
- Custom rules for specific threats relevant to your environment

---

**Last Updated:** December 26, 2024
**Configuration Source:** config-firewall.claffey.cloud-20251226200007.xml
