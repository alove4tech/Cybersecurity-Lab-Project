cat > README.md <<'EOF'
# Cybersecurity Homelab (SOC + Detection Lab)

This repository documents my cybersecurity homelab designed to practice **defensive monitoring, detection engineering, and incident response**.  
It includes controlled **adversary emulation** targets (Metasploitable2/3) to generate realistic telemetry for detections.

## What this demonstrates
- Lab documentation: architecture, assets, and logging strategy
- Defensive monitoring: SIEM + log pipelines
- Detection engineering: use-cases with validation steps
- Incident response: playbooks and case studies
- Repeatability: automation for builds and configuration

## Start Here
- [Lab Overview](docs/00-lab-overview.md)
- [VM Inventory](assets/vm-inventory.md)
- [Detection Use Cases](detections/use-cases/)
- [Incident Response Playbooks](incident-response/playbooks/)
- [Roadmap](docs/99-roadmap.md)

## Current Targets
- Metasploitable2 (Linux)
- Metasploitable3 (Ubuntu)
- Metasploitable3 (Windows 2008)

## Roadmap Highlights
- Windows Server 2022 Active Directory lab
- Wazuh SIEM node for Windows + Linux monitoring
- pfSense log ingestion into an ELK stack
EOF
