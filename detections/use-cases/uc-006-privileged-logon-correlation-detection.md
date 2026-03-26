# UC-006: Privileged Logon Correlation Detection

## Detection Metadata

- Detection ID: UC-006
- Log Source: Windows Security Event Log
- Event ID(s): 4624, 4672
- Platform: Windows Server 2022 Active Directory
- Primary System: Domain Controller (DC01)
- SIEM: Wazuh
- Severity: Medium (High when correlated with remote logon or unexpected source host)
- MITRE ATT&CK:
  - T1078 – Valid Accounts
  - T1021 – Remote Services
  - T1068 – Exploitation for Privilege Escalation
- Data Sensitivity: Privileged authentication telemetry

---

## Objective

Detect privileged logons in the Windows domain and identify cases where elevated privileges are assigned after a successful authentication. This behavior may indicate legitimate administrative activity, lateral movement, credential misuse, or post-compromise privilege escalation.

This use case focuses on Windows Security Event ID 4672 and correlates it with Event ID 4624 to determine whether the privileged session originated locally or from a remote system.

---

## Lab Environment

- **Domain Controller (DC01):** 10.10.69.10 (Windows Server 2022, corp.local)
- **SIEM (Wazuh):** 10.10.69.20
- **Domain Workstation / Client Host:** Used to generate remote administrative authentication
- **Network:** 10.10.69.0/24 isolated cyberlab VLAN

### Prerequisites

- Advanced Audit Policy enabled for Windows logon events
- Event ID 4624 and 4672 confirmed in Windows Security logs
- Wazuh agent installed on DC01 using EventChannel collection
- Time synchronization working across lab systems
- Administrative credentials available for controlled validation

---

## Log Source & Field Mapping

### Event ID 4624 – Successful Logon

Relevant fields:

- `data.win.system.eventID` = 4624
- `data.win.eventdata.targetUserName` – Authenticated account
- `data.win.eventdata.logonType` – Logon type
- `data.win.eventdata.workstationName` – Source workstation name
- `data.win.eventdata.ipAddress` – Source IP address
- `data.win.eventdata.targetLogonId` – Session identifier for correlation

### Event ID 4672 – Special Privileges Assigned to New Logon

Relevant fields:

- `data.win.system.eventID` = 4672
- `data.win.eventdata.subjectUserName` – Privileged account
- `data.win.eventdata.subjectDomainName` – Account domain
- `data.win.eventdata.subjectLogonId` – Session identifier for correlation
- `data.win.system.computer` – Host where privileges were assigned

### Correlation Method

Correlation is performed by matching:

- `4624.targetLogonId`
- `4672.subjectLogonId`

This confirms both events belong to the same authenticated session.

---

## Detection Logic

### High-Level Logic

1. Detect Event ID 4672 indicating a privileged logon.
2. Identify the related authenticated session using Logon ID.
3. Confirm whether a preceding 4624 event exists for the same session.
4. Review logon type and source host/IP.
5. Escalate investigation when the privileged session originated from a remote or unusual source.

### Indicators of Interest

- Logon Type 3 (network)
- Logon Type 10 (remote interactive / RDP)
- Administrative or highly privileged accounts
- Unexpected source host or subnet
- Privileged logon on a Domain Controller
- Privileged activity following failed logons or lateral movement indicators

---

## Rule Implementation

A custom Wazuh rule was created to alert on Event ID 4672.

The rule triggers when the Windows Security log reports that special privileges were assigned to a new logon session. This provides a reliable signal for privileged activity and can then be correlated during investigation with Event ID 4624 by matching Logon ID values.

### Example Alert Conditions

- Event ID 4672 detected
- Windows Security channel
- Domain Controller source
- Privileged account identified

### Example Wazuh Rule

```xml
<rule id="100500" level="8">
  <if_group>windows</if_group>
  <field name="win.system.eventID">4672</field>
  <description>LAB: Privileged logon detected on Windows system</description>
  <group>windows,authentication,privileged_logon,lab</group>
</rule>
```

**Note:** In this lab, direct correlation between 4624 and 4672 was validated manually during investigation by matching Logon ID values in collected events.

---

## Validation Procedure

