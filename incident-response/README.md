# Incident Response

This section documents response playbooks and case studies
associated with detections developed in the lab.

The goal is to demonstrate structured investigation,
containment, remediation, and defensive improvement workflows.

---

## Structure

### Playbooks (PB-XXX)

Reusable operational procedures for responding to specific alert types.

Location: incident-response/playbooks/

Each playbook includes:

- Alert Trigger
- Severity Assessment
- Triage Steps
- Investigation Workflow
- Escalation Criteria
- Containment Actions
- Eradication Steps
- Recovery Actions
- Post-Incident Improvements

Playbooks are detection-driven and aligned to documented use cases.

---

### Case Studies (CS-XXX)

Narrative investigations of simulated attack scenarios.

Location: incident-response/case-studies/

Each case study includes:

- Scenario Overview
- Attack Simulation Steps
- Timeline of Events
- Detection Trigger
- Investigation Findings
- Root Cause
- Remediation
- Detection Performance Evaluation
- Lessons Learned

Case studies validate detection fidelity and response workflow effectiveness.

---

## Response Philosophy

The lab emphasizes:

- Evidence-driven investigation
- Log correlation across sources
- Structured escalation criteria
- Defensive hardening after detection
- Continuous tuning of detection thresholds

---

## Current Playbooks

- PB-001 – SSH Brute Force / Password Spraying
- PB-002 – Kerberos RC4 Service Ticket Alert
- PB-003 – Lateral Movement / Network Scanning

---

## Current Case Studies

- CS-001 – SSH Brute Force Simulation
- CS-002 – Kerberoasting Simulation
- CS-003 – Lateral Movement Simulation

---

## Future Expansions

- Password spray response
- Privileged escalation response
- Firewall anomaly investigation
- Correlation-based response (auth + network events)
- Full purple-team scenario writeups (attack → detect → respond)