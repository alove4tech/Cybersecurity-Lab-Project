#!/usr/bin/env bash
# Advanced Red Team Command Center Script
set -euo pipefail

# Colors for UI
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

clear
echo -e "${BLUE}====================================================${NC}"
echo -e "${GREEN}      DEBIAN RED TEAM LAB - COMMAND CENTER          ${NC}"
echo -e "${BLUE}====================================================${NC}"

# SYSTEM INFO
MY_IP=$(hostname -I | awk '{print $1}')
KERNEL=$(uname -r)
echo -e "Attacker IP:    ${GREEN}$MY_IP${NC}"
echo -e "Kernel:         ${CYAN}$KERNEL${NC}"

# GATEWAY CHECK
if ping -c 1 -W 2 10.10.69.1 >/dev/null 2>&1; then
    echo -e "Lab Gateway:    ${GREEN}ONLINE (10.10.69.1)${NC}"
else
    echo -e "Lab Gateway:    ${RED}OFFLINE (Check pfSense VM)${NC}"
fi

# TARGET REACHABILITY
echo -e "\n${YELLOW}[ Target Hosts ]${NC}"
for host in "DC01:10.10.69.10" "Wazuh:10.10.69.20"; do
    label="${host%%:*}"
    addr="${host##*:}"
    if ping -c 1 -W 1 "$addr" >/dev/null 2>&1; then
        echo -e "  $label ($addr):  ${GREEN}REACHABLE${NC}"
    else
        echo -e "  $label ($addr):  ${RED}UNREACHABLE${NC}"
    fi
done

# SERVICE MONITORING
echo -e "\n${YELLOW}[ Service Status ]${NC}"
if systemctl is-active --quiet postgresql; then
    echo -e "Metasploit DB:  ${GREEN}ACTIVE${NC}"
else
    echo -e "Metasploit DB:  ${RED}INACTIVE${NC}"
fi

if pgrep -f "Responder.py" > /dev/null 2>&1; then
    echo -e "Responder:      ${GREEN}RUNNING${NC}"
else
    echo -e "Responder:      ${RED}STOPPED${NC}"
fi

# TOOL CHECK
echo -e "\n${YELLOW}[ Installed Tools ]${NC}"
for tool in msfconsole nmap responder bloodhound sqlmap gobuster nikto crackmapexec; do
    if command -v "$tool" >/dev/null 2>&1; then
        echo -e "  $tool:  ${GREEN}available${NC}"
    fi
done

echo -e "\n${YELLOW}[ Quick Commands ]${NC}"
echo -e "  msfconsole              ${GREEN}# Metasploit Framework${NC}"
echo -e "  responder -I eth0       ${GREEN}# LLMNR/NBT-NS poisoner${NC}"
echo -e "  nmap -sV 10.10.69.0/24  ${GREEN}# Service scan on lab subnet${NC}"
echo -e "  crackmapexec smb 10.10.69.0/24 ${GREEN}# SMB enumeration${NC}"
echo -e "${BLUE}====================================================${NC}"
