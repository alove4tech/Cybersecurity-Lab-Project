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
│  10.10.69.20                                                 │
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
| Remote Log Server | 10.10.69.20 | Wazuh server IP |
| Remote Log Server Port | 514 | Default syslog UDP port |
| Protocol | UDP | UDP (default) or TCP for reliability |
| Log Levels | Log All | Capture all forwarded pfSense log categories |

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
# IP 10.10.69.1.43821 > 10.10.69.20.514: SYSLOG local0.info, ...
```

---

## Wazuh Configuration

The Wazuh manager is configured to receive pfSense syslog directly on UDP 514. The listener is restricted to the firewall source IP (`10.10.69.1`) so the manager is not accepting arbitrary syslog from the full lab subnet.

### Wazuh Manager Syslog Listener

Edit `/var/ossec/etc/ossec.conf` on the Wazuh manager and add a remote syslog listener similar to the following:

```xml
<remote>
  <connection>syslog</connection>
  <port>514</port>
  <protocol>udp</protocol>
  <allowed-ips>10.10.69.1</allowed-ips>
</remote>
```

Restart the manager after updating the configuration:

```bash
systemctl restart wazuh-manager
systemctl status wazuh-manager
```

### Listener Verification

```bash
ss -lunp | grep ':514'
```

Expected result: Wazuh is listening on UDP 514 for pfSense syslog.

The pfSense side is configured for remote syslog forwarding to `10.10.69.20:514/UDP` using UDP. Firewall events have been confirmed flowing from pfSense to the Wazuh manager. To re-verify traffic on the Wazuh manager:

```bash
tcpdump -i any host 10.10.69.1 and udp port 514 -n -v
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

> **Note:** UC-003 now includes the pfSense `filterlog` base rule and three correlation rules for multi-destination scanning, port sweeps, and port scans.

**Objective:** Detect network scanning behavior indicating lateral movement attempts.

---

**Detection Logic:**

Trigger alert when:
- Single source IP attempts connections to **≥ 10 unique destinations**
- Or single source IP probes **≥ 20 unique ports**
- Within a 5-minute window

**Wazuh Rules:**

| Rule ID | Purpose |
|---------|---------|
| 100200 | pfSense `filterlog` base rule |
| 100201 | Multiple destination IPs from one source |
| 100400 | Same destination port contacted across multiple hosts |
| 100401 | Multiple destination ports probed on one host |

The deployed rules use Wazuh field-correlation syntax such as `same_srcip` and `different_dstip`.

---

**Validation Procedure:**

1. Use Nmap from attack VM:
   ```bash
   nmap -sT -p 1-1000 10.10.69.0/24
   ```

2. Check pfSense logs for connection attempts

3. Verify Wazuh rule 100201 triggers

---

### Blocked External Access Detection (Planned)

**Detection Metadata:**
- Log Source: pfSense firewall logs
- Severity: Medium (High if repeated)
- MITRE ATT&CK: T1071 – Application Layer Protocol

> **Note:** This is a planned firewall-based detection. Rule IDs use the 101xxx range to avoid conflicts with host-based detection rules (100xxx series).

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
  <rule id="101000" level="7">
    <if_sid>100200</if_sid>
    <field name="action">block</field>
    <description>Firewall blocked connection</description>
  </rule>

  <rule id="101001" level="9">
    <if_sid>101000</if_sid>
    <same_srcip />
    <different_dstip />
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

### Port Sweep / Network Recon

**Detection Metadata:**
- Log Source: pfSense firewall logs
- Severity: High
- MITRE ATT&CK: T1595 – Active Scanning

> **Note:** Port sweep and port scan logic is implemented under UC-003 with rule IDs `100400` and `100401`.

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
    <if_sid>100200</if_sid>
    <same_srcip />
    <same_dst_port />
    <different_dstip />
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
  <rule id="101200" level="10">
    <if_sid>100100,100201</if_sid> <!-- UC-002 Kerberos RC4 OR UC-003 lateral movement -->
    <same_srcip />
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
  <rule id="101300" level="13">
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
  <rule id="101400" level="13">
    <if_sid>61602,100200</if_sid> <!-- 4672 OR firewall connection -->
    <same_srcip />
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
- Query: `rule.id: 100201 OR rule.id: 100400 OR rule.id: 100401`
- Columns: timestamp, source_ip, dst_ip, dst_port, action

**Panel 6: Correlated Alerts Table**
- Query: `rule.id: 101200 OR rule.id: 101300 OR rule.id: 101400`
- Columns: timestamp, rule.description, source_ip, severity

---

## Validation Checklist

- [x] pfSense remote syslog enabled
- [x] Wazuh UDP 514 listener configured
- [x] Wazuh server receiving pfSense syslog traffic
- [x] Firewall events visible in Wazuh telemetry
- [x] UC-003 Wazuh rules deployed
- [x] Port sweep and port scan rules deployed
- [ ] Blocked external access detection validated
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

**Check 2: Wazuh UDP listener**
```bash
ss -lunp | grep ":514"
```
Expected: UDP 514 listener owned by the Wazuh manager process.

**Check 3: Source restriction**

Confirm `/var/ossec/etc/ossec.conf` allows only the pfSense firewall IP (`10.10.69.1`) for this listener.

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
