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

## Detection Limitations

- Does not detect AES-based Kerberoasting
- Requires proper audit policy configuration
- Relies on accurate event ingestion

---

## Detection Maturity

✔ Custom Wazuh rule implemented (ID 100100)  
✔ Downgrade reproduced in lab  
✔ Remediation validated  
✔ Playbook documented (PB-002)  
✔ Case study documented (CS-002)