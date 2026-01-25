# Active Directory Lab Design

## Purpose
This Active Directory lab supports:
- Authentication logging
- Privilege monitoring
- Credential attack detection
- Incident response practice

## Domain
- Domain Name: corp.local
- Forest Functional Level: Windows Server 2022
- Domain Controller: DC01

## Network
- Network: 10.10.69.0/24
- DC01 IP: 10.10.69.10 (static)
- Gateway: 10.10.69.1 (pfSense)

## Security Considerations
- Isolated lab network
- No trust relationships
- No external exposure
- Logging planned via Wazuh agent
