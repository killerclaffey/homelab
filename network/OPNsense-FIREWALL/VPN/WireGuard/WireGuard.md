# VPN: WireGuard

## Status

**WireGuard VPN:** Disabled (not configured)

## Configuration

**Servers:** None configured
**Peers:** None configured
**Endpoints:** None defined

## About WireGuard

WireGuard is a modern, high-performance VPN protocol that:
- Uses state-of-the-art cryptography (Curve25519, ChaCha20, Poly1305)
- Extremely lightweight and fast
- Simple configuration compared to IPsec/OpenVPN
- Built into modern Linux kernels
- Cross-platform support (Windows, macOS, Linux, iOS, Android)

## Typical Use Cases

**Remote Access VPN:**
- Connect from mobile devices
- Access homelab from anywhere
- Secure connection to internal services

**Site-to-Site VPN:**
- Connect multiple locations
- Link homelab to cloud infrastructure
- Create distributed networks

**Service Access:**
- Secure access to OPNsense Web GUI
- Access to internal-only services
- Alternative to port forwarding for security

## Configuration Steps (When Needed)

### 1. Create Local Instance
Navigate to **VPN > WireGuard > Local**
- Create new WireGuard instance
- Generate private/public key pair
- Assign listen port (default: 51820)
- Configure tunnel addresses

### 2. Add Peers
Navigate to **VPN > WireGuard > Peers**
- Add peer for each client/site
- Configure peer public keys
- Set allowed IPs (networks accessible through peer)
- Optional: Set endpoint for site-to-site

### 3. Configure Endpoint
Navigate to **VPN > WireGuard > Endpoints**
- Assign peer to local instance
- Configure routing
- Set interface parameters

### 4. Firewall Rules
Create rules on WireGuard interface:
- Allow VPN clients to access specific networks
- Allow access to firewall services (DNS, etc.)
- Implement security policies

### 5. Port Forward (If Behind NAT)
- Forward UDP port 51820 to firewall
- Required for incoming VPN connections

## Client Configuration Example

```ini
[Interface]
PrivateKey = <client-private-key>
Address = 10.0.99.10/24
DNS = 10.0.0.1

[Peer]
PublicKey = <opnsense-public-key>
Endpoint = firewall.claffey.cloud:51820
AllowedIPs = 10.0.0.0/8, 172.16.0.0/28
PersistentKeepalive = 25
```

## Recommended Network Allocation

**Suggested VPN Network:** 10.0.99.0/24 (Guest network range currently unassigned)

This provides:
- 254 usable addresses for VPN clients
- Separate from production networks
- Easy to implement firewall rules for isolation

## Integration with Current Setup

**Benefits for Homelab:**
- Secure remote access to OPNsense Web GUI (port 4443)
- Access OKD/OpenShift services without port forwards
- Connect to TrueNAS (10.0.0.142) remotely
- Access internal services (Scrutiny, monitoring, etc.)
- Secure alternative to exposing services directly

**Recommended Firewall Rules:**
- Allow WireGuard clients to reach LAN DNS (10.0.0.1)
- Allow access to Web GUI (10.0.0.1:4443)
- Block access to sensitive VLANs (OKDStorage, Helium)
- Allow specific service access as needed

---

**Last Updated:** December 26, 2024
**Configuration Source:** config-firewall.claffey.cloud-20251226200007.xml
