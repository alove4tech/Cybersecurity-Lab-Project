# PB-003: Lateral Movement / Network Scanning

## Alert Trigger

Detection ID: UC-003
Log Source: pfSense firewall logs (filterlog)
Severity: Medium (escalate to High if correlated with other alerts)

---

## Severity Assessment

| Severity | Criteria |
|----------|----------|
| Low | Single host scanning, no successful connections |
| Medium | Multiple destinations scanned, no auth success |
| High | Scanning + successful authentication attempts |
| Critical | Scanning + privileged logon + data exfiltration signals |

---

## Escalation Criteria

**Escalate to High severity if:**
- Source IP shows 4624 successful logons after scanning
- Kerberos ticket requests (4769) from same source IP
- Privileged logon (4672) follows scanning activity
- Connections to critical assets (DC01, database servers)

**Escalate to Critical if:**
- Multiple detection correlations (brute force + scanning + lateral movement)
- Data exfiltration indicators (large outbound transfers)
- Service account abuse detected
- Persistence mechanisms observed

---

## Initial Triage

### 1. Confirm Alert Details

From Wazuh Dashboard, extract:
- **Source IP:** Scanning host
- **Destination IPs:** Targets being scanned
- **Ports probed:** Services being targeted
- **Time window:** Duration of scanning activity
- **Action taken:** Allow vs. block by firewall

---

### 2. Map Source IP to Lab Host

Check lab inventory:

```bash
# Match IP to hostname
# Use assets/vm-inventory.md or lab documentation

# Example:
# 10.10.69.50 → attack-vm
# 10.10.69.20 → win10-client
# 10.10.69.30 → win11-client
```

---

### 3. Determine Context

**Key questions:**
- Is this an expected admin activity?
- Is it a scheduled scanning tool (Nagios, backup software)?
- Does it correlate with other security events?
- Is it within normal baseline traffic patterns?

---

## Investigation

### Step 1: Assess Authentication Events

Query Windows Security logs for source IP:

**Event 4624 - Successful Logons**

```bash
# Wazuh query (or direct log review)
winlogbeat-* AND event_id:4624 AND source_ip: "10.10.69.X"
```

**What to look for:**
- Any successful authentications from source IP
- Types of logons (2=Interactive, 3=Network, 10=RemoteInteractive)
- Account names used
- Logon times relative to scanning activity

---

**Event 4625 - Failed Logons**

```bash
winlogbeat-* AND event_id:4625 AND source_ip: "10.10.69.X"
```

**What to look for:**
- Brute force patterns (multiple failures)
- Targeted usernames (especially privileged accounts)
- Time correlation with scanning

---

**Event 4768/4769 - Kerberos Tickets**

```bash
winlogbeat-* AND (event_id:4768 OR event_id:4769) AND source_ip: "10.10.69.X"
```

**What to look for:**
- Service ticket requests (potential Kerberoasting)
- Target service names (SPNs)
- Encryption types (RC4 vs AES)
- Correlation with UC-002 Kerberos detection

---

### Step 2: Assess Privilege Escalation

**Event 4672 - Privileged Logons**

```bash
winlogbeat-* AND event_id:4672 AND source_ip: "10.10.69.X"
```

**What to look for:**
- Administrative privileges assigned
- Group memberships (Domain Admins, Enterprise Admins)
- Correlation with scanning → successful logon → privilege escalation

---

### Step 3: Assess Network Activity

Review pfSense logs for:
- Successful vs. blocked connections
- Protocols used (TCP, UDP, ICMP)
- Destination ports (SMB, RDP, SSH, etc.)
- Data transfer volume

**Query for successful connections:**

```bash
log_type: firewall AND source_ip: "10.10.69.X" AND action: pass
```

---

### Step 4: Host-Based Investigation

If source host is Windows:

```powershell
# Check recent logon sessions
query user

# Check running processes
Get-Process | Sort-Object CPU -Descending | Select-Object -First 20

# Check scheduled tasks
Get-ScheduledTask

# Check for recent PowerShell history
Get-Content (Get-PSReadlineOption).HistorySavePath | Select-String -Pattern "Invoke|Impacket|mimikatz|kerberoast"
```

If source host is Linux:

```bash
# Check auth.log
grep -i "10.10.69.X" /var/log/auth.log

# Check running processes
ps aux | grep -E "nmap|nc|netcat|python|impacket"

# Check bash history
tail -100 ~/.bash_history | grep -E "nmap|smbclient|psexec|wmiexec"
```

---

### Step 5: Correlation Analysis

Correlate with:
- **UC-001** (SSH brute force) - Was there credential abuse first?
- **UC-002** (Kerberos RC4) - Were Kerberos tickets used?
- **Security events** - Any successful authentications?

**Correlation queries:**

