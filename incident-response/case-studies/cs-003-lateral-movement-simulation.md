# CS-003: Lateral Movement Simulation

## Scenario

Simulated lateral movement behavior from an attacker-controlled host (compromised workstation) scanning the corporate network for high-value targets (Domain Controller, file servers, database servers).

**Objective:** Validate detection of network scanning and lateral movement patterns using pfSense firewall logs and Wazuh correlation rules.

---

## Lab Setup

### Attacker Host

- **Hostname:** ATTACK-VM
- **IP Address:** 10.10.69.50
- **OS:** Debian/Ubuntu (attack host)
- **Role:** Compromised workstation, attacker pivot point

### Target Environment

- **Domain Controller:** DC01 (10.10.69.10)
- **Windows Clients:** WIN10-CLIENT (10.10.69.20), WIN11-CLIENT (10.10.69.30)
- **Metasploitable Targets:** Metasploitable2 (10.10.69.40), Metasploitable3 (10.10.69.45)
- **Gateway:** pfSense (10.10.69.1)

---

## Attack Simulation

### Phase 1: Network Discovery

**Time:** 14:02 - 14:05

**Actions:**
1. Attacker scans entire lab network to identify live hosts
2. Identifies domain controller (DC01) and client systems
3. Maps open ports on discovered hosts

**Commands:**

```bash
# Host discovery scan
nmap -sn 10.10.69.0/24

# Port scan on discovered hosts
nmap -sT -p 1-1000 10.10.69.10
nmap -sT -p 1-1000 10.10.69.20
nmap -sT -p 1-1000 10.10.69.30
nmap -sT -p 1-1000 10.10.69.40
nmap -sT -p 1-1000 10.10.69.45
```

**Results:**
- Identified 5 live hosts in lab network
- Discovered open ports: 22 (SSH), 80 (HTTP), 135 (RPC), 139/445 (SMB), 3389 (RDP)
- Targeted DC01 (10.10.69.10) for lateral movement

---

### Phase 2: Port Sweep for Critical Services

**Time:** 14:05 - 14:07

**Actions:**
1. Attacker specifically scans for SMB (port 445) across all hosts
2. Identifies SMB shares and potential credential abuse paths
3. Targets domain controller for SMB exploitation

**Commands:**

```bash
# SMB port sweep across entire network
nmap -sT -p 445 10.10.69.0/24

# Enumerate SMB shares on DC01
smbclient -L //10.10.69.10 -U guest%
```

**Results:**
- Identified 3 hosts with SMB open (DC01, WIN10-CLIENT, WIN11-CLIENT)
- Discovered accessible SMB shares on DC01
- Mapped attack path: compromised workstation → SMB → domain controller

---

### Phase 3: Credential Abuse Attempt

**Time:** 14:07 - 14:10

**Actions:**
1. Attacker attempts to authenticate to DC01 using captured credentials
2. Tries multiple authentication methods (SMB, LDAP, Kerberos)
3. Attempts privilege escalation (admin account)

**Commands:**

```bash
# SMB authentication attempt
smbclient //10.10.69.10/c$ -U jsmith

# LDAP enumeration
ldapsearch -x -H ldap://10.10.69.10 -D "cn=jsmith,cn=users,dc=corp,dc=local" -W

# Kerberos ticket request (simulated)
# (Note: This was pre-validated in CS-002 Kerberoasting scenario)
```

**Results:**
- All authentication attempts failed (4625 events logged)
- No successful logons achieved
- Attacker did not compromise credentials

---

## Timeline

| Time | Event | Detection |
|------|-------|-----------|
| 14:02 | Network discovery scan (10.10.69.0/24) | UC-003 Alert: Multiple destinations |
| 14:03 | Port scan on DC01 (1-1000 ports) | UC-003 Alert: Port scanning |
| 14:04 | Port scan on client systems | UC-003 Alert: Multiple destinations |
| 14:05 | SMB port sweep (445 on all hosts) | UC-003 Alert: Port sweep (level 12) |
| 14:06 | SMB enumeration on DC01 | Firewall log: SMB connection |
| 14:07 | SMB auth attempt (guest) | Firewall log: Connection |
| 14:08 | LDAP enumeration attempt | Firewall log: LDAP connection |
| 14:09 | Kerberos ticket request | UC-002 Alert: RC4 ticket (if applicable) |
| 14:10 | Activity ceases (attacker paused) | End of simulation |

---

## Detection Triggered

### Primary Detection

**Detection ID:** UC-003
**Rule ID:** 100201 (multiple destinations), 100400 (port sweep)
**Severity:** Medium (8), High (12)
**MITRE ATT&CK:**
- T1021 – Remote Services
- T1595 – Active Scanning

