# Session Progress - May 15, 2026

## Overview

Completed a Wazuh and pfSense validation pass focused on the SIEM ingestion
pipeline, custom rule coverage, and dashboard visibility across the documented
detection use cases.

---

## Completed Work

### 1. pfSense Syslog Forwarding Stabilized

pfSense remote syslog forwarding is now enabled to the Wazuh manager at
`10.10.69.20:514/UDP` using Log All mode. The Wazuh manager receives the
firewall telemetry directly through its UDP 514 syslog listener, which is
restricted to the pfSense firewall source.

Validation results:

- Wazuh manager active and running
- UDP 514 listening for pfSense syslog
- pfSense firewall events flowing into Wazuh archives
- Roughly 12,000 `filterlog` events observed during validation
- Forwarding persisted after reboot testing

The initial event volume is primarily firewall block telemetry from the
upstream-facing interface. LAN pass-rule logging can be added later if more
internal east/west traffic visibility is needed.

### 2. Wazuh Rules Verified

All 23 custom Wazuh rules remain deployed across the seven documented use
cases, with syntax verified through Wazuh rule testing.

| Use Case | Rule IDs | Validation |
|----------|----------|------------|
| UC-001 SSH Brute Force | 100001, 100002, 100003 | SSH authentication failure and brute force chain |
| UC-002 Kerberos RC4 | 100100, 100101 | Windows 4769 Kerberos service ticket detection |
| UC-003 Lateral Movement | 100200, 100201, 100400, 100401 | pfSense filterlog, multi-destination scan, port sweep, port scan |
| UC-004 Password Spraying | 100600, 100601 | Windows 4625 failures across multiple usernames |
| UC-005 Kerberos Anomaly | 100300, 100301, 100302, 100303 | SPN enumeration and Kerberos volume anomalies |
| UC-006 Privileged Logon | 100500, 100501, 100502 | Privileged and remote administrative logon correlation |
| UC-007 Suspicious Process | 100800, 100801, 100802, 100803, 100804 | Sysmon suspicious process execution coverage |

### 3. Dashboard Access and Visualization

Wazuh dashboard API access was validated and four custom dashboards were built
to cover the full detection set:

1. Detection Use Case Overview
2. Authentication and Kerberos Monitoring
3. Firewall and Lateral Movement Monitoring
4. Endpoint and Privileged Activity Monitoring

These dashboards provide practical views for rule activity, authentication
patterns, firewall telemetry, lateral movement indicators, privileged logons,
and suspicious process execution.

### 4. Endpoint Status

Active Wazuh endpoints remain aligned with the documented inventory:

- `wazuh-server`
- `dc01`
- `win10-client`
- `win11-client`

The Debian attack host remains documented as a traffic-generation and validation
system rather than a currently enrolled Wazuh endpoint.

---

## Documentation Updates

Updated the project documentation to reflect the current validated state:

- `docs/04-wazuh-deployment.md`
- `defensive/pfsense/syslog-forwarding.md`
- `docs/99-roadmap.md`
- `docs/README.md`
- `README.md`
- `scripts/README.md`

---

## Current Status

The lab now has validated firewall telemetry ingestion, all seven detection use
cases mapped to deployed Wazuh rules, active endpoint coverage for the Windows
systems and Wazuh server, and dashboard views for operational monitoring.
