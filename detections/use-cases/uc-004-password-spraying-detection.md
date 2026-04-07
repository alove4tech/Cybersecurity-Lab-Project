# UC-004: Windows Active Directory Password Spraying Detection

## Detection Metadata

- Detection ID: UC-004
- Log Source: Windows Security Event Log (Event ID 4625)
- Platform: Windows Server 2022 AD
- SIEM: Wazuh
- Severity: High
- MITRE ATT&CK:
  - T1110.003 – Password Spraying
  - T1110 – Brute Force: Password Guessing
- Data Sensitivity: Authentication telemetry

---

## Objective

Detect multiple failed logon attempts from a single source IP address across different usernames within a short time window, which is a common password spraying technique used by attackers to evade account lockout policies.

---

## Lab Environment

- **Domain Controller (DC01)**: 10.10.69.10 (Windows Server 2022, corp.local)
- **SIEM (Wazuh)**: 10.10.69.20
- **Attacker Host (debianpen)**: 10.10.69.50 (Debian)
- **Network**: 10.10.69.0/24 (segmented lab VLAN)

**Test Accounts Created**:
- spray.test1@corp.local through spray.test5@corp.local
- Group membership: SprayLab

---

## Log Source & Field Mapping

**Event ID 4625 – An account failed to log on**

Key fields for detection:

- `ipAddress` – Source IP of the failed login attempt
- `targetUserName` – Target account being authenticated
- `logonType` – Type of logon (3 = Network logon)
- `subStatus` – Reason for failure (0xc000006a = Wrong password)
- `eventTime` – Timestamp of the failed attempt

**Sample event data**:
```xml
<EventData>
  <Data Name="SubjectUserSid">S-1-5-18</Data>
  <Data Name="SubjectUserName">DC01$</Data>
  <Data Name="SubjectDomainName">CORP</Data>
  <Data Name="LogonType">3</Data>
  <Data Name="Status">0xc000006a</Data>
  <Data Name="SubStatus">0xc000006a</Data>
  <Data Name="LogonProcessName">Kerberos</Data>
  <Data Name="AuthenticationPackageName">Kerberos</Data>
  <Data Name="WorkstationName"></Data>
  <Data Name="IpAddress">10.10.69.50</Data>
  <Data Name="IpPort">49876</Data>
  <Data Name="TargetUserName">spray.test1</Data>
  <Data Name="TargetDomainName">CORP</Data>
</EventData>
```

---

## Detection Logic

### Rule 1: Base Failed Network Logon Detection

**Rule ID**: 100600

Triggers when a failed network logon attempt with bad password is detected:

- **Condition**: Event ID 4625 with logonType 3 and subStatus 0xc000006a
- **Parent Rule**: 60122 (Windows failed logon)
- **Level**: 6 (Medium)

**Wazuh rule configuration**:
```xml
<rule id="100600" level="6">
  <if_sid>60122</if_sid>
  <field name="logonType">3</field>
  <field name="subStatus">0xc000006a</field>
  <description>Windows: Failed network logon with bad password</description>
  <group>authentication_failed,win_security</group>
</rule>
```

### Rule 2: Password Spraying Correlation

**Rule ID**: 100601

Correlates multiple failed logons to detect password spraying:

- **Condition**: 5 or more failed logons within 300 seconds
  - Same source IP (`same_field ipAddress`)
  - Different usernames (`different_field targetUserName`)
- **Level**: 10 (High)
- **Frequency**: 300 seconds time window

**Wazuh rule configuration**:
```xml
<rule id="100601" level="10">
  <if_sid>100600</if_sid>
  <if_matched_level>6</if_matched_level>
  <same_field>ipAddress</same_field>
  <different_field>targetUserName</different_field>
  <check_diff />
  <description>Windows: Possible password spraying detected from $(ipAddress) across multiple usernames</description>
  <group>password_spraying,brute_force,win_security</group>
  <frequency>5</frequency>
  <time_frame>300</time_frame>
</rule>
```

---

## Threshold Tuning

**Initial threshold**:
- 5 failed attempts from same IP across different usernames
- Time window: 300 seconds (5 minutes)

**Rationale**:
- Avoids triggering on legitimate user typos (typically 1-3 attempts)
- Captures true password spraying behavior (targeting many accounts with few attempts)
- 5-minute window balances detection speed with noise reduction

**Testing results**:
- No false positives with normal user behavior
- Alert triggered consistently during controlled attack simulation

---

## Validation Procedure

### 1. Environment Setup

