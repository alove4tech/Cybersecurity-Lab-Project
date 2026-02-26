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

- SSH brute force detection (Linux auth.log)
- Kerberos RC4 service ticket detection (Kerberoasting signal)
- Privileged logon monitoring (4672)
- Failed logon burst detection (4625 thresholding)

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
✔ Custom Wazuh rule (ID 100100) firing successfully  

---

## Start Here

- Lab Overview → docs/00-lab-overview.md  
- Architecture → docs/01-architecture-diagram.md  
- Active Directory Design → docs/02-active-directory-design.md  
- Detection Engineering Overview → detections/
- Incident Response Overview → incident-response/ 
- Roadmap → docs/99-roadmap.md  

---

## Roadmap

Near-Term:
- pfSense syslog ingestion into SIEM
- 4625 burst + password spray correlation
- 4768/4769 anomaly detection

Mid-Term:
- Purple team scenario write-ups (attack → detect → respond)
- Automated lab provisioning scripts

Long-Term:
- Infrastructure-as-Code build automation
- Dashboarding and detection metrics