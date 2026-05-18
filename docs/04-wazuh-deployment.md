# Wazuh Deployment & Agent Onboarding

## Overview

Wazuh serves as the SIEM (Security Information and Event Management) platform for this cybersecurity lab, providing centralized log collection, correlation, alerting, and incident response capabilities.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Wazuh Server                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │
│  │   Wazuh     │  │  Filebeat    │  │   Wazuh     │       │
│  │   Indexer   │  │  (Log Ship)  │  │  Dashboard  │       │
│  └──────────────┘  └──────────────┘  └──────────────┘       │
│         │                   │                   │           │
└─────────┼───────────────────┼───────────────────┼───────────┘
          │                   │                   │
          ▼                   ▼                   ▼
┌─────────────────────────────────────────────────────────────┐
│                   Wazuh Manager                              │
│  - Rule evaluation                                           │
│  - Alert generation                                          │
│  - Decoders                                                  │
│  - Active Response (optional)                                │
└─────────────────────────────────────────────────────────────┘
          │
          │ Agent Communication (1514/TCP, 1515/TCP) + Syslog (514/UDP)
          ▼
┌─────────────────────────────────────────────────────────────┐
│                    Agents                                    │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │
│  │   Linux      │  │   Windows    │  │ pfSense     │       │
│  │   Agent      │  │   Agent      │  │  Syslog     │       │
│  │  (auth.log)  │  │  (Security)  │  │ Forwarder   │       │
│  └──────────────┘  └──────────────┘  └──────────────┘       │
└─────────────────────────────────────────────────────────────┘
```

---

## Server Deployment

### Server Information

- **Hostname:** `wazuh-server`
- **IP Address:** `10.10.69.20`
- **Operating System:** Debian or Ubuntu LTS
- **Wazuh Version:** 4.9.x (latest stable release at time of deployment)
- **Deployment Method:** All-in-One install first, split components later only if scale or tuning requires it

This keeps the first deployment simple and matches the rest of the lab, which is already standardized on the `10.10.69.0/24` isolated VLAN behind pfSense.

### Component Versions

- **Wazuh Manager:** v4.9.x (or latest stable)
- **Wazuh Indexer:** OpenSearch (bundled with all-in-one installer)
- **Wazuh Dashboard:** Web UI (bundled with all-in-one installer, default port 443)
- **Filebeat:** Bundled with all-in-one installer

> **Note:** The all-in-one installer handles all component versions automatically. Replace `4.9` in URLs below with the current major.minor version if a newer release is available. Check https://documentation.wazuh.com/current/installation-guide.html for the latest.

### Installation Method

All-In-One installation (single-node deployment for lab scale):
```bash
# Download Wazuh installation script (replace 4.9 with current version)
curl -sO https://packages.wazuh.com/4.9/wazuh-install.sh

# Run installer
bash wazuh-install.sh -a
```

After installation completes, the script outputs the admin password and confirms the dashboard URL (typically `https://10.10.69.20`). Save these credentials.

---

## Agent Onboarding

### General Agent Registration Flow

1. **Generate agent enrollment token** on Wazuh Manager
2. **Install agent** on target system
3. **Configure agent** with manager IP and enrollment token
4. **Verify agent status** in Wazuh Dashboard
5. **Validate log ingestion** in Wazuh events viewer

### Linux Agent (Debian/Ubuntu)

```bash
# Add Wazuh repository (replace 4.x with current major version)
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --dearmor -o /usr/share/keyrings/wazuh.gpg
echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt stable main" | tee /etc/apt/sources.list.d/wazuh.list

# Install agent
apt-get update
apt-get install wazuh-agent

# Configure agent (edit /var/ossec/etc/ossec.conf)
# Set <server><address>10.10.69.20</address></server>

# Start agent
systemctl daemon-reload
systemctl enable wazuh-agent
systemctl start wazuh-agent
```

### Windows Agent

```powershell
# Download Wazuh agent MSI from https://packages.wazuh.com/4.x/windows/
# Install via command line with manager IP
msiexec.exe /i wazuh-agent-<version>.msi /q WAZUH_MANAGER="10.10.69.20" WAZUH_AGENT_GROUP="windows"

# Start agent (auto-starts as service)
# Verify: Get-Service Wazuh
```

### pfSense Agent (Syslog Forwarding)

pfSense does not run a native Wazuh agent. Instead, firewall telemetry is forwarded via syslog. The Wazuh manager has a UDP 514 listener enabled in `ossec.conf` and restricted to the pfSense firewall (`10.10.69.1`). Remote logging is enabled on pfSense and forwards firewall telemetry to `10.10.69.20:514/UDP`.

