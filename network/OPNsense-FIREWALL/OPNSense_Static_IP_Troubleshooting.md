# OPNSense Static IP Troubleshooting Guide

This guide helps troubleshoot issues where static IPs don't work on OPNSense interfaces, but DHCP does.

## Common Causes

1. **Interface not set to Static IPv4** - Interface might still be set to DHCP
2. **DHCP service conflict** - DHCP service might be interfering
3. **Interface not enabled** - Interface might be disabled
4. **Firewall rules blocking** - Firewall might be blocking the static IP
5. **IP conflict** - Another device might have the same IP
6. **Interface assignment issue** - Interface might not be properly assigned

---

## Step 1: Verify Interface Configuration

### Check Interface Assignment

**Location:** Interfaces → Assignments

1. Navigate to: **Interfaces → Assignments**
2. Find your LAN interface (might be listed as `LAN`, `OPT1`, or similar)
3. **Click on the interface name** to edit it

### Verify Interface Settings

**Location:** Interfaces → [Your LAN Interface]

Check these settings:

| Field | Should Be | Notes |
|-------|-----------|-------|
| **Enable interface** | ☑ Checked | Interface must be enabled |
| **IPv4 Configuration Type** | `Static IPv4` | **Critical** - Must be Static, not DHCP |
| **IPv4 Address** | Your desired IP (e.g., `10.0.1.2`) | Must be in correct subnet |
| **IPv4 Subnet** | Correct subnet (e.g., `24` for /24) | Must match your network |
| **Block private networks** | ☐ Unchecked | Usually leave unchecked for LAN |
| **Block bogon networks** | ☐ Unchecked | Usually leave unchecked for LAN |

**Critical:** If "IPv4 Configuration Type" is set to "DHCP" or "None", change it to "Static IPv4"

### Save and Apply

1. Click **Save**
2. Click **Apply Changes** (if prompted)
3. Wait for changes to apply

---

## Step 2: Check for DHCP Service Conflict

### Disable DHCP on the Interface

**Location:** Services → DHCPv4 → [Your LAN Interface]

1. Navigate to: **Services → DHCPv4**
2. Find your LAN interface in the list
3. **Uncheck "Enable"** if it's enabled
4. Click **Save**
5. Click **Apply Changes**

**Why:** If DHCP service is running on the interface, it might be interfering with static IP configuration.

---

## Step 3: Verify Interface Status

### Check Interface Status

**Location:** Interfaces → Overview

1. Navigate to: **Interfaces → Overview**
2. Find your LAN interface
3. Check:
   - **Status:** Should show "up" or "active"
   - **IP Address:** Should show your static IP
   - **Link:** Should show "up"

### Check from Command Line (Optional)

**Location:** System → Shell or SSH to OPNSense

```bash
# Check interface status
ifconfig

# Look for your LAN interface (might be igc1, igc2, etc.)
# Should show your static IP address

# Check routing table
netstat -rn

# Should show route for your LAN subnet
```

---

## Step 4: Check for IP Conflicts

### Ping Test

**From OPNSense Shell:**

```bash
# Ping your static IP from OPNSense
ping -c 3 10.0.1.2

# If you get responses, another device has that IP
```

### ARP Table Check

```bash
# Check ARP table
arp -a

# Look for your static IP - if it shows a different MAC address, there's a conflict
```

### Solution if Conflict Found

1. Change your static IP to a different address
2. Or find and change the conflicting device's IP
3. Make sure static IP is outside DHCP range

---

## Step 5: Check Firewall Rules

### Verify Firewall Rules Exist

**Location:** Firewall → Rules → [Your LAN Interface]

1. Navigate to: **Firewall → Rules**
2. Select your LAN interface tab
3. Verify there are rules allowing traffic:
   - At minimum, should allow traffic to the interface network
   - Should allow established/related connections

### Default Rule Check

**Location:** Firewall → Rules → [Your LAN Interface]

- There should be a default "allow" rule or specific rules
- If there's only a "block" rule, that's the problem

---

## Step 6: Check Interface Assignment

### Verify Interface is Assigned

**Location:** Interfaces → Assignments

1. Your LAN interface should be listed
2. It should have a name (like `LAN`, `OPT1`, etc.)
3. If it shows as "Available" or unassigned, that's the problem

### Re-assign Interface (If Needed)

1. If interface is not assigned:
   - Click **"+"** to add interface
   - Select the physical interface
   - Configure as Static IPv4
   - Enable the interface

---

## Step 7: Network Configuration Verification

### Verify Subnet Configuration

Make sure your static IP matches your network:

| Your Network | Static IP Should Be | Subnet |
|--------------|---------------------|--------|
| 10.0.1.0/24 | 10.0.1.x | /24 (255.255.255.0) |
| 192.168.1.0/24 | 192.168.1.x | /24 (255.255.255.0) |

