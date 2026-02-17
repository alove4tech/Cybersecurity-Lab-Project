# VM Inventory

| Name | OS | Role | IP Assignment | Network | Notes |
|----------|------|--------|---------------------|------------|----------|
| pfSense | FreeBSD | Firewall / Router | Static (10.10.69.1) | Cyberlab | Segmentation + DHCP |
| DC01 | Windows Server 2022 | Domain Controller / DNS | Static (10.10.69.10) | Cyberlab | AD DS + Advanced Auditing |
| WIN10-CLIENT | Windows 10 | Domain Workstation | DHCP | Cyberlab | Domain-joined endpoint |
| WIN11-CLIENT | Windows 11 | Domain Workstation | DHCP | Cyberlab | Domain-joined endpoint |
| Debian-Attack | Debian Linux | Attack / Management | DHCP | Cyberlab | Adversary simulation tools |
| Metasploitable2 | Linux | Vulnerable Target | DHCP | Cyberlab | Adversary emulation |
| Metasploitable3-Ubuntu | Ubuntu | Vulnerable Target | DHCP | Cyberlab | Adversary emulation |
| Metasploitable3-Win2k8 | Windows Server 2008 | Vulnerable Target | DHCP | Cyberlab | Adversary emulation |

