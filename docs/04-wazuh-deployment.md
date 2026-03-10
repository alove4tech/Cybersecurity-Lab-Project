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
          │ Agent Communication (1514/TCP, 1515/TCP, 1516/UDP)
          ▼
┌─────────────────────────────────────────────────────────────┐
│                    Agents                                    │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │
│  │   Linux      │  │   Windows    │  │ pfSense     │       │
│  │   Agent      │  │   Agent      │  │   Agent     │       │
│  │  (auth.log)  │  │  (Security)  │  │  (syslog)   │       │
│  └──────────────┘  └──────────────┘  └──────────────┘       │
└─────────────────────────────────────────────────────────────┘
```

---

## Server Deployment

### Server Information

- **Hostname:** TBD
- **IP Address:** TBD
- **Operating System:** TBD (likely Debian/Ubuntu or Wazuh All-In-One)
- **Wazuh Version:** TBD
- **Deployment Method:** TBD (Docker, All-In-One package, or individual components)

### Component Versions

- **Wazuh Manager:** v4.x
- **Wazuh Indexer:** OpenSearch
- **Wazuh Dashboard:** Kibana-based
- **Filebeat:** Latest compatible

### Installation Method

[Document installation approach - e.g., All-In-One installer or Docker Compose]

**Example All-In-One Installation:**
```bash
# Download Wazuh installation script
curl -sO https://packages.wazuh.com/4.8/wazuh-install.sh

# Run installer
bash wazuh-install.sh -a <manager-node-ip>
```

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
# Add Wazuh repository
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --dearmor -o /usr/share/keyrings/wazuh.gpg
echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt stable main" | tee /etc/apt/sources.list.d/wazuh.list

# Install agent
apt-get update
apt-get install wazuh-agent

# Configure agent (edit /var/ossec/etc/ossec.conf)
# Set <server><address>10.10.69.X</address></server>

# Start agent
systemctl daemon-reload
systemctl enable wazuh-agent
systemctl start wazuh-agent
```

### Windows Agent

```powershell
# Download Wazuh agent MSI
# Install via command line with manager IP
msiexec.exe /i wazuh-agent-4.8.0-1.msi /q WAZUH_MANAGER="10.10.69.X" WAZUH_AGENT_GROUP="windows"

# Start agent (auto-starts as service)
# Verify: Get-Service Wazuh
```

### pfSense Agent (Syslog Forwarding)

pfSense does not run a native Wazuh agent. Instead, logs are forwarded via syslog:

1. Configure remote syslog in pfSense: Status → System Logs → Settings
2. Set remote log server to Wazuh manager IP (10.10.69.X)
3. Use UDP 514 (or TLS 6514 for encrypted)
4. Enable log categories: Firewall, DHCP, System, VPN
5. Verify ingestion in Wazuh Dashboard → Events viewer

---

## Lab Agent Inventory

| Hostname | IP Address | OS | Agent Type | Log Sources | Status |
|----------|------------|-------|-------------|--------------|--------|
| wazuh-server | 10.10.69.X | Linux | Manager/Server | All telemetry | ✔ Active |
| dc01 | 10.10.69.10 | Windows Server 2022 | Wazuh Agent | Windows Security (4624, 4625, 4672, 4768, 4769) | ✔ Active |
| win10-client | 10.10.69.X | Windows 10 | Wazuh Agent | Windows Security | ✔ Active |
| win11-client | 10.10.69.X | Windows 11 | Wazuh Agent | Windows Security | ✔ Active |
| attack-vm | 10.10.69.X | Debian/Ubuntu | Wazuh Agent | /var/log/auth.log, syslog | ✔ Active |
| pfSense | 10.10.69.1 | pfSense | Syslog Forwarder | Firewall, DHCP, System | ⏳ Planned |

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

Log categories to forward:
- Firewall rules (allow/deny)
- NAT traffic
- DHCP assignments
- VPN connections
- System events

---

## Custom Rules

### Rule ID 100100: Kerberos RC4 Ticket Detection

**File:** `/var/ossec/ruleset/rules/local_rules.xml` (on manager)

```xml
<group name="windows,kerberos,">
  <rule id="100100" level="12">
    <if_sid>61602</if_sid> <!-- Base Windows 4769 rule -->
    <field name="TicketEncryptionType">0x17</field>
    <description>Kerberos service ticket issued with RC4 encryption - Potential Kerberoasting</description>
    <mitre>
      <id>T1558.003</id>
    </mitre>
    <group>kerberos,kerberoasting,privilege_escalation</group>
  </rule>
</group>
```

**Testing the Rule:**
1. Force RC4 encryption on a service account
2. Request service ticket: `klist get <SPN>`
3. Confirm 4769 event logs `TicketEncryptionType: 0x17`
4. Verify Wazuh rule 100100 fires in dashboard

---

## Dashboard Views

### Key Dashboards

1. **Security Events Overview**
   - Total events by source
   - Top alerting rules
   - Severity distribution

2. **Authentication Monitoring**
   - Failed vs. successful logons
   - Brute force detection (UC-001)
   - Kerberos ticket anomalies (UC-002)

3. **Network Activity**
   - Firewall log correlation
   - Connection frequency by host
   - Blocked traffic analysis

4. **Incident Response**
   - Alert timeline
   - Affected assets
   - Investigation notes

---

## Validation Checklist

- [ ] Wazuh server installed and accessible
- [ ] Dashboard login working
- [ ] DC01 agent enrolled and reporting
- [ ] Windows client agents enrolled
- [ ] Linux attack VM agent enrolled
- [ ] pfSense syslog forwarding configured
- [ ] Windows Security events ingesting (4624, 4625, 4672, 4768, 4769)
- [ ] Linux auth.log ingesting
- [ ] Custom rule 100100 deployed
- [ ] Alert generation validated for UC-001 and UC-002
- [ ] Dashboards configured

---

## Troubleshooting

### Agent Not Connecting

```bash
# Check agent status
/var/ossec/bin/agent_control -l

# Check agent logs
tail -f /var/ossec/logs/ossec.log

# Test connectivity to manager
telnet 10.10.69.X 1514
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

- [ ] Complete pfSense syslog forwarding integration
- [ ] Implement 4625 burst + password spray correlation
- [ ] Build correlation rules for lateral movement detection
- [ ] Create automated response playbooks (Active Response)
- [ ] Integrate threat intelligence feeds (future)

---

## References

- Wazuh Documentation: https://documentation.wazuh.com
- MITRE ATT&CK: https://attack.mitre.org
- Windows Event IDs: https://learn.microsoft.com/en-us/windows/security/threat-protection/auditing
