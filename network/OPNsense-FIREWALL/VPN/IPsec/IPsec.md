# VPN: IPsec

## Status

**IPsec VPN:** Disabled (not configured)

## Configuration

**Tunnels:** None configured
**Pre-Shared Keys:** None defined
**Mobile Clients:** Not configured

## About IPsec

IPsec (Internet Protocol Security) is a mature, standards-based VPN protocol that:
- Operates at the network layer (Layer 3)
- Widely supported across platforms and vendors
- Strong encryption and authentication
- Two modes: Tunnel mode and Transport mode
- Supports both site-to-site and remote access

## IPsec Modes

### Tunnel Mode (Site-to-Site)
- Encrypts entire IP packet
- Creates secure tunnel between networks
- Common for connecting branch offices, data centers
- Both sites need static IPs or DDNS

### Transport Mode (Host-to-Host)
- Encrypts only packet payload
- Used for end-to-end encryption
- Less overhead than tunnel mode
- Common for specific service protection

## Authentication Methods

**Pre-Shared Key (PSK):**
- Simplest to configure
- Shared secret on both sides
- Less secure than certificates
- Good for homelab use

**X.509 Certificates:**
- Most secure method
- Requires PKI infrastructure
- Better for enterprise
- Can use ACME certificates

**Extended Authentication (XAuth):**
- Adds user authentication to PSK
- Username/password in addition to PSK
- Common for mobile clients

## Typical Use Cases

**Site-to-Site VPN:**
- Connect homelab to cloud VPS
- Link homelab to remote office
- Redundant WAN connections
- Access to remote networks

**Mobile/Remote Access:**
- iOS/Android native IPsec support
- Windows built-in VPN client
- Access homelab from anywhere
- No client software needed

**Secure Service Access:**
- Encrypted access to internal services
- Alternative to port forwarding
- DMZ-to-LAN access

## Configuration Steps (When Needed)

### Site-to-Site VPN

1. **Create Tunnel**
   - Navigate to **VPN > IPsec > Tunnel Settings**
   - Configure Phase 1 (IKE - Internet Key Exchange)
   - Configure Phase 2 (ESP - Encapsulating Security Payload)

2. **Phase 1 (IKE) Settings:**
   - Authentication method: PSK or Certificate
   - Encryption: AES-256
   - Hash: SHA256 or higher
   - DH Group: 14 or higher
   - Lifetime: 28800 seconds

3. **Phase 2 (ESP) Settings:**
   - Protocol: ESP
   - Encryption: AES-256-GCM or AES-256 + SHA256
   - PFS Group: 14 or higher
   - Lifetime: 3600 seconds
   - Local/Remote networks

4. **Firewall Rules:**
   - Allow IPsec traffic (UDP 500, 4500)
   - Create rules on IPsec interface
   - Define allowed traffic between sites

### Mobile Clients (IKEv2)

1. **Configure Mobile Client Support:**
   - Enable IKEv2
   - Create user authentication (XAuth or EAP)
   - Configure address pool
   - Generate client configurations

2. **Client Pool:**
   - Suggested: 10.0.99.0/24
   - Assign DNS servers
   - Define split-tunnel routes

---

## Integration with Current Setup

**Potential Use Cases:**

**Cloud Integration:**
- VPN to cloud VPS for external services
- Encrypted tunnel for outbound traffic
- Access homelab from cloud resources

**Remote OKD Access:**
- Secure access to OpenShift cluster
- No need to expose ports publicly
- VPN into OKDInfra VLAN (10.0.20.0/24)

**IoT Security:**
- VPN access to surveillance cameras
- Encrypted access to IOT devices
- No port forwarding needed

---

## Comparison: IPsec vs WireGuard

| Feature | IPsec | WireGuard |
|---------|-------|-----------|
| Configuration | Complex | Simple |
| Performance | Good | Excellent |
| Mobile Support | Native | Requires app |
| Standards | Industry standard | Modern/Emerging |
| Firewall Traversal | Good (NAT-T) | Excellent |
| Codebase Size | Large | Minimal |
| Best For | Enterprise, site-to-site | Personal, cloud |

---

## Recommendations

**For Homelab Use:**
- **WireGuard** for personal remote access (simpler, faster)
- **IPsec** for site-to-site to commercial sites (broader compatibility)
- Use **IPsec IKEv2** if native mobile support is priority
- Consider **WireGuard** for OKD/OpenShift cluster access

---

**Last Updated:** December 26, 2024
**Configuration Source:** config-firewall.claffey.cloud-20251226200007.xml