```bash
# Multiple detections from same IP
rule.id:(100100 OR 100201 OR 100300) AND source_ip: "10.10.69.X"

# Temporal correlation
source_ip: "10.10.69.X" AND @timestamp:[now-1h TO now]
```

---

## Containment

### Immediate Actions

1. **Block source IP at pfSense:**
   - Navigate to: Firewall → Rules → Cyberlab
   - Add block rule: Source = 10.10.69.X, Action = Block
   - Log option: ☑️ Log packets matched by rule
   - Apply changes

2. **Disable affected account** (if compromise confirmed):
   ```powershell
   Disable-ADAccount -Identity <compromised_account>
   ```

3. **Isolate affected host** (optional, for deeper analysis):
   - Disconnect from network
   - Create snapshot for forensic analysis
   - Rebuild from clean image if needed

---

### Containment Validation

Verify containment is effective:
- No new connections from source IP in firewall logs
- Account cannot authenticate (4624 failures)
- Host cannot reach lab network

---

## Eradication

### 1. Remove Persistence Mechanisms

Check for:
- Scheduled tasks
- Registry run keys
- WMI event subscriptions
- Backdoor accounts
- SSH keys (Linux)

**Windows persistence check:**

```powershell
# Scheduled tasks
Get-ScheduledTask | Where-Object {$_.State -eq "Ready"} | Get-ScheduledTaskInfo

# Registry run keys
Get-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run"
Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"

# WMI subscriptions
Get-WmiObject -Class __EventFilter -Namespace "root\subscription"
```

**Linux persistence check:**

```bash
# Cron jobs
crontab -l
cat /etc/cron.d/*

# systemd services
systemctl list-timers --all

# SSH keys
cat ~/.ssh/authorized_keys
```

---

### 2. Rotate Credentials

- Reset passwords for all compromised accounts
- Force password change at next logon
- Revoke Kerberos tickets (purge ticket cache)

```powershell
# Reset service account password
Set-ADServiceAccount -Identity <account> -ResetPassword -NewPassword (ConvertTo-SecureString "NewPass123!" -AsPlainText -Force)

# Force password change at next logon
Set-ADUser -Identity <user> -ChangePasswordAtLogon $true
```

---

### 3. Audit Lateral Movement Paths

Review:
- Which systems were accessed?
- Which credentials were used?
- What data was accessed?
- Any signs of exfiltration?

---

## Recovery

### 1. Restore Service Access

- Re-enable accounts (if false positive)
- Restore network access (if containment was temporary)
- Confirm normal operations resumed

---

### 2. Monitor for Recurrence

Set up alerts for:
- Return of same source IP (if not permanently blocked)
- Similar scanning patterns from different IPs
- Same targeting behavior

---

### 3. Document Lessons Learned

Capture:
- Detection effectiveness (did UC-003 trigger?)
- Response time (how long from alert to containment?)
- False positive rate
- Areas for improvement

---

## Post-Incident Actions

### Detection Improvements

- **Tune thresholds** - Adjust based on baseline traffic
- **Add correlation rules** - Better integrate with auth events
- **Implement automated response** - Wazuh Active Response to auto-block scanners
- **Baseline normal behavior** - Define expected admin activity patterns

---

### Network Hardening

- **Implement Zero Trust** - Require authentication for all lateral movement
- **Network segmentation** - Separate admin workstations from production
- **Just-in-time access** - Temporary privilege elevation, not persistent
- **Micro-segmentation** - Restrict east-west traffic flow

---

### Monitoring Enhancements

- **Add honeypots** - Decoy systems to attract scanners
- **Behavioral analysis** - ML-based anomaly detection
- **Threat intel feeds** - Cross-reference with known malicious IPs
- **EDR/AV integration** - Host-based detection of scanning tools

---

## Communication

### Internal Team

Notify:
- SOC/Security team (alert details, response actions)
- System admins (affected systems, containment actions)
- Management (severity, business impact)

### External (if applicable)

- If real-world incident: Legal, compliance, PR teams

---

## Metrics to Track

| Metric | Target |
|--------|--------|
| Detection time (alert to investigation) | < 15 minutes |
| Containment time (investigation to block) | < 30 minutes |
| False positive rate | < 10% |
| Detection accuracy | > 90% |

---

## Runbook Validation

To test this playbook:
1. Simulate lateral movement with Nmap from attack VM
2. Trigger UC-003 alert
3. Follow this playbook step-by-step
4. Document any issues or gaps
5. Update playbook based on findings

---

## References

- MITRE ATT&CK: T1021 - Remote Services
- MITRE ATT&CK: T1078 - Valid Accounts
- NIST SP 800-61 - Incident Response Guide
- Wazuh Active Response: https://documentation.wazuh.com/current/user-manual/capabilities/active-response/index.html
