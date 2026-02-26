# PB-002: Kerberos RC4 Service Ticket Alert

## Alert Trigger
Detection ID: UC-002  
Event ID: 4769  
Condition: TicketEncryptionType = 0x17 (RC4)

---

## Severity Assessment
Medium (elevate to High if correlated with privilege escalation or lateral movement)

## Escalation Criteria

Escalate to High severity if:
- Multiple SPNs requested in short time window
- RC4 observed on privileged account
- Correlated 4624 privileged logon follows
- Source host is unexpected

---

## Initial Triage

1. Identify:
   - TargetUserName
   - ServiceName
   - Client Address
   - Time of event

2. Validate:
   - Is RC4 expected for this service?
   - Is the service account legacy?

---

## Scope Investigation

- Query for:
  - Additional 4769 events for same user
  - 4624 logons from same source IP
  - 4672 privileged logons
  - 4625 failed attempts

- Check:
  - Volume of ticket requests
  - Multiple SPNs requested
  - Activity outside business hours

---

## Containment

If suspicious:

- Disable affected account
- Reset service account password
- Force AES-only encryption
- Block suspicious IP at firewall

---

## Eradication

- Remove RC4 support via msDS-SupportedEncryptionTypes
- Audit other service accounts
- Confirm no lateral movement occurred

---

## Recovery

- Re-enable account if false positive
- Confirm AES encryption enforced
- Monitor for recurrence

---

## Post-Incident Actions

- Tune detection thresholds
- Update allowlists
- Document encryption configuration baseline