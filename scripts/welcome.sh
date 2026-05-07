#!/usr/bin/env bash
# Red Team Lab Command Center — quick status dashboard for the attack host
set -euo pipefail

VERSION="1.2.0"

# Lab network constants
GATEWAY="10.10.69.1"
LAB_SUBNET="10.10.69.0/24"
WAZUH_MANAGER="10.10.69.20"

usage() {
    cat <<EOF
Red Team Lab Command Center v${VERSION}

Usage: $(basename "$0") [OPTIONS]

Options:
  -h, --help      Show this help message
  -v, --version   Show version
  -n, --no-clear  Skip clearing the screen (useful in scripts)

Runs a quick status dashboard showing network connectivity,
service status, and tool availability for the attack host.
EOF
    exit 0
}

NO_CLEAR=0
for arg in "$@"; do
    case "$arg" in
        -h|--help)    usage ;;
        -v|--version) echo "welcome.sh v${VERSION}"; exit 0 ;;
        -n|--no-clear) NO_CLEAR=1 ;;
        *) echo "Unknown option: $arg. Try --help."; exit 1 ;;
    esac
done

# Colors for UI
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
DIM='\033[2m'
NC='\033[0m'

[[ "$NO_CLEAR" -eq 0 ]] && clear
echo -e "${BLUE}====================================================${NC}"
echo -e "${GREEN}      DEBIAN RED TEAM LAB - COMMAND CENTER          ${NC}"
echo -e "${BLUE}====================================================${NC}"

# SYSTEM INFO
if MY_IP=$(hostname -I 2>/dev/null | awk '{print $1}') && [[ -n "$MY_IP" ]]; then
    echo -e "Attacker IP:    ${GREEN}$MY_IP${NC}"
else
    echo -e "Attacker IP:    ${RED}<no ip>${NC}"
fi
KERNEL=$(uname -r)
echo -e "Kernel:         ${CYAN}$KERNEL${NC}"

# Timestamp so it's clear when the dashboard was generated
echo -e "Checked at:     ${DIM}$(date '+%Y-%m-%d %H:%M:%S')${NC}"

# GATEWAY CHECK
if ping -c 1 -W 2 "$GATEWAY" >/dev/null 2>&1; then
    echo -e "Lab Gateway:    ${GREEN}ONLINE ($GATEWAY)${NC}"
else
    echo -e "Lab Gateway:    ${RED}OFFLINE (Check pfSense VM)${NC}"
fi

# WAZUH MANAGER CHECK
if nc -z -w 2 "$WAZUH_MANAGER" 1514 2>/dev/null; then
    echo -e "Wazuh Manager:  ${GREEN}REACHABLE ($WAZUH_MANAGER:1514)${NC}"
elif ping -c 1 -W 1 "$WAZUH_MANAGER" >/dev/null 2>&1; then
    echo -e "Wazuh Manager:  ${YELLOW}PING OK but port 1514 not responding ($WAZUH_MANAGER)${NC}"
else
    echo -e "Wazuh Manager:  ${RED}UNREACHABLE ($WAZUH_MANAGER)${NC}"
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

# VULNERABLE TARGETS
echo -e "\n${YELLOW}[ Vulnerable Targets ]${NC}"
for host in "Meta2:10.10.69.100" "Meta3-Ubuntu:10.10.69.101" "Meta3-Win2k8:10.10.69.102"; do
    label="${host%%:*}"
    addr="${host##*:}"
    if ping -c 1 -W 1 "$addr" >/dev/null 2>&1; then
        echo -e "  $label ($addr):  ${GREEN}REACHABLE${NC}"
    else
        echo -e "  $label ($addr):  ${DIM}OFFLINE${NC}"
    fi
done

# SERVICE MONITORING
echo -e "\n${YELLOW}[ Service Status ]${NC}"
if systemctl is-active --quiet postgresql 2>/dev/null; then
    echo -e "Metasploit DB:  ${GREEN}ACTIVE${NC}"
else
    echo -e "Metasploit DB:  ${RED}INACTIVE${NC}"
fi

if pgrep -fi "responder" > /dev/null 2>&1; then
    echo -e "Responder:      ${GREEN}RUNNING${NC}"
else
    echo -e "Responder:      ${RED}STOPPED${NC}"
fi

if systemctl is-active --quiet wazuh-agent 2>/dev/null; then
    echo -e "Wazuh Agent:    ${GREEN}ACTIVE${NC}"
else
    echo -e "Wazuh Agent:    ${RED}INACTIVE${NC}"
fi

# TOOL CHECK — show all tools with status
echo -e "\n${YELLOW}[ Tool Inventory ]${NC}"
for tool in msfconsole nmap responder bloodhound sqlmap gobuster nikto netexec impacket-wmiexec certipy-ad bloodhound-python; do
    if command -v "$tool" >/dev/null 2>&1; then
        echo -e "  $tool:  ${GREEN}available${NC}"
    else
        echo -e "  $tool:  ${DIM}not found${NC}"
    fi
done

# Quick commands — detect the default interface, fall back gracefully
if IFACE=$(ip route 2>/dev/null | awk '/default/ {print $5; exit}') && [[ -n "$IFACE" ]]; then
    : # good, IFACE is set
else
    IFACE="<interface>"
fi
echo -e "\n${YELLOW}[ Quick Commands ]${NC}"
echo -e "  msfconsole                ${GREEN}# Metasploit Framework${NC}"
echo -e "  responder -I $IFACE       ${GREEN}# LLMNR/NBT-NS poisoner${NC}"
echo -e "  nmap -sV $LAB_SUBNET      ${GREEN}# Service scan on lab subnet${NC}"
echo -e "  netexec smb $LAB_SUBNET   ${GREEN}# SMB enumeration${NC}"
echo -e "${BLUE}====================================================${NC}"
