# UC-005: Kerberos Anomaly Detection (Kerberoasting)

## Detection Metadata

- Detection ID: UC-005
- Log Source: Windows Security Log
- Event ID(s): 4769
- Domain: corp.local
- Severity: Medium (High if correlated with privilege activity)
- MITRE ATT&CK:
  - T1558.003 – Kerberoasting
- Data Sensitivity: Domain authentication telemetry

---

## Objective

Detect Kerberoasting attack patterns using Wazuh correlation rules. This use case builds upon basic RC4 ticket detection (UC-002) to identify abnormal Kerberos service ticket activity that may indicate credential theft or automated Kerberoasting tools.

Detection focuses on:

- Single account requesting many service tickets (SPN enumeration)
- Multiple accounts requesting the same service ticket (targeted Kerberoasting)
- High volume of Kerberos ticket requests (noisy tools or automation)
- Suspicious Kerberos activity originating from one host

---

## Lab Environment

### Systems

- **Domain Controller:** Windows Server 2022
  - Hostname: DC01
  - IP: 10.10.69.10
  - Role: Kerberos Key Distribution Center (KDC)

- **Wazuh SIEM:**
  - IP: 10.10.69.20
  - Windows agent installed on DC01
  - Collects Windows Security events in real-time

- **Attack Host:** Debian penetration testing VM
  - Used Impacket tools to simulate Kerberoasting attacks
  - IP: 10.10.69.52

- **Network:** 10.10.69.0/24 isolated lab network

### Prerequisites

- Windows Security logs confirmed collected in Wazuh
- Event ID 4769 telemetry validated before writing rules
- Time synchronization between KDC and attack host
- Impacket tools installed on attack host (GetUserSPNs.py)

---

## Log Field Mapping

### Event ID: 4769 - Kerberos Service Ticket Requested

**Relevant Fields:**

- `data.win.system.eventID` = 4769
- `data.win.eventdata.serviceName` - SPN being requested
- `data.win.eventdata.targetUserName` - Account requesting ticket
- `data.win.eventdata.ipAddress` - Client IP address
- `data.win.eventdata.ticketEncryptionType` - Encryption type (0x17 = RC4, 0x12 = AES256)
- `data.win.eventdata.status` - Request result (0x0 = success)

**Example Event:**

```json
{
  "win": {
    "system": {
      "eventID": 4769
    },
    "eventdata": {
      "serviceName": "svc_sql",
      "targetUserName": "jsmith@CORP.LOCAL",
      "ipAddress": "10.10.69.52",
      "ticketEncryptionType": "0x17",
      "status": "0x0"
    }
  }
}
```

---

## Detection Logic

### Rule Chain Architecture

The detection uses a hierarchical rule chain:

```
Rule 100100 (RC4 Detection)
    ↓
Rule 100300 (Lab Base Rule)
    ↓
Rules 100301-100303 (Correlation Rules)
```

- **100100:** Base RC4 ticket detection (from UC-002)
- **100300:** Simplifies correlation logic by grouping all RC4 ticket events
- **100301:** Detects single account requesting many SPNs (SPN enumeration)
- **100302:** Detects multiple accounts requesting same SPN (targeted Kerberoasting)
- **100303:** Detects high volume ticket activity (noisy tools)

---

## Wazuh Rule Configuration

**Rule File:** `/var/ossec/ruleset/rules/local_rules.xml` (on Wazuh Manager)

### Rule 100300 - Base Lab Rule

This rule groups all RC4 Kerberos ticket events for correlation.

```xml
<rule id="100300" level="3">
  <if_sid>100100</if_sid>
  <description>LAB: Kerberos RC4 ticket observed</description>
  <group>windows,kerberos,kerberoast_lab,rc4_ticket</group>
</rule>
```

**Purpose:**
- Creates a unified target for correlation rules
- Reduces complexity of rule chaining
- All subsequent correlation rules match against this rule

