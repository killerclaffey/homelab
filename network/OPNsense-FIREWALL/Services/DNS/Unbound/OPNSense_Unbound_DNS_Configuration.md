# OPNSense Unbound DNS Configuration - Section 1.11

This document provides complete field-by-field configuration for setting up Unbound DNS with domain forwarding to TrueNAS Bind9.

## Prerequisites

- ✅ TrueNAS Bind9 is configured and running (see README Phase 3)
- ✅ TrueNAS DNS is accessible at `10.0.20.2`
- ✅ All VLAN interfaces are configured

## Step 1: Verify Unbound DNS is Enabled

**Location:** Services → Unbound DNS → General

1. Navigate to: **Services → Unbound DNS → General**
2. Verify: ☑ **Enable Unbound**
3. If not enabled, check the box and click **Save**
4. Click **Apply Changes**

## Step 2: Configure Unbound General Settings

**Location:** Services → Unbound DNS → General

### General Settings

| Field | Value | Notes |
|-------|-------|-------|
| **Enable Unbound** | ☑ Checked | Enable the service |
| **Port** | `53` | Standard DNS port |
| **Network Interfaces** | Select all VLAN interfaces | VLAN1, VLAN20, VLAN50, VLAN60, VLAN70, VLAN99 |
| **Outgoing Network Interfaces** | Select WAN interface | For external DNS queries |
| **DNS Query Forwarding** | ☑ Enabled | Forward queries to upstream DNS |
| **Register DHCP leases** | ☑ Enabled | Register DHCP clients in DNS (optional) |
| **Register DHCP static mappings** | ☑ Enabled | Register static DHCP reservations (optional) |

### Access Control

| Field | Value | Notes |
|-------|-------|-------|
| **Network Interfaces** | Select all VLAN interfaces | Allow DNS queries from all VLANs |
| **Action** | `Allow` | Allow queries from selected interfaces |

Click **Save** → **Apply Changes**

## Step 3: Configure DNS Query Forwarding

**Location:** Services → Unbound DNS → General

### Upstream DNS Servers

In the **DNS Query Forwarding** section:

1. **Primary DNS Server:** `10.0.20.2` (TrueNAS Bind9)
2. **Secondary DNS Server:** `1.1.1.1` (Cloudflare) or `8.8.8.8` (Google)
3. **Tertiary DNS Server:** `8.8.4.4` (Google) or leave empty

**Note:** Unbound will first try TrueNAS Bind9 for local domain resolution, then fall back to public DNS for external queries.

## Step 4: Configure Domain Overrides (Critical for OKD)

**Location:** Services → Unbound DNS → Overrides

This forwards queries for `okd.lab` domain to TrueNAS Bind9.

### Add Domain Override

Click **"+"** to add a new override:

| Field | Value | Notes |
|-------|-------|-------|
| **Domain** | `okd.lab` | OKD cluster domain |
| **Type** | `Host` | Host override type |
| **Host** | (Leave empty) | For domain-wide forwarding |
| **IP Address** | `10.0.20.2` | TrueNAS Bind9 IP |
| **Description** | `Forward to TrueNAS Bind9 for OKD cluster` | Optional but helpful |

**Alternative Method (Domain Forwarding):**

If the above doesn't work, use domain forwarding instead:

1. Navigate to: **Services → Unbound DNS → Advanced**
2. Scroll to **Custom Options**
3. Add:
```
forward-zone:
    name: "okd.lab"
    forward-addr: 10.0.20.2
```

Click **Save** → **Apply Changes**

## Step 5: Configure DNS Resolver Settings

**Location:** Services → Unbound DNS → Advanced

### Advanced Settings

| Field | Value | Notes |
|-------|-------|-------|
| **Hide Identity** | ☑ Enabled | Security: Hide server identity |
| **Hide Version** | ☑ Enabled | Security: Hide Unbound version |
| **Prefetch Support** | ☑ Enabled | Performance: Prefetch popular domains |
| **Prefetch DNS Key Support** | ☑ Enabled | Performance: Prefetch DNS keys |
| **Message Cache Size** | `4m` | Default cache size (4MB) |
| **Number of Threads** | `1` | Default (increase if needed) |
| **Outgoing TCP Buffers** | `10m` | Default buffer size |
| **Incoming TCP Buffers** | `10m` | Default buffer size |

### DNSSEC Settings

