# PB-004: Suspicious Process Execution Response

## Alert Trigger

Detection ID: UC-007
Log Source: Sysmon Event ID 1 (Process Creation)
Severity: High (default for encoded PowerShell, LOLBin, WMI execution)
         Critical (if credential dumping tool detected)

---

## Severity Assessment

| Severity | Criteria |
|----------|----------|
| Low | WMI spawned cmd.exe from known management tool (SCCM, Ansible) |
| Medium | Execution policy bypass from non-standard parent process |
| High | Encoded PowerShell, certutil download, WMI remote execution |
| Critical | Credential dumping tool executed (mimikatz, procdump, lazagne) |

---

## Escalation Criteria

**Escalate to Critical if:**
- Rule 100802 triggered (credential dumping tool)
- Multiple rules triggered simultaneously (e.g., encoded PowerShell + WMI + credential dump)
- Activity originates from attacker IP range or non-standard source
- LSASS access detected alongside process execution

**Escalate to incident if:**
- Credential dumping succeeded (check for LSASS memory access events)
- Lateral movement follows process execution (correlate with UC-003)
- Privileged account credentials may be compromised (correlate with UC-006)
- Evidence of data collection or staging for exfiltration

---

## Initial Triage

### 1. Confirm Alert Details

From Wazuh Dashboard, extract:
- **Rule ID:** Which rule triggered (100800–100804)
- **Host:** Endpoint where process executed
- **User:** Account context running the process
- **Process Image:** Full path of the spawned process
- **Command Line:** Full command line arguments
- **Parent Process:** What spawned the suspicious process
- **Source IP:** If WMI or remote execution, the originating IP

### 2. Assess Threat Level

| Rule | Threat Level | Immediate Action |
|------|-------------|-----------------|
| 100800 (Encoded PowerShell) | High | Investigate command content immediately |
| 100801 (Execution Policy Bypass) | Medium-High | Check parent process and user context |
| 100802 (Credential Dumping) | Critical | Treat as active incident |
| 100803 (Certutil Download) | High | Identify downloaded payload |
| 100804 (WMI Execution) | High | Determine if remote or local |

### 3. Determine Context

**Key questions:**
- Is this a known administrator performing scheduled work?
- Is the parent process a legitimate management tool (SCCM, Ansible, Group Policy)?
- Does the user account normally run PowerShell or administrative commands?
- Is there a corresponding remote authentication event (4624) from an external IP?

---

## Investigation

### Step 1: Authentication Event Correlation

Query Windows Security logs for the same host and user:

**Event 4624 – Successful Logons**

```bash
# Wazuh query
winlogbeat-* AND event_id:4624 AND host: "<target_host>" AND @timestamp:[now-1h TO now]
```

**What to look for:**
- Logon type 3 (network) from attacker IP (10.10.69.50) → Impacket wmiexec
- Logon type 10 (remote interactive) → RDP session
- Service account logons from unusual sources
- Timestamp correlation with Sysmon Event ID 1

**Event 4625 – Failed Logons**

```bash
winlogbeat-* AND event_id:4625 AND host: "<target_host>" AND @timestamp:[now-1h TO now]
```

**What to look for:**
- Failed attempts preceding successful logon
- Account enumeration patterns

---

### Step 2: Parent Process Analysis

Examine the parent process chain:

```bash
# Query Sysmon for parent process details
winlogbeat-* AND event_id:1 AND win.eventdata.parentImage: "<parent_image>" AND @timestamp:[now-1h TO now]
```

**Suspicious parent indicators:**
- `WmiPrvSE.exe` → WMI remote execution (Impacket wmiexec, PowerShell WMI)
- `svchost.exe` (unusual) → Service exploitation
- `cmd.exe` spawned by web service → Web shell
- `taskeng.exe` → Scheduled task abuse
- Office applications (`winword.exe`, `excel.exe`) → Macro-based attack

**Legitimate parent indicators:**
- `explorer.exe` → User-initiated
- `svchost.exe -k netsvcs` → Group Policy or enterprise management
- Known management agents (SCCM, Ansible, Chef)

---

### Step 3: Network Connection Analysis

Check for network activity from the affected host:

```bash
# Sysmon Event ID 3 (Network Connection)
winlogbeat-* AND event_id:3 AND host: "<target_host>" AND @timestamp:[now-1h TO now]
```

**What to look for:**
- Outbound connections to external IPs after process execution
- Connections on unusual ports
- C2 beaconing patterns (periodic connections to same destination)
- Data transfer volume anomalies

**Cross-reference with pfSense logs:**
```bash
# Check firewall logs for outbound connections
log_type: firewall AND source_ip: "<target_ip>" AND @timestamp:[now-1h TO now]
```

---

### Step 4: Decode and Analyze Commands

For encoded PowerShell (Rule 100800):

```bash
# Decode base64-encoded PowerShell command
echo "<encoded_string>" | base64 -d | iconv -f UTF-16LE -t UTF-8
```

**Look for:**
- Download cradles (`Net.WebClient`, `Invoke-WebRequest`, `IEX`)
- Credential access (`Get-Credential`, `ConvertTo-SecureString`)
- Registry modification (`Set-ItemProperty`, `New-Item`)
- Process injection (`Invoke-ReflectivePEInjection`)
- Reverse shell payloads

---

### Step 5: Correlation with Other Detections

```bash
# All alerts from same host in last hour
host: "<target_host>" AND rule.level: [7 TO 14] AND @timestamp:[now-1h TO now]

# All alerts from same source IP
source_ip: "10.10.69.50" AND @timestamp:[now-2h TO now]
```