**Alert Details:**

```
Rule: 100201 (level 8)
Description: Lateral movement: Multiple destination IPs from single source
Source IP: 10.10.69.50 (ATTACK-VM)
Destinations: 10.10.69.10, 10.10.69.20, 10.10.69.30, 10.10.69.40, 10.10.69.45
Window: 5 minutes
Time: 14:02 - 14:05
```

```
Rule: 100400 (level 12)
Description: Port sweep: Same port accessed on multiple hosts
Source IP: 10.10.69.50 (ATTACK-VM)
Destination Port: 445 (SMB)
Hosts: 10.10.69.10, 10.10.69.20, 10.10.69.45
Window: 2 minutes
Time: 14:05 - 14:07
```

---

### Correlation with Other Detections

**UC-001 (SSH Brute Force):** No correlation - attacker did not attempt SSH brute force in this scenario

**UC-002 (Kerberos RC4):** No correlation - attacker did not successfully obtain Kerberos tickets

**Authentication Events:**
- Event 4625 (failed logons): 15 attempts from 10.10.69.50
- Event 4624 (successful logons): 0 (no successful authentication)
- Event 4672 (privileged logons): 0 (no privilege escalation)

**Severity Assessment:** Medium (scanning detected, no successful compromise)

---

## Investigation Steps

### 1. Alert Triage

**Identified:**
- Source IP: 10.10.69.50 (ATTACK-VM)
- Behavior: Network scanning + SMB port sweep
- Scope: 5 destinations targeted, SMB services probed

**Context:**
- No successful authentication events
- No privilege escalation observed
- Scanning activity only (no compromise confirmed)

---

### 2. Host Investigation

**Source Host (ATTACK-VM):**

```bash
# Checked running processes
ps aux | grep -E "nmap|smbclient|ldapsearch"

# Found:
# - nmap process running
# - smbclient process running
# - ldapsearch process running
```

**Conclusion:** Attacker tools actively running on ATTACK-VM

---

### 3. Target Investigation

**DC01 (10.10.69.10):**

```powershell
# Checked recent logon events
Get-WinEvent -FilterHashtable @{LogName='Security'; ID=4625} | Where-Object {$_.Message -like '*10.10.69.50*'}

# Found: 3 failed SMB authentication attempts (4625 events)
# No successful logons (4624) from source IP
```

**Conclusion:** Attacker attempted authentication but did not compromise credentials

---

### 4. Network Activity Review

**pfSense Firewall Logs:**

- Total connections from 10.10.69.50: 847
- Successful connections: 632 (mostly SYN-ACK, some established)
- Blocked connections: 215 (ports not open on targets)
- Top destination ports: 22 (SSH), 80 (HTTP), 445 (SMB), 3389 (RDP)

**Conclusion:** Extensive scanning activity, but no evidence of successful compromise

---

## Containment Actions

**Immediate Response:**

1. **Blocked source IP at pfSense:**
   - Added firewall rule: Block 10.10.69.50
   - Rule logged: ☑️ Yes
   - Status: Active

2. **Isolated ATTACK-VM:**
   - Disconnected from lab network
   - Created snapshot for forensic analysis

3. **Verified containment:**
   - No new connections from 10.10.69.50
   - Scanning activity ceased

---

## Root Cause

**Attacker Motivation:** Lateral movement to high-value targets (domain controller, file servers)

**Attack Vector:** Network scanning + SMB enumeration

**Why Detection Worked:**
- Firewall logs captured all connection attempts
- Wazuh rules identified scanning patterns (multiple destinations, port sweep)
- Correlation with auth events confirmed no successful compromise

---

## Remediation

### Immediate Actions

✅ Blocked attacker IP (10.10.69.50)
✅ Isolated compromised host (ATTACK-VM)
✅ Verified no successful compromise occurred

---

### Longer-Term Hardening

**Network Segmentation:**
- Implement Zero Trust network architecture
- Require authentication for all lateral movement
- Separate admin workstations from production networks

**Authentication Controls:**
- Enforce MFA for privileged accounts
- Implement just-in-time access (temporary privilege)
- Monitor and alert on unusual authentication patterns

**Monitoring Enhancements:**
- Deploy EDR/AV on all endpoints
- Implement behavioral analytics for anomaly detection
- Add threat intel integration for known scanner IPs

---

## Lessons Learned

### Detection Effectiveness

**What Worked:**
✅ Firewall logs captured all scanning activity
✅ Wazuh rules identified scanning patterns accurately
✅ Threshold tuning (10 destinations, 15 hosts) appropriate for lab environment
✅ Correlation with auth events confirmed scope of activity

