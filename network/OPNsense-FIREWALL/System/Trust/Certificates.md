# System: Trust: Certificates

## Certificate Authorities

### R12 (Let's Encrypt)
**Certificate Reference:** 6928bb990d8ef
**Issuer:** Let's Encrypt - ISRG Root X1
**Type:** External CA (imported)
**Purpose:** ACME client validation chain

**Used By:**
- ACME client certificate renewals
- Let's Encrypt wildcard certificate validation

---

## Server Certificates

### *.claffey.cloud (Active Web GUI)
**Certificate Reference:** 6928bb990f8db
**Type:** ACME/Let's Encrypt
**Key Type:** RSA 4096-bit
**Certificate Authority:** R12 (Let's Encrypt)

**Subject Alternative Names:**
- *.claffey.cloud (wildcard)
- claffey.cloud (apex domain)

**Validity:**
- Auto-renewal: Enabled
- Renewal interval: 60 days
- Next renewal: Automatic via ACME

**Current Usage:**
- Web GUI HTTPS (port 4443)
- OPNsense administration interface

**Benefits:**
- Browser-trusted certificate (no warnings)
- Covers all subdomains (*.claffey.cloud)
- Automatic renewal (no manual intervention)
- Free from Let's Encrypt

---

### Web GUI TLS certificate (Backup #1)
**Certificate Reference:** 69242c03e6186
**Type:** Self-signed
**Subject:** OPNsense.internal
**Key Type:** RSA 2048-bit

**Purpose:** Backup certificate for Web GUI if ACME renewal fails

**Status:** Not currently in use (ACME cert active)

---

### Web GUI TLS certificate (Backup #2)
**Certificate Reference:** 69242d7de4897
**Type:** Self-signed
**Subject:** OPNsense.internal
**Key Type:** RSA 2048-bit

**Purpose:** Additional backup/fallback certificate

**Status:** Not currently in use

---

## ACME Client Configuration

### Account Settings

**Account Name:** Configured
**Email:** (configured - see OPNsense UI)
**Certificate Authority:** Let's Encrypt (Production)
**Account Status:** Active
**Last Verified:** December 27, 2024

**Purpose:** ACME account credentials for Let's Encrypt certificate operations

---

### DNS Validation (Cloudflare)

**Validation Method:** DNS-01 Challenge
**DNS Provider:** Cloudflare (dns_cf)

**Configuration:**
- Cloudflare Account ID: (configured in OPNsense)
- Cloudflare API Token: (configured in OPNsense)

**How It Works:**
1. ACME client requests certificate from Let's Encrypt
2. Let's Encrypt challenges ownership via DNS
3. ACME client uses Cloudflare API to create TXT record
4. Let's Encrypt verifies DNS record
5. Certificate issued and installed
6. Process repeats every 60 days for renewal

**Advantages of DNS-01:**
- Works without opening ports
- Can issue wildcard certificates
- No need for HTTP access
- Firewall can be completely closed

---

## Certificate Lifecycle

### Current Status
**Active Certificate:** *.claffey.cloud (ACME)
**Expiration Monitoring:** Automated via ACME plugin
**Renewal:** Automatic (60-day interval)
**Backup Certificates:** 2 self-signed certs available

### Renewal Process
1. ACME plugin checks certificate age daily
2. When 60 days remaining, initiates renewal
3. DNS challenge created via Cloudflare API
4. New certificate obtained from Let's Encrypt
5. Certificate automatically installed
6. Web GUI reloaded with new certificate

### Failover
If ACME renewal fails:
- Web GUI continues with expired cert (warning)
- Manual intervention required
- Can switch to self-signed backup temporarily

---

## Certificate Usage Recommendations

### Internal Services
**Recommendation:** Use self-signed or internal CA
- OKD/OpenShift cluster
- TrueNAS management
- Internal applications
- Service-to-service communication

**Reason:** No external validation needed, faster deployment

### External Services
**Recommendation:** Use ACME/Let's Encrypt
- Published web services
- Remote access portals
- Public-facing applications
- Anything accessed from internet

**Reason:** Browser trust, no certificate warnings

### VPN
**Recommendation:** Self-signed or internal CA
- OpenVPN server
- IPsec authentication
- Client certificates
- Site-to-site VPN

**Reason:** VPN clients configured to trust specific CA

---

## Creating Additional Certificates

### Self-Signed Certificate
1. Navigate to **System > Trust > Certificates**
2. Click **+** to add certificate
3. Method: Create internal certificate
4. Descriptive name: Service name
5. Certificate type: Server certificate
6. Key type: RSA 2048 or 4096
7. Digest algorithm: SHA256
8. Lifetime: 365-3650 days
9. Common name: service.claffey.cloud
10. Alternative names: Additional DNS names

### ACME Certificate
1. Navigate to **Services > ACME Client > Accounts**
2. Verify account is active
3. Navigate to **Certificates**
4. Add new certificate
5. Select account and validation method
6. Domain name: service.claffey.cloud
7. Enable auto-renewal
8. Set renewal interval (60 days)

---

## Security Best Practices

**Private Key Protection:**
- Private keys stored encrypted on firewall
- Never export private keys unless necessary
- Use strong passphrases for exported keys
- Regenerate keys if compromised

**Certificate Rotation:**
- Use automatic renewal for ACME certs
- Plan rotation for long-lived certificates
- Monitor expiration dates
- Test renewal process periodically

**Key Strength:**
- Minimum RSA 2048-bit
- Prefer RSA 4096-bit for long-lived certs
- Consider EC keys (P-256, P-384) for performance
- Use SHA256 or higher for signatures

**Monitoring:**
- Check ACME renewal logs regularly
- Verify certificates before expiration
- Test certificate chain validation
- Monitor for CA/Browser Forum changes

---

## Troubleshooting

**ACME Renewal Fails:**
1. Check Cloudflare API token is valid
2. Verify DNS records are managed by Cloudflare
3. Review ACME client logs
4. Test Cloudflare API connectivity
5. Check Let's Encrypt status page

**Certificate Not Trusted:**
1. Verify certificate chain is complete
2. Check CA certificate is imported
3. Ensure intermediate certificates included
4. Validate certificate dates
5. Check certificate revocation status

**Wrong Certificate Displayed:**
1. Check Web GUI SSL certificate setting
2. Verify certificate reference ID
3. Clear browser SSL cache
4. Check for multiple certificates with same CN
5. Restart Web GUI service

---

**Last Updated:** December 26, 2024
**Configuration Source:** config-firewall.claffey.cloud-20251226200007.xml
