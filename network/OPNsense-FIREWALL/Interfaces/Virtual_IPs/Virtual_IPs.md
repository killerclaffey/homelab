# Interfaces: Virtual IPs

## Configured Virtual IP Addresses

### scrutiny
**Type:** IP Alias
**Interface:** LAN (igc1)
**Address:** 10.0.0.2
**Subnet Mask:** /24 (255.255.255.0)
**Description:** Scrutiny monitoring service
**VHID Group:** Not applicable (IP Alias)

**Purpose:** Dedicated IP address for Scrutiny disk monitoring service on the LAN network.

---

### OKD API VIP
**Type:** IP Alias
**Interface:** OPT4 (OKDInfra - vlan02)
**Address:** 10.0.20.5
**Subnet Mask:** /24 (255.255.255.0)
**Description:** Load balances API requests to master nodes
**VHID Group:** Not applicable (IP Alias)

**Purpose:** Virtual IP for OpenShift/OKD API endpoint load balancing. This VIP is used to distribute API requests across the OKD master nodes in the cluster infrastructure VLAN.

---

## Virtual IP Types

### IP Alias
IP Aliases are additional IP addresses on an existing interface. They:
- Do not require ARP
- Are bound directly to the interface
- Can be used for service binding
- Common use cases: Multiple services, load balancing endpoints, monitoring tools

### CARP (Not Currently Used)
CARP (Common Address Redundancy Protocol) provides high availability failover. Features:
- Requires VHID (Virtual Host ID)
- Supports redundant firewalls
- Automatic failover on primary failure
- Not currently configured in this deployment

---

## Network Allocation

| VIP Name | Interface | IP Address | Network | Purpose |
|----------|-----------|------------|---------|---------|
| scrutiny | LAN | 10.0.0.2/24 | 10.0.0.0/20 | Disk monitoring service |
| OKD API VIP | OKDInfra | 10.0.20.5/24 | 10.0.20.0/24 | OKD API load balancer |

---

## Related Services

**scrutiny VIP:**
- May be used for port forwards or HAProxy backends
- Provides dedicated IP for storage health monitoring
- Located on main LAN network for accessibility

**OKD API VIP:**
- Critical for OpenShift cluster operations
- Used by kubectl, oc, and other API clients
- Should be configured in HAProxy or load balancer
- Typically distributes traffic to master nodes (e.g., 10.0.20.10, 10.0.20.11, 10.0.20.12)

---

**Last Updated:** December 26, 2024
**Configuration Source:** config-firewall.claffey.cloud-20251226200007.xml
