# UC-001: SSH Brute Force Detection

## Detection Metadata

- Detection ID: UC-001
- Log Source: Linux /var/log/auth.log
- Platform: Debian / Ubuntu
- Severity: Medium (High if successful login follows)
- MITRE ATT&CK:
  - T1110 – Brute Force
  - T1110.003 – Password Spraying
- Data Sensitivity: Authentication telemetry

---

## Objective

Detect repeated failed SSH authentication attempts from a single source IP
within a defined time window to identify brute force or password spray activity.

---

## Log Source & Field Mapping

Example log entry: 
- Failed password for invalid user testuser from 10.10.69.50 port 54432 ssh2

Key Fields Parsed:

- Source IP
- Username
- Result (Failed / Accepted)
- Timestamp

---

## Detection Logic

Trigger alert when:

- ≥ X failed SSH attempts
- From same source IP
- Within Y minutes

Optional Correlation Enhancement:
- Escalate severity if:
  - Successful login occurs after failures
  - Privileged account targeted

---

## Threshold Tuning

Initial threshold:
- 5 failed attempts within 2 minutes

Adjusted threshold (after testing):
- 8 failed attempts within 3 minutes

Rationale:
Reduces noise from mistyped passwords while maintaining sensitivity.

---

## Validation Procedure

1. Execute controlled brute force:hydra -l testuser -P wordlist.txt ssh://10.10.69.X
2. Confirm failed entries in auth.log
3. Verify SIEM ingestion
4. Confirm alert triggers
5. Test false positive scenario (normal mistyped login)

---

## False Positive Considerations

- Users mistyping passwords
- Automated configuration tools retrying connections
- Internal vulnerability scans

Mitigation:
- Correlate with success events
- Exclude known management hosts

---

## Detection Limitations

- Does not detect distributed password spray across multiple IPs
- Requires log ingestion reliability
- Threshold tuning environment-dependent

---

## Response Summary

- Identify source IP and targeted accounts
- Block IP at firewall (if malicious)
- Investigate for post-auth activity
- Harden SSH configuration (key-based auth, rate limiting)

---

## Detection Maturity

✔ Validated in lab  
✔ Threshold tuned  
✔ Correlation logic defined  
✔ Playbook documented (PB-001)  
✔ Case study documented (CS-001)