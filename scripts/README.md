### 🧠 Technical Logic Breakdown
To ensure the reliability of the command center, the script utilizes several standard Linux utilities to parse system data:

* **`hostname -I | awk '{print $1}'`**: This retrieves the system's IP address. `awk` is used here as a pattern scanner to grab only the first network interface address, ensuring the dashboard remains clean even if multiple virtual bridges are present.
* **`pgrep -f "Responder.py"`**: Instead of just checking if a service is "enabled," `pgrep` looks for the actual running process by name. This provides a more accurate "Real-Time" status of offensive tools that may not run as standard system services.
* **`systemctl is-active --quiet`**: This query checks the status of the PostgreSQL database (the backend for Metasploit) without cluttering the terminal with raw output, allowing for a clean "ACTIVE/INACTIVE" UI toggle.
* **`ping -c 1`**: A single-count ICMP request is sent to the pfSense gateway. This acts as a heartbeat check to verify that the virtual network bridge and firewall are correctly routing internal traffic.
