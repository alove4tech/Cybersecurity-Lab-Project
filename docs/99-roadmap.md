# Roadmap

## Completed

- [x] Document lab architecture + segmentation
- [x] Document Wazuh deployment + agent onboarding
- [x] pfSense syslog integration → Wazuh
- [x] UC-001: SSH brute force detection
- [x] UC-002: Kerberos RC4 service ticket detection (rule 100100)
- [x] UC-003: Lateral movement / network scan detection (rules 100200–100401)
- [x] UC-004: Password spraying detection (rules 100600, 100601)
- [x] UC-005: Kerberos anomaly / Kerberoasting detection (rules 100300–100303)
- [x] UC-006: Privileged logon correlation detection (rule 100500)
- [x] UC-007: Suspicious process execution via Sysmon (rules 100800–100804)
- [x] PB-001 through PB-004: Incident response playbooks
- [x] CS-001 through CS-004: Case studies with live simulation
- [x] Correlation rules for auth + network events
- [x] Dashboard visualization plan

## In progress

- [ ] Evidence screenshots for validated detections
- [ ] Dashboard implementation in Wazuh

## Planned

- [ ] Blocked external access detection
- [ ] Port sweep and recon detection coverage
- [ ] Automated lab build scripts (Terraform/Ansible)
- [ ] Full purple-team scenario write-ups linking attack → alert → response
- [ ] Wazuh Active Response for auto-blocking scanners