**Important Note:**
This rule uses `if_sid>100100` (custom rule), NOT `60103` (built-in Wazuh rule). The built-in rule was not generating alerts in this environment, so the custom RC4 detection rule (100100) must be the parent.

---

### Rule 100301 - Single User Requesting Multiple SPNs

Detects SPN enumeration pattern where one account requests many different service tickets.

```xml
<rule id="100301" level="10" frequency="4" timeframe="180">
  <if_matched_sid>100300</if_matched_sid>
  <same_field>win.eventdata.targetUserName</same_field>
  <different_field>win.eventdata.serviceName</different_field>
  <description>LAB: Possible Kerberoasting - single account requested tickets for many different SPNs</description>
  <group>kerberoast_lab,kerberos,spn_enumeration,credential_access</group>
</rule>
```

**Detection Logic:**
- Matches when same user requests 4+ different SPNs within 3 minutes
- Pattern: Targeting phase of Kerberoasting (discovering service accounts)
- High severity (level 10) - indicates active credential theft preparation

**Threshold Tuning:**
- `frequency="4"`: 4 different SPNs triggers alert
- `timeframe="180"`: 3-minute window
- Adjust based on legitimate domain activity patterns

---

### Rule 100302 - Multiple Users Requesting Same SPN

Detects targeted Kerberoasting of a specific service account.

```xml
<rule id="100302" level="9" frequency="2" timeframe="600">
  <if_matched_sid>100300</if_matched_sid>
  <same_field>win.eventdata.serviceName</same_field>
  <different_field>win.eventdata.targetUserName</different_field>
  <description>LAB: Possible SPN targeting - multiple users requesting same service ticket</description>
  <group>kerberoast_lab,kerberos,spn_targeting,credential_access</group>
</rule>
```

**Detection Logic:**
- Matches when 2+ different users request the same SPN within 10 minutes
- Pattern: Post-exploitation - attacker uses compromised accounts to target high-value service account
- Severity 9 (slightly lower than 100301 - could be legitimate shared service access)

**Threshold Tuning:**
- `frequency="2"`: 2 different users triggers alert
- `timeframe="600"`: 10-minute window
- Lower threshold due to higher false positive potential (legitimate shared service access)

---

### Rule 100303 - High Volume Kerberos Activity

Detects noisy Kerberoasting or automated tools.

```xml
<rule id="100303" level="10" frequency="4" timeframe="120">
  <if_matched_sid>100300</if_matched_sid>
  <description>LAB: Kerberos anomaly - high volume of service ticket requests</description>
  <group>kerberoast_lab,kerberos,volume_anomaly,credential_access</group>
</rule>
```

**Detection Logic:**
- Matches when 4+ RC4 tickets are issued within 2 minutes (any user, any SPN)
- Pattern: Automated Kerberoasting tools or aggressive SPN enumeration
- High severity (level 10) - indicates likely attack tooling

**Threshold Tuning:**
- `frequency="4"`: 4 tickets triggers alert
- `timeframe="120"`: 2-minute window
- Short window to catch rapid automated activity

---

## Validation Procedure

### Attack Simulation Using Impacket

#### Prerequisites

1. **Time Synchronization** (CRITICAL)
   ```bash
   # Install NTP client on attack host
   sudo apt install ntpsec-ntpdate

   # Sync time with domain controller
   sudo ntpdate 10.10.69.10
   ```

   **Why:** Kerberos is highly sensitive to clock skew. Even 5-minute drift causes ticket request failures.

2. **Verify Target SPNs Exist**
   ```bash
   # List SPNs on a user account
   setspn -Q */<username>

   # List service accounts
   setspn -Q */svc_*
   ```

#### Testing Rule 100301 (Single User, Many SPNs)

**Attack Command:**
```bash
# Request tickets for multiple SPNs as one user
python3 GetUserSPNs.py corp.local/jsmith:Password! -dc-ip 10.10.69.10 -request
```

