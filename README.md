# Cybersecurity Homelab (SOC + Detection Lab)

This repository documents a segmented cybersecurity homelab designed to practice:

- Defensive monitoring
- Detection engineering
- Incident response
- Adversary emulation

The environment generates realistic enterprise telemetry (Active Directory, Kerberos, Windows Security logs, Linux auth logs, firewall logs) and validates detections using controlled attack scenarios.

---

## Architecture Summary

- Hypervisor: Proxmox VE
- Network: 10.10.69.0/24 (isolated Cyberlab VLAN)
- Firewall: pfSense (10.10.69.1)
- Identity: Windows Server 2022 AD DS (corp.local)
- SIEM: Wazuh (Windows + Linux agents)
- Targets: Metasploitable2/3 + Debian attack host

---

## Detection Lifecycle in This Lab

Each detection follows a structured workflow:

1. Generate attack telemetry (controlled adversary simulation)
2. Validate raw logs at source
3. Create detection logic (Wazuh rule / query)
4. Trigger alert
5. Document tuning & false positives
6. Write response playbook
7. Implement hardening (where applicable)

This ensures detections are validated, repeatable, and defensible.

---

## Confirmed Security Telemetry

The following Windows Security events are validated:

- 4624 – Successful logon
- 4625 – Failed logon
- 4672 – Privileged logon
- 4768 – Kerberos TGT request
- 4769 – Kerberos service ticket request

Linux telemetry:
- SSH authentication logs
- Syslog forwarding (in progress)

---

## Detection Highlights

**Authentication Monitoring:**
- UC-001 – SSH brute force detection (Linux auth.log)
- UC-002 – Kerberos RC4 service ticket detection (Kerberoasting signal)

**Network Monitoring:**
- UC-003 – Lateral movement detection (network scanning)
- UC-004 – Password spraying detection (Windows AD, Event ID 4625)
- UC-005 – Blocked external access attempts (planned)
- UC-006 – Port sweep / reconnaissance (planned)

**Correlation Rules:**
- Credential abuse (failed auth + network activity)
- Kerberos lateral movement (Kerberos + scanning)
- Privileged lateral movement (admin logon + network activity)

Each use-case includes:
- Objective
- Data sources
- Detection logic
- Validation procedure
- MITRE ATT&CK mapping
- Hardening actions (where applicable)

---

## Current Operational State

✔ AD domain deployed
✔ Advanced audit policies enabled
✔ Kerberos telemetry validated
✔ RC4 downgrade reproduced and remediated
✔ Custom Wazuh rules deployed (IDs: 100100, 100200-100401, 100500-100700)
✔ Incident response playbooks documented (PB-001, PB-002, PB-003)
✔ Case studies validated (CS-001, CS-002, CS-003)
✔ Wazuh deployment guide complete
✔ Password spraying detection validated (UC-004, Rule IDs 100200, 100201)
✔ pfSense syslog integration documented  

---

## Start Here

- Lab Overview → docs/00-lab-overview.md
- Architecture → docs/01-architecture-diagram.md
- Active Directory Design → docs/02-active-directory-design.md
- Wazuh Deployment → docs/04-wazuh-deployment.md
- Detection Engineering Overview → detections/
- Incident Response Overview → incident-response/
- Roadmap → docs/99-roadmap.md  

---

## Roadmap

Near-Term (Complete):
- ✅ pfSense syslog ingestion into SIEM
- ✅ Wazuh deployment documentation
- ✅ Network-based detection use cases (UC-003)
- ✅ Lateral movement response playbooks (PB-003)

Mid-Term (In Progress):
- 🔵 4625 burst + password spray correlation
- 🔵 4768/4769 anomaly detection
- 🔵 4672 privileged logon correlation
- 🔵 Dashboard visualization and metrics

Long-Term:
- 🔵 Automated lab provisioning scripts (Terraform/Ansible)
- 🔵 Purple team scenario write-ups (attack → detect → respond)
- 🔵 Infrastructure-as-Code build automation