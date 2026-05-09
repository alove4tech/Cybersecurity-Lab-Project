# Defensive Security

Defensive configurations and hardening notes for the lab environment.

---

## Contents

### pfSense

- **[Syslog Forwarding to Wazuh](pfsense/syslog-forwarding.md)** — End-to-end guide for forwarding pfSense firewall logs to Wazuh via syslog, including detection use cases (lateral movement, blocked external access, port sweep), correlation rules, and dashboard visualization specs.

---

## Relationship to Other Sections

- Firewall detection use cases are cross-referenced in [detections/](../detections/README.md)
- Correlation rules tie into the incident response playbooks in [incident-response/](../incident-response/README.md)
- pfSense network configuration details live in [docs/03-network-configuration.md](../docs/03-network-configuration.md)