**Expected Result:**
- GetUserSPNs.py enumerates all service accounts with SPNs
- Requests RC4 service tickets for each discovered SPN
- Generates multiple Event 4769 events (one per SPN)
- Rule 100301 fires after 4+ different SPNs requested within 3 minutes

**Wazuh Alert:**
```
Rule: 100301 (level 10)
Description: Possible Kerberoasting - single account requested tickets for many different SPNs
Fields:
  - targetUserName: jsmith@CORP.LOCAL
  - Multiple serviceName values (svc_sql, svc_test_rc4, etc.)
```

---

#### Testing Rule 100302 (Multiple Users, Same SPN)

**Attack Commands:**
```bash
# Request same SPN as user1
python3 GetUserSPNs.py corp.local/jsmith:Password! -dc-ip 10.10.69.10 -request-user svc_sql

# Request same SPN as user2
python3 GetUserSPNs.py corp.local/mjones:Password! -dc-ip 10.10.69.10 -request-user svc_sql
```

**Expected Result:**
- Two different users (jsmith, mjones) request tickets for the same SPN (svc_sql)
- Generates two Event 4769 events with matching serviceName
- Rule 100302 fires when 2+ users request same SPN within 10 minutes

**Wazuh Alert:**
```
Rule: 100302 (level 9)
Description: Possible SPN targeting - multiple users requesting same service ticket
Fields:
  - serviceName: svc_sql
  - Multiple targetUserName values (jsmith, mjones)
```

---

#### Testing Rule 100303 (High Volume)

**Attack Command:**
```bash
# Rapid SPN enumeration (no delay between requests)
python3 GetUserSPNs.py corp.local/jsmith:Password! -dc-ip 10.10.69.10 -request
```

**Expected Result:**
- GetUserSPNs.py requests tickets for all SPNs rapidly
- Generates 4+ Event 4769 events within 2 minutes
- Rule 100303 fires on volume threshold

**Wazuh Alert:**
```
Rule: 100303 (level 10)
Description: Kerberos anomaly - high volume of service ticket requests
Fields:
  - Count: 4+ events within 120 seconds
```

---

## Troubleshooting

### Issue 1: Clock Skew Too Great

**Symptoms:**
- GetUserSPNs.py fails with "KDC_ERR_S_PRINCIPAL_UNKNOWN"
- Event 4769 not generated in Windows Security logs
- Status field shows error codes (not 0x0)

**Root Cause:**
- Attack host clock drifted from Domain Controller by >5 minutes
- Kerberos rejects tickets with timestamp skew

**Solution:**
```bash
# Install NTP client
sudo apt install ntpsec-ntpdate

# Sync time with DC
sudo ntpdate 10.10.69.10

# Verify sync
date
```

**Prevention:**
- Configure NTP on all lab systems
- Use cron job to sync daily if needed
- Monitor time drift in logs

---

### Issue 2: Wrong SID in Correlation Rules

**Symptoms:**
- Base rule 100100 fires (RC4 ticket detected)
- Correlation rules (100301-100303) do NOT fire
- No correlation alerts in Wazuh dashboard

**Root Cause:**
- Initial attempt used `if_sid>60103` (built-in Wazuh rule)
- Wazuh was not generating built-in 60103 alerts in this environment
- Correlation rules couldn't match events from non-existent parent

**Solution:**
- Change all correlation rules to use `if_matched_sid>100300` (custom base rule)
- Ensure rule 100300 uses `if_sid>100100` (actual firing rule)
- Verify rule chain: 100100 → 100300 → 100301/100302/100303

---

### Issue 3: Field Name Mismatch

**Symptoms:**
- Rule syntax errors in Wazuh
- Wazuh manager logs XML parsing errors
- Wazuh manager fails to restart

**Root Cause:**
- GUI shows fields like `TargetUserName` (PascalCase)
- Rule engine expects `targetUserName` (camelCase)
- Copied field names from Wazuh GUI without checking decoder

