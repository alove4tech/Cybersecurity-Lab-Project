# Cybersecurity Homelab (SOC + Detection Lab)

This repository documents my cybersecurity homelab designed to practice **enterprise defensive monitoring, detection engineering, and incident response**.  
The lab includes **Active Directory**, **Wazuh SIEM**, **pfSense**, and an **ELK stack**, with controlled adversary emulation targets (Metasploitable2/3) to generate realistic telemetry.

## What this demonstrates
- Building and documenting a segmented lab network (pfSense)
- Centralized log ingestion and normalization (Wazuh + ELK)
- Detection engineering (use cases, tuning, and validation)
- Incident response workflows (playbooks + case studies)
- Automation for repeatable deployments (Ansible/PowerShell/Bash)

## Lab Overview
- **Firewall/Router:** pfSense
- **SIEM:** Wazuh
- **Logging/Analytics:** ELK (Logstash + Elasticsearch + Kibana)
- **Targets:** Metasploitable2, Metasploitable3 (Ubuntu), Metasploitable3 (Win2k8)
- **Planned:** Windows Server 2022 Active Directory (DC + workstation)

## Start Here
- [Lab Overview](docs/00-lab-overview.md)
- [Architecture + Segmentation](docs/01-architecture-diagram.md)
- [Logging Strategy](docs/04-logging-strategy.md)
- [Detection Use Cases](detections/use-cases/)
- [Incident Response Playbooks](incident-response/playbooks/)
- [Roadmap](docs/99-roadmap.md)

## Status
This repo is actively maintained as I expand the lab and publish new detections and case studies.
