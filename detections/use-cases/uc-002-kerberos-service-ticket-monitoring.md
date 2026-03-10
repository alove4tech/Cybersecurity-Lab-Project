# UC-002: Kerberos Service Ticket Monitoring (RC4 Downgrade Detection)

## Detection Metadata

- Detection ID: UC-002
- Log Source: Windows Security Log
- Event ID(s): 4769
- Domain: corp.local
- Severity: Medium (High if correlated with privilege activity)
- MITRE ATT&CK:
  - T1558.003 – Kerberoasting
- Data Sensitivity: Domain authentication telemetry

---

## Objective

Detect weak Kerberos encryption (RC4) in service ticket issuance
to identify potential Kerberoasting exposure or legacy configuration risk.

---

## Log Field Mapping

Event ID: 4769

Relevant Fields:

- TargetUserName
- ServiceName
- Client Address
- TicketEncryptionType
- SessionKeyEncryptionType
- Status

Example Observed Event:

- TargetUserName: jsmith@CORP.LOCAL
- ServiceName: svc_sql
- Client Address: 10.10.69.52
- TicketEncryptionType: 0x17 (RC4-HMAC)
- SessionKeyEncryptionType: 0x12 (AES256)
- Status: 0x0

---

## Baseline Behavior

Normal domain configuration:
- AES128 / AES256 encryption
- Standard service access patterns
- Consistent client IP usage

---

## Detection Logic

Trigger alert when:

- Event ID = 4769
- AND TicketEncryptionType = 0x17 (RC4)

Optional Correlation Enhancements:

- Multiple SPNs requested by same user within X minutes
- 4625 failures preceding 4769 activity
- 4672 privileged logon following ticket issuance
- Client IP outside expected subnet

---

## Detection Rationale

Kerberoasting relies on requesting RC4-encrypted service tickets
that can be offline cracked.

Modern domains supporting AES should not issue RC4 tickets
unless legacy configuration permits downgrade.

---

## Validation Procedure

1. Force RC4-only encryption on service account
2. Request service ticket via:klist get <SPN>
3. Confirm Event 4769 logs 0x17
4. Validate Wazuh rule ID 100100 fires

---

## False Positive Considerations

- Legacy service accounts
- Old operating systems
- Compatibility configurations

Mitigation:
- Maintain inventory of approved legacy accounts
- Monitor volume anomalies

---

## Hardening Action (Defensive Outcome)

Root Cause:
msDS-SupportedEncryptionTypes not configured.

Remediation:
- Set msDS-SupportedEncryptionTypes = 24
- Reset service account password

Validation:
Post-remediation 4769 shows:
- TicketEncryptionType: 0x12 (AES256)

---

## Wazuh Rule Configuration

**Rule File:** `/var/ossec/ruleset/rules/local_rules.xml` (on Wazuh Manager)

**Rule Definition:**

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

**Rule Breakdown:**
- `if_sid>61602`: Inherits from Wazuh's built-in Windows 4769 decoder
- `level="12"`: High severity alert (10-12 range for critical)
- `TicketEncryptionType>0x17`: Matches RC4-HMAC encryption
- MITRE ATT&CK T1558.003: Kerberoasting technique

**Testing the Rule:**

```bash
# 1. On a Windows domain-joined machine with admin rights:
# Force RC4 encryption on a service account
Set-ADServiceAccount -Identity <service_account> -ServicePrincipalNames "HTTP/<server>.corp.local"

# 2. Request service ticket to trigger RC4 downgrade:
klist get HTTP/<server>.corp.local

# 3. Verify 4769 event in Windows Event Viewer (Security log):
# Look for TicketEncryptionType: 0x17

# 4. Check Wazuh Dashboard for rule 100100 alert
# Navigate to: Security Events → Events viewer
# Search for rule.id: 100100
```

**Expected Alert in Wazuh Dashboard:**

```
Rule: 100100 (level 12)
Description: Kerberos service ticket issued with RC4 encryption - Potential Kerberoasting
Location: DC01
Source IP: 10.10.69.52
Fields:
  - TargetUserName: jsmith@CORP.LOCAL
  - ServiceName: HTTP/fileserver
  - TicketEncryptionType: 0x17
  - SessionKeyEncryptionType: 0x12
MITRE ATT&CK: T1558.003
```

---

## Evidence & Screenshots

### 1. Raw Windows 4769 Event

*[Screenshot: Windows Event Viewer showing Event ID 4769 with TicketEncryptionType: 0x17]*

**Location:** `assets/evidence/uc-002-001-raw-event.png`

Key fields to document:
- Event ID: 4769
- TicketEncryptionType: 0x17 (RC4-HMAC)
- SessionKeyEncryptionType: 0x12 (AES256)
- ServiceName: HTTP/<target>
- TargetUserName: <attacker>
- Status: 0x0 (success)

---

### 2. Wazuh Alert in Dashboard

*[Screenshot: Wazuh Security Events showing rule 100100 alert]*

**Location:** `assets/evidence/uc-002-002-wazuh-alert.png`

Screenshot should show:
- Alert rule ID 100100
- Level 12 (critical)
- Description text
- Host: DC01
- Source IP address
- Full event details panel

---

### 3. Service Account Configuration (Pre-Remediation)

*[Screenshot: Active Directory Users and Computers showing service account properties]*

**Location:** `assets/evidence/uc-002-003-service-account-pre.png`

Document:
- Service account name
- SPN configuration
- msDS-SupportedEncryptionTypes value (should be empty or missing)
- Account status

---

### 4. Service Account Configuration (Post-Remediation)

*[Screenshot: Active Directory Users and Computers after hardening]*

**Location:** `assets/evidence/uc-002-004-service-account-post.png`

Document:
- msDS-SupportedEncryptionTypes: 24 (AES128 + AES256)
- Service account status
- Confirmation of password reset

---

### 5. Post-Remediation 4769 Event

*[Screenshot: Windows Event Viewer showing 4769 with AES encryption]*

**Location:** `assets/evidence/uc-002-005-post-remediation-event.png`

Should show:
- Event ID: 4769
- TicketEncryptionType: 0x12 (AES256)
- Same service account
- No RC4 encryption

---

### 6. Wazuh Alert Timeline

*[Screenshot: Wazuh timeline showing alert triage and resolution]*

**Location:** `assets/evidence/uc-002-006-timeline.png`

Document:
- Alert trigger time
- Investigation notes
- Remediation action
- Confirmation timestamp

---

## Detection Limitations

- Does not detect AES-based Kerberoasting (requires behavioral analysis)
- Requires proper audit policy configuration
- Relies on accurate event ingestion
- May miss encrypted Kerberoasting if attacker uses valid tools (e.g., Rubeus with AES)

---

## Future Enhancements

- **Correlation Rule:** Alert when multiple RC4 tickets requested in short window
- **Behavioral Detection:** Baseline normal Kerberos ticket patterns per user
- **Machine Learning:** Detect anomalies in service ticket request frequency
- **Automated Response:** Disable account with Wazuh Active Response (future)

---

## Detection Maturity

✔ Custom Wazuh rule implemented (ID 100100)
✔ Rule XML documented in use case
✔ Downgrade reproduced in lab
✔ Remediation validated
✔ Playbook documented (PB-002)
✔ Case study documented (CS-002)
⏳ Evidence screenshots (add to assets/evidence/)