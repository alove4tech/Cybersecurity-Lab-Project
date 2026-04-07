# pfSense Syslog Forwarding to Wazuh

## Objective

Forward pfSense firewall logs to Wazuh SIEM for centralized monitoring, enabling correlation between network activity and host-based telemetry (authentication events, Kerberos tickets, etc.).

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         pfSense                              │
│  10.10.69.1                                                  │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  Syslog Client                                        │  │
│  │  - Firewall Events                                    │  │
│  │  - NAT Logs                                            │  │
│  │  - DHCP Assignments                                    │  │
│  │  - VPN Connections                                     │  │
│  │  - System Events                                       │  │
│  └────────────────┬──────────────────────────────────────┘  │
└───────────────────┼──────────────────────────────────────────┘
                    │ UDP 514 (Syslog)
                    │
                    ▼
┌─────────────────────────────────────────────────────────────┐
│                      Wazuh Server                            │
│  10.10.69.X                                                  │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  Syslog Receiver (rsyslog/syslog-ng)                  │  │
│  │  → Decodes pf syslog format                           │  │
│  │  → Forwards to Filebeat → Wazuh Indexer                │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

---

## pfSense Configuration

### Step 1: Enable Remote Syslog

Navigate to: **Status → System Logs → Settings**

#### Remote Logging Options

| Setting | Value | Notes |
|---------|-------|-------|
| Enable Remote Logging | ☑️ Checked | Enable syslog forwarding |
| Remote Log Server | 10.10.69.X | Wazuh server IP |
| Remote Log Server Port | 514 | Default syslog UDP port |
| Protocol | UDP | UDP (default) or TCP for reliability |
| Log Levels | Everything | Capture all log levels |

#### Log Categories to Forward

Enable these categories for security monitoring:

☑️ **Firewall Events**
- Allow rules
- Block rules
- NAT translations

☑️ **System**
- General system events
- Service status changes
- Config changes

☑️ **DHCP**
- DHCP leases
- DHCP requests
- Static lease assignments

☑️ **VPN** (if applicable)
- OpenVPN connections
- IPsec events

☑️ **Gateways**
- Gateway status
- Failover events

**Uncheck** (for now):
- Resolver (DNS) - optional, high volume
- Wireless (if not applicable)

#### Click **Save** and **Apply Changes**

---

### Step 2: Verify Syslog Transmission

```bash
# On Wazuh server, listen for syslog traffic
tcpdump -i any udp port 514 -n -v

# You should see packets from 10.10.69.1 (pfSense)
# Example output:
# IP 10.10.69.1.43821 > 10.10.69.X.514: SYSLOG local0.info, ...
```

---

## Wazuh Configuration

### Option 1: Wazuh Manager with rsyslog Receiver

Wazuh Manager includes rsyslog for syslog ingestion. Configure to accept pfSense logs.

#### Configure rsyslog to Listen on UDP 514

Edit `/etc/rsyslog.conf` on Wazuh Manager:

```bash
# Add these lines to accept remote syslog
$ModLoad imudp
$UDPServerRun 514
$UDPServerAddress 10.10.69.X  # Wazuh server IP

# Create pfSense-specific log file
$template PFSenseFormat,"%timestamp% %hostname% %syslogtag% %msg%\n"
$InputTCPServerBindRuleset pfSense
*.* ?PFSenseFormat

# Restart rsyslog
systemctl restart rsyslog
```

#### Configure Filebeat to Read pfSense Logs

Edit `/etc/filebeat/filebeat.yml`:

```yaml
filebeat.inputs:
  # ... existing inputs ...

  # pfSense syslog input
  - type: log
    enabled: true
    paths:
      - /var/log/pfsense.log
    fields:
      log_type: firewall
      source: pfsense
    fields_under_root: true

output.elasticsearch:
  hosts: ["localhost:9200"]

# Restart Filebeat
systemctl restart filebeat
```

---

### Option 2: Direct Wazuh Agent on Wazuh Server

If using the all-in-one Wazuh installer, configure the local Wazuh agent to monitor pfSense logs.

#### Configure Agent to Read pfSense Logs

