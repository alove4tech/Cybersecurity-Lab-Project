# pfSense Syslog Forwarding

## Objective
Forward firewall logs to Wazuh for centralized monitoring and correlation with host telemetry.

## Log Types
- Firewall allow/deny events
- NAT activity
- DHCP logs
- System events

## Configuration (Planned)

1. Enable remote logging in pfSense:
   Status → System Logs → Settings
2. Remote Log Server:
   10.10.69.X (Wazuh server IP)
3. Transport: UDP 514
4. Log Categories:
   - Firewall Events
   - DHCP
   - System

## Detection Opportunities

- Outbound connection spikes from single host
- Lateral movement attempts
- Blocked internal scanning
- Unexpected inter-VLAN traffic

## Correlation Plan

Correlate:
- 4624/4625 authentication logs
- 4769 Kerberos tickets
- Firewall connection logs

Goal: Detect credential abuse + lateral movement patterns.