# VM Inventory

| Name | OS | Role | IP Assignment | Network | Notes |
|---|---|---|---|---|---|
| pfSense | FreeBSD | Firewall / Router | Static (10.10.69.1) | Cyberlab | Network segmentation + traffic control |
| Debian Attack VM | Debian Linux | Attack / Management | DHCP | Cyberlab | Pen tools + attack simulation |
| Metasploitable2 | Linux | Vulnerable target | DHCP | Cyberlab | Adversary emulation |
| Metasploitable3 (Ubuntu) | Ubuntu | Vulnerable target | DHCP | Cyberlab | Adversary emulation |
| Metasploitable3 (Win2k8) | Windows | Vulnerable target | DHCP | Cyberlab | Adversary emulation |
| (Planned) AD DC | Windows Server 2022 | Domain Controller | Static | Cyberlab | Authentication + logging |
| (Planned) Wazuh | Linux | SIEM | Static | Cyberlab | Centralized monitoring |
