# UC-003: Lateral Movement Detection (Network Scanning)

## Detection Metadata

- Detection ID: UC-003
- Log Source: pfSense firewall logs (filterlog)
- Severity: Medium (High if correlated with failed auth or privileged activity)
- MITRE ATT&CK:
  - T1021 – Remote Services
  - T1021.001 – Remote Desktop Protocol
  - T1021.004 – SSH
- Data Sensitivity: Network activity telemetry

---

## Objective

Detect lateral movement behavior by identifying network scanning patterns — a single host attempting connections to multiple destinations or probing multiple ports on the same destination.

---

## Log Source & Field Mapping

**Log Format:** pfSense `filterlog` events

**Example Event (Connection Allowed):**

```
filterlog: 8,,,1000000103,em0,match,pass,out,4,0x0,,61,1390,0,none,6,tcp,20,10.10.69.20,10.10.69.30,22,54321,0,SA,1157239258,1157239258,,,
```

**Parsed Fields:**

| Field | Value | Description |
|-------|-------|-------------|
| Interface | em0 | Network interface |
| Action | pass | Firewall action (allow/block) |
| Direction | out | Traffic direction (in/out) |
| Protocol | tcp | IP protocol (tcp/udp/icmp) |
| Source IP | 10.10.69.20 | Originating host |
| Dest IP | 10.10.69.30 | Target host |
| Dest Port | 22 | Destination port (SSH) |
| Source Port | 54321 | Source ephemeral port |
| TCP Flags | SA | SYN-ACK (connection established) |

**Example Event (Connection Blocked):**

```
filterlog: 8,,,1000000103,em0,match,block,in,4,0x0,,61,1390,0,none,6,tcp,20,10.10.69.50,10.10.69.10,22,54321,0,S,1157239300,1157239300,,,
```

---

## Baseline Behavior

**Normal traffic patterns:**
- Users connect to expected services (web, file shares, domain controller)
- Consistent source-destination pairings
- Predictable port usage (80/443 for web, 22 for SSH, 445 for SMB)

**Anomalous indicators:**
- Single host connecting to **many different destination IPs**
- Single host probing **many different ports on same destination**
- Connections to unexpected ports (e.g., 445 from non-server hosts)
- Rapid successive connections (scanning behavior)

---

## Detection Logic

### Alert Threshold 1: Destination Scan

Trigger when:
- Single source IP connects to **≥ 10 unique destination IPs**
- Within a **5-minute window**
- On any port

**Purpose:** Detect horizontal scanning across the network

---

### Alert Threshold 2: Port Sweep

Trigger when:
- Single source IP connects to **same destination port on ≥ 15 different hosts**
- Within a **2-minute window**

**Purpose:** Detect vertical scanning for a specific service (e.g., scanning port 22 across all hosts)

---

### Alert Threshold 3: Port Scanning

Trigger when:
- Single source IP probes **≥ 20 unique ports** on a single destination
- Within a **3-minute window**

**Purpose:** Detect vertical scanning of a single host

---

## Wazuh Rules

### Base Rule: Firewall Connection

```xml
<group name="firewall,pfsense,">
  <rule id="100200" level="0">
    <match>filterlog</match>
    <description>pfSense firewall event logged</description>
  </rule>
</group>
```

---

### Rule: Lateral Movement - Multiple Destinations

```xml
<group name="firewall,pfsense,lateral_movement,">
  <rule id="100201" level="8">
    <if_sid>100200</rule>
    <same_source_ip />
    <different_dst_ip />
    <options>alert_by_email</options>
    <description>Lateral movement: Multiple destination IPs from single source (≥ 10 in 5m)</description>
    <mitre>
      <id>T1021</id>
    </mitre>
    <group>lateral_movement,scanning</group>
  </rule>
</group>
```

**Note:** Wazuh handles the frequency/thresholding internally. Configure via `<rules>` in `/var/ossec/etc/ossec.conf`:

```xml
<rules>
  <rule frequency="10" timeframe="300">
    <rule_id>100201</rule_id>
  </rule>
</rules>
```

---

### Rule: Port Sweep - Same Port, Multiple Hosts

```xml
<group name="firewall,pfsense,reconnaissance,">
  <rule id="100400" level="12">
    <if_sid>100200</rule>
    <same_source_ip />
    <same_dst_port />
    <different_dst_ip />
    <description>Port sweep: Same port accessed on multiple hosts (≥ 15 in 2m)</description>
    <mitre>
      <id>T1595.001</id>
    </mitre>
    <group>reconnaissance,port_sweep</group>
  </rule>
</group>
```

**Frequency Configuration:**

```xml
<rules>
  <rule frequency="15" timeframe="120">
    <rule_id>100400</rule_id>
  </rule>
</rules>
```

---

### Rule: Port Scanning - Multiple Ports, Single Host

```xml
<rule id="100401" level="10">
  <if_sid>100200</rule>
  <same_source_ip />
  <same_dst_ip />
  <different_dst_port />
  <description>Port scanning: Multiple ports accessed on single host (≥ 20 in 3m)</description>
  <mitre>
    <id>T1595.002</id>
  </mitre>
  <group>reconnaissance,port_scan</group>
</rule>

<rules>
  <rule frequency="20" timeframe="180">
    <rule_id>100401</rule_id>
  </rule>
</rules>
```

