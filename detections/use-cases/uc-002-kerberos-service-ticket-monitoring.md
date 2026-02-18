# UC-002: Kerberos Service Ticket Monitoring

## Objective

Monitor Kerberos service ticket activity (Event ID 4769) to detect abnormal service account usage and potential credential abuse.

---

## Baseline Behavior

Normal 4769 events observed:

- Account Name: jsmith
- Service Name: MSSQLSvc/win10-client.corp.local:1433
- Client Address: 10.10.69.52
- Ticket Encryption Type: AES256
- Failure Code: 0x0 (Success)

Service tickets are requested when users access services tied to Service Principal Names (SPNs).

---

## Suspicious Indicators

- High volume of 4769 events for a single account
- Service tickets requested for multiple SPNs in short time window
- RC4 encryption when AES is available
- Service tickets requested from unexpected hosts
- Service account requesting tickets interactively

---

## Detection Logic Concept

Alert when:

- Event ID = 4769
- AND Ticket Encryption Type = RC4 (0x17)
- OR More than X service tickets requested by same user within Y minutes
- OR Client Address not in expected subnet

---

## Response Actions

1. Identify source host
2. Validate user behavior
3. Review account privilege level
4. Check for related 4625 failures
5. Reset credentials if compromise suspected

## Observed Telemetry

Event ID: 4769

- TargetUserName: jsmith@CORP.LOCAL
- ServiceName: svc_sql
- Client Address: 10.10.69.52
- TicketEncryptionType: 0x17 (RC4-HMAC)
- SessionKeyEncryptionType: 0x12 (AES256)
- Status: 0x0 (Success)

---

## Security Observation

Although AES encryption is supported in the domain, the service ticket was issued using RC4 (0x17).

This behavior can indicate:
- Legacy encryption compatibility
- Potential Kerberoasting exposure
- Weak cryptographic configuration

---

## Detection Opportunity

Alert when:
- Event ID = 4769
- TicketEncryptionType = 0x17
- AND AES encryption is supported in the domain

Rationale:
Kerberoasting attacks rely on requesting RC4-encrypted service tickets to extract crackable hashes.

## Encryption Hardening

Initial Observation:
Service tickets for svc_sql were issued using RC4 (TicketEncryptionType: 0x17).

Root Cause:
Service account did not have msDS-SupportedEncryptionTypes configured, allowing legacy RC4 negotiation.

Remediation:
Set msDS-SupportedEncryptionTypes = 24 (AES128 + AES256 only)
Reset service account password to regenerate Kerberos keys.

Validation:
Post-change Event 4769 showed:
- TicketEncryptionType: 0x12 (AES256)
- SessionEncryptionType: 0x12

Result:
Kerberos service tickets now enforce modern AES encryption.