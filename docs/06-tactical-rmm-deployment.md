# Tactical RMM Deployment & Endpoint Management Lab

## Overview

Tactical RMM was deployed as an internal Remote Monitoring and Management (RMM) platform inside the Cybersecurity Homelab. The goal was to gain practical experience with centralized endpoint management, agent onboarding, remote administration workflows, and troubleshooting RMM infrastructure in a controlled enterprise-style lab.

This component complements the existing defensive lab stack by adding an operations/administration layer alongside Active Directory, Wazuh SIEM, pfSense segmentation, and Windows endpoint telemetry.

---

## Lab Placement

Tactical RMM was deployed inside the same isolated Cyberlab environment as the rest of the lab systems.

- **Network:** `10.10.69.0/24` Cyberlab network
- **Tactical RMM server:** `10.10.69.15`
- **RMM DNS names:** `rmm.lab.local`, `api.lab.local`, `mesh.lab.local`
- **Firewall / DNS:** pfSense
- **Exposure model:** Internal-only; not internet-facing
- **Host OS:** Debian 12 CLI/headless
- **Access scope:** Lab endpoints only
- **Certificate model:** No certificate infrastructure was configured for this internal lab deployment

The deployment was intentionally kept internal so it could be evaluated as an administrative tool without exposing RMM services outside the lab network.

---

## Managed Endpoints

The RMM deployment was tested against Windows systems already present in the lab:

| Host | Role | Result |
|------|------|--------|
| `DC01` | Windows Server 2022 Domain Controller | Successfully managed |
| `WIN10-CLIENT` | Windows 10 workstation | Successfully managed |
| `WIN11-CLIENT` | Windows 11 workstation | Successfully managed |

The integration was performed in standalone mode. Tactical RMM was not integrated with Active Directory for centralized authentication or domain-based deployment. The RMM service names used the `lab.local` namespace (`rmm.lab.local`, `api.lab.local`, and `mesh.lab.local`) while the existing Active Directory environment remained documented as `corp.local`.

---

## What Was Implemented

- Deployed Tactical RMM on a Debian 12 headless server inside the Cyberlab network
- Configured the platform for internal-only lab access
- Used pfSense for lab DNS handling of the RMM service records
- Onboarded Windows lab endpoints into Tactical RMM
- Verified management coverage for the domain controller and Windows client systems
- Evaluated Linux/macOS agent deployment paths
- Documented troubleshooting findings and platform limitations encountered during agent generation

---

## Troubleshooting: Linux/macOS Agent Deployment

Linux and macOS agent deployment was investigated after the Windows endpoint onboarding succeeded. The issue was initially approached as a lab infrastructure problem, but troubleshooting showed that the blockage was tied to Tactical RMM's agent signing workflow rather than a basic DNS, firewall, or operator error.

### Investigation Performed

The following areas were reviewed during troubleshooting:

- Linux installer generation workflow
- Linux/macOS deployment payload behavior
- DNS and internal service resolution
- Possible certificate/signing assumptions
- Tactical RMM Global Key Store behavior
- Linux/macOS signing key requirements
- Manual agent binary availability from upstream release artifacts

### Code Signing Investigation

A local signing authority was created on the Tactical RMM server using OpenSSL to test whether local signing material could satisfy the Linux/macOS agent generation requirements.

Generated signing components included:

- 2048-bit RSA private key
- Self-signed X.509 certificate

These values were imported into Tactical RMM's Global Key Store using the expected identifiers:

- `LINUX_KEY`
- `LINUX_CERT`

Even after the signing material was imported, Tactical RMM continued to return the message:

```text
Linux/Mac agents require code signing.
```

This indicated that the Global Key Store values were not being consumed by the Linux/macOS installer validation path in the tested Tactical RMM version.

### Backend Validation

The investigation was then traced beyond the dashboard workflow into the
Tactical RMM backend validation path. Review of the signing validation logic
showed that Linux/macOS agent generation checked the database-backed
`CodeSignToken` model instead of relying only on the `LINUX_KEY` and
`LINUX_CERT` values from the Global Key Store.

Direct Django shell validation returned an empty token set, meaning the server
considered itself unsigned for Linux/macOS deployment even though local signing
material had been added to the key store. This confirmed that the issue was a
platform signing workflow dependency in the tested Tactical RMM version, not a
basic DNS, firewall, or endpoint enrollment problem.

### Manual Binary Acquisition

Manual acquisition of Linux agent binaries was also tested after dashboard-based installer generation remained blocked. Expected release artifact names such as the following were checked:

- `tacticalagent-v2.10.0-linux-amd64`
- `tacticalagent-linux-amd64`

The attempted downloads returned `404 Not Found`, indicating that the Linux agent binaries were either not publicly hosted under those names or were distributed through a different release/signing process.

### Final Assessment

The Windows RMM deployment was functional and met the primary goal of gaining hands-on RMM experience with Windows endpoint administration. Linux/macOS onboarding was documented as a platform limitation encountered during testing, specifically around mandatory code-signing validation in Tactical RMM v1.4.0 and the lack of usable local signing behavior through the tested Global Key Store workflow.

This troubleshooting path demonstrates practical infrastructure analysis rather than a failed deployment: the investigation moved from common environmental causes to product-specific behavior, tested a local remediation path, validated the error condition, and documented the boundary of what could be supported in the lab build.

---

## How This Fits the Cybersecurity Lab

Tactical RMM adds a realistic systems administration and endpoint operations component to the existing lab.

| Existing Lab Component | Tactical RMM Relationship |
|------------------------|---------------------------|
| Active Directory / DC01 | Managed Windows server endpoint and domain infrastructure system |
| Windows clients | RMM-managed workstation endpoints |
| pfSense | Internal routing, segmentation, and DNS support |
| Wazuh SIEM | Separate defensive telemetry layer that can observe endpoint activity independently from RMM administration |
| Attack/target hosts | Future opportunity to compare administrative activity, attacker activity, and detection visibility |

This creates a more realistic enterprise-style environment where endpoint administration, monitoring, detection engineering, and incident response can be practiced together.

---

## Skills Demonstrated

- Remote Monitoring and Management platform deployment
- Windows endpoint administration
- Debian 12 server administration
- Headless Linux service deployment
- Internal DNS troubleshooting with pfSense
- Active Directory lab integration considerations
- RMM agent onboarding and validation
- Infrastructure troubleshooting methodology
- Code-signing and software distribution troubleshooting
- Documentation of product limitations and implementation boundaries

---

## Future Enhancements

- Document Tactical RMM service ports and firewall rules once finalized
- Add screenshots of the dashboard and enrolled Windows endpoints
- Capture evidence of remote command/script execution against a lab workstation
- Compare RMM administrative actions against Wazuh telemetry
- Create a detection use case for suspicious RMM-style activity or unauthorized remote administration
- Re-test Linux/macOS agent deployment after Tactical RMM version changes or signing workflow changes