Edit `/var/ossec/etc/ossec.conf` (on Wazuh server):

```xml
<ossec_config>
  <localfile>
    <log_format>syslog</log_format>
    <location>/var/log/pfsense.log</location>
  </localfile>
</ossec_config>
```

**Restart Wazuh Agent:**

```bash
systemctl restart wazuh-agent
```

---

## pfSense Log Formats

### Firewall Allow Event

```
filterlog: 8,,,1000000103,em0,match,pass,out,4,0x0,,61,1390,0,none,6,tcp,20,10.10.69.20,10.10.69.30,80,55432,0,SA,1157239258,1157239258,,,
```

**Fields:**
- `em0`: Interface
- `pass`: Action (allow)
- `out`: Direction (outbound)
- `10.10.69.20`: Source IP
- `10.10.69.30`: Destination IP
- `80`: Destination port (HTTP)
- `55432`: Source port

---

### Firewall Block Event

```
filterlog: 8,,,1000000103,em0,match,block,in,4,0x0,,61,1390,0,none,6,tcp,20,10.10.69.50,10.10.69.10,22,54321,0,S,1157239300,1157239300,,,
```

**Fields:**
- `block`: Action (denied)
- `in`: Direction (inbound)
- `10.10.69.50`: Source IP (potentially malicious)
- `10.10.69.10`: Destination IP (DC01)
- `22`: Destination port (SSH)

---

### NAT Translation

```
filterlog: 8,,,1000000103,em0,match,pass,out,4,0x0,,61,1390,0,none,6,tcp,20,10.10.69.20,192.168.1.100,443,55432,0,SA,1157239258,1157239258,,,
```

**Fields:**
- `10.10.69.20`: Internal source
- `192.168.1.100`: External destination (NAT destination)
- `443`: Destination port (HTTPS)

---

### DHCP Lease Assignment

```
dhcpd: DHCPDISCOVER from 00:11:22:33:44:55 on em0
dhcpd: DHCPOFFER on 10.10.69.100 to 00:11:22:33:44:55 (WIN10-CLIENT) via em0
dhcpd: DHCPREQUEST for 10.10.69.100 from 00:11:22:33:44:55 (WIN10-CLIENT) via em0
dhcpd: DHCPACK on 10.10.69.100 to 00:11:22:33:44:55 (WIN10-CLIENT) via em0
```

---

### VPN Connection (OpenVPN)

```
openvpn: 10.10.69.50:50202 [user1] Peer Connection Initiated with [AF_INET]10.10.69.1:1194
openvpn: user1/10.10.69.50:50202 MULTI_sva: pool returned IPv4=10.10.70.10
```

---

## Detection Use Cases

### UC-003: Lateral Movement Detection (Network Scanning)

**Detection Metadata:**
- Detection ID: UC-003
- Log Source: pfSense firewall logs
- Severity: Medium (High if correlated with failed auth)
- MITRE ATT&CK: T1021 – Remote Services

**Objective:** Detect network scanning behavior indicating lateral movement attempts.

---

**Detection Logic:**

Trigger alert when:
- Single source IP attempts connections to **≥ 10 unique destinations**
- Or single source IP probes **≥ 20 unique ports**
- Within a 5-minute window

**Wazuh Rule:**

```xml
<group name="firewall,pfsense,lateral_movement,">
  <rule id="100200" level="10">
    <if_sid>5500</if_sid> <!-- pfSense firewall rule -->
    <field name="action">pass</field>
    <description>Firewall connection logged</description>
  </rule>

  <rule id="100201" level="8">
    <if_sid>100200</rule>
    <same_source_ip />
    <different_dst_ip />
    <description>Lateral movement: Multiple destination IPs from single source</description>
    <mitre>
      <id>T1021</id>
    </mitre>
    <group>lateral_movement,scanning</group>
  </rule>
</group>
```

---

**Validation Procedure:**

1. Use Nmap from attack VM:
   ```bash
   nmap -sT -p 1-1000 10.10.69.0/24
   ```

2. Check pfSense logs for connection attempts

3. Verify Wazuh rule 100201 triggers

---

### UC-004: Blocked External Access Attempt

**Detection Metadata:**
- Detection ID: UC-004
- Log Source: pfSense firewall logs
- Severity: Medium (High if repeated)
- MITRE ATT&CK: T1071 – Application Layer Protocol

**Objective:** Detect attempts to access external networks from isolated lab (security control validation).

---

**Detection Logic:**

Trigger alert when:
- Outbound connection is **blocked** by firewall
- Destination IP is **outside 10.10.69.0/24**
- More than 5 blocked attempts in 1 minute

**Wazuh Rule:**

```xml
<group name="firewall,pfsense,blocked_traffic,">
  <rule id="100300" level="7">
    <if_sid>100200</rule>
    <field name="action">block</field>
    <description>Firewall blocked connection</description>
  </rule>

  <rule id="100301" level="9">
    <if_sid>100300</rule>
    <same_source_ip />
    <different_dst_ip />
    <description>Blocked external access: Multiple destinations from single source</description>
    <mitre>
      <id>T1071</id>
    </mitre>
    <group>egress_control,security_breach</group>
  </rule>
</group>
```

---

**Validation Procedure:**

1. From lab VM, attempt external connectivity:
   ```bash
   curl http://example.com
   ping 8.8.8.8
   ```

2. Confirm blocks in pfSense logs

3. Verify Wazuh alert triggers

---

### UC-008: Port Sweep / Network Recon

**Detection Metadata:**
- Detection ID: UC-008
- Log Source: pfSense firewall logs
- Severity: High
- MITRE ATT&CK: T1595 – Active Scanning

**Objective:** Detect port sweeping behavior indicating reconnaissance.

---

**Detection Logic:**

Trigger alert when:
- Single source IP connects to **same destination port on ≥ 15 different hosts**
- Within a 2-minute window
- Pattern: Port sweep (horizontal scanning)

**Wazuh Rule:**

```xml
<group name="firewall,pfsense,reconnaissance,">
  <rule id="100400" level="12">
    <if_sid>100200</rule>
    <same_source_ip />
    <same_dst_port />
    <different_dst_ip />
    <description>Port sweep: Same port accessed on multiple hosts</description>
    <mitre>
      <id>T1595.001</id>
    </mitre>
    <group>reconnaissance,port_sweep</group>
  </rule>
</group>
```

---

**Validation Procedure:**

1. Use Nmap for port sweep:
   ```bash
   nmap -sT -p 22 10.10.69.0/24
   ```

2. Check firewall logs for multiple connections to port 22

3. Verify Wazuh rule 100400 triggers

---

## Correlation Scenarios

### Correlation 1: Failed Auth + Network Scan

**Pattern:** SSH brute force (UC-001) followed by network scanning (UC-003)

**Wazuh Correlation Rule:**

```xml
<group name="correlation,credential_abuse,">
  <rule id="100500" level="10">
    <if_sid>100100,100201</if_sid> <!-- UC-001 brute force OR UC-003 lateral movement -->
    <same_source_ip />
    <description>Correlation: Network activity following authentication failures</description>
    <mitre>
      <id>T1110,T1021</id>
    </mitre>
    <group>credential_abuse,lateral_movement</group>
  </rule>
</group>
```

---

### Correlation 2: Kerberos + Network Movement

**Pattern:** Kerberoasting (UC-002) followed by lateral movement (UC-003)

**Detection Rationale:**
Attacker obtains service account credentials via Kerberoasting, then uses them to move laterally through the network.

**Wazuh Correlation Rule:**

```xml
<group name="correlation,kerberos_lateral,">
  <rule id="100600" level="13">
    <if_sid>100100</if_sid> <!-- Kerberos RC4 (UC-002) -->
    <check_diff />
    <description>Correlation: Kerberos anomaly followed by lateral movement</description>
    <mitre>
      <id>T1558.003,T1021</id>
    </mitre>
    <group>credential_abuse,lateral_movement,critical</group>
  </rule>
</group>
```

---

### Correlation 3: Privileged Logon + New Connections

**Pattern:** 4672 privileged logon followed by unusual network activity

**Detection Rationale:**
Administrator credential compromise → attacker accesses new systems.