---

## Validation Procedure

### Test 1: Destination Scan (Horizontal)

```bash
# From attack VM (10.10.69.X), scan multiple hosts
nmap -sT -p 22 10.10.69.10,10.10.69.20,10.10.69.30,10.10.69.40,10.10.69.50,10.10.69.60,10.10.69.70,10.10.69.80,10.10.69.90,10.10.69.100
```

**Expected Result:**
- pfSense logs connection attempts
- Wazuh rule 100201 triggers (level 8)
- Alert shows source IP and multiple destination IPs

---

### Test 2: Port Sweep (Vertical)

```bash
# Scan same port across multiple hosts
nmap -sT -p 445 10.10.69.0/24
```

**Expected Result:**
- Multiple connections to port 445 (SMB)
- Wazuh rule 100400 triggers (level 12)
- Alert shows port sweep pattern

---

### Test 3: Port Scanning (Vertical on Single Host)

```bash
# Scan multiple ports on single host
nmap -sT -p 1-100 10.10.69.10
```

**Expected Result:**
- Connection attempts to multiple ports
- Wazuh rule 100401 triggers (level 10)
- Alert shows port scanning behavior

---

### Test 4: False Positive Scenario

```bash
# Normal administrative access
ssh 10.10.69.10
ssh 10.10.69.20
ssh 10.10.69.30
```

**Expected Result:**
- Legitimate admin connections
- Should NOT trigger alerts (frequency below threshold)
- Verify threshold tuning is appropriate

---

## False Positive Considerations

**Common false positives:**

1. **Administrator activity** - Legitimate admin connecting to multiple servers
2. **Backup software** - Automated backup jobs scanning for hosts
3. **Network discovery tools** - Spiceworks, Nagios, monitoring systems
4. **Windows browsing** - SMB enumeration from domain-joined machines

**Mitigation strategies:**

- **Whitelist known admin IPs** in Wazuh configuration
- **Exclude management tools** from detection (e.g., backup server IP)
- **Tune thresholds** based on baseline traffic patterns
- **Correlate with authentication events** to validate context

---

## Detection Rationale

Lateral movement is a key phase in attacker kill chains. After compromising an initial foothold, attackers scan the network to:

1. **Identify high-value targets** (domain controllers, file servers, databases)
2. **Map network topology** and trust relationships
3. **Find vulnerable services** (SMB, RDP, SSH)
4. **Pivot to additional systems** using compromised credentials

Firewall logs provide visibility into network scanning behavior that host-based logs alone may miss.

---

## Response Summary

### Investigation Steps

1. **Identify source host:**
   - Check which lab VM corresponds to source IP
   - Review recent authentication events (4624/4625) for that host
   - Look for suspicious processes (PowerShell, Impacket, tools)

2. **Assess impact:**
   - Were any successful connections established?
   - Did source IP successfully authenticate to any target?
   - Review Kerberos events (4768/4769) for ticket requests

3. **Determine intent:**
   - Scanning activity may be reconnaissance only
   - Successful connections + auth events indicate compromise
   - Correlate with security alerts from other sources

---

### Containment Actions

If malicious activity confirmed:

1. **Block source IP** at pfSense (temporary firewall rule)
2. **Isolate affected host** (disconnect from network)
3. **Revoke credentials** if compromise suspected
4. **Rotate service account passwords** if SPNs targeted

---

### Eradication Actions

- Remove persistence mechanisms
- Review firewall logs for prior activity
- Audit privilege escalation (4672 events)
- Scan for artifacts of tools used

---

### Recovery Actions

- Restore service access if disrupted
- Reinforce network segmentation rules
- Implement additional detection rules
- Document incident for future reference

---

## Detection Limitations

1. **Encrypted traffic** - TLS/SSL may obscure content, but IPs/ports visible
2. **Protocol-aware tools** - Some lateral movement uses legitimate protocols (SMB)
3. **Living off the land** - Attackers may use built-in Windows tools
4. **Threshold tuning** - Requires baseline of normal network activity
5. **False positives** - Administrative tools can trigger alerts

---

## Post-Incident Improvements

- **Add machine learning** - Baseline normal traffic per user/host
- **Implement honeypots** - Decoy systems to attract scanners
- **Behavioral analysis** - Detect anomalies beyond simple thresholds
- **Automated blocking** - Wazuh Active Response to auto-block scanners
- **Threat intel integration** - Cross-reference with known scanner IPs

---

## Detection Maturity

✔ Detection logic defined
✔ Wazuh rules documented
✔ Validation procedures defined
⏳ Threshold tuning in progress
⏳ Evidence screenshots (add to assets/evidence/)
⏳ False positive tuning based on lab traffic
⏳ Incident response playbook (PB-003 - to be created)

---

## References

- MITRE ATT&CK: T1021 - Remote Services
- MITRE ATT&CK: T1595 - Active Scanning
- pfSense Firewall Logging: https://docs.netgate.com/pfsense/
- Wazuh Correlation Rules: https://documentation.wazuh.com/current/user-manual/ruleset/rules.html
