#!/bin/bash
###############################################################################
#  ScanX – Bug-Bounty Edition  (Sequential • Colourful • Verbose)
#  Author : Custom Build   |   Tested : Kali 2025 (no jq / no subfinder)
###############################################################################

# ── Colours ──────────────────────────────────────────────────────────────────
RST='\e[0m'; RED='\e[31;1m'; GRN='\e[32;1m'; YLW='\e[33;1m'
BLU='\e[34;1m'; MAG='\e[35;1m'; CYN='\e[36;1m'; WHT='\e[97;1m'
sep(){ printf "${BLU}%s${RST}\n" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; }
hdr(){ sep; printf "${MAG}%-2s ${YLW}%s${RST}\n" "$1" "$2"; }

# ── Banner ───────────────────────────────────────────────────────────────────
clear
printf "███████╗ ██████╗ █████╗ ███╗   ██╗    ██╗  ██╗
██╔════╝██╔════╝██╔══██╗████╗  ██║    ╚██╗██╔╝
███████╗██║     ███████║██╔██╗ ██║     ╚███╔╝ 
╚════██║██║     ██╔══██║██║╚██╗██║     ██╔██╗ 
███████║╚██████╗██║  ██║██║ ╚████║    ██╔╝ ██╗
╚══════╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═══╝    ╚═╝  ╚═╝
\n"
printf "${CYN}┌-----------------------------------------------┐\n"
printf "│ 🔥 ${WHT}ScanX – Ultimate vulnerability Scanner${CYN}     │\n"
printf "│ 🕵  Author: STEVE  |  ⚙ Fast  |  🛡 Pro-Level │\n"
printf "└-----------------------------------------------┘${RST}\n\n"

# ── Input & Initialisation ───────────────────────────────────────────────────
read -rp "$(printf "${GRN}🎯 Target : ${RST}")" target
start=$(date +%s); today=$(date '+%Y-%m-%d'); now=$(date '+%H:%M:%S')
printf "📅 %s | 🕒 %s\n\n" "$today" "$now"

report=$(mktemp)              # live log
log(){ tee -a "$report"; }