Created test accounts:
```powershell
for ($i=1; $i -le 5; $i++) {
    New-ADUser -Name "spray.test$i" -SamAccountName "spray.test$i" `
               -UserPrincipalName "spray.test$i@corp.local" `
               -Path "OU=SprayLab,DC=corp,DC=local" `
               -Enabled $true -AccountPassword (ConvertTo-SecureString "BadP@ssw0rd123!" -AsPlainText -Force)
}
Add-ADGroupMember -Identity "SprayLab" -Members "spray.test1","spray.test2","spray.test3","spray.test4","spray.test5"
```

Verified domain lockout policy to ensure safe testing.

### 2. Wazuh Agent Connectivity Verification

Checked Wazuh agent status on DC01:
```bash
/var/ossec/bin/agent_control -i 001
```

**Issue encountered**: Agent was disconnected.

**Troubleshooting**:
- Wazuh manager was not listening on port 1514
- Service `wazuh-remoted` was not running
- Restarted Wazuh manager: `systemctl restart wazuh-manager`
- Confirmed port 1514 listening: `netstat -tlnp | grep 1514`
- Agent reconnected successfully

### 3. Log Collection Validation

Generated a single failed login and verified Event ID 4625 reached Wazuh:
```bash
grep "4625" /var/ossec/logs/active-responses.log
```

Confirmed required fields present: `logonType`, `subStatus`, `targetUserName`, `ipAddress`.

### 4. Rule Development

**Initial attempt** (failed):
- Attempted to match fields directly without parent rule
- Event was already decoded by rule 60122
- Rule did not trigger

**Debugging with wazuh-logtest**:
```bash
/var/ossec/bin/wazuh-logtest -t /path/to/sample_event.json
```

Identified correct parent rule (60122) and rewrote rule using `if_sid`.

**Final rule deployment**:
- Restarted Wazuh manager: `systemctl restart wazuh-manager`
- Verified rule loaded: `/var/ossec/bin/wazuh-logtest -t sample_event`

### 5. Attack Simulation

**Tool selection**:

**Attempt 1 – Hydra**:
```bash
hydra -L users.txt -p "BadP@ssw0rd123!" smb://10.10.69.10
```
- **Issue**: Invalid SMB reply error
- **Cause**: Modern Windows SMB signing requirement

**Attempt 2 – NetExec** (successful):

Installation (pipx):
```bash
pipx install git+https://github.com/Pennyw0rth/NetExec.git
```

Verification:
```bash
which netexec  # Confirmed binary path
netexec --version
```

**Password spray execution**:
```bash
netexec smb 10.10.69.10 -u spray.test1,spray.test2,spray.test3,spray.test4,spray.test5 -p "BadP@ssw0rd123!" --local-auth
```

Generated multiple Event ID 4625 events for each username.

### 6. Detection Validation

Checked Wazuh alerts:
```bash
grep "100601" /var/ossec/logs/alerts/alerts.log
```

**Result**: Rule 100601 fired successfully with alert message:
```
Windows: Possible password spraying detected from 10.10.69.50 across multiple usernames
```

Confirmed detection logic works end-to-end.

---

## False Positive Considerations

**Potential false positive sources**:
- Legitimate users mistyping passwords multiple times
- Automated applications with incorrect credentials
- Internal security tools performing authentication testing

**Mitigation strategies**:
- High threshold (5 attempts across different usernames) reduces noise
- Time window (5 minutes) filters out sporadic typos
- Different username requirement excludes single-account issues
- Correlate with subsequent successful logons to filter out legitimate users

**Testing performed**:
- Normal user behavior (1-2 failed attempts) did not trigger alert
- Only deliberate multi-account attacks triggered detection

---

## Detection Limitations

1. **Distributed attacks**: Does not detect password spray from multiple different IPs
2. **Time window**: Attackers could spray slowly (e.g., 1 attempt per minute for hours)
3. **Single account focus**: Does not detect traditional brute force against one account
4. **Log availability**: Requires reliable Windows Security log collection and SIEM ingestion
5. **Account lockout**: If domain enforces aggressive lockout policies, detection may never trigger

**Recommended enhancements**:
- Add rule for distributed spray (same username across multiple IPs)
- Add rule for traditional brute force (same IP, same username, many attempts)
- Integrate with threat intelligence to flag known malicious IPs

---

## Response Summary

1. **Identify source IP and targeted accounts**:
   - Extract IP from alert metadata
   - Review targeted usernames from correlated events

2. **Block source IP** (if confirmed malicious):
   - Add block rule to pfSense firewall
   - Document in firewall change log

3. **Investigate for post-auth activity**:
   - Search for successful logons from source IP (Event ID 4624)
   - Review subsequent lateral movement events

4. **Hardening actions**:
   - Implement account lockout policy (if not already enabled)
   - Enforce MFA for sensitive accounts
   - Review user account list and disable unused accounts
   - Deploy conditional access policies

---

## Detection Maturity

✔ Validated in lab environment
✔ Custom Wazuh rules deployed (IDs: 100600, 100601)
✔ Attack simulation performed (NetExec)
✔ End-to-end detection confirmed
✔ Threshold tuned
✔ False positive testing completed
✔ Troubleshooting documented (agent connectivity, SMB signing, tool installation)

---

## Lessons Learned

1. **Wazuh agent connectivity is critical**:
   - Agent disconnection can cause detection gaps
   - Monitor `wazuh-remoted` service status
   - Verify port 1514 listening when troubleshooting

2. **Rule development requires parent rule knowledge**:
   - Use `wazuh-logtest` to understand event decoding
   - Always identify parent rule before writing custom rules
   - Direct field matching may not work if event is pre-decoded

3. **Attack tool compatibility matters**:
   - Modern Windows requires SMB signing consideration
   - Hydra may fail on recent Windows versions
   - NetExec provides better SMB support for modern environments

4. **Correlation rules need careful threshold tuning**:
   - Balance detection speed with false positive reduction
   - Test against normal user behavior
   - Document rationale for chosen thresholds

---

## References

- MITRE ATT&CK: https://attack.mitre.org/techniques/T1110/003/
- NetExec: https://github.com/Pennyw0rth/NetExec
- Wazuh Rules Documentation: https://documentation.wazuh.com/current/user-manual/ruleset/rules.html
