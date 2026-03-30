# Lab Overview

Segmented cybersecurity homelab for practicing detection engineering, incident response, and adversary emulation. Everything runs on an isolated VLAN — no production traffic crosses into this network.

## What I use it for

- SIEM detection rule development (Wazuh)
- Windows AD/ Kerberos attack detection
- IR playbook testing against real telemetry
- Network-level detection (firewall logs, port scans)
- Hardening validation (before/after comparisons)

## Safety

- All targets are intentionally vulnerable lab VMs
- Network is isolated (10.10.69.0/24, no internet bridge)
- Attack tools only on designated Debian host
- Snapshots let me reset to clean state between exercises

## Flow

1. Snapshot the target VMs
2. Run a controlled attack from the Debian host
3. Check raw logs at the source
4. Write and tune a Wazuh detection rule
5. Verify the alert fires
6. Document the rule, tuning notes, and false positives
7. Write an IR playbook
8. Revert snapshots

## Next

See [architecture](01-architecture-diagram.md) and [roadmap](99-roadmap.md).