**Wazuh Correlation Rule:**

```xml
<group name="correlation,privileged_lateral,">
  <rule id="100700" level="13">
    <if_sid>61602,100200</if_sid> <!-- 4672 OR firewall connection -->
    <same_source_ip />
    <description>Correlation: Privileged logon followed by network activity</description>
    <mitre>
      <id>T1078,T1021</id>
    </mitre>
    <group>privilege_escalation,lateral_movement,critical</group>
  </rule>
</group>
```

---

## Dashboard Visualization

### Dashboard: Firewall Activity Overview

Create a new dashboard in Wazuh with these panels:

**Panel 1: Blocked vs. Allowed Traffic (Pie Chart)**
- Query: `log_type: firewall`
- Split by: `action.keyword`

**Panel 2: Top Blocked Source IPs (Bar Chart)**
- Query: `log_type: firewall AND action: block`
- Aggregate by: `source_ip.keyword`
- Time range: Last 24h

**Panel 3: Top Destination Ports (Horizontal Bar)**
- Query: `log_type: firewall AND action: pass`
- Aggregate by: `dst_port`
- Time range: Last 24h

**Panel 4: Network Activity Timeline (Line Chart)**
- Query: `log_type: firewall`
- Time series: Count over time
- Time range: Last 7d

**Panel 5: Lateral Movement Alerts (Data Table)**
- Query: `rule.id: 100201 OR rule.id: 100400`
- Columns: timestamp, source_ip, dst_ip, dst_port, action

**Panel 6: Correlated Alerts Table**
- Query: `rule.id: 100500 OR rule.id: 100600 OR rule.id: 100700`
- Columns: timestamp, rule.description, source_ip, severity

---

## Validation Checklist

- [ ] pfSense remote syslog enabled
- [ ] Wazuh server receiving syslog traffic (tcpdump verified)
- [ ] Filebeat reading pfSense logs
- [ ] Wazuh agent configured to monitor pfSense logs
- [ ] Logs visible in Wazuh Dashboard → Events viewer
- [ ] UC-003 lateral movement detection validated
- [ ] UC-008 blocked external access validated
- [ ] UC-009 port sweep detection validated
- [ ] Correlation rules tested
- [ ] Dashboard panels configured

---

## Troubleshooting

### No Logs Appear in Wazuh

**Check 1: pfSense sending syslog**
```bash
# On Wazuh server
tcpdump -i any udp port 514 -n -v
```
Expected: Packets from 10.10.69.1

**Check 2: rsyslog receiving**
```bash
# Check rsyslog is listening
netstat -tuln | grep 514
```
Expected: `0.0.0.0:514`

**Check 3: Filebeat reading**
```bash
# Check Filebeat logs
journalctl -u filebeat -f
```
Look for errors accessing `/var/log/pfsense.log`

---

### Decoders Not Working

**Check decoder path:**
```bash
# Verify pfSense decoder exists
cat /var/ossec/ruleset/decoders/0160-pfsense-decoders.xml
```

**Test decoder:**
```bash
# Use logtest tool
/var/ossec/bin/wazuh-logtest -t /var/log/pfsense.log
```

---

### High Log Volume

pfSense can generate significant log volume. Mitigation strategies:

1. **Filter log categories** in pfSense (disable Resolver logs)
2. **Use Wazuh rules** to suppress low-value alerts
3. **Implement log rotation** on Wazuh server
4. **Consider rate limiting** in rsyslog for high-volume events

---

## Future Enhancements

- [ ] **Encrypted syslog (TLS 6514)** - Secure log transmission
- [ ] **GeoIP enrichment** - Add country/city info to external IPs
- [ ] **Threat intel correlation** - Cross-reference with known malicious IPs
- [ ] **Automated blocking** - Wazuh Active Response to block IPs
- [ ] **Packet capture** - Store full PCAP for deep investigation

---

## References

- pfSense Documentation: https://docs.netgate.com/pfsense/
- Wazuh Firewall Monitoring: https://documentation.wazuh.com/current/user-manual/capabilities/firewall-monitoring.html
- MITRE ATT&CK: https://attack.mitre.org/
