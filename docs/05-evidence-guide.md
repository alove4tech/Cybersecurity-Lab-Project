# Evidence Collection Guide

Screenshots and artifacts that validate detections in this lab. When capturing evidence for a use case or case study, follow the conventions below so the gallery stays consistent.

## Directory layout

Drop screenshots under `assets/evidence/` using this naming pattern:

```
assets/evidence/
  uc-NNN-NNN-description.png
  cs-NNN-NNN-description.png
```

Examples:

- `uc-002-001-raw-event.png` — Raw Windows 4769 event from UC-002
- `cs-003-001-multiple-destinations.png` — Wazuh alert from CS-003

## What to capture

### Detection evidence (UC-XXX)

1. **Raw source event** — the log entry that triggered the detection (Event Viewer, auth.log, filterlog)
2. **Wazuh alert** — the alert in the Wazuh Dashboard events viewer showing rule ID, severity, and description
3. **Pre-remediation state** — configuration before the fix (e.g., service account properties)
4. **Post-remediation state** — configuration after the fix (e.g., AES encryption enforced)
5. **Post-remediation event** — clean event showing the fix worked

### Case study evidence (CS-XXX)

1. **Primary alert** — the main detection that triggered the investigation
2. **Correlated alerts** — any secondary alerts that fired during the scenario
3. **Firewall / network logs** — pfSense filterlog entries showing attack traffic
4. **Authentication events** — Windows Security events (4624, 4625, 4672) related to the scenario
5. **Attacker tooling** — terminal showing the attack commands and results
6. **Containment** — firewall rules, account disable, or other response actions

## Screenshot guidelines

- **Format:** PNG preferred
- **Resolution:** High enough to read text (at least 1280px wide)
- **Redaction:** Blur or crop any real credentials, API keys, or personal data
- **Annotations:** Circle or highlight the key field if the screenshot is busy
- **Timestamps:** Leave timestamps visible when possible — they help with timeline correlation

## Referencing in documentation

Use relative paths in markdown:

```markdown
*[Screenshot: Wazuh alert showing rule 100100]*

**Location:** `assets/evidence/uc-002-002-wazuh-alert.png`
```

## Outstanding evidence

The following use cases and case studies have placeholder screenshots that still need to be captured:

| ID | Evidence needed | Count |
|-----|----------------|-------|
| UC-002 | Raw event, Wazuh alert, pre/post remediation, timeline | 6 |
| CS-003 | Multiple destinations alert, port sweep alert, firewall logs, failed logons, attacker processes, containment rule | 6 |
| CS-004 | Encoded PowerShell alert, bypass alert, credential dump alert, WMI execution alert, Sysmon events, containment rule | 6 |

**Total placeholders:** 18
