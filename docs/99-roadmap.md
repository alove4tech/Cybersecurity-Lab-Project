# Roadmap

## Near-term (1–2 weeks)
- [ ] Document lab architecture + segmentation (docs/01-architecture.md)
- [ ] Document Wazuh deployment + agent onboarding (docs/04-wazuh.md)
- [ ] UC-002: Kerberos RC4 session key detection + rule + evidence screenshots

## Mid-term
- [ ] pfSense → SIEM ingestion (syslog) + dashboards
- [ ] Kerberos & AD detections:
  - [ ] 4768/4769 volume anomalies (Kerberoasting signal)
  - [ ] 4625 burst / password spray patterns
  - [ ] 4672 privileged logon correlation

## Long-term
- [ ] Automated lab build scripts (Terraform/Ansible where possible)
- [ ] Full “purple team” scenario write-ups (attack → detect → respond)