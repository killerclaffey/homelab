# Services: Monitoring: Monit

## Status

**Monit System Monitoring:** Disabled (configured but not active)

## General Settings

**Monitoring Interval:** 120 seconds (default)
**Start Delay:** 120 seconds (default)
**Log File:** /var/log/monit.log
**State File:** /var/run/monit.state
**Event Queue:** Enabled

## Configured Services

### System Monitoring ($HOST)

**Service Name:** $HOST
**Type:** System
**Status:** Configured

**Monitored Resources:**
- System load average
- CPU usage
- Memory usage
- Filesystem space

---

### Root Filesystem Monitoring

**Service Name:** RootFs
**Type:** Filesystem
**Path:** /
**Status:** Configured

**Alert Threshold:**
- Space usage > 75%

---

## Alert Configuration

### Alert Recipient
**Email Address:** Configured (not shown for security)
**Alert Events:** All monitored services

### Alert Conditions

**Memory Usage:**
- Threshold: > 75%
- Action: Alert

**CPU Usage:**
- Threshold: > 75% for 2 cycles
- Action: Alert

**Load Average:**
- 1-minute: > 8.0
- 5-minute: > 6.0
- 15-minute: > 4.0
- Action: Alert

**Filesystem Space:**
- Threshold: > 75%
- Action: Alert

## Email Notification Settings

**SMTP Server:** Not configured
**Port:** Default (25 or 587)
**Authentication:** Not configured
**TLS/SSL:** Not configured

**Note:** Email alerts will not function until SMTP settings are configured.

## Web Interface

**Status:** Not enabled
**Port:** 2812 (default)
**Authentication:** Not configured

## Additional Monitored Services

No additional services (SSH, Unbound, HAProxy, etc.) are currently configured for monitoring.

## Why Disabled?

Monit is configured but disabled, likely due to:
1. **No SMTP Configuration:** Cannot send email alerts
2. **Alternative Monitoring:** Using external monitoring (Prometheus, Grafana, etc.)
3. **Resource Overhead:** Minimal benefit for homelab without alerting
4. **Testing Phase:** Configuration exists for future use

## Enabling Monit

To enable Monit monitoring:

1. Navigate to **Services > Monit > Settings**
2. Configure SMTP server for email alerts (optional)
3. Check "Enable Monit" box
4. Review configured services and thresholds
5. Apply changes
6. Monitor **/var/log/monit.log** for activity

## Recommended Additional Monitors

Consider adding monitoring for:
- **Unbound DNS:** Check if DNS service is responding
- **SSH:** Monitor SSH service availability
- **Kea DHCP:** Verify DHCP server is running
- **Network Interfaces:** Monitor interface status and throughput
- **Temperature:** Monitor system temperature (if sensors available)

---

**Last Updated:** December 26, 2024
**Configuration Source:** config-firewall.claffey.cloud-20251226200007.xml
