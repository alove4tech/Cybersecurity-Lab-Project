```bash
#!/bin/bash
# Advanced Red Team Command Center Script

# Colors for UI
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

clear
echo -e "${BLUE}====================================================${NC}"
echo -e "${GREEN}      DEBIAN RED TEAM LAB - COMMAND CENTER          ${NC}"
echo -e "${BLUE}====================================================${NC}"

# NETWORK STATUS
MY_IP=$(hostname -I | awk '{print $1}')
echo -e "Attacker IP:    ${GREEN}$MY_IP${NC}"

# GATEWAY CHECK
if ping -c 1 10.10.69.1 &> /dev/null; then
    echo -e "Lab Gateway:    ${GREEN}ONLINE (10.10.69.1)${NC}"
else
    echo -e "Lab Gateway:    ${RED}OFFLINE (Check pfSense VM)${NC}"
fi

# SERVICE MONITORING
echo -e "\n${YELLOW}[ Service Status ]${NC}"
if systemctl is-active --quiet postgresql; then
    echo -e "Metasploit DB:  ${GREEN}ACTIVE${NC}"
else
    echo -e "Metasploit DB:  ${RED}INACTIVE${NC}"
fi

if pgrep -f "Responder.py" > /dev/null; then
    echo -e "Responder:      ${GREEN}RUNNING${NC}"
else
    echo -e "Responder:      ${RED}STOPPED${NC}"
fi
echo -e "${BLUE}====================================================${NC}"
