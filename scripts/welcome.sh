#!/usr/bin/env bash
# Red Team Lab Command Center — quick status dashboard for the attack host
set -euo pipefail

VERSION="1.3.0"

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

# --- Helper: test if a TCP port is open on a remote host ---
# Tries nc first, then bash /dev/tcp, then falls back to ping-only.
# Usage: check_tcp_port <host> <port> <label>
# Prints a status line and returns 0 if port is open.
check_tcp_port() {
    local host="$1" port="$2" label="$3"
    local port_ok=false

    if command -v nc >/dev/null 2>&1; then
        nc -z -w 2 "$host" "$port" 2>/dev/null && port_ok=true
    elif command -v timeout >/dev/null 2>&1; then
        timeout 2 bash -c "echo >/dev/tcp/$host/$port" 2>/dev/null && port_ok=true
    fi

    if $port_ok; then
        echo -e "$label:  ${GREEN}REACHABLE ($host:$port)${NC}"
        return 0
    elif ping -c 1 -W 1 "$host" >/dev/null 2>&1; then
        echo -e "$label:  ${YELLOW}PING OK but port $port not responding ($host)${NC}"
        return 1
    else
        echo -e "$label:  ${RED}UNREACHABLE ($host)${NC}"
        return 1
    fi
}

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

# WAZUH CHECKS
check_tcp_port "$WAZUH_MANAGER" 1514 "Wazuh Manager"
check_tcp_port "$WAZUH_MANAGER" 55000 "Wazuh Dashboard"

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

if pgrep -f "[Rr]esponder" > /dev/null 2>&1; then
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
tool_total=0
tool_found=0
for tool in msfconsole nmap responder bloodhound sqlmap gobuster nikto netexec impacket-wmiexec certipy-ad bloodhound-python crackmapexec xfreerdp; do
    tool_total=$((tool_total + 1))
    if command -v "$tool" >/dev/null 2>&1; then
        tool_found=$((tool_found + 1))
        echo -e "  $tool:  ${GREEN}available${NC}"
    else
        echo -e "  $tool:  ${DIM}not found${NC}"
    fi
done
echo -e "  ${DIM}($tool_found/$tool_total available)${NC}"

# --- Detection Coverage Summary ---
echo -e "\n${YELLOW}[ Detection Coverage ]${NC}"
echo -e "  UC-001 SSH Brute Force         ${GREEN}validated${NC}   T1110"
echo -e "  UC-002 Kerberos RC4             ${GREEN}validated${NC}   T1558.003"
echo -e "  UC-003 Lateral Movement         ${GREEN}validated${NC}   T1021/T1595"
echo -e "  UC-004 Password Spraying        ${GREEN}validated${NC}   T1110.003"
echo -e "  UC-005 Kerberos Anomaly         ${GREEN}validated${NC}   T1558.003"
echo -e "  UC-006 Privileged Logon         ${GREEN}validated${NC}   T1078"
echo -e "  UC-007 Suspicious Process       ${GREEN}validated${NC}   T1059.001/T1003"

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
