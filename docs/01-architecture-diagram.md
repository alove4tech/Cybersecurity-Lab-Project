# Lab Architecture & Network Segmentation

## Overview
This homelab is designed as an **isolated cybersecurity environment** for practicing detection engineering, incident response, and adversary emulation.  
All lab systems are segmented from the home network using pfSense.

---

## Network Layout

**Cyberlab Network:** `10.10.69.0/24`

| Component | IP Address | Notes |
|---|---|---|
| pfSense | 10.10.69.1 | Default gateway, firewall, DHCP |
| Attack / Management VM | DHCP | Debian-based attack host |
| Metasploitable Targets | DHCP | Vulnerable lab systems |
| Future AD / SIEM | Static | Logging + authentication |

---

## Logical Diagram (Text)

[ Home Network ]
|
| (Blocked by Firewall Rules)
|
[ pfSense ]
10.10.69.1
|
+---------------- Cyberlab Network (10.10.69.0/24) ----------------+
| |
[ Attack VM ] [ Metasploitable2 ] [ Metasploitable3 ] [ Future AD / SIEM ]
(DHCP) (DHCP) (DHCP) (Static)


---

## Segmentation & Security Controls

- Cyberlab network is **fully segmented** from the home network
- pfSense firewall rules:
  - Block inbound traffic from home → lab
  - Block outbound traffic from lab → home
  - Allow controlled internal lab communication
- DHCP is used for most lab VMs to simulate real enterprise environments
- Static addressing reserved for infrastructure services (pfSense, AD, SIEM)

---

## Design Rationale

- **Isolation:** Prevents accidental impact on production/home systems
- **Realism:** Mirrors enterprise network segmentation
- **Telemetry:** Enables realistic firewall + host-level logs
- **Detection:** Supports attack → firewall log → SIEM alert workflows

This architecture supports both **offensive testing** and **defensive monitoring** within a controlled environment.
