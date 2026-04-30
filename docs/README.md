# Cybersecurity Homelab Overview

This lab simulates a segmented enterprise environment designed for practicing:

- Active Directory administration
- Authentication telemetry analysis
- Detection engineering
- Incident response workflows
- Adversary emulation in a controlled network

The goal of this project is to bridge offensive techniques with defensive monitoring by generating realistic logs and validating detections.

---

# Architecture Summary

**Cyberlab Network:** 10.10.69.0/24
**Firewall:** pfSense (10.10.69.1)
**Domain Controller:** DC01 (10.10.69.10)
**Domain:** corp.local

# Security Telemetry Validated

The following event types are confirmed in the DC Security log:

- 4624 — Successful logon
- 4625 — Failed logon
- 4672 — Privileged logon
- 4768 — Kerberos TGT request
- 4769 — Kerberos service ticket request

These events form the baseline for future detection engineering and attack simulation.

---

## Current Stack (Lab at a Glance)
- Network segmentation: pfSense (10.10.69.1) isolating 10.10.69.0/24
- Identity: Windows Server 2022 AD DS / DNS (DC01 – 10.10.69.10)
- Endpoints: WIN10-CLIENT, WIN11-CLIENT (domain-joined)
- SIEM: Wazuh (server + agents) collecting Windows Security telemetry
- Targets: Metasploitable2/3 (Ubuntu + Win2k8), Debian attack/management VM

## Next Up
- Evidence screenshots for validated detections
- Dashboard implementation in Wazuh
- Wazuh Active Response for auto-blocking
- Purple-team scenario write-ups (attack → alert → response)
- Terraform/Ansible provisioning for repeatable lab builds

## Documentation Index

| Document | Description |
|----------|-------------|
| [Lab Overview](00-lab-overview.md) | Project goals and scope |
| [Architecture Diagram](01-architecture-diagram.md) | Network topology and segmentation |
| [Active Directory Design](02-active-directory-design.md) | Domain structure, OUs, and GPOs |
| [Network Configuration](03-network-configuration.md) | Subnet layout, firewall rules, DHCP |
| [Wazuh Deployment](04-wazuh-deployment.md) | SIEM setup, agent onboarding, rules |
| [Evidence Collection Guide](05-evidence-guide.md) | Screenshot standards and chain of custody |
| [VM Inventory](../assets/vm-inventory.md) | All lab VMs with roles, IPs, and notes |
| [Roadmap](99-roadmap.md) | Planned work and completion status |

## Quick links

- [pfSense syslog forwarding notes](../defensive/pfsense/syslog-forwarding.md)
- [Detection use cases](../detections/README.md)
- [Incident response playbooks and case studies](../incident-response/README.md)