**What Didn't Work:**
⚠️ No automated containment - required manual IP blocking
⚠️ No behavioral baseline to compare against "normal" scanning
⚠️ Alert volume high during simulation (multiple rule triggers)

---

### Response Time

| Phase | Time |
|-------|------|
| Alert triggered | 14:02 |
| Investigation started | 14:03 (1 minute) |
| Containment (IP blocked) | 14:04 (2 minutes) |
| Host isolated | 14:05 (3 minutes) |

**Total response time:** 3 minutes (excellent)

---

### False Positives

**Expected false positives:**
- Administrator scanning network for troubleshooting
- Backup software discovering hosts
- Monitoring tools (Nagios, Zabbix) polling services

**Mitigation:**
- Whitelist known admin IPs and tools
- Implement time-based alerts (business hours vs off-hours)
- Correlate with authentication to validate intent

---

### Detection Gaps

**What we missed:**
- Attacker did not attempt credential dumping (no LSASS access)
- No persistence mechanisms observed
- No exfiltration activity detected

**Future improvements:**
- Add EDR detection for credential dumping
- Implement DNS exfiltration detection
- Add honeypots to attract attackers and provide early warning

---

## Detection Fidelity

| Metric | Result |
|--------|--------|
| Alert triggered? | ✅ Yes |
| Accurate classification? | ✅ Yes (lateral movement) |
| False positive? | ❌ No |
| Response time? | ✅ < 5 minutes |
| Containment effective? | ✅ Yes |
| Root cause identified? | ✅ Yes |

**Overall Assessment:** **Excellent** - Detection, investigation, and containment all performed as expected

---

## Recommendations

### Short-Term (1-2 weeks)

1. **Implement Wazuh Active Response:**
   - Auto-block IPs triggering UC-003 level 12 alerts
   - Send notifications to security team

2. **Add dashboard visualization:**
   - Lateral movement alert timeline
   - Source IP heat map
   - Top targeted services

3. **Document baseline traffic:**
   - Profile normal admin scanning activity
   - Establish expected connection patterns

---

### Medium-Term (1-2 months)

1. **Deploy EDR on all endpoints:**
   - Host-based detection of scanning tools
   - Behavioral monitoring for anomalous activity

2. **Implement Zero Trust networking:**
   - Require authentication for all lateral movement
   - Micro-segmentation between network zones

3. **Add threat intel feeds:**
   - Cross-reference scanner IPs with known bad actors
   - Enrich alerts with reputation data

---

### Long-Term (3-6 months)

1. **Machine learning analytics:**
   - Baseline normal per-user/per-host behavior
   - Detect anomalies beyond simple thresholds

2. **Automated incident response:**
   - End-to-end automated containment for confirmed threats
   - Playbook-driven response workflows

3. **Continuous validation:**
   - Regular purple team exercises
   - Penetration testing to validate detection coverage

---

## Evidence & Screenshots

### Evidence 1: Wazuh Alert - Multiple Destinations

*[Screenshot: Wazuh Security Events showing rule 100201 alert]*
**Location:** `assets/evidence/cs-003-001-multiple-destinations.png`

### Evidence 2: Wazuh Alert - Port Sweep

*[Screenshot: Wazuh Security Events showing rule 100400 alert (level 12)]*
**Location:** `assets/evidence/cs-003-002-port-sweep.png`

### Evidence 3: pfSense Firewall Logs

*[Screenshot: pfSense System Logs showing filterlog entries from 10.10.69.50]*
**Location:** `assets/evidence/cs-003-003-firewall-logs.png`

### Evidence 4: Windows Event Viewer - Failed Logons

*[Screenshot: Windows Event Viewer (Security) showing 4625 events from 10.10.69.50]*
**Location:** `assets/evidence/cs-003-004-failed-logons.png`

### Evidence 5: Attack VM - Running Processes

*[Screenshot: ATTACK-VM terminal showing nmap/smbclient processes]*
**Location:** `assets/evidence/cs-003-005-attack-processes.png`

### Evidence 6: Containment - pfSense Block Rule

*[Screenshot: pfSense Firewall Rules showing block rule for 10.10.69.50]*
**Location:** `assets/evidence/cs-003-006-containment-rule.png`

---

## References

- MITRE ATT&CK: T1021 - Remote Services
- MITRE ATT&CK: T1595 - Active Scanning
- Wazuh Active Response: https://documentation.wazuh.com/current/user-manual/capabilities/active-response/index.html
- NIST SP 800-61 - Incident Response Guide
