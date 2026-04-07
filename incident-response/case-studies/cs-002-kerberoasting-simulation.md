# CS-002: Kerberoasting Simulation

## Scenario

Simulated Kerberoasting conditions by forcing RC4 encryption on service account `svc_sql`.

Objective:
Validate detection of weak Kerberos encryption and assess detection fidelity.

---

## Attack Simulation

1. Disabled AES support on service account
2. Forced RC4 negotiation
3. Requested service ticket using `klist get`
4. Verified Event ID 4769 with TicketEncryptionType 0x17

---

## Timeline

| Time | Event |
|------|-------|
| 10:02 | Service ticket requested |
| 10:02 | Event 4769 logged |
| 10:03 | Wazuh rule 100100 triggered |

---

## Detection Triggered

Rule ID: 100100  
Severity: Medium  
MITRE: T1558.003

---

## Investigation Steps

- Queried DC Security Log for additional 4769 events
- Confirmed multiple ticket requests
- Validated no 4672 or admin logons followed

---

## Root Cause

Service account allowed legacy RC4 encryption.

---

## Remediation

- Set msDS-SupportedEncryptionTypes = 24
- Reset password
- Re-tested

Result:
TicketEncryptionType changed to 0x12 (AES256)

---

## Lessons Learned

- Legacy encryption introduces Kerberoasting risk
- Detection thresholding should account for legitimate service behavior
- Correlation with 4624 logons improves fidelity

## Detection Fidelity

- Alert triggered immediately after RC4 ticket issuance
- No false positives during baseline monitoring
- Threshold tuning not required
- Hardening validation confirmed encryption upgrade effective