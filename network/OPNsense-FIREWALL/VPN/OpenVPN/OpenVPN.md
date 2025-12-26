# VPN: OpenVPN

## Status

**OpenVPN:** Not configured

## Configuration

**Servers:** None configured
**Clients:** None configured
**Client Specific Overrides:** None defined

## About OpenVPN

OpenVPN is a mature, open-source VPN solution that:
- Uses SSL/TLS for encryption and authentication
- Highly configurable and flexible
- Excellent firewall traversal (TCP mode)
- Cross-platform support
- Large user base and extensive documentation

## OpenVPN Modes

### Server Modes

**SSL/TLS + User Auth:**
- Certificate-based authentication
- Additional username/password
- Most secure option
- Recommended for production

**SSL/TLS:**
- Certificate-based only
- No username/password
- Good for site-to-site
- Simpler user management

**Static Key:**
- Shared secret
- Point-to-point only
- Less secure
- Simple site-to-site

### Network Modes

**Routed (TUN):**
- Layer 3 (IP routing)
- More efficient
- Can't bridge networks
- Best for most use cases

**Bridged (TAP):**
- Layer 2 (Ethernet bridging)
- Can pass non-IP protocols
- More overhead
- Needed for broadcast/multicast

---

## Protocol Options

**UDP (Recommended):**
- Faster performance
- Lower latency
- Better for real-time applications
- May have NAT traversal issues

**TCP (Fallback):**
- Better firewall traversal
- Works through restrictive networks
- Higher overhead
- More reliable delivery

**Recommended Ports:**
- UDP 1194 (default)
- TCP 443 (disguised as HTTPS)

---

## Typical Use Cases

**Remote Access:**
- Connect from any device
- Access homelab services
- Mobile worker access
- Travel security

**Site-to-Site:**
- Connect multiple locations
- Persistent always-on tunnels
- Branch office connectivity
- Redundant WAN paths

**Multi-Site Mesh:**
- Multiple interconnected sites
- Complex routing scenarios
- Hub-and-spoke topology

---

## Configuration Steps (When Needed)

### Server Setup

1. **Certificate Authority**
   - Navigate to **System > Trust > Authorities**
   - Create CA for OpenVPN
   - Or use existing ACME CA

2. **Server Certificate**
   - Navigate to **System > Trust > Certificates**
   - Create server certificate
   - Sign with OpenVPN CA

3. **OpenVPN Server Instance**
   - Navigate to **VPN > OpenVPN > Servers**
   - Create new server
   - Configure protocol, port, encryption

4. **Server Configuration:**
   - Protocol: UDP4
   - Port: 1194
   - Encryption: AES-256-GCM
   - Auth Digest: SHA256
   - Tunnel Network: 10.0.99.0/24
   - Local Network: 10.0.0.0/8

5. **Client Certificates**
   - Create certificate per client
   - Export client configuration
   - Distribute to users

6. **Firewall Rules**
   - Allow OpenVPN on WAN (UDP 1194)
   - Create OpenVPN interface rules
   - Define client access policies

---

## Client Export

**Client Export Plugin:** os-openvpn-export

Navigate to **VPN > OpenVPN > Client Export**
- Automatically generate client configs
- Include embedded certificates
- Support for Windows, macOS, Linux, mobile
- Inline or separate certificate files

---

## Integration with Current Setup

### Recommended Configuration

**Tunnel Network:** 10.0.99.0/24 (Guest network range)
**DNS Server:** 10.0.0.1 (Unbound)
**Domain:** claffey.cloud

**Push Routes:**
- 10.0.0.0/20 (LAN)
- 10.0.20.0/24 (OKD Infra) - if needed
- 10.0.30.0/24 (OKD Storage) - if needed

**Client Access Policy:**
- Allow DNS queries to firewall
- Allow Web GUI access (10.0.0.1:4443)
- Allow access to specific services
- Block sensitive VLANs by default

### Advanced Features

**Multi-Factor Authentication:**
- Integrate with TOTP/Google Authenticator
- Require certificate + password + OTP
- Extra security layer

**Client-Specific Overrides:**
- Assign static IPs to specific clients
- Different routing per client
- Custom firewall rules per client

**Compression:**
- LZ4 compression (modern)
- Reduces bandwidth
- Slight CPU overhead

---

## Comparison with Other VPN Options

| Feature | OpenVPN | WireGuard | IPsec |
|---------|---------|-----------|-------|
| Configuration | Moderate | Simple | Complex |
| Performance | Good | Excellent | Good |
| Firewall Traversal | Excellent | Good | Good |
| Client Software | Required | Required | Often native |
| Flexibility | Very High | Moderate | Moderate |
| Maturity | Very mature | Modern | Very mature |
| Best For | Restrictive networks | Speed/simplicity | Enterprise |

---

## Recommendations

**Choose OpenVPN if:**
- Need to traverse restrictive corporate firewalls (TCP 443)
- Require maximum flexibility and features
- Want built-in client certificate management
- Need client-specific configurations

**Choose WireGuard if:**
- Want simplest setup and best performance
- Mobile/roaming clients
- Don't need complex routing

**Choose IPsec if:**
- Need native client support (no apps)
- Enterprise site-to-site requirements
- Standards compliance is critical

---

**Last Updated:** December 26, 2024
**Configuration Source:** config-firewall.claffey.cloud-20251226200007.xml
