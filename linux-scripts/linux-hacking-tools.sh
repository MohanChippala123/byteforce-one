#!/usr/bin/env bash

set -x
set -uo pipefail

# Regex containing top 50 auditing & security tool package names
TOOLS_REGEX='^(aircrack-ng|airgeddon|amass|arp-scan|bettercap|bloodhound|burpsuite|cewl|crackmapexec|crunch|dirb|dirbuster|dnsrecon|dsniff|ettercap-text-only|ffuf|fierce|gobuster|hashcat|hping3|hydra|impacket-scripts|john|kismet|maltego|masscan|medusa|metasploit-framework|mimikatz|ncrack|netexec|netsniff-ng|nikto|nmap|ophcrack|pixiewps|powersploit|reaver|recon-ng|responder|sqlmap|tcpdump|theharvester|tshark|unicornscan|wfuzz|wifite|wireshark|wpscan|zaproxy)$'

echo "[+] Checking installed packages on Ubuntu..."

dpkg-query -W -f='${Status} ${Package}\n' 2>/dev/null | \
  awk '/install ok installed/ {print $4}' | \
  grep -E -i "$TOOLS_REGEX"