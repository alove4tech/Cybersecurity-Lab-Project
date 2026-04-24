# Scripts

Utility scripts for the attack and management hosts.

## welcome.sh

A command-center dashboard for the Debian attack host. Run it on login to get a quick status overview of the lab network, services, and common tools.

```bash
chmod +x welcome.sh
./welcome.sh
# or add to ~/.bashrc for auto-run on login
```

### What it checks

- **Attacker IP and kernel** — quick system identification
- **Lab gateway (pfSense)** — is the network up?
- **Target host reachability** — pings DC01 and Wazuh to confirm they're alive
- **Service status** — PostgreSQL (Metasploit DB) and Responder
- **Installed tools** — scans for common offensive tools on PATH (msfconsole, nmap, responder, bloodhound, sqlmap, gobuster, nikto, crackmapexec)
- **Quick commands** — handy one-liners for common lab tasks

### Technical Logic Breakdown

The script uses several standard Linux utilities to parse system data:

* **`hostname -I | awk '{print $1}'`**: This retrieves the system's IP address. `awk` is used here as a pattern scanner to grab only the first network interface address, ensuring the dashboard remains clean even if multiple virtual bridges are present.
* **`pgrep -f "Responder.py"`**: Instead of just checking if a service is "enabled," `pgrep` looks for the actual running process by name. This provides a more accurate "Real-Time" status of offensive tools that may not run as standard system services.
* **`systemctl is-active --quiet`**: This query checks the status of the PostgreSQL database (the backend for Metasploit) without cluttering the terminal with raw output, allowing for a clean "ACTIVE/INACTIVE" UI toggle.
* **`ping -c 1 -W 1`**: A single-count ICMP request with a 1-second timeout. Used for gateway and target host checks to verify network connectivity.
* **`command -v`**: Checks whether a tool is available on PATH without executing it. Used to show which offensive tools are installed at a glance.