**Correlate with:**
- **UC-003** (Lateral Movement) → Did network scanning precede process execution?
- **UC-004** (Password Spraying) → Were credentials brute-forced before execution?
- **UC-006** (Privileged Logon) → Did privileged access occur?
- **UC-001** (SSH Brute Force) → Was SSH compromise the entry vector?

---

## Containment

### Immediate Actions

1. **Isolate affected host:**
   - Disconnect from network (or isolate at pfSense)
   - Create snapshot for forensic analysis before any remediation

   ```bash
   # Block host at pfSense
   # Firewall → Rules → Cyberlab → Block <host_ip>
   ```

2. **Kill suspicious process** (if not isolated):
   ```powershell
   # On affected host
   Stop-Process -Id <PID> -Force
   Stop-Process -Name "mimikatz" -Force -ErrorAction SilentlyContinue
   ```

3. **Block source IP** (if remote execution):
   ```bash
   # Block attacker IP at pfSense
   # Firewall → Rules → Cyberlab → Block 10.10.69.50
   ```

4. **Disable compromised account** (if credential theft suspected):
   ```powershell
   Disable-ADAccount -Identity <compromised_account>
   # Force password reset
   Set-ADUser -Identity <compromised_account> -ChangePasswordAtLogon $true
   ```

### Containment Validation

- No new suspicious processes spawned on affected host
- No new network connections from affected host
- Source IP blocked at firewall
- Compromised account cannot authenticate

---

## Eradication

### 1. Identify Persistence Mechanisms

```powershell
# Scheduled tasks
Get-ScheduledTask | Where-Object {$_.State -eq "Ready" -and $_.TaskPath -notlike "\Microsoft\*"} | Get-ScheduledTaskInfo

# Registry run keys
Get-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run"
Get-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce"
Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"

# WMI event subscriptions
Get-WmiObject -Class __EventFilter -Namespace "root\subscription"
Get-WmiObject -Class __FilterToConsumerBinding -Namespace "root\subscription"

# Service creation
Get-WinEvent -FilterHashtable @{LogName='System'; ID=7045} | Select-Object -First 20
```

### 2. Remove Malicious Artifacts

- Delete downloaded payloads (check certutil cache directory)
- Remove any created scheduled tasks
- Clean registry run keys
- Remove WMI subscriptions
- Delete unauthorized accounts

### 3. Credential Rotation

- Reset passwords for all accounts that were active on the affected host
- Force Kerberos ticket purge:
  ```powershell
  klist purge -li 0x3e7
  ```
- Revoke and reissue service account credentials if applicable

---

## Recovery

### 1. Restore Service Access

- Re-enable accounts after password reset
- Restore network access after confirming clean state
- Verify endpoint functionality

### 2. Monitor for Recurrence

Set up targeted monitoring:
```bash
# Watch for same techniques from any source
rule.id:(100800 OR 100801 OR 100802 OR 100803 OR 100804) AND @timestamp:[now-24h TO now]
```

### 3. Validate Hardening

- Confirm PowerShell logging is enabled (Script Block Logging, Transcription)
- Confirm LSA Protection (RunAsPPL) is enabled
- Confirm Credential Guard status
- Confirm Sysmon is running and forwarding events

---

## Post-Incident Actions

### Detection Improvements

- Add rules for additional LOLBins identified during investigation
- Update Rule 100802 patterns if new credential dumping tools discovered
- Implement frequency-based correlation for repeated bypass attempts
- Add automated enrichment (GeoIP, threat intel lookup for source IPs)

### Endpoint Hardening

- Deploy Application Whitelisting (AppLocker / WDAC)
- Enable AMSI (Anti-Malware Scan Interface) for script content inspection
- Restrict WMI remote access to admin-only security group
- Implement PowerShell Constrained Language Mode for non-admin users

### Documentation Updates

- Update this playbook with lessons learned
- Update UC-007 with new false positive patterns
- Add new rule IDs if detection gaps identified

---

## Metrics to Track

| Metric | Target |
|--------|--------|
| Detection time (alert to investigation) | < 10 minutes |
| Containment time (investigation to isolate) | < 15 minutes |
| False positive rate | < 5% for Rules 100800/100803 |
| Credential dump containment (Rule 100802) | < 5 minutes |
| Post-incident hardening completion | < 48 hours |

---

## Runbook Validation

To test this playbook:

1. Deploy Sysmon and verify Event ID 1 collection on target endpoint
2. Deploy UC-007 rules (100800–100804) to Wazuh
3. From attack VM (10.10.69.50), execute:
   ```bash
   impacket-wmiexec corp.local/jsmith:Password123@10.10.69.10 "powershell.exe -enc <encoded_whoami>"
   ```
4. Follow this playbook step-by-step from alert through containment
5. Document any gaps, false positives, or improvement opportunities
6. Update playbook and detection rules based on findings

---

## References

- MITRE ATT&CK T1059.001: https://attack.mitre.org/techniques/T1059/001/
- MITRE ATT&CK T1003: https://attack.mitre.org/techniques/T1003/
- MITRE ATT&CK T1047: https://attack.mitre.org/techniques/T1047/
- Sysmon: https://docs.microsoft.com/en-us/sysinternals/downloads/sysmon
- Wazuh Active Response: https://documentation.wazuh.com/current/user-manual/capabilities/active-response/index.html
- NIST SP 800-61 – Incident Response Guide