1. Configure remote syslog in pfSense: Status → System Logs → Settings
2. Set remote log server to Wazuh manager IP (`10.10.69.20`)
3. Use UDP 514
4. Enable Log All mode for forwarded pfSense events
5. Verify ingestion in Wazuh Dashboard → Events viewer

---

## Lab Agent Inventory

| Hostname | IP Address | OS | Agent Type | Log Sources | Status |
|----------|------------|-------|-------------|--------------|--------|
| wazuh-server | 10.10.69.20 | Linux | Manager/Server | All telemetry | ✅ Deployed |
| dc01 | 10.10.69.10 | Windows Server 2022 | Wazuh Agent | Windows Security (4624, 4625, 4672, 4768, 4769), Sysmon | ✅ Enrolled |
| win10-client | DHCP | Windows 10 | Wazuh Agent | Windows Security, Sysmon | ✅ Enrolled |
| win11-client | DHCP | Windows 11 | Wazuh Agent | Windows Security, Sysmon | ✅ Enrolled |
| Debian-Attack | DHCP (typically 10.10.69.50) | Debian | Traffic Generator | Attack simulation activity | N/A |
| pfSense | 10.10.69.1 | pfSense | Syslog Forwarder | Firewall, DHCP, System | ✅ Forwarding to Wazuh |

Current active Wazuh endpoints: `wazuh-server`, `dc01`, `win10-client`, and `win11-client`.

---

## Log Source Configuration

### Windows Security Log Configuration

Advanced audit policies enabled on DC01 and Windows clients:

- **Account Logon:** Credential Validation (Success/Failure)
- **Logon/Logoff:** Logon, Logoff
- **Account Management:** User and Computer Account Management
- **Privilege Use:** Sensitive Privilege Use
- **Directory Service Access:** Directory Service Changes
- **Policy Change:** Audit Policy Change

Validation events:
- 4624: Successful logon
- 4625: Failed logon
- 4672: Privileged logon
- 4768: Kerberos TGT request
- 4769: Kerberos service ticket request

### Linux Log Configuration

Agents monitor:
- `/var/log/auth.log` (Debian/Ubuntu) or `/var/log/secure` (RHEL/CentOS)
- Syslog forwarding enabled
- Custom rules for SSH brute force detection

### Firewall Log Configuration (pfSense)

Wazuh manager and pfSense forwarding status:

- UDP 514: listening for pfSense syslog
- Source restriction: `10.10.69.1` only
- pfSense remote syslog: enabled to `10.10.69.20:514/UDP`
- Forwarded mode: Log All
- Firewall events: flowing into Wazuh telemetry

Log categories to forward:
- Firewall rules (allow/deny)
- NAT traffic
- DHCP assignments
- VPN connections
- System events

---

## Custom Rules

The custom ruleset contains 26 deployed Wazuh rules aligned to seven detection use cases. Rules are maintained in the Wazuh manager local rules configuration and validated with Wazuh rule testing before manager restart.

| Use Case | Rule IDs | Purpose | Status |
|----------|----------|---------|--------|
| UC-001 SSH Brute Force | 100001, 100002, 100003 | SSH failed authentication, brute force correlation, and brute force followed by successful login | ✅ Deployed |
| UC-002 Kerberos RC4 | 100100, 100101 | RC4 Kerberos service ticket detection using Wazuh's Windows 4769 parent rule | ✅ Deployed |
| UC-003 Lateral Movement | 100200, 100201, 100400, 100401 | pfSense `filterlog` base rule, multi-destination scan, port sweep, and port scan correlation | ✅ Deployed |
| UC-004 Password Spraying | 100600, 100601 | Windows 4625 failed network logons across multiple usernames from the same source IP | ✅ Deployed |
| UC-005 Kerberos Anomaly | 100300, 100301, 100302, 100303 | Kerberos RC4 ticket grouping, SPN enumeration, SPN targeting, and volume anomaly correlation | ✅ Deployed |
| UC-006 Privileged Logon | 100500, 100501, 100502 | Privileged logon detection with filtering for service accounts and remote administrative logons | ✅ Deployed |
| UC-007 Suspicious Process | 100800, 100801, 100802, 100803, 100804, 100805, 100806, 100807 | Sysmon process execution detections for PowerShell, credential dumping, certutil, WMI execution, bitsadmin, mshta, and rundll32 | ✅ Deployed |

### Rule Deployment Notes