| Field | Value | Notes |
|-------|-------|-------|
| **DNSSEC** | ☑ Enabled | Enable DNSSEC validation |
| **DNSSEC Private Key** | (Auto-generated) | Leave default |
| **Hardened DNSSEC** | ☐ Disabled | Optional security hardening |

Click **Save** → **Apply Changes**

## Step 6: Verify Unbound DNS is Working

### Test from OPNSense

**Location:** Services → Unbound DNS → Diagnostics

1. Navigate to: **Services → Unbound DNS → Diagnostics**
2. Check **Query Statistics** - should show queries being processed
3. Use **Query DNS** tool to test:
   - Query: `api.okd.lab`
   - Should resolve to: `10.0.20.5`
   - Query: `google.com`
   - Should resolve to Google's IP

### Test from Client Device

From a device on Management VLAN (10.0.1.x):

```bash
# Test local domain resolution
nslookup api.okd.lab
# Should return: 10.0.20.5

# Test external domain resolution
nslookup google.com
# Should return: Google's IP addresses

# Test DNS server being used
nslookup
> server
# Should show: 10.0.1.1 (OPNSense Unbound)
```

## Step 7: Configure DNS for Each VLAN

Unbound DNS should be accessible from all VLANs. Verify firewall rules allow DNS queries:

### Firewall Rules for DNS (Already in Section 1.10)

Each VLAN should have a firewall rule allowing:
- **Protocol:** UDP
- **Destination Port:** 53
- **Destination:** `10.0.1.1` (OPNSense) or `10.0.20.2` (TrueNAS)

These rules are already specified in Section 1.10 (Firewall Rules).

## Quick Reference: DNS Configuration Summary

| Service | IP Address | Purpose | Accessible From |
|---------|------------|---------|-----------------|
| Unbound DNS | 10.0.1.1 | Primary DNS resolver | All VLANs |
| TrueNAS Bind9 | 10.0.20.2 | OKD cluster DNS | All VLANs (via forwarding) |
| Public DNS | 1.1.1.1, 8.8.8.8 | External DNS fallback | Via Unbound forwarding |

## Troubleshooting

### "Unbound not starting"
- **Check:** Services → Unbound DNS → Status
- **Check:** System → Log Files → General for Unbound errors
- **Verify:** Port 53 is not in use by another service
- **Verify:** All VLAN interfaces are properly configured

### "Cannot resolve okd.lab domains"
- **Verify:** Domain override is configured correctly
- **Test:** Direct query to TrueNAS: `dig @10.0.20.2 api.okd.lab`
- **Check:** Firewall rules allow DNS queries to 10.0.20.2
- **Verify:** TrueNAS Bind9 is running and accessible

### "Cannot resolve external domains"
- **Verify:** DNS Query Forwarding is enabled
- **Check:** Upstream DNS servers are correct (1.1.1.1, 8.8.8.8)
- **Test:** Direct query: `dig @10.0.1.1 google.com`
- **Check:** WAN interface is working (Unbound needs internet for external queries)

### "DNS queries timing out"
- **Check:** Firewall rules allow UDP port 53
- **Verify:** Unbound is listening on all VLAN interfaces
- **Test:** From client: `nslookup google.com 10.0.1.1`
- **Check:** System → Log Files → General for Unbound errors

### "Wrong DNS server being used"
- **Verify:** KEA DHCP is handing out correct DNS servers (10.0.20.2, 10.0.1.1)
- **Check:** Device network settings to see which DNS servers are configured
- **Test:** `nslookup` without arguments to see default DNS server

## Important Notes

1. **DNS Hierarchy:**
   - Clients query Unbound DNS (10.0.1.1)
   - Unbound forwards `okd.lab` queries to TrueNAS Bind9 (10.0.20.2)
   - Unbound forwards other queries to public DNS (1.1.1.1, 8.8.8.8)

2. **DHCP DNS Configuration:**
   - KEA DHCP hands out: `10.0.20.2, 10.0.1.1` as DNS servers
   - Clients try TrueNAS first, then OPNSense Unbound
   - This provides redundancy

3. **Domain Forwarding:**
   - `okd.lab` domain queries are forwarded to TrueNAS Bind9
   - All other queries go to public DNS via Unbound

## Next Steps

After configuring Unbound DNS:

1. ✅ **Test DNS resolution** from devices on each VLAN
2. ✅ **Verify OKD domain resolution** works (`api.okd.lab`, `*.apps.okd.lab`)
3. ✅ **Section 1.10:** Configure Firewall Rules (if not already done)
4. ✅ **Section 1.12:** Configure NAT/Outbound rules