# ── Quick dependency check (only busybox tools & APT defaults) --------------
need=(curl nmap nikto ffuf whatweb dig sslscan host awk sed grep)
miss=(); for c in "${need[@]}"; do command -v "$c" &>/dev/null || miss+=("$c"); done
if ((${#miss[@]})); then
  printf "${RED}[!] Missing tools: %s${RST}\n" "${miss[*]}"; exit 1; fi

######################## 1 ▸ HOST CHECK #######################################
hdr "🔍" "[1] Host Availability"
ping -c1 -W2 "$target" &>/dev/null \
  && printf "${GRN}[✔] Host alive${RST}\n" | log \
  || { printf "${RED}[✘] Host down – abort${RST}\n" | log; exit 1; }

######################## 2 ▸ SUB-DOMAIN ENUM (NO jq) ##########################
hdr "🌐" "[2] Sub-Domain Enumeration"
subs=$( { command -v subfinder &>/dev/null   && subfinder -silent -d "$target";
          command -v assetfinder &>/dev/null && assetfinder --subs-only "$target";
          command -v amass &>/dev/null       && amass enum -passive -nolocal -norecursive -d "$target" 2>/dev/null;
          curl -s "https://crt.sh/?q=%25.$target&output=csv" | cut -d, -f6; } |
        sed 's/^\*\.\?//' | sort -u | grep -E "\.$target$")
echo "$subs" | sed 's/^/[+] /' | log
printf "[i] %s sub-domains\n" "$(echo "$subs" | grep -c .)" | log
finish

######################## 3 ▸ NMAP FAST SCAN ###################################
hdr "🛰" "[3] Nmap Fast Scan"
nmap -T4 -F -sV "$target" | log
printf "${GRN}[✓] Nmap done${RST}\n" | log

######################## 4 ▸ NIKTO QUICK ######################################
hdr "🧪" "[4] Nikto Web Scan"
nikto -h "$target" -Tuning 2 | log
printf "${GRN}[✓] Nikto done${RST}\n" | log

######################## 5 ▸ DIR BRUTE (ffuf) #################################
hdr "📁" "[5] Directory Brute-Force"
ffuf -w /usr/share/wordlists/dirb/common.txt -u "http://$target/FUZZ" -t 40 -of cli \
 | grep -E '^\[.*\]' | log
printf "${GRN}[✓] Dir brute done${RST}\n" | log

######################## 6 ▸ SSL / TLS ########################################
hdr "🔐" "[6] SSL/TLS"
sslscan "$target" | head -n 40 | log
printf "${GRN}[✓] SSL scan done${RST}\n" | log

######################## 7 ▸ CMS / TECH #######################################
hdr "🧠" "[7] CMS / Tech Detect"
whatweb "$target" | log
printf "${GRN}[✓] CMS detect done${RST}\n" | log

######################## 8 ▸ SECURITY HEADERS #################################
hdr "🛡" "[8] Security Headers"
curl -s -D - "$target" -o /dev/null | awk '/^HTTP\/|^[A-Za-z-]+:/{print "[+] "$0}' | log
printf "${GRN}[✓] Header analysis done${RST}\n" | log

######################## 9 ▸ DANGEROUS METHODS ################################
hdr "⚔" "[9] HTTP Methods"
methods=$(curl -s -X OPTIONS -I "$target" | grep -i '^Allow:')
echo "[+] $methods" | log
echo "$methods" | grep -qiE 'PUT|DELETE|PATCH' \
 && printf "${RED}[!] Risky methods present${RST}\n" | log \
 || printf "${GRN}[✓] No risky methods${RST}\n" | log

######################## 10 ▸ CORS MISCONFIG ##################################
hdr "🔄" "[10] CORS Misconfig"
aco=$(curl -s -I -H "Origin: evil.com" "$target" | grep -i 'access-control-allow-origin')
[[ "$aco" == *"*"* || "$aco" == *"evil.com"* ]] \
 && printf "${RED}[!] %s${RST}\n" "$aco" | log \
 || printf "${GRN}[✓] CORS safe${RST}\n" | log

######################## 11 ▸ JS + ENDPOINTS ##################################
hdr "⚔" "[11] Quick Misconfig Checks"
cors=$(curl -s -I -H "Origin: evil.com" "$target" | grep -Fi 'access-control-allow-origin')
[[ "$cors" == *"*"* || "$cors" == *"evil.com"* ]] && echo -e "${RED}[!] CORS $cors${RST}" | log
redir=$(curl -s -I "$target/?next=https://evil.com" | grep -Fi '^Location:')
[[ "$redir" == *"evil.com"* ]] && echo -e "${RED}[!] Open redirect${RST}" | log
finish

######################## 12 ▸ OPEN REDIRECT ###################################
hdr "↪" "[12] Open Redirect"
loc=$(curl -s -I "$target/?next=https://evil.com" | grep -i '^Location:')
[[ "$loc" == *"evil.com"* ]] \
  && printf "${RED}[!] Open redirect via ?next= (%s)${RST}\n" "$loc" | log \
  || printf "${GRN}[✓] No redirect vuln${RST}\n" | log

######################## 13 ▸ 403 BYPASS ######################################
hdr "🔓" "[13] 403 Bypass"
code=$(curl -s -o /dev/null -w '%{http_code}' "$target/admin")
if [[ $code == 403 ]]; then
  bypass=$(curl -s -o /dev/null -w '%{http_code}' -H "X-Original-URL: /admin" "$target/")
  [[ $bypass != 403 ]] \
     && printf "${RED}[!] 403 bypass success (X-Original-URL)${RST}\n" | log \
     || printf "${GRN}[✓] Bypass failed (still 403)${RST}\n" | log
else printf "[i] /admin not 403 (%s) – skip\n" "$code" | log; fi

######################## 14 ▸ REFLECTED XSS ###################################
hdr "💬" "[14] Reflected XSS"
x='<svg/onload=alert(1)>'
curl -s "$target/?x=$x" | grep -q "$x" \
  && printf "${RED}[!] Reflected XSS at ?x= param${RST}\n" | log \
  || printf "${GRN}[✓] No reflection${RST}\n" | log

######################## 15 ▸ LFI #############################################
hdr "📂" "[15] Local File Inclusion"
curl -s "$target/?file=/etc/passwd" | grep -q "root:x:" \
  && printf "${RED}[!] LFI via ?file= param${RST}\n" | log \
  || printf "${GRN}[✓] No LFI${RST}\n" | log

######################## SAVE OR DISCARD ######################################
sep
read -rp "$(printf "${YLW}💾 Save report? [y/N] ${RST}")" ans
if [[ "$ans" =~ ^[Yy]$ ]]; then
  out="output/$target"; mkdir -p "$out"
  mv "$report" "$out/${target}_full_report.txt"
  printf "${GRN}[✓] Report saved to %s${RST}\n" "$out/${target}_full_report.txt"
else rm -f "$report"; printf "${RED}[✘] Report discarded${RST}\n"; fi

######################## WRAP-UP ##############################################
elapsed=$(( $(date +%s) - start ))
end_ts=$(date +%s); runtime=$((end_ts - start_ts))
sep; printf "${WHT}🏁 ScanX completed successfully in %02d:%02d seconds${RST}\n" $((elapsed/60)) $((elapsed%60)); sep