**Solution:**
- Check Wazuh decoder for correct field names:
  ```bash
  cat /var/ossec/ruleset/decoders/windows-decoder.xml
  ```
- Use `win.eventdata.targetUserName` (not `win.eventdata.TargetUserName`)
- Test rule syntax with:
  ```bash
  /var/ossec/bin/ossec-logtest -t local_rules.xml
  ```

---

### Issue 4: Correlation Thresholds Too High

**Symptoms:**
- Attack simulation completes successfully
- Correlation rules do not fire
- Base rule 100300 fires, but no correlation alerts

**Root Cause:**
- Initial thresholds were too aggressive for lab size
- Lab has limited users/services, so normal activity is low
- Attack simulation didn't hit frequency counts

**Solution:**
- Reduce thresholds for lab testing:
  - 100301: `frequency="4"` (was testing with 10)
  - 100302: `frequency="2"` (was testing with 5)
  - 100303: `frequency="4"` (was testing with 8)
- Increase thresholds for production deployment based on baseline
- Document threshold tuning decisions

---

### Issue 5: Wazuh Manager Won't Start

**Symptoms:**
- `systemctl status wazuh-manager` shows "failed"
- Rule syntax errors in logs
- Dashboard shows "No connection to manager"

**Root Cause:**
- XML syntax error in `local_rules.xml`
- Missing closing tags or malformed elements
- Unclosed comments or special characters

**Solution:**
1. Check logs for specific error:
   ```bash
   journalctl -u wazuh-manager -n 50
   ```

2. Validate XML syntax:
   ```bash
   xmllint --noout /var/ossec/ruleset/rules/local_rules.xml
   ```

3. Test rule parsing:
   ```bash
   /var/ossec/bin/ossec-logtest -t local_rules.xml
   ```

4. Fix syntax errors and restart:
   ```bash
   systemctl restart wazuh-manager
   systemctl status wazuh-manager
   ```

---

## Baseline Behavior

### Normal Kerberos Ticket Activity

In a typical Active Directory domain:

- Users request tickets for services they use regularly
- Most requests use AES256 encryption (0x12)
- Single user requesting 2-3 different SPNs per hour is normal
- Multiple users accessing shared services (e.g., file servers) is expected
- RC4 tickets should be rare (legacy systems or misconfigurations only)

### Anomaly Indicators

**Warning Signs:**
- Single user requesting 10+ different SPNs in short window
- Multiple accounts targeting the same high-value service account
- Sudden spike in RC4 ticket usage
- Kerberos requests from unusual client IPs
- Failed ticket requests followed by successful ones (credential cracking)

---

## False Positive Considerations

### Legitimate Use Cases

**Rule 100301 (Single User, Many SPNs):**
- IT administrators managing multiple services
- Service discovery tools during deployment
- Application servers accessing multiple backend services
- False positives: Low with proper threshold tuning

**Rule 100302 (Multiple Users, Same SPN):**
- Shared service accounts (e.g., database connections)
- Load balancers or application pools
- Scheduled tasks running under different service accounts
- False positives: Moderate - maintain service account inventory

**Rule 100303 (High Volume):**
- Bulk administrative operations
- Automated deployment scripts
- Service discovery scans during maintenance
- False positives: Low - 2-minute window catches only rapid activity

### Mitigation Strategies

1. **Service Account Inventory**
   - Document all service accounts and expected SPN access patterns
   - Tag accounts as "shared" or "dedicated"
   - Maintain whitelist for legitimate multi-user access

2. **User Behavior Baselines**
   - Track typical ticket request patterns per user
   - Identify power users vs. normal users
   - Seasonal adjustments (more activity during business hours)

3. **Whitelisting**
   - Add known-administrator groups to exception lists
   - Exclude maintenance windows from correlation
   - Document all exceptions with justification

---

## Detection Limitations

