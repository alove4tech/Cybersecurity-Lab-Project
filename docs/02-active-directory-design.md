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

## DNS Configuration

DC01 hosts Active Directory–integrated DNS and is authoritative for the `corp.local` zone.

External name resolution is handled via DNS forwarders:
- Primary forwarder: pfSense (10.10.69.1)
- Upstream resolution handled by firewall

This mirrors enterprise designs where internal DNS servers forward unknown queries to perimeter resolvers.

## Organizational Unit (OU) Design

The domain uses a structured OU layout to separate users, administrators, servers, and service accounts.

### OUs
- Corp-Users: Standard user accounts
- Corp-Admins: Privileged administrative accounts
- Corp-Servers: Domain infrastructure and servers
- Corp-Workstations: Domain-joined endpoints
- Service-Accounts: Non-interactive service identities
- Disabled-Accounts: Offboarded users

This structure supports clearer detection logic and role-based monitoring.

## Auditing Configuration

Advanced audit policies are enabled on domain controllers to support detailed authentication and account activity monitoring.

### Enabled Audit Categories
- Account Logon: Credential Validation (Success/Failure)
- Logon/Logoff: Logon, Logoff
- Account Management: User and Computer Account Management
- Privilege Use: Sensitive Privilege Use
- Directory Service Access: Directory Service Changes
- Policy Change: Audit Policy Change

Advanced audit subcategory enforcement is enabled to ensure policies are applied correctly.

### Validation
- Event ID 4624: Successful logon
- Event ID 4625: Failed logon
- Event ID 4672: Privileged logon
