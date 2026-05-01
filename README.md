# Cybersecurity Homelab

SOC + detection lab running on Proxmox. Isolated VLAN (10.10.69.0/24) with Active Directory, Wazuh SIEM, and attack hosts for detection engineering and IR practice.

[![Detection status](https://img.shields.io/badge/detections-7%20validated-brightgreen)](./detections/) [![MITRE ATT&CK](https://img.shields.io/badge/MITRE%20ATT%26CK-13%20techniques-blue)](#mitre-attck-coverage) [![Playbooks](https://img.shields.io/badge/playbooks-4-orange)](./incident-response/)

## Table of contents

- [Network](#network)
- [Detection workflow](#detection-workflow)
- [What's built so far](#whats-built-so-far)
- [Lab artifacts at a glance](#lab-artifacts-at-a-glance)
- [Docs](#docs)
- [Next up](#next-up)

## Network

- **Hypervisor:** Proxmox VE
- **Firewall:** pfSense (10.10.69.1)
- **Domain Controller:** Windows Server 2022 (10.10.69.10, corp.local)
- **SIEM:** Wazuh (Windows + Linux agents)
- **Attack box:** Debian with Kali tools
- **Targets:** Metasploitable 2/3

## Detection workflow

For each use case I:

1. Run a controlled attack
2. Check raw logs at the source
3. Write a Wazuh rule
4. Verify the alert fires
5. Document tuning and false positives
6. Write a response playbook
7. Apply hardening if applicable

## What's built so far

| Use Case | Rule IDs | Status |
|----------|----------|--------|
| SSH brute force | Custom (UC-001) | Done |
| Kerberos RC4 (Kerberoasting signal) | 100100 | Done |
| Lateral movement (network scan) | 100200, 100201, 100400, 100401 | Done |
| Password spraying (AD) | 100600, 100601 | Done |
| Kerberos anomaly correlation | 100300–100303 | Done |
| Privileged logon correlation | 100500 | Done |
| Suspicious process execution (Sysmon) | 100800–100804 | Done |

**Incident response playbooks:** PB-001 (brute force), PB-002 (Kerberos RC4), PB-003 (lateral movement), PB-004 (suspicious process)
**Case studies:** CS-001, CS-002, CS-003, CS-004 validated against live telemetry

## Lab artifacts at a glance

- pfSense syslog forwarding notes are documented and tied into the detection workflow
- Sysmon coverage is in place for process execution visibility on Windows hosts
- Use case write-ups live under `detections/use-cases/` and map cleanly to the corresponding playbooks
- Progress snapshots live under `docs/session-progress-*.md` so changes over time are easy to track
- VM inventory in `assets/vm-inventory.md` tracks all lab hosts and their roles

## Docs

- [Lab overview](docs/00-lab-overview.md)
- [Architecture diagram](docs/01-architecture-diagram.md)
- [AD design](docs/02-active-directory-design.md)
- [Network configuration](docs/03-network-configuration.md)
- [Wazuh deployment](docs/04-wazuh-deployment.md)
- [Evidence collection guide](docs/05-evidence-guide.md)
- [pfSense syslog forwarding notes](defensive/pfsense/syslog-forwarding.md)
- [Detection use cases](detections/)
- [IR playbooks](incident-response/)
- [VM inventory](assets/vm-inventory.md)
- [Roadmap](docs/99-roadmap.md)

## Next up

- [ ] Evidence screenshots for validated detections (in progress)
- [x] Correlation rules for auth + network events
- [ ] Dashboard implementation in Wazuh
- [ ] Blocked external access detection
- [ ] Port sweep and recon detection coverage
- [ ] Terraform/Ansible provisioning for repeatable lab builds
- [ ] Full purple-team scenario write-ups (attack → alert → response)
- [ ] Wazuh Active Response for auto-blocking

## MITRE ATT&CK Coverage

| Technique | Name | Detection |
|-----------|------|-----------|
| T1110 | Brute Force | UC-001 |
| T1110.003 | Password Spraying | UC-001, UC-004 |
| T1558.003 | Kerberoasting | UC-002, UC-005 |
| T1021 | Remote Services | UC-003 |
| T1021.001 | Remote Desktop Protocol | UC-003 |
| T1021.004 | SSH | UC-001 |
| T1059.001 | PowerShell | UC-007 |
| T1003 | OS Credential Dumping | UC-007 |
| T1218 | Signed Binary Proxy Execution | UC-007 |
| T1105 | Ingress Tool Transfer | UC-007 |
| T1047 | WMI | UC-007 |
| T1595 | Active Scanning | UC-003 |
| T1595.001 | Port Scanning | UC-003 |
