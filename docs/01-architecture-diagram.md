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
| DC01 (Domain Controller) | 10.10.69.10 | Windows Server 2022, corp.local |
| Wazuh SIEM | 10.10.69.20 | Centralized log collection & alerting |
| Tactical RMM | 10.10.69.15 | Internal RMM platform on Debian 12; rmm.lab.local / api.lab.local / mesh.lab.local |
| WIN10-CLIENT | DHCP | Domain-joined workstation |
| WIN11-CLIENT | DHCP | Domain-joined workstation |
| Debian-Attack | DHCP | Adversary simulation tools |
| Metasploitable2 | DHCP | Vulnerable Linux target |
| Metasploitable3-Ubuntu | DHCP | Vulnerable Ubuntu target |
| Metasploitable3-Win2k8 | DHCP | Vulnerable Windows target |

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
[ Attack VM ] [ WIN10-CL ] [ WIN11-CL ] [ DC01 ] [ Wazuh ] [ Tactical RMM ] [ Meta2 ] [ Meta3 ]
 (DHCP) (DHCP) (DHCP) (Static) (Static) (10.10.69.15) (DHCP) (DHCP)


---

## Network Topology (Mermaid)

```mermaid
graph TB
    subgraph Home["Home Network"]
        home_router["Home Router"]
    end

    subgraph Lab["Cyberlab Network<br/>10.10.69.0/24"]
        pfsense["pfSense<br/>10.10.69.1<br/>Firewall / DHCP / Syslog"]
        dc01["DC01<br/>10.10.69.10<br/>Windows Server 2022<br/>corp.local"]
        wazuh["Wazuh SIEM<br/>10.10.69.20<br/>Manager + Indexer + Dashboard"]
        tactical["Tactical RMM<br/>10.10.69.15<br/>Debian 12<br/>rmm/api/mesh.lab.local"]
        win10["WIN10-CLIENT<br/>DHCP<br/>Domain Workstation"]
        win11["WIN11-CLIENT<br/>DHCP<br/>Domain Workstation"]
        attack["Debian-Attack<br/>DHCP (~10.10.69.50)<br/>Adversary Simulation"]
        meta2["Metasploitable2<br/>DHCP<br/>Vulnerable Linux"]
        meta3u["Meta3-Ubuntu<br/>DHCP<br/>Vulnerable Ubuntu"]
        meta3w["Meta3-Win2k8<br/>DHCP<br/>Vulnerable Windows"]
    end

    home_router -.->|"Blocked"| pfsense

    pfsense --> dc01
    pfsense --> wazuh
    pfsense --> tactical
    pfsense --> win10
    pfsense --> win11
    pfsense --> attack
    pfsense --> meta2
    pfsense --> meta3u
    pfsense --> meta3w

    attack -->|"Attack traffic"| dc01
    attack -->|"Attack traffic"| meta2
    attack -->|"Attack traffic"| meta3u
    attack -->|"Attack traffic"| meta3w

    dc01 -->|"Syslog + Agent"| wazuh
    win10 -->|"Sysmon + Agent"| wazuh
    win11 -->|"Sysmon + Agent"| wazuh
    tactical -->|"RMM Agent Management"| dc01
    tactical -->|"RMM Agent Management"| win10
    tactical -->|"RMM Agent Management"| win11
    attack -->|"Agent"| wazuh
    pfsense -->|"Syslog UDP 514"| wazuh

    classDef firewall fill:#f9a825,stroke:#f57f17,color:#000
    classDef server fill:#e53935,stroke:#b71c1c,color:#fff
    classDef siem fill:#43a047,stroke:#2e7d32,color:#fff
    classDef rmm fill:#00897b,stroke:#00695c,color:#fff
    classDef workstation fill:#1e88e5,stroke:#1565c0,color:#fff
    classDef attack fill:#8e24aa,stroke:#6a1b9a,color:#fff
    classDef target fill:#757575,stroke:#424242,color:#fff

    class pfsense firewall
    class dc01 server
    class wazuh siem
    class tactical rmm
    class win10,win11 workstation
    class attack attack
    class meta2,meta3u,meta3w target
```

> **Note:** The Mermaid diagram renders visually on GitHub. Dashed lines represent blocked traffic; solid lines show allowed communication paths. Color coding: 🟡 Firewall, 🔴 Server, 🟢 SIEM, 🟩 RMM, 🔵 Workstations, 🟣 Attack host, ⚫ Vulnerable targets.

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
