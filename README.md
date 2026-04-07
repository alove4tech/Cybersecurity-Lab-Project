# Cybersecurity Homelab

SOC + detection lab running on Proxmox. Isolated VLAN (10.10.69.0/24) with Active Directory, Wazuh SIEM, and attack hosts for detection engineering and IR practice.

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

## Docs

- [Lab overview](docs/00-lab-overview.md)
- [Architecture diagram](docs/01-architecture-diagram.md)
- [AD design](docs/02-active-directory-design.md)
- [Wazuh deployment](docs/04-wazuh-deployment.md)
- [Detection use cases](detections/)
- [IR playbooks](incident-response/)
- [Roadmap](docs/99-roadmap.md)

## Next up

- [ ] pfSense syslog → Wazuh (in progress)
- [ ] Blocked external access attempts
- [ ] Port sweep/recon detection
- [ ] Dashboard visualization
- [ ] Terraform/Ansible provisioning
