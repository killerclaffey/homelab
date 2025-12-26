# System: Settings: Administration

## Web GUI Configuration

**Protocol:** HTTPS
**Port:** 4443 (non-standard for security)
**SSL Certificate:** *.claffey.cloud (ACME/Let's Encrypt wildcard)
**SSL Certificate Reference:** 6928bb990f8db

**Access Settings:**
- Interfaces: All (accessible from any interface)
- Compression: Disabled
- SSL Ciphers: Default

## Console Settings

**Console Menu:** Disabled
**Primary Console:** Video
**Virtual Terminal:** Enabled
**Serial Speed:** 115200 baud

## Secure Shell (SSH)

**Status:** Enabled

**Access Control:**
- Interfaces: LAN only (restricted for security)
- Permitted group: admins

**Authentication:**
- Password authentication: Enabled
- Root login: Permitted
- Permit empty passwords: No

**Security Settings:**
- Key exchange algorithms: Default
- Ciphers: Default
- MACs: Default
- Host keys: Default
- Key signature algorithms: Default
- Rekey limit: Default

## User and Group Management

### Administrators Group
- **Group Name:** admins
- **GID:** 1999
- **Scope:** System
- **Description:** System Administrators
- **Privileges:** page-all (full access to all pages)
- **Members:** root (UID 0)

### Root User
- **UID:** 0
- **Scope:** System
- **Description:** System Administrator
- **2FA/OTP:** Enabled
- **OTP Seed:** Configured (HBUPHN4FOSZHF2KWJDJOTAOAMEYAOVIP)
- **Shell Access:** Enabled
- **Password:** Encrypted (bcrypt)
- **API Keys:** None configured

## Backup Settings

**Configuration Backups:**
- Backup count: 5 (local backups retained)
- RRD data backup: Disabled
- Netflow backup: Disabled

See [System: Configuration: Backups](../Configuration/Backups.md) for Git backup configuration.

---

**Last Updated:** December 26, 2024
**Configuration Source:** config-firewall.claffey.cloud-20251226200007.xml
