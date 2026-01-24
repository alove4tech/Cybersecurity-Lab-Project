# UC-001: SSH Brute Force Detection

## Objective
Detect repeated failed SSH authentication attempts and generate an actionable alert.

## Data Sources
- Linux auth logs (e.g., `/var/log/auth.log`)

## Detection Logic (high level)
- Multiple failed SSH logins from the same source IP in a short time window
- Optional: followed by a successful login from the same IP

## Validation Plan
1. Generate failed logins from an attacker host (e.g., `hydra`, `ssh` with wrong passwords)
2. Confirm events appear in logs
3. Confirm SIEM alert fires (Wazuh/ELK)
4. Record tuning notes (thresholds, allowlists)

## Response Actions
- Identify source IP, account targeted, and time window
- Block IP at firewall if appropriate
- Check for successful logins and suspicious post-auth activity
