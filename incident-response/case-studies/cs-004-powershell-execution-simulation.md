# CS-004: PowerShell Execution via WMI Simulation

## Scenario Overview

Simulated an adversary using Impacket's wmiexec tool to remotely execute encoded PowerShell commands and attempt credential dumping on the domain controller. This validates the UC-007 detection rules for suspicious process execution.

**Objective:** Validate that Sysmon Event ID 1 collection via Wazuh detects encoded PowerShell, execution policy bypass, credential dumping attempts, and WMI-based remote command execution.

---

## Lab Setup

### Attacker Host

- **Hostname:** debianpen
- **IP Address:** 10.10.69.50
- **OS:** Debian (attack host with Kali tools)
- **Role:** External attacker / red team operator

### Target Environment

- **Domain Controller:** DC01 (10.10.69.10, Windows Server 2022, corp.local)
- **SIEM:** Wazuh (10.10.69.20)
- **Gateway:** pfSense (10.10.69.1)
- **Windows Clients:** WIN10-CLIENT, WIN11-CLIENT (domain-joined)
- **Sysmon:** Deployed on DC01 and Windows clients, Event ID 1 forwarded to Wazuh

### Compromised Credentials (Simulated)

- **Username:** jsmith@corp.local
- **Password:** Password123
- **Obtained via:** Prior password spraying attack (CS-001/UC-004 scenario)

---

## Attack Simulation

### Phase 1: WMI Session Establishment

**Time:** 15:00 - 15:01

**Actions:**
1. Attacker establishes WMI session to DC01 using compromised credentials
2. Impacket wmiexec creates a semi-interactive shell via WMI
3. Windows logs network logon (4624) and WMI activity

**Commands:**

```bash
# Establish WMI remote session
impacket-wmiexec corp.local/jsmith:Password123@10.10.69.10
```

**Expected telemetry:**
- Event ID 4624 (Logon Type 3) from 10.10.69.50
- Sysmon Event ID 1: `WmiPrvSE.exe` spawning `cmd.exe`
- WMI activity logs

**Results:**
- WMI session established successfully
- Network logon logged from attacker IP
- `cmd.exe` spawned under `WmiPrvSE.exe` parent

---

### Phase 2: Encoded PowerShell Execution

**Time:** 15:01 - 15:03

**Actions:**
1. Attacker encodes a reconnaissance command in base64
2. Executes encoded PowerShell via WMI channel
3. Attempts to enumerate domain admins and network configuration

**Commands:**

```bash
# Generate encoded command
ENCODED=$(echo -n "Get-ADUser -Filter {AdminCount -eq 1} | Select-Object Name" | iconv -t UTF-16LE | base64 -w0)

# Execute via WMI session
impacket-wmiexec corp.local/jsmith:Password123@10.10.69.10 "powershell.exe -enc $ENCODED"
```

**Alternative - execution policy bypass:**

```bash
impacket-wmiexec corp.local/jsmith:Password123@10.10.69.10 "powershell.exe -ExecutionPolicy Bypass -Command \"Get-ADUser -Filter * | Select Name,SamAccountName\""
```

**Expected telemetry:**
- Sysmon Event ID 1: `powershell.exe` with `-enc` flag
- Sysmon Event ID 1: Parent process `WmiPrvSE.exe`
- Rule 100800 (encoded PowerShell) should fire
- Rule 100801 (execution policy bypass) should fire
- Rule 100804 (WMI command execution) should fire

**Results:**
- Encoded PowerShell executed successfully
- Domain admin enumeration returned results
- All expected Wazuh alerts triggered

---

### Phase 3: Credential Dump Attempt

**Time:** 15:03 - 15:05

**Actions:**
1. Attacker attempts to invoke credential dumping tool via WMI
2. Simulates mimikatz execution through encoded PowerShell
3. Tests whether Rule 100802 (credential dumping) detects the pattern

**Commands:**