**Example:**
- If your network is `10.0.1.0/24`
- Static IP should be `10.0.1.2` (or any .1-.254, avoiding .1 which is usually gateway)
- Subnet should be `/24` or `255.255.255.0`

---

## Step 8: Reset Interface (Last Resort)

### Disable and Re-enable Interface

1. **Disable Interface:**
   - Interfaces → [Your LAN Interface]
   - Uncheck "Enable interface"
   - Click Save → Apply Changes

2. **Wait 10 seconds**

3. **Re-enable Interface:**
   - Check "Enable interface"
   - Verify all settings are correct
   - Click Save → Apply Changes

### Restart Interface from Shell

```bash
# Find your interface name
ifconfig

# Restart the interface (replace igc1 with your interface)
ifconfig igc1 down
ifconfig igc1 up

# Or restart all interfaces
/etc/rc.restart_networking
```

---

## Common Scenarios

### Scenario 1: Interface Shows DHCP Instead of Static

**Symptom:** Interface configuration shows "DHCP" as IPv4 Configuration Type

**Solution:**
1. Change to "Static IPv4"
2. Enter your static IP and subnet
3. Save and Apply Changes

---

### Scenario 2: Interface Not Enabled

**Symptom:** Interface shows as "down" or "inactive"

**Solution:**
1. Interfaces → [Your LAN Interface]
2. Check "Enable interface"
3. Save and Apply Changes

---

### Scenario 3: DHCP Service Running

**Symptom:** DHCP service is enabled on the interface

**Solution:**
1. Services → DHCPv4 → [Your LAN Interface]
2. Uncheck "Enable"
3. Save and Apply Changes

---

### Scenario 4: IP Address Conflict

**Symptom:** Another device has the same IP

**Solution:**
1. Find the conflicting device
2. Change its IP or change your static IP
3. Ensure static IP is outside DHCP range

---

### Scenario 5: Wrong Subnet Mask

**Symptom:** IP is in wrong subnet

**Solution:**
1. Verify your network's subnet mask
2. Set correct subnet in interface configuration
3. Example: If network is 10.0.1.0/24, use subnet 24

---

## Verification Checklist

After configuring static IP:

- [ ] Interface is enabled
- [ ] IPv4 Configuration Type is "Static IPv4" (not DHCP)
- [ ] Static IP address is entered correctly
- [ ] Subnet mask is correct
- [ ] IP address is in the correct subnet
- [ ] IP address is not in DHCP range
- [ ] No IP conflict (ping test passes)
- [ ] DHCP service is disabled on this interface (if not needed)
- [ ] Changes were saved and applied
- [ ] Interface shows as "up" in Interfaces → Overview
- [ ] Can ping gateway from OPNSense
- [ ] Can ping static IP from another device

---

## Testing Static IP

### From OPNSense

**Location:** System → Shell

```bash
# Check interface has static IP
ifconfig

# Should show your static IP on the interface

# Ping gateway
ping -c 3 10.0.1.1

# Should get responses
```

### From Another Device

```bash
# Ping OPNSense static IP
ping 10.0.1.2

# Should get responses

# Traceroute to verify routing
traceroute 10.0.1.2
```

---

## Still Not Working?

### Check System Logs

**Location:** System → Log Files → General

1. Look for interface-related errors
2. Look for DHCP-related errors
3. Look for network configuration errors

### Check Interface Logs

**Location:** Interfaces → [Your LAN Interface] → Log

1. Check for interface-specific errors
2. Look for configuration issues

### Reset to Defaults (Last Resort)

**Warning:** This will reset interface configuration

1. Interfaces → [Your LAN Interface]
2. Remove interface assignment
3. Re-assign interface
4. Configure from scratch with static IP

---

## Quick Diagnostic Commands

Run these from OPNSense Shell to diagnose:

```bash
# Show all interfaces
ifconfig -a

# Show routing table
netstat -rn

# Show ARP table
arp -a

# Test connectivity
ping -c 3 10.0.1.1

# Check DHCP service status
ps aux | grep dhcp

# Check interface status
ifconfig igc1  # Replace igc1 with your interface
```

---

## Most Common Issue

**The most common issue is that the interface is still set to "DHCP" instead of "Static IPv4".**

**Quick Fix:**
1. Go to: Interfaces → [Your LAN Interface]
2. Change "IPv4 Configuration Type" from "DHCP" to "Static IPv4"
3. Enter your static IP and subnet
4. Click Save → Apply Changes

---

## Need More Help?

If static IP still doesn't work after trying these steps:

1. **Document the issue:**
   - What interface are you configuring?
   - What static IP are you trying to set?
   - What error messages do you see?
   - What does "Interfaces → Overview" show?

2. **Check OPNSense documentation:**
   - Official OPNSense documentation
   - OPNSense forums

3. **Check system logs:**
   - System → Log Files → General
   - Look for relevant error messages

