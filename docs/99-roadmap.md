# Roadmap

## Near-term (1–2 weeks) - ✅ COMPLETE
- [x] Document lab architecture + segmentation (docs/01-architecture-diagram.md)
- [x] Document Wazuh deployment + agent onboarding (docs/04-wazuh-deployment.md)
- [x] UC-002: Kerberos RC4 session key detection + rule documented
  - Wazuh rule 100100 defined and documented
  - Evidence section added (screenshots to be captured)

## Mid-term
- [x] pfSense → SIEM ingestion (syslog) + dashboards
  - Complete documentation with Wazuh configuration
  - Detection use cases UC-003, UC-004, UC-005 defined
  - Correlation rules documented
  - Dashboard visualization plan included
- [x] Kerberos & AD detections:
  - [x] 4768/4769 volume anomalies (Kerberoasting signal) - UC-005 documented
  - [x] 4625 burst / password spray patterns (UC-004 documented)
  - [x] 4672 privileged logon correlation - UC-006 documented
- [x] Incident Response playbooks:
  - [x] PB-003: Lateral Movement response documented
  - [x] CS-003: Lateral Movement simulation documented

## Long-term
- [ ] Automated lab build scripts (Terraform/Ansible where possible)
- [ ] Full "purple team" scenario write-ups (attack → detect → respond)