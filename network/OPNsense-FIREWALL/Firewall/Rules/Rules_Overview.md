# Firewall: Rules: Overview

## Default Firewall Policy

**Default Action:** Block (implicit deny all)
**State Table:** Enabled (stateful firewall)

## LAN Interface Rules

### Rule 1: Allow LAN to Any (IPv4)

**Action:** Pass
**Quick:** Yes
**Interface:** LAN (igc1)
**Direction:** In
**IP Protocol:** IPv4

**Source:**
- Type: LAN network
- Address: 10.0.0.0/20

**Destination:**
- Type: Any
- Port: Any

**Protocol:** Any

**Description:** Default allow LAN to any rule

**Logging:** No

---

### Rule 2: Allow LAN IPv6 to Any

**Action:** Pass
**Quick:** Yes
**Interface:** LAN (igc1)
**Direction:** In
**IP Protocol:** IPv6

**Source:**
- Type: LAN network (IPv6)
- Address: LAN subnet

**Destination:**
- Type: Any
- Port: Any

**Protocol:** Any

**Description:** Default allow LAN IPv6 to any rule

**Logging:** No

---

## VLAN Interface Rules

**Status:** Likely using default rules or custom rules not visible in config export

Each VLAN interface (OPT3-OPT9) should have rules governing:
- Inter-VLAN communication
- Internet access
- Access to firewall services (DNS, DHCP, NTP)
- Isolation rules (especially for IOT/Guest networks)

**Recommendation:** Document specific rules for each VLAN showing:
- What can access what
- Any isolation policies
- Special port forwards or exceptions

---

## WAN Interface Rules

**Default:** Block all inbound (implicit)
**Allowed:** Established/Related connections for outbound traffic

**Anti-Lockout Rule:** Disabled (console menu disabled)

**Special Rules:**
- Block private networks: Yes
- Block bogon networks: Yes

---

## Floating Rules

**Status:** None configured

Floating rules apply across multiple interfaces and are evaluated first.

---

## Rule Processing Order

1. **Floating rules** (if any) - processed first
2. **Interface rules** - processed in order from top to bottom
3. **Implicit deny** - blocks all traffic not explicitly allowed

**Quick Rules:** Stop processing when matched (first match wins)
**Non-Quick Rules:** Continue evaluating subsequent rules

---

## NAT Configuration

**Outbound NAT Mode:** Automatic

Automatic outbound NAT creates rules for:
- LAN network (10.0.0.0/20) → WAN
- All VLAN networks → WAN
- OPT2 network (172.16.0.0/28) → WAN

See [Firewall: NAT](../NAT/) for NAT rule details.

---

## Traffic Shaping

**Status:** Not configured

No traffic shaping pipes, queues, or rules are currently defined.

---

## Firewall Optimization Settings

**State Table Optimization:** Normal
**Firewall Maximum States:** Default
**State Table Size:** Default
**Firewall Maximum Table Entries:** Default

**Advanced Settings:**
- Share forward: Enabled
- Sticky connections: Enabled
- Disable NAT reflection: Yes

---

## Recommendations

1. **Document VLAN Rules:** Create specific rule documentation for each VLAN
2. **IOT Isolation:** Ensure IOT/Surveillance VLAN (OPT7) is properly isolated
3. **Guest Network:** Implement strict isolation for guest network (10.0.99.0/24)
4. **Port Forwards:** Document any port forward rules for published services
5. **Logging:** Enable logging on critical allow/deny rules for security auditing

---

**Last Updated:** December 26, 2024
**Configuration Source:** config-firewall.claffey.cloud-20251226200007.xml