1. **Does Not Detect AES-Based Kerberoasting**
   - Modern Kerberoasting tools (e.g., Rubeus) can request AES tickets
   - Rules only trigger on RC4 tickets (0x17)
   - Behavioral analysis needed for AES attacks

2. **Requires RC4 Ticket Presence**
   - Domains configured with AES-only will not generate alerts
   - Attackers can avoid RC4 if domain doesn't support downgrade

3. **Time Window Constraints**
   - Attackers can stay below thresholds (e.g., 1 SPN per hour)
   - Low-and-slow techniques evade detection

4. **Relies on Event Collection**
   - If Wazuh agent stops, detection gaps occur
   - Log rotation can hide historical data

5. **No Contextual Awareness**
   - Rules don't know if user is authorized for SPN access
   - Cannot distinguish between legitimate admin and compromised admin

---

## Future Enhancements

### Near-Term Improvements

- **Add Time-Based Correlation:** Detect Kerberos activity outside business hours
- **Client IP Tracking:** Alert on Kerberos requests from unexpected subnets
- **Failure Correlation:** Correlate 4769 failures with successful requests
- **Privilege Correlation:** Alert if 4769 ticket followed by 4672 (admin assignment)

### Long-Term Enhancements

- **Machine Learning:** Train models on normal Kerberos patterns per user
- **User Risk Scores:** Combine multiple Kerberos anomalies into risk score
- **Automated Response:** Disable account or force password reset via Active Response
- **Behavioral Profiling:** Detect deviations from baseline per user/SPN combination

---

## MITRE ATT&CK Mapping

| Tactic | Technique | Sub-technique | Detection Method |
|--------|-----------|---------------|------------------|
| Credential Access | T1558 | .003 - Kerberoasting | Correlation rules 100301-100303 |

### Technique Coverage

**T1558.003 - Kerberoasting:**

- **Rule 100301:** Detects SPN enumeration phase
- **Rule 100302:** Detects post-exploitation targeting phase
- **Rule 100303:** Detects automated tooling

---

## Detection Maturity

✔ Custom Wazuh correlation rules implemented (IDs 100300-100303)
✔ All 3 detection patterns validated with real Kerberoasting simulation
✔ Impacket GetUserSPNs.py attack simulation documented
✔ Troubleshooting guide documented (5 common issues + solutions)
✔ Threshold tuning decisions documented
✔ False positive mitigation strategies documented
✔ MITRE ATT&CK T1558.003 mapped
⏳ Behavioral detection (AES-based Kerberoasting) - future work
⏳ Machine learning anomaly detection - future work

---

## Related Documentation

- **UC-002:** Kerberos RC4 Service Ticket Monitoring (base rule 100100)
- **PB-002:** Kerberos RC4 Incident Response Playbook
- **CS-002:** Kerberos RC4 Case Study
- **01-architecture-diagram.md:** Lab network diagram and AD design
- **04-wazuh-deployment.md:** Wazuh installation and agent configuration

---

## Summary

This use case demonstrates how correlation rules in Wazuh can detect Kerberoasting attack patterns beyond simple RC4 ticket detection. By correlating Kerberos service ticket events across users, SPNs, and time, the detection catches SPN enumeration, targeted service account attacks, and high-volume automated tools.

The lab validated all three correlation rules using Impacket's GetUserSPNs.py, providing real-world attack telemetry for detection tuning. Troubleshooting revealed critical dependencies (time synchronization, correct SID chaining, field name accuracy) that are essential for successful Wazuh correlation rules.

**Key Takeaways:**

1. Correlation rules require correct parent SID chaining - test chain end-to-end
2. GUI field names may differ from decoder field names - always check XML
3. Kerberos is sensitive to clock skew - sync time before testing
4. Threshold tuning is environment-specific - lab vs production differs
5. Rule failures can be silent - verify with active attack simulation

**Next Steps:**

- Expand to detect AES-based Kerberoasting (behavioral analysis)
- Implement user baseline tracking for anomaly detection
- Add automated response capabilities via Active Response