The detection was validated in the isolated cyberlab environment.

### Steps Performed

1. Confirm Windows auditing is enabled for logon events.
2. Verify Event ID 4672 appears on DC01.
3. Confirm Wazuh receives the event.
4. Create and deploy the custom detection rule.
5. Generate privileged logon activity from another host.
6. Confirm the alert fires in Wazuh.
7. Verify 4624 and 4672 correlation using raw event data.

### Test Method Used

From a domain workstation:

```cmd
net use \\DC01\c$ /user:corp\administrator
```

This generated:

- Event ID 4624 – successful network logon
- Event ID 4672 – privileged logon

The events shared the same Logon ID, confirming they belonged to the same session.

---

## Evidence Collected

Observed telemetry included:

- Successful network logon from client host
- Administrator account authentication
- Privileged logon event on DC01
- Matching Logon ID between 4624 and 4672
- Alert generated by custom Wazuh rule

This confirmed the detection worked and that the session correlation was valid.

---

## False Positive Considerations

Event ID 4672 occurs frequently during normal Windows operation and should not be treated as malicious on its own.

### Common Benign Sources

- `SYSTEM` account
- Window Manager accounts
- Scheduled tasks
- Services
- Domain Controller processes
- Group Policy processing

### Required Context

To determine significance, review:

- Who logged in
- From where
- Logon type
- Whether the host is expected
- What happened next in the session

---

## Detection Limitations

1. This lab implementation alerts on privileged logon but does not fully automate correlation between Event ID 4624 and Event ID 4672.
2. Correlation was validated manually by comparing Logon ID values in archived logs.
3. In production environments, more complete correlation may require:
   - SIEM queries
   - Advanced rule chaining
   - Timeline analysis
   - EDR integration
4. Event ID 4672 is noisy in Windows environments, especially on domain controllers.
5. Contextual baselining is required to distinguish legitimate administrative work from suspicious activity.

Despite these limitations, the detection provides useful visibility into privileged activity and supports investigation of remote admin behavior.

---

## Response Summary

When this alert triggers:

1. Identify the account associated with Event ID 4672.
2. Match the Logon ID to the corresponding Event ID 4624.
3. Determine the source host, source IP, and logon type.
4. Assess whether the account, host, and timing are expected.
5. Review nearby events for failed logons, scanning activity, Kerberos requests, or lateral movement.
6. Escalate severity if the logon occurred from an unexpected source or was followed by suspicious activity.

---

## Hardening Recommendations

- Limit use of Domain Administrator accounts
- Use separate admin accounts for administration
- Restrict remote access to Domain Controllers
- Monitor privileged logons on critical systems
- Enable full audit policy for logon events
- Forward logs to centralized SIEM
- Review privileged activity regularly
- Establish baselines for expected admin workstations and accounts

---

## MITRE ATT&CK Mapping

| Tactic | Technique | Notes |
|--------|-----------|-------|
| Defense Evasion / Persistence / Privilege Escalation | T1078 – Valid Accounts | Abuse of legitimate admin credentials |
| Lateral Movement | T1021 – Remote Services | Remote admin access to DC or critical host |
| Privilege Escalation | T1068 – Exploitation for Privilege Escalation | Relevant when privileged session follows compromise |

---

## Detection Maturity

✔ Event ID 4672 validated in lab environment
✔ Event ID 4624 correlation verified by Logon ID
✔ Custom Wazuh rule created and validated
✔ Remote administrative test activity generated
✔ False positive considerations documented
✔ Hardening recommendations documented
⏳ Full automated SIEM correlation – future enhancement
⏳ Baseline-driven anomaly detection – future enhancement

---

## Related Documentation

- `detections/use-cases/uc-004-password-spraying-detection.md`
- `detections/use-cases/uc-005-kerberos-anomaly-detection.md`
- `incident-response/playbooks/pb-003-lateral-movement.md`
- `docs/04-wazuh-deployment.md`
- `docs/99-roadmap.md`

---

## Result

Privileged logon detection using Event ID 4672 was successfully implemented, validated, and documented in the cyberlab environment.

The lab confirms that privileged logons can be detected, correlated with authentication events, and investigated using centralized logging in Wazuh.
