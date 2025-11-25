```markdown
# Migration Plan: Dnsmasq → Kea + Unbound (Zero Downtime)

## Strategy Overview

We'll migrate in two phases to minimize risk:
1. **Phase 1:** Migrate DNS (Dnsmasq → Unbound) while keeping DHCP on Dnsmasq
2. **Phase 2:** Migrate DHCP (Dnsmasq → Kea) after DNS is stable

This way we're only changing one service at a time.

---

## PHASE 1: Migrate DNS (Dnsmasq → Unbound)

### Step 1: Document Current Dnsmasq Configuration

1. Go to **Services → Dnsmasq → Settings**
2. Take screenshots or note down:
   - Upstream DNS servers being used
   - Any custom host overrides
   - Any domain overrides
   - Custom options

### Step 2: Configure Unbound (Don't Enable Yet)

1. Go to **Services → Unbound DNS → General**
2. Configure but **DON'T enable yet**:
   - ☑ **Enable Unbound** (we'll save this for later)
   - ☑ **DNSSEC** (recommended)
   - ☑ **DNS Query Forwarding** (if you want to use specific upstream DNS like Cloudflare/Google)
     - If enabled, add your preferred DNS servers (e.g., 1.1.1.1, 8.8.8.8)
   - Network Interfaces: **All** or select specific interfaces

3. Go to **Services → Unbound DNS → Advanced**
   - ☑ **DHCP Registration** (this will allow Unbound to resolve DHCP hostnames once we switch)
   - Hide Identity: ☑ (privacy)
   - Hide Version: ☑ (security)

4. **Don't click Apply yet!**

### Step 3: Migrate Custom DNS Entries

If you have any **Host Overrides** in Dnsmasq:

1. Go to **Services → Unbound DNS → Overrides → Host Overrides**
2. Add each custom entry from Dnsmasq (e.g., `server.lan → 192.168.1.100`)
3. Click **Save** after each entry

### Step 4: Enable Unbound and Disable Dnsmasq DNS

**This is the critical switch - but it's seamless:**

1. Go to **Services → Unbound DNS → General**
   - ☑ **Enable Unbound**
   - Click **Apply**

2. Go to **Services → Dnsmasq → Settings**
   - **Scroll down to the DHCP section - DON'T touch it yet!**
   - Uncheck: ☐ **DNS Forwarder** (or "Enable Dnsmasq")
   - Click **Save**

**What happens:** 
- Clients already have cached DNS responses
- New DNS queries go to Unbound (which is listening on the same firewall IP)
- **No interruption to connectivity**

### Step 5: Verify DNS is Working

From a client machine:
```bash
# Windows
nslookup google.com

# Linux/Mac
dig google.com

