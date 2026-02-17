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

---

Home Network
|
[pfSense]
|
| Cyberlab |
| |
| DC01 (AD/DNS) |
| WIN10-CLIENT |
| WIN11-CLIENT |
| Debian Attack VM |
| Metasploitable Targets |

---

# Security Telemetry Validated

The following event types are confirmed in the DC Security log:

- 4624 — Successful logon
- 4625 — Failed logon
- 4672 — Privileged logon
- 4768 — Kerberos TGT request
- 4769 — Kerberos service ticket request

These events form the baseline for future detection engineering and attack simulation.

---

# Current Status

Baseline AD environment complete:
- Domain functional
- DNS resolving correctly
- Clients joined
- Auditing enabled
- Snapshots taken

Next phases will include:
- Service Principal Name (SPN) configuration
- Kerberos ticket analysis
- Adversary simulation from Debian
- Wazuh SIEM integration