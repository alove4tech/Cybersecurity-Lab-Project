# CS-001: SSH Brute Force Simulation

## Scenario

Simulated an SSH brute force attack from the Debian attack host
against a Linux target to validate detection logic and response workflow.

Objective:
Confirm UC-001 detection accuracy and assess alert fidelity.

---

## Attack Simulation

Tool Used: hydra  
Command:

hydra -l testuser -P rockyou.txt ssh://10.10.69.X

Result:
Multiple failed login attempts generated within short time window.

---

## Timeline

| Time | Event |
|------|-------|
| 14:02 | Multiple failed SSH attempts initiated |
| 14:03 | /var/log/auth.log populated with failures |
| 14:03 | Wazuh alert triggered |
| 14:05 | Manual review initiated |

---

## Detection Triggered

Detection ID: UC-001  
Log Source: Linux auth.log  
Severity: Medium  

Alert Condition:
Multiple failed SSH attempts from same source IP within defined threshold.

---

## Investigation

Reviewed:

- /var/log/auth.log
- Firewall logs for connection volume
- Checked for:
  - Successful login events
  - New user creation
  - sudo usage
  - Persistence artifacts

Findings:
- No successful login occurred
- No lateral movement observed
- Source IP confined to lab attack VM

---

## Root Cause

Intentional brute force simulation for detection validation.

---

## Containment

- Temporary firewall block tested
- No account compromise confirmed

---

## Detection Performance

- Alert triggered within seconds of threshold breach
- No false positives observed
- Detection logic working as intended

---

## Lessons Learned

- Threshold of X attempts within Y minutes provides strong signal
- Correlation with successful login improves severity accuracy
- Future enhancement: Detect distributed spray attempts