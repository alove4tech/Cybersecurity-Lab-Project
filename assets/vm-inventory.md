# VM Inventory

| Name | OS | Role | IP Assignment | Proxmox VM ID | Network | Notes |
|----------|------|--------|---------------------|----------------|------------|----------|
| pfSense | FreeBSD | Firewall / Router | Static (10.10.69.1) | — | Cyberlab | Segmentation + DHCP + Syslog forwarder |
| DC01 | Windows Server 2022 | Domain Controller / DNS | Static (10.10.69.10) | — | Cyberlab | AD DS + Advanced Auditing + Sysmon |
| Wazuh | Linux (Debian/Ubuntu) | SIEM / Log Collection | Static (10.10.69.20) | — | Cyberlab | Manager + Indexer + Dashboard |
| Tactical RMM | Debian 12 | Remote Monitoring & Management | Static (10.10.69.15) | — | Cyberlab | Internal-only RMM; DNS: rmm.lab.local, api.lab.local, mesh.lab.local; manages DC01, WIN10-CLIENT, and WIN11-CLIENT |
| WIN10-CLIENT | Windows 10 | Domain Workstation | DHCP | — | Cyberlab | Domain-joined endpoint + Sysmon |
| WIN11-CLIENT | Windows 11 | Domain Workstation | DHCP | — | Cyberlab | Domain-joined endpoint + Sysmon |
| Debian-Attack | Debian Linux | Attack / Management | DHCP (typically 10.10.69.50) | — | Cyberlab | Adversary simulation tools (Impacket, NetExec, Hydra, Nmap) |
| Metasploitable2 | Linux | Vulnerable Target | DHCP | — | Cyberlab | Adversary emulation |
| Metasploitable3-Ubuntu | Ubuntu | Vulnerable Target | DHCP | — | Cyberlab | Adversary emulation |
| Metasploitable3-Win2k8 | Windows Server 2008 | Vulnerable Target | DHCP | — | Cyberlab | Adversary emulation |

> **Note:** Fill in the Proxmox VM IDs above (e.g., 100, 101, …) once assigned. This makes snapshot and clone operations easier: `qm snapshot <VM_ID> clean-state`.
