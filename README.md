# ScanX
**🛡ScanX** is a Ultimate vulnerability scanner & penetration testing automation tool written in Bash. It performs a sequential, modular security scan against a given target using only native or widely available Linux tools. Ideal for reconnaissance, vulnerability enumeration, and quick web assessments.

## 🚀 Features
🔍 Host availability check

🌐 Sub-domain enumeration

🛰 Fast Nmap scanning

🧪 Nikto vulnerability scan

📁 Directory brute-forcing with ffuf

🔐 SSL/TLS scan using sslscan

🧠 CMS/Tech detection using whatweb

🛡 Security headers check

⚔ HTTP methods risk analysis

🔄 CORS misconfiguration detection

⚔ Quick checks for CORS & Open Redirect

↪ Open Redirect vulnerability check

🔓 403 Bypass test (X-Original-URL)

💬 Reflected XSS detection

📂 Local File Inclusion (LFI) test

## 🛠 Requirements
ScanX is designed to work without heavy dependencies. It checks and uses only lightweight, essential tools that are usually available in Kali Linux by default or via APT.

## To install all dependencies:
```bash
  sudo apt update && sudo apt install -y curl nmap nikto ffuf whatweb dig sslscan host
```
## 📦 Installation

Clone it
```bash
  git clone https://github.com/yourusername/ScanX.git
```
Go to the directory
```bash
  cd ScanX
```
To make it executable
```bash
chmod +x scanX.sh
```
To run the tool
```bash
./scanX.sh
```