- UC-001 was rebuilt from a placeholder sample rule into three production-style SSH authentication rules. The final chain detects failed SSH authentication for valid and invalid users, correlates 8 failures within 3 minutes, and raises severity when a successful SSH login follows brute force activity.
- UC-002 uses Wazuh built-in rule `61602` as the parent for Windows Event ID 4769.
- UC-003 includes a pfSense `filterlog` base rule plus correlation rules using Wazuh field correlation syntax such as `same_srcip`, `different_dstip`, and destination port grouping.
- UC-004 is separated from UC-003 and uses its own 100600-series rules for password spraying across multiple usernames.
- UC-006 was moved into the 100500-series to keep privileged-logon logic separate from network-scanning logic and includes filtering for noisy service account activity.
- UC-007 uses Sysmon Event ID 1 telemetry from all Windows endpoints and includes high-confidence LOLBin coverage for certutil, bitsadmin, mshta, and rundll32.

### Listener Validation

Current Wazuh listener checks:

```bash
systemctl status wazuh-manager
ss -lunp | grep ':514'    # pfSense syslog
ss -ltnp | grep ':1514'   # Wazuh agent communication
```

Expected state:

- Wazuh manager: active/running
- UDP 514: listening for pfSense syslog
- TCP 1514: listening for Wazuh endpoint communication
- pfSense firewall events: forwarding to Wazuh over UDP 514

---

## Dashboard Views

### Key Dashboards

Four custom Wazuh dashboards are deployed and aligned to the seven detection
use cases:

1. **Detection Use Case Overview**
   - Rule hit counts by use case
   - Alert severity distribution
   - High-priority detections across UC-001 through UC-007

2. **Authentication and Kerberos Monitoring**
   - Failed and successful authentication trends
   - SSH brute force and password spraying activity
   - Kerberos RC4 service ticket and Kerberos anomaly alerts

3. **Firewall and Lateral Movement Monitoring**
   - pfSense `filterlog` volume and action breakdown
   - Lateral movement, port sweep, and port scan rule activity
   - Top source and destination patterns for firewall events

4. **Endpoint and Privileged Activity Monitoring**
   - Sysmon suspicious process execution alerts
   - Privileged logon correlation results
   - Endpoint-focused investigation views for Windows hosts

---

## Validation Checklist

- [x] Wazuh server installed and accessible
- [x] Dashboard login working
- [x] DC01 agent enrolled and reporting
- [x] Windows client agents enrolled
- [x] Wazuh server local agent active
- [x] Wazuh UDP 514 syslog listener configured for pfSense
- [x] pfSense remote syslog forwarding enabled and verified
- [x] Windows Security events ingesting (4624, 4625, 4672, 4768, 4769)
- [x] Wazuh server Linux auth logs ingesting
- [x] Sysmon events ingesting (Event ID 1 on Windows endpoints)
- [x] Custom Wazuh rules 100001–100807 deployed where applicable
- [x] All 26 custom rules aligned to UC-001 through UC-007
- [x] Alert generation validated for UC-001 through UC-007
- [x] Wazuh dashboard API access validated
- [x] Four custom Wazuh dashboards configured for UC-001 through UC-007
- [ ] Wazuh Active Response configured (planned)

---

## Troubleshooting

### Agent Not Connecting

```bash
# Check agent status
/var/ossec/bin/agent_control -l

# Check agent logs
tail -f /var/ossec/logs/ossec.log

# Test connectivity to manager
telnet 10.10.69.20 1514
```

### Logs Not Ingesting

- Verify audit policies are enabled on Windows
- Check firewall rules between agent and manager
- Review `/var/ossec/logs/ossec.log` for errors
- Validate decoder configuration matches log format

### Rule Not Firing

- Check `/var/ossec/ruleset/rules/local_rules.xml` syntax
- Validate field names in XML rule match actual log fields
- Use Wazuh rule testing tool: `/var/ossec/bin/wazuh-logtest`

---

## Next Steps

- [x] Stand up `wazuh-server` at `10.10.69.20` and document final package versions
- [x] Enroll DC01, the two Windows clients, and the Wazuh server local agent
- [x] Configure Wazuh UDP 514 listener for pfSense syslog
- [x] Enable and verify pfSense remote syslog forwarding to `10.10.69.20:514/UDP`
- [x] Implement 4625 burst + password spray correlation (UC-004, rules 100600–100601)
- [x] Build correlation rules for lateral movement detection (rules 100200–100401)
- [x] Kerberos anomaly detection (UC-005, rules 100300–100303)
- [x] Privileged logon correlation (UC-006, rule 100500)
- [x] Suspicious process execution via Sysmon (UC-007, rules 100800–100807)
- [x] Validate Wazuh dashboard API access
- [x] Build Wazuh dashboards for all seven detection use cases
- [ ] Create automated response playbooks (Active Response)
- [ ] Integrate threat intelligence feeds (future)

---

## References

- Wazuh Documentation: https://documentation.wazuh.com
- MITRE ATT&CK: https://attack.mitre.org
- Windows Event IDs: https://learn.microsoft.com/en-us/windows/security/threat-protection/auditing
