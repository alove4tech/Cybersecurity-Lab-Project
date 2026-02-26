# PB-001: Brute Force / Password Spraying (Linux SSH)

## Detection Context
Detection ID: UC-001  
Log Source: /var/log/auth.log  
Severity: Medium (High if successful login occurs)

---

## Alert Triage

1. Confirm alert details:
   - Source IP
   - Target host
   - Target username(s)
   - Time window
   - Number of attempts

2. Determine:
   - Did a successful login (Accepted password) occur?
   - Is the source IP internal or external?
   - Is the targeted account privileged?

---

## Investigation

Review authentication logs during the alert window:

- Count failed attempts
- Identify:
  - Successful logins after failures
  - New account creation
  - sudo usage
  - SSH key additions
  - Cron jobs or persistence
  - Unusual outbound connections

Correlate with:
- Firewall logs (connection frequency)
- Other hosts targeted from same IP

---

## Escalation Criteria

Escalate to High severity if:
- Successful login occurred after failures
- Privileged account targeted
- Lateral movement indicators observed
- Multiple hosts targeted

---

## Containment

If malicious activity suspected:

- Block source IP at pfSense (temporary rule)
- Disable affected account if compromised
- Isolate affected host if needed

---

## Eradication

- Remove persistence mechanisms
- Rotate compromised credentials
- Harden SSH:
  - Disable root login
  - Enforce key-based auth
  - Implement fail2ban or rate limiting

---

## Recovery

- Restore service access if impacted
- Monitor for recurrence
- Review logs for follow-up activity

---

## Post-Incident Improvements

- Adjust detection thresholds
- Implement failed → success correlation
- Add IP reputation checks (future enhancement)