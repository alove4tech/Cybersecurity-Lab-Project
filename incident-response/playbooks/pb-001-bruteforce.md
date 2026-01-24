# PB-001: Brute Force / Password Spraying (Linux SSH)

## Triage
- Confirm alert details (src IP, target host, username, time window)
- Determine whether any successful login occurred

## Containment
- Block source IP on pfSense (temporary rule)
- If compromise suspected: isolate host from network

## Investigation
- Review auth logs around the time window
- Look for:
  - Successful logins after failures
  - New users, sudo usage, persistence mechanisms
  - Unusual outbound connections

## Recovery
- Reset affected credentials
- Patch exposed services and enforce MFA where possible
- Tighten SSH policy (no root login, key auth, fail2ban)

## Lessons Learned
- Update thresholds/allowlists to reduce noise
- Add correlation (failed → success) if feasible