```bash
# Simulate credential dumping invocation (command pattern only - no actual mimikatz binary)
DUMP_CMD=$(echo -n "Invoke-Expression -Command 'mimikatz.exe \"sekurlsa::logonpasswords\"'" | iconv -t UTF-16LE | base64 -w0)
impacket-wmiexec corp.local/jsmith:Password123@10.10.69.10 "powershell.exe -enc $DUMP_CMD"

# Also test procdump pattern
impacket-wmiexec corp.local/jsmith:Password123@10.10.69.10 "powershell.exe -enc <encoded: procdump.exe -ma lsass>"
```

**Expected telemetry:**
- Sysmon Event ID 1: Command line containing "mimikatz" or "procdump" patterns
- Rule 100802 (credential dumping tool) should fire at level 14 (Critical)
- Rule 100800 (encoded PowerShell) fires simultaneously
- Rule 100804 (WMI execution) fires simultaneously

**Results:**
- Credential dumping tool patterns detected in command line
- Rule 100802 triggered at Critical severity
- Multiple correlated alerts provided strong detection signal

---

### Phase 4: Cleanup and Evidence Collection

**Time:** 15:05 - 15:06

**Actions:**
1. Attacker disconnects WMI session
2. Investigator collects evidence from Wazuh and target host
3. Validates full detection chain

---

## Timeline

| Time | Event | Detection |
|------|-------|-----------|
| 15:00 | WMI session established from 10.10.69.50 to DC01 | Event 4624 (Logon Type 3) |
| 15:00:30 | WmiPrvSE.exe spawns cmd.exe on DC01 | Rule 100804 (WMI execution) |
| 15:01 | Encoded PowerShell command executed | Rule 100800 (encoded PS) + Rule 100804 |
| 15:02 | Execution policy bypass attempted | Rule 100801 (bypass) + Rule 100804 |
| 15:03 | Credential dump command (mimikatz pattern) | Rule 100802 (cred dump) + Rule 100800 + Rule 100804 |
| 15:03:30 | Procdump pattern detected | Rule 100802 (cred dump) |
| 15:05 | WMI session disconnected | — |
| 15:06 | Evidence collection begins | — |

---

## Detection Triggered

### Primary Detections

**Rule 100800 – Encoded PowerShell (Level 12)**

```
Rule: 100800 (level 12)
Description: Suspicious process: Encoded PowerShell command detected from CORP\jsmith
Host: DC01 (10.10.69.10)
Image: C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe
CommandLine: powershell.exe -enc RwBlAHQALQBB...
ParentImage: C:\Windows\System32\wbem\WmiPrvSE.exe
User: CORP\jsmith
Time: 15:01
```

**Rule 100802 – Credential Dumping Tool (Level 14)**

```
Rule: 100802 (level 14)
Description: Critical: Credential dumping tool executed - mimikatz.exe "sekurlsa::logonpasswords"
Host: DC01 (10.10.69.10)
CommandLine: powershell.exe -enc <mimikatz invocation>
ParentImage: C:\Windows\System32\wbem\WmiPrvSE.exe
User: CORP\jsmith
Time: 15:03
MITRE: T1003
```

**Rule 100804 – WMI Command Execution (Level 10)**

```
Rule: 100804 (level 10)
Description: Suspicious process: WMI spawned command interpreter from CORP\jsmith
Host: DC01 (10.10.69.10)
Image: C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe
ParentImage: C:\Windows\System32\wbem\WmiPrvSE.exe
User: CORP\jsmith
Time: 15:00:30, 15:01, 15:02, 15:03
```

### Correlation with Other Detections

**Authentication Events:**
- Event 4624 (Logon Type 3): Network logon from 10.10.69.50 as CORP\jsmith
- Event 4624 correlation confirms remote execution origin

**UC-004 (Password Spraying):**
- Credentials used in this attack were obtained via simulated password spraying
- Demonstrates full attack chain: spray → credential → lateral movement → execution

**Severity Assessment:** Critical (credential dumping attempt on domain controller)

---

## Investigation Steps

### 1. Alert Triage

**Identified:**
- Source IP: 10.10.69.50 (ATTACK-VM / debianpen)
- Target: DC01 (10.10.69.10) — Domain Controller
- User: CORP\jsmith — standard user account
- Technique: WMI remote execution with encoded PowerShell and credential dumping
- Scope: Domain controller compromised, credential dump attempted

**Context:**
- jsmith credentials previously compromised via password spraying (UC-004)
- Attacker escalated from credential abuse to domain controller access
- Credential dumping attempted (critical severity)

### 2. Host Investigation

**DC01 (10.10.69.10):**

```powershell
# Check for WMI-spawned processes
Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-Sysmon/Operational'; ID=1} |
  Where-Object {$_.Message -like '*WmiPrvSE*'} |
  Select-Object TimeCreated, Message | Format-List

# Check for PowerShell command history
Get-Content (Get-PSReadlineOption).HistorySavePath | Select-String -Pattern "mimikatz|procdump|sekurlsa"

# Check LSASS access attempts
Get-WinEvent -FilterHashtable @{LogName='Security'; ID=4663} |
  Where-Object {$_.Message -like '*lsass*'}
```

**Conclusion:** WMI-spawned PowerShell activity confirmed. Credential dumping command executed but tool not present on system (simulation only).

### 3. Source Investigation

**ATTACK-VM (10.10.69.50):**

```bash
# Check bash history for Impacket usage
grep -i "wmiexec\|impacket" ~/.bash_history

# Check running processes
ps aux | grep -E "impacket|python"
```

**Conclusion:** Impacket wmiexec was used to execute commands remotely.

### 4. Network Activity Review

**pfSense Firewall Logs:**
- SMB connections (port 445) from 10.10.69.50 to 10.10.69.10
- RPC connections (port 135) from 10.10.69.50 to 10.10.69.10
- WMI traffic (port 135 + dynamic RPC range)

**Conclusion:** Network traffic consistent with Impacket wmiexec behavior (DCERPC over SMB).

---

## Containment Actions

### Immediate Response

1. **Blocked source IP at pfSense:**
   - Added firewall rule: Block 10.10.69.50
   - Applied to Cyberlab interface
   - Logged: ☑️ Yes

2. **Disabled compromised account:**
   ```powershell
   Disable-ADAccount -Identity jsmith
   Set-ADUser -Identity jsmith -ChangePasswordAtLogon $true
   ```

3. **Kerberos ticket purge on DC01:**
   ```powershell
   klist purge -li 0x3e7
   ```

4. **Verified containment:**
   - No new connections from 10.10.69.50
   - jsmith account cannot authenticate
   - DC01 WMI activity ceased

---

## Root Cause Analysis

**Attack Chain:**
1. Credentials obtained via password spraying (UC-004)
2. Attacker used Impacket wmiexec to establish WMI session to DC01
3. WMI remote execution spawned PowerShell under WmiPrvSE.exe parent
4. Encoded commands used to evade basic logging
5. Credential dumping tool invocation attempted

**Why Detection Worked:**
- Sysmon Event ID 1 captured full command line including `-enc` flag
- Parent process analysis identified WMI as execution vector
- Credential dumping command patterns matched Rule 100802
- Multiple correlated alerts provided high-confidence signal

**Why Attack Succeeded Initially:**
- Valid credentials obtained from prior attack phase
- No MFA required for WMI/SMB access
- No network segmentation between attacker and domain controller
- No application whitelisting to prevent tool execution

---

## Remediation

### Immediate Actions

✅ Blocked attacker IP (10.10.69.50)
✅ Disabled compromised account (jsmith)
✅ Purged Kerberos tickets on DC01
✅ Verified no persistence mechanisms created

### Short-Term Hardening

- **Enable MFA** for all privileged accounts
- **Restrict WMI access** to Domain Admins security group only
- **Deploy PowerShell Constrained Language Mode** for non-admin users
- **Enable LSA Protection** (RunAsPPL) on DC01
- **Reset all passwords** for accounts active during attack window

### Long-Term Improvements

- **Application whitelisting** (AppLocker/WDAC) on domain controllers
- **Network segmentation** — restrict workstation-to-DC direct access
- **Credential Guard** deployment on all endpoints
- **Just-in-time admin access** for privileged operations

---

## Lessons Learned

### Detection Effectiveness

**What Worked:**
✅ Sysmon Event ID 1 captured full command line details including encoded content
✅ Rule 100800 detected encoded PowerShell reliably
✅ Rule 100802 detected credential dumping tool patterns at Critical severity
✅ Rule 100804 detected WMI-spawned command interpreters
✅ Multiple correlated alerts provided strong confidence signal
✅ Parent process analysis clearly identified WMI as attack vector

**What Didn't Work:**
⚠️ Detection is reactive — attacker already had access when alerts fired
⚠️ No automated containment — manual IP blocking and account disable required
⚠️ Command content was encoded — had to decode manually for full analysis
⚠️ No detection for the initial credential compromise in this scenario (would need UC-004 correlation)

### Response Time

| Phase | Time |
|-------|------|
| Alert triggered | 15:00 (WMI session) |
| Investigation started | 15:01 (1 minute) |
| Severity escalated (cred dump) | 15:03 (3 minutes) |
| Source IP blocked | 15:05 (5 minutes) |
| Account disabled | 15:05 (5 minutes) |

**Total response time:** 5 minutes (excellent for Critical severity)

### False Positives

**Expected false positives for this detection set:**
- Rule 100801 (execution policy bypass): Enterprise deployment tools often bypass execution policy legitimately
- Rule 100804 (WMI execution): SCCM, Ansible, and Group Policy routinely spawn cmd.exe via WMI
- Rule 100800 (encoded PowerShell): Rare but possible in enterprise automation frameworks

**Mitigation:**
- Whitelist known management tool service accounts
- Whitelist known admin workstation IPs
- Correlate with source IP to prioritize alerts from non-standard sources

### Detection Gaps

**What we missed:**
- No detection for the WMI session establishment itself (before command execution)
- No detection for data exfiltration (if attacker collected data before triggering process rules)
- No detection for privilege escalation (if attacker elevated from jsmith to admin)
- No AMSI integration to detect decoded malicious script content

**Future improvements:**
- Add Sysmon Event ID 3 (Network Connection) correlation for outbound C2 detection
- Add Sysmon Event ID 7 (Image Loaded) for DLL monitoring (credential dumping modules)
- Implement AMSI log integration for script content analysis
- Add frequency-based rule for rapid successive WMI commands

---

## Detection Fidelity

| Metric | Result |
|--------|--------|
| Rule 100800 (Encoded PS) triggered? | ✅ Yes |
| Rule 100801 (Bypass) triggered? | ✅ Yes |
| Rule 100802 (Cred Dump) triggered? | ✅ Yes (Critical) |
| Rule 100804 (WMI Exec) triggered? | ✅ Yes (4 instances) |
| Accurate classification? | ✅ Yes (all techniques correctly identified) |
| False positive? | ❌ No (all alerts were true positives) |
| Response time? | ✅ < 5 minutes |
| Containment effective? | ✅ Yes |
| Root cause identified? | ✅ Yes (credential spray → WMI lateral movement) |

**Overall Assessment:** **Excellent** — All five detection rules fired correctly with proper severity levels and MITRE ATT&CK mapping. Correlated alerts provided complete attack chain visibility.

---

## Recommendations

### Short-Term (1–2 weeks)

1. **Implement Wazuh Active Response** for Rule 100802:
   - Auto-disable account on credential dumping detection
   - Auto-block source IP at Critical severity
   - Send immediate notification to security team

2. **Add dashboard visualization:**
   - Suspicious process timeline by host
   - Top users triggering process alerts
   - WMI execution heat map by source IP

3. **Enable PowerShell Script Block Logging** (Sysmon Event ID 4104):
   - Captures decoded script content for encoded commands
   - Provides full visibility into what encoded PowerShell actually executed

### Medium-Term (1–2 months)

1. **Expand LOLBin coverage:**
   - Add rules for bitsadmin.exe downloads
   - Add rules for mshta.exe execution
   - Add rules for rundll32.exe with suspicious entry points
   - Add rules for installutil.exe code execution

2. **Implement credential protection:**
   - Deploy Credential Guard on all Windows endpoints
   - Enable LSA Protection (RunAsPPL) on domain controllers
   - Implement Windows Defender Exploit Guard

3. **Add network correlation:**
   - Correlate Sysmon Event ID 3 (network connections) with process execution
   - Detect C2 beaconing after initial process execution
   - Flag outbound connections from processes spawned via WMI

### Long-Term (3–6 months)

1. **Endpoint Detection and Response (EDR):**
   - Deploy full EDR solution for behavioral analysis
   - Machine learning-based process anomaly detection
   - Automated threat hunting queries

2. **Zero Trust implementation:**
   - Require MFA for all remote management protocols (WMI, PSRemoting, SSH)
   - Network micro-segmentation between workstations and domain controllers
   - Just-in-time privileged access management

3. **Continuous validation:**
   - Automated attack simulation pipeline
   - Purple team exercises targeting process execution detection
   - Detection coverage gap analysis against MITRE ATT&CK framework

---

## Evidence & Screenshots

### Evidence 1: Wazuh Alert – Encoded PowerShell (Rule 100800)

*[Screenshot: Wazuh Security Events showing Rule 100800 alert with encoded command line]*
**Location:** `assets/evidence/cs-004-001-encoded-powershell.png`

### Evidence 2: Wazuh Alert – Execution Policy Bypass (Rule 100801)

*[Screenshot: Wazuh Security Events showing Rule 100801 alert]*
**Location:** `assets/evidence/cs-004-002-execution-policy-bypass.png`

### Evidence 3: Wazuh Alert – Credential Dumping Tool (Rule 100802)

*[Screenshot: Wazuh Security Events showing Rule 100802 Critical alert with mimikatz pattern]*
**Location:** `assets/evidence/cs-004-003-credential-dumping.png`

### Evidence 4: Wazuh Alert – WMI Command Execution (Rule 100804)

*[Screenshot: Wazuh Security Events showing Rule 100804 alert with WmiPrvSE parent]*
**Location:** `assets/evidence/cs-004-004-wmi-execution.png`

### Evidence 5: Sysmon Event Viewer – Process Creation Events

*[Screenshot: Windows Event Viewer showing Sysmon Event ID 1 entries from attack simulation]*
**Location:** `assets/evidence/cs-004-005-sysmon-events.png`

### Evidence 6: pfSense Block Rule – Containment

*[Screenshot: pfSense Firewall Rules showing block rule for 10.10.69.50 after containment]*
**Location:** `assets/evidence/cs-004-006-containment-rule.png`

---

## References

- MITRE ATT&CK T1059.001: https://attack.mitre.org/techniques/T1059/001/
- MITRE ATT&CK T1003: https://attack.mitre.org/techniques/T1003/
- MITRE ATT&CK T1047: https://attack.mitre.org/techniques/T1047/
- Impacket: https://github.com/SecureAuthCorp/impacket
- Sysmon: https://learn.microsoft.com/en-us/sysinternals/downloads/sysmon
- LOLBAS Project: https://lolbas-project.github.io/
- NIST SP 800-61 – Incident Response Guide
