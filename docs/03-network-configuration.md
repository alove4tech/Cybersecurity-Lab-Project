# Network Configuration

Lab network runs on an isolated VLAN — 10.10.69.0/24 — behind a pfSense VM acting as firewall, router, and DHCP server. No production traffic crosses into this segment.

## Subnet Layout

| Role | Host | IP | Method |
|---|---|---|---|
| Firewall / Gateway | pfSense | 10.10.69.1 | Static |
| Domain Controller | DC01 | 10.10.69.10 | Static |
| Windows Workstation | WIN10-CLIENT | DHCP | Dynamic |
| Windows Workstation | WIN11-CLIENT | DHCP | Dynamic |
| Attack / Management | Debian-Attack | DHCP | Dynamic |
| Vulnerable Target | Metasploitable2 | DHCP | Dynamic |
| Vulnerable Target | Metasploitable3-Ubuntu | DHCP | Dynamic |
| Vulnerable Target | Metasploitable3-Win2k8 | DHCP | Dynamic |

## pfSense Configuration Highlights

- Single VLAN interface for the lab subnet
- Default deny rule with explicit allow rules for lab traffic
- DHCP pool configured for dynamic hosts
- Syslog forwarding to Wazuh for network-level telemetry

## Isolation Notes

- The lab VLAN has no route to the internet or home network
- Snapshots on all VMs allow clean-state resets between exercises
- Attack tools are confined to the Debian-Attack host