# Verify it's resolving correctly
ping google.com
```

Check Unbound is handling queries:
- Go to **Services → Unbound DNS → Diagnostics**
- You should see query statistics increasing

### Step 6: Update Dnsmasq DHCP to Use Unbound

Since Dnsmasq is still handling DHCP, make sure it's handing out the correct DNS server:

1. Go to **Services → Dnsmasq → Settings**
2. In the DHCP section, verify **DNS servers** field points to your OPNsense firewall IP (e.g., `192.168.1.1`)
   - This should already be the case, but verify
3. Click **Save** if you made changes

**Phase 1 Complete!** DNS is now on Unbound. Let this run for a few hours or a day to ensure stability.

---

## PHASE 2: Migrate DHCP (Dnsmasq → Kea)

### Step 7: Document Current Dnsmasq DHCP Configuration

**Critical - document everything:**

1. Go to **Services → Dnsmasq → Settings**
2. Note down **for each interface** (usually LAN):
   - **Enable DHCP** on which interfaces
   - **Range:** Start and End IP (e.g., `192.168.1.100` to `192.168.1.250`)
   - **DNS servers** being handed out
   - **Gateway** 
   - **Domain name** (e.g., `lan` or `home.local`)
   - **Default lease time**
   - **Maximum lease time**

3. Go to **Services → Dnsmasq → DHCP Static Mappings**
   - Export or screenshot ALL static DHCP reservations (MAC → IP mappings)
   - You'll need to recreate these in Kea

### Step 8: Install Kea DHCP Plugin (If Not Already Installed)

1. Go to **System → Firmware → Plugins**
2. Search for **os-kea-dhcp**
3. Click **+** to install if not already installed
4. Wait for installation to complete

### Step 9: Configure Kea DHCP (Don't Enable Yet)

1. Go to **Services → Kea DHCP → Settings**
2. **DO NOT enable yet!**

3. Go to **Services → Kea DHCP → DHCPv4**
4. Click **+** to add a subnet
5. Configure to match your Dnsmasq settings:
   - **Subnet:** Your network (e.g., `192.168.1.0/24`)
   - **Pools:** Click **+** to add a pool
     - **Pool Start:** (e.g., `192.168.1.100`)
     - **Pool End:** (e.g., `192.168.1.250`)
   - **Option Data:** Click **+** to add options:
     - **routers:** Your gateway IP (e.g., `192.168.1.1`)
     - **domain-name-servers:** Your OPNsense IP (e.g., `192.168.1.1`)
     - **domain-name:** Your domain (e.g., `lan`)
   - **Valid Lifetime:** Match Dnsmasq's default lease time (in seconds, e.g., `86400` for 24 hours)
   - **Max Valid Lifetime:** Match Dnsmasq's max lease time

6. Click **Save**

### Step 10: Migrate Static DHCP Reservations

1. In **Services → Kea DHCP → Reservations**
2. Click **+** for each static mapping from Dnsmasq
3. Configure:
   - **Subnet:** Select the subnet you created
   - **IP Address:** The reserved IP
   - **HW Address:** MAC address in format `aa:bb:cc:dd:ee:ff`
   - **Hostname:** Optional but recommended
4. Click **Save** after each

### Step 11: The DHCP Switch (Quick Operation)

**Preparation:**
- Do this during a maintenance window if possible (evening/low usage)
- Have console access to OPNsense in case something goes wrong
- Warn users there might be a brief hiccup

**The Switch:**

1. Go to **Services → Dnsmasq → Settings**
   - Uncheck all **Enable DHCP server on [interface]** options
   - Click **Save**
   - Dnsmasq DHCP is now OFF

2. **Immediately** go to **Services → Kea DHCP → Settings**
   - ☑ **Enable Kea DHCP**
   - Click **Apply**

3. Verify Kea is running:
```bash
# SSH to OPNsense or use console
service kea-dhcp4 status
sockstat -4 -l | grep :67
```

**What happens:**
- Existing DHCP leases remain valid (clients won't notice immediately)
- New DHCP requests (renewals, new devices) go to Kea
- Transition is seamless for most clients

### Step 12: Monitor and Verify

1. Check Kea is issuing leases:
   - Go to **Services → Kea DHCP → Leases**
   - You should see leases appearing as clients renew

2. From a client, force DHCP renewal:
   ```bash
   # Windows
   ipconfig /release
   ipconfig /renew
   
   # Linux
   sudo dhclient -r
   sudo dhclient
   
   # Mac
   sudo ipconfig set en0 DHCP
   ```

3. Verify the client:
   - Got an IP in the correct range
   - Can ping the gateway
   - Can resolve DNS (try `nslookup google.com`)
   - Has internet connectivity

### Step 13: Fully Disable Dnsmasq

Once you've verified everything works (give it at least a few hours):

1. Go to **Services → Dnsmasq → Settings**
2. Uncheck **Enable** at the top (if there's a global enable)
3. Click **Save**

**Optional:** Uninstall Dnsmasq plugin if you want to clean up:
- **System → Firmware → Plugins**
- Find **os-dnsmasq** and click **-** to remove (only if not needed)

---

## Rollback Plan (If Something Goes Wrong)

If Kea has issues:

1. **Services → Kea DHCP → Settings** → Uncheck Enable → Save
2. **Services → Dnsmasq → Settings** → Re-enable DHCP → Save
3. Everything goes back to how it was

---

## Expected Downtime

- **DNS migration (Phase 1):** **0 seconds** - seamless
- **DHCP migration (Phase 2):** **0-30 seconds** during the switch
  - Existing leases continue working
  - Only new DHCP requests might have a brief delay

---

## Post-Migration Checklist

After both phases are complete:

- ✅ All clients can get DHCP leases
- ✅ All clients can resolve DNS
- ✅ Static reservations are working
- ✅ Internet connectivity works
- ✅ Local hostname resolution works (e.g., `ping server.lan`)
- ✅ Check logs for errors: **System → Log Files → General**

---

## Tips for Success

1. **Do Phase 1 first, wait 24 hours, then do Phase 2**
2. **Test with one client** before assuming everything works
3. **Keep the OPNsense console open** during the switch
4. **Do this during low-traffic hours** if possible
5. **Have a backup** of your OPNsense config: **System → Configuration → Backups → Download**
```
