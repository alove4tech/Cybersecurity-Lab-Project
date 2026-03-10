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

## Detection Categories

### Authentication Monitoring
- UC-001 – SSH Brute Force Detection
- UC-002 – Kerberos RC4 Service Ticket Monitoring

### Network Monitoring
- UC-003 – Lateral Movement Detection (Network Scanning)

### Planned Expansions
- Password spray (multi-user 4625 burst)
- Privileged logon anomaly (4672 correlation)
- Kerberos TGT volume anomalies (4768)
- Firewall anomaly detection (blocked external access, port sweep)
- Correlation rules (auth + network events)

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
- T1558.003 – Kerberoasting
- T1021 – Remote Services (Lateral Movement)
- T1021.001 – Remote Desktop Protocol
- T1021.004 – SSH
- T1595 – Active Scanning
- T1595.001 – Port Scanning
- T1595.002 – Content Scanning

Additional techniques will be mapped as new use cases are developed.

---

## Relationship to Incident Response

Each detection maps directly to a documented playbook in: incident-response/playbooks/
Validated attacks are documented in: incident-response/case-studies/

This ensures detection → response → hardening is fully documented.
