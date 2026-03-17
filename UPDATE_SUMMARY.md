# GitHub Documentation Updates Summary

## Date: March 17, 2026

## Overview
Updated all documentation to reflect the new UC-005 Kerberos Anomaly Detection use case and resolved numbering conflicts with planned network monitoring use cases.

---

## Changes Made

### 1. Main README.md

**Updated Detection Highlights:**
- Added UC-005 to Authentication Monitoring section
- Clarified UC-005 focuses on "correlation rules for Kerberoasting patterns"

**Updated Current Operational State:**
- Updated Wazuh rule IDs: Added 100300-100303 (Kerberos anomaly correlation rules)
- Removed old rule ranges (100200-100401, 100500-100700) that were incorrect
- Added "Kerberos anomaly detection validated" with UC-005 reference

**Updated Network Monitoring Section:**
- Corrected UC-005 description from "Blocked external access attempts" to "Kerberos anomaly detection"
- Renumbered planned use cases:
  - UC-006: Blocked external access attempts (was UC-005)
  - UC-007: Port sweep / reconnaissance (was UC-006)

**Updated Mid-Term Roadmap:**
- Marked "4768/4769 anomaly detection" as complete ✅
- Added reference to UC-005

---

### 2. docs/99-roadmap.md

**Updated Mid-Term Section:**
- Marked "4768/4769 volume anomalies (Kerberoasting signal)" as complete [x]
- Added note: "UC-005 documented"
- This now aligns with the actual delivered work

---

### 3. defensive/pfsense/syslog-forwarding.md

**Renumbered UC-005 → UC-006:**
- Updated detection metadata section (line 365-368)
- Updated validation checklist (line 535)
- Changed UC-005 to UC-006 for "Port Sweep / Network Recon"
- This fixes the conflict where UC-005 was used for both planned port sweep and actual Kerberos anomaly detection

---

## Files Modified

1. `README.md` - Main lab documentation
2. `docs/99-roadmap.md` - Project roadmap
3. `defensive/pfsense/syslog-forwarding.md` - pfSense syslog configuration

---

## Consistency Check

### Use Case Numbering (Correct)
- UC-001: SSH Brute Force Detection
- UC-002: Kerberos RC4 Service Ticket Monitoring
- UC-003: Lateral Movement Detection (Network Scanning)
- UC-004: Password Spraying Detection
- UC-005: Kerberos Anomaly Detection (Kerberoasting) ✅ NEW
- UC-006: Blocked External Access Attempts (renumbered from UC-005)
- UC-007: Port Sweep / Network Recon (renumbered from UC-006)

### Wazuh Rule IDs (Correct)
- 100100: Kerberos RC4 detection (UC-002)
- 100200-100201: Password spraying detection (UC-004)
- 100300: Kerberos RC4 base rule (UC-005)
- 100301: Single user, many SPNs (UC-005)
- 100302: Many users, same SPN (UC-005)
- 100303: High volume tickets (UC-005)

### Roadmap Status (Correct)
- Near-term: ✅ Complete
- Mid-term:
  - pfSense syslog: ✅ Complete
  - 4768/4769 anomalies: ✅ Complete (UC-005)
  - 4625 burst / password spray: ✅ Complete (UC-004)
  - 4672 privileged logon: 🔵 In Progress
- Long-term: 🔵 Planned

---

## Historical Files (Not Modified)

The following files contain historical references to UC-005 as "Port Sweep" but were **NOT** modified because they document the state of the project at that time (March 10, 2026):

- `docs/session-progress-2026-03-10.md` - Historical session notes
  - References UC-005 as planned "Port Sweep / Network Recon"
  - This was accurate at the time of the session
  - Leaving as-is preserves historical context

---

## Verification Steps

1. ✅ Use case numbering is sequential (UC-001 through UC-007)
2. ✅ No duplicate use case IDs across the repository
3. ✅ Wazuh rule IDs are unique and documented
4. ✅ Roadmap status matches actual delivered work
5. ✅ Cross-references between files are consistent
6. ✅ Planned vs. completed work is clearly distinguished

---

## Next Steps

No further documentation updates required. The GitHub repository now accurately reflects:

1. Completed Kerberos anomaly detection (UC-005) with correlation rules
2. Properly numbered planned network monitoring use cases (UC-006, UC-007)
3. Updated roadmap marking Kerberos work as complete
4. Consistent rule ID documentation across all files
