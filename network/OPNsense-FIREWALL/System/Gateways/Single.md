# System: Gateways: Single

## Configured Gateways

### WAN_PERSISTANT (Primary Gateway)

**Status:** Active (Default)

**Basic Settings:**
- Name: WAN_PERSISTANT
- Description: "WAN DHCP Gateway Set statically lol"
- Interface: WAN (igc0)
- IP Protocol: IPv4
- Gateway: 50.4.0.1

**Priority and Weight:**
- Default Gateway: Yes
- Priority: 255 (highest)
- Weight: 1

**Monitoring:**
- Monitoring: Enabled
- Monitor IP: Not specified (uses gateway IP)
- Disable Gateway Monitoring: No
- Disable Gateway Monitoring Action: None

**Advanced:**
- Far Gateway: No
- Disable Gateway Action: No

---

### WAN_DHCP (Secondary Gateway)

**Status:** Active (Non-default)

**Basic Settings:**
- Name: WAN_DHCP
- Description: None
- Interface: WAN (igc0)
- IP Protocol: IPv4
- Gateway: Dynamic (assigned via DHCP)

**Priority and Weight:**
- Default Gateway: No
- Priority: 254
- Weight: 1

**Monitoring:**
- Monitoring: Disabled
- Monitor IP: Not applicable
- Disable Gateway Monitoring: Yes

**Advanced:**
- Far Gateway: No
- Disable Gateway Action: No

---

## Gateway Configuration Notes

The firewall has two WAN gateways configured:

1. **WAN_PERSISTANT** - Statically defined gateway at 50.4.0.1, set as the default with highest priority (255). Monitoring is enabled to detect gateway failures.

2. **WAN_DHCP** - Dynamically assigned gateway from DHCP. Not set as default and has monitoring disabled. Acts as a reference but is not actively used.

This configuration ensures consistent routing through the static gateway while maintaining the DHCP-assigned gateway information for reference.

---

**Last Updated:** December 26, 2024
**Configuration Source:** config-firewall.claffey.cloud-20251226200007.xml
