# Detection Engineering

This section documents detection use cases developed and validated within the cybersecurity homelab.

Each detection follows a structured lifecycle:

1. Generate controlled telemetry (attack simulation)
2. Validate raw logs at source
3. Develop detection logic (Wazuh rule / query)
4. Trigger and verify alert
5. Tune thresholds and reduce false positives
6. Document response workflow (see Incident Response section)
7. Implement hardening where applicable

---

## Detection Methodology

Detections are built using:

- Windows Security Event Logs
- Linux authentication logs
- Firewall telemetry (pfSense)
- Kerberos authentication events
- Service ticket behavior analysis

Each use case includes:

- Detection Metadata
- Log Source & Field Mapping
- Detection Logic
- Threshold Tuning
- Validation Procedure
- False Positive Considerations
- Detection Limitations
- Defensive Hardening Actions
- MITRE ATT&CK Mapping

---


## Wazuh Rule Deployment Status

The current custom Wazuh ruleset contains 26 deployed rules mapped to the seven documented use cases.

| Use Case | Rule IDs | Coverage | Status |
|----------|----------|----------|--------|
| UC-001 SSH Brute Force | 100001, 100002, 100003 | SSH authentication failures, 8 failures/3 minutes, brute force followed by success | 🟢 Validated |
| UC-002 Kerberos RC4 | 100100, 100101 | Kerberos Event ID 4769 RC4 service ticket detection | 🟢 Validated |
| UC-003 Lateral Movement | 100200, 100201, 100400, 100401 | pfSense filterlog base parsing, multi-destination scans, port sweeps, port scans | 🟢 Validated |
| UC-004 Password Spraying | 100600, 100601 | Event ID 4625 failures across multiple usernames from one source IP | 🟢 Validated |
| UC-005 Kerberos Anomaly | 100300, 100301, 100302, 100303 | SPN enumeration, targeted SPN activity, high-volume Kerberos ticket requests | 🟢 Validated |
| UC-006 Privileged Logon | 100500, 100501, 100502 | Privileged Windows logons, service account filtering, remote admin logon correlation | 🟢 Validated |
| UC-007 Suspicious Process | 100800, 100801, 100802, 100803, 100804, 100805, 100806, 100807 | Sysmon suspicious process execution, PowerShell, credential dumping, certutil, WMI, bitsadmin, mshta, rundll32 | 🟢 Validated |

---

## Detection Categories

### Authentication Monitoring
- UC-001 – SSH Brute Force Detection
- UC-002 – Kerberos RC4 Service Ticket Monitoring
- UC-004 – Password Spraying Detection
- UC-005 – Kerberos Anomaly Detection (Kerberoasting)
- UC-006 – Privileged Logon Correlation Detection

### Network Monitoring
- UC-003 – Lateral Movement Detection (Network Scanning)

### Endpoint Monitoring
- UC-007 – Suspicious Process Execution (Sysmon Event ID 1)

### Planned Expansions
- Kerberos TGT volume anomalies (4768)
- Blocked external access detection
- Cross-source correlation rules combining authentication and network events
- Baseline-driven privileged activity anomaly detection

---

## Detection Maturity Model (Lab)

Each use case is marked as:

- 🟢 Validated (attack simulated + alert confirmed)
- 🟡 In Development
- 🔵 Planned

This helps track detection coverage growth over time.

---

## ATT&CK Coverage (Current)

- T1110 – Brute Force
- T1110.003 – Password Spraying
- T1558.003 – Kerberoasting (RC4 + Correlation)
- T1021 – Remote Services (Lateral Movement)
- T1021.001 – Remote Desktop Protocol
- T1021.004 – SSH
- T1595 – Active Scanning
- T1595.001 – Port Scanning
- T1595.002 – Content Scanning
- T1059.001 – Command and Scripting Interpreter: PowerShell
- T1003 – OS Credential Dumping
- T1003.001 – LSASS Memory
- T1218 – Signed Binary Proxy Execution
- T1218.005 – Mshta
- T1218.011 – Rundll32
- T1105 – Ingress Tool Transfer
- T1197 – BITS Jobs
- T1047 – Windows Management Instrumentation

Additional techniques will be mapped as new use cases are developed.

---

## Relationship to Incident Response

Each detection maps directly to a documented playbook in: incident-response/playbooks/
Validated attacks are documented in: incident-response/case-studies/

This ensures detection → response → hardening is fully documented.
