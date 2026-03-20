# HoneyPod Exercise Scenarios Index

**Version:** 1.0  
**Last Updated:** 2026-03-18  
**Directory:** `exercises/scenarios/`

---

## Scenario Overview

The HoneyPod exercise framework includes 9 carefully designed scenarios mapped to the MITRE ATT&CK framework, progressing from basic to expert difficulty levels.

---

## Scenario Summary Table

| ID | Scenario Name | Primary Techniques | Difficulty | Duration | Focus Area |
|:---:|---|---|:---:|:---:|---|
| 001 | Brute Force & Lateral Movement | T1110, T1021.001/002, T1003 | Medium | 45 min | Initial Compromise |
| 002 | Phishing Campaign | T1566, T1204, T1547 | Medium | 45 min | Social Engineering |
| 003 | WMI Lateral Movement | T1047, T1021.006, T1036 | Hard | 60 min | Lateral Movement |
| 004 | Credential Dumping | T1003.001/002, T1555, T1550.002 | Hard | 50 min | Credential Access |
| 005 | Persistence Mechanisms | T1547, T1053.005, T1546.003 | Medium | 40 min | Persistence |
| 006 | Web Application Attack | T1190, T1005, T1020 | Medium | 50 min | Initial Exploit |
| 007 | Data Exfiltration | T1041, T1071.001, T1048.003 | Hard | 55 min | Data Theft |
| 008 | Defense Evasion | T1027, T1562, T1070.001 | Hard | 60 min | Anti-Forensics |
| 009 | Advanced APT Simulation | T1566→T1021→T1003→T1041 (chain) | Expert | 90 min | Complete Attack |

---

## Scenario Details

### Scenario 001: Brute Force Attack & Lateral Movement
**File:** `scenario-001-brute-force-lateral-movement.yml` *(updated with complete structure)*

- **Primary Techniques:** SSH Brute Force (T1110.001), SMB Lateral Movement (T1021.002), Credential Harvesting (T1003)
- **Difficulty:** Medium
- **Duration:** 45 minutes
- **Learning Objectives:**
  - Detect SSH brute force attacks with rate-based alerting
  - Identify SMB lateral movement patterns
  - Correlate events across multiple systems
  - Respond to initial compromise
- **Red Team Goals:**
  - Successful SSH compromise of database server
  - Lateral movement to domain systems
  - Credential extraction and reuse
  - Establish C2 communication
- **Blue Team Goals:**
  - Detect brute force within 5 minutes
  - Identify lateral movement before domain controller compromise
  - Implement containment procedures
  - Prevent C2 establishment

---

### Scenario 002: Phishing Campaign & Credential Harvesting
**File:** `scenario-002-phishing.yml`

- **Primary Techniques:** Spearphishing Link (T1566.002), User Execution (T1204.001), Persistence (T1547.001), PowerShell Execution (T1059.001)
- **Difficulty:** Medium
- **Duration:** 45 minutes  
- **Learning Objectives:**
  - Detect phishing emails and malicious links
  - Identify suspicious file execution patterns
  - Monitor registry modifications for persistence
  - Alert on scheduled task creation
- **Red Team Goals:**
  - Deliver convincing phishing email
  - Trick user into clicking link/downloading file
  - Establish persistence via registry run key
  - Exfiltrate credentials to C2
- **Blue Team Goals:**
  - Detect ≥25% of phishing attempts
  - Identify initial access within 5 minutes
  - Detect persistence mechanisms (≥75%)
  - Respond before credential access

---

### Scenario 003: Lateral Movement via WMI
**File:** `scenario-003-wmi-lateral-movement.yml`

- **Primary Techniques:** WMI (T1047), WinRM (T1021.006), Network Reconnaissance (T1018), Masquerading (T1036)
- **Difficulty:** Hard
- **Duration:** 60 minutes
- **Learning Objectives:**
  - Detect WMI usage for command execution
  - Identify network enumeration activities
  - Monitor SMB/RDP unusual access patterns
  - Correlate suspicious behaviors across systems
- **Red Team Goals:**
  - Enumerate network topology
  - Execute commands via WMI
  - Establish PowerShell remoting sessions
  - Evade endpoint detection
- **Blue Team Goals:**
  - Detect WMI exploitation (≥50%)
  - Identify reconnaissance phase (≥75%)
  - Alert on cross-boundary lateral movement
  - Implement network segmentation blocks

---

### Scenario 004: Credential Dumping & Pass-the-Hash
**File:** `scenario-004-credential-dumping.yml`

- **Primary Techniques:** LSASS Memory Dump (T1003.001), SAM Database (T1003.002), Browser Credentials (T1555.003), Pass-the-Hash (T1550.002)
- **Difficulty:** Hard
- **Duration:** 50 minutes
- **Learning Objectives:**
  - Detect memory dump attempts (procdump, mimikatz)
  - Monitor LSASS process access
  - Identify credential harvesting tools
  - Alert on pass-the-hash authentication
- **Red Team Goals:**
  - Dump LSASS memory successfully
  - Extract SAM database hashes
  - Harvest browser stored credentials
  - Authenticate using stolen credentials
- **Blue Team Goals:**
  - Detect LSASS access (≥80%)
  - Identify credential dump tools (≥90%)
  - Prevent pass-the-hash usage (≥85%)
  - Implement Credential Guard

---

### Scenario 005: Persistence Mechanisms
**File:** `scenario-005-persistence.yml`

- **Primary Techniques:** Registry Run Keys (T1547.001), Scheduled Tasks (T1053.005), WMI Events (T1546.003), Active Setup (T1547.014)
- **Difficulty:** Medium
- **Duration:** 40 minutes
- **Learning Objectives:**
  - Monitor registry modifications for persistence
  - Detect scheduled task creation/modification
  - Identify WMI event subscriptions
  - Verify persistence across reboots
- **Red Team Goals:**
  - Create registry run key
  - Schedule malware execution
  - Establish WMI event-driven persistence
  - Survive system reboot
- **Blue Team Goals:**
  - Detect registry persistence (≥90%)
  - Identify scheduled tasks (≥85%)
  - Find WMI subscriptions (≥75%)
  - Successfully remove all persistence mechanisms

---

### Scenario 006: Web Application Exploitation
**File:** `scenario-006-web-app.yml`

- **Primary Techniques:** Public-Facing App Exploit (T1190), Local Data Access (T1005), Auto-Exfiltration (T1020)
- **Difficulty:** Medium
- **Duration:** 50 minutes
- **Learning Objectives:**
  - Detect SQL injection attacks
  - Identify webshell upload/execution
  - Monitor database access anomalies
  - Respond to application-layer attacks
- **Red Team Goals:**
  - Identify SQL injection vulnerability
  - Bypass authentication
  - Achieve RCE via webshell
  - Extract database contents
- **Blue Team Goals:**
  - Detect SQL injection (≥80%)
  - Identify webshell (≥90%)
  - Alert on database exfiltration
  - Disable application and patch

---

### Scenario 007: Data Exfiltration & C2
**File:** `scenario-007-exfiltration.yml`

- **Primary Techniques:** C2 Exfiltration (T1041), Web Protocols (T1071.001), DNS Tunneling (T1048.003)
- **Difficulty:** Hard
- **Duration:** 55 minutes
- **Learning Objectives:**
  - Detect C2 communication patterns
  - Identify data exfiltration attempts
  - Monitor for DNS tunneling
  - Implement C2 blocking
- **Red Team Goals:**
  - Discover sensitive data
  - Stage and compress data
  - Establish C2 channel
  - Exfiltrate data successfully
- **Blue Team Goals:**
  - Detect C2 signatures (≥75%)
  - Identify exfiltration (≥80%)
  - Find DNS tunnels (≥75%)
  - Block C2 channels

---

### Scenario 008: Defense Evasion & Anti-Forensics
**File:** `scenario-008-defense-evasion.yml`

- **Primary Techniques:** Obfuscation (T1027), Impair Defenses (T1562.001), Clear Event Logs (T1070.001), Masquerading (T1036.003)
- **Difficulty:** Hard
- **Duration:** 60 minutes
- **Learning Objectives:**
  - Detect disabling of security controls
  - Identify log tampering attempts
  - Monitor process injection attacks
  - Implement immutable logging
- **Red Team Goals:**
  - Obfuscate malware to evade AV
  - Disable Windows Defender/Firewall
  - Clear Windows Event Logs
  - Inject into legitimate processes
- **Blue Team Goals:**
  - Detect log tampering (≥90%)
  - Identify defense evasion (≥85%)
  - Catch process injection (≥80%)
  - Restore and verify integrity

---

### Scenario 009: Advanced Persistent Threat (APT) Simulation
**File:** `scenario-009-apt-simulation.yml`

- **Primary Techniques:** Complete multi-stage attack chain: T1566 → T1547 → T1548 → T1021 → T1003 → T1041
- **Difficulty:** Expert
- **Duration:** 90 minutes
- **Learning Objectives:**
  - Execute coordinated multi-stage attack
  - Detect attack chain across phases
  - Correlate events across systems
  - Implement comprehensive incident response
- **Red Team Goals (Multi-Phase):**
  1. Initial Access (Phishing) - T10
  2. Persistence & Escalation - T25  
  3. Lateral Movement - T40
  4. Credential Harvesting - T45
  5. Data Exfiltration - T90
- **Blue Team Goals:**
  - Detect initial access within 10 min (15 pts)
  - Detect privilege escalation within 25 min (20 pts)
  - Detect lateral movement within 45 min (20 pts)
  - Contain and remediate (20 pts)
  - Prevent data loss (15 pts)

---

## Execution Model

### Pre-Exercise Setup

1. **Capture Baseline Snapshot**
   ```bash
   bash automation/snapshot-restore.sh create all
   ```

2. **Verify SIEM Connectivity**
   ```bash
   bash automation/verify-siem-ingest.sh
   ```

3. **Test Network Segmentation**
   ```bash
   bash automation/test-segmentation.sh
   ```

### Exercise Execution

1. **Red Team:** Execute Caldera playbook corresponding to scenario
2. **Blue Team:** Monitor dashboards and respond to alerts
3. **White Team:** Record timeline and score objectives

### Post-Exercise Reset

```bash
bash automation/test-reset-lab.sh
bash automation/snapshot-restore.sh restore all
```

---

## Difficulty Progression

### Recommended Learning Path

**Day 1 - Fundamentals** (3 scenarios)
1. Scenario 001 - Brute Force (easy detection)
2. Scenario 002 - Phishing (email gateway focus)
3. Scenario 005 - Persistence (local analysis)

**Day 2 - Advanced** (3 scenarios)
4. Scenario 003 - WMI Lateral Movement (requires correlation)
5. Scenario 004 - Credential Dumping (LSASS monitoring)
6. Scenario 006 - Web App (application security)

**Day 3 - Expert** (3 scenarios)
7. Scenario 007 - Exfiltration (network evasion)
8. Scenario 008 - Defense Evasion (anti-forensics)
9. Scenario 009 - APT Simulation (comprehensive integration)

---

## Scoring Framework

### Red Team
- **Objective Achievement Points:** 10-60 points per scenario
- **Bonus Points:** 
  - Evade detection: +10 pts (Scenarios 008-009)
  - Interact with honeypots: +5-10 pts
  - Faster execution: Bonus for TTK <target

---

## Success Metrics

### Detection Metrics
- **Time to Detect (TTD):** Measured from attack start to alert generation
- **Detection Rate:** Percentage of attacks detected
- **False Positive Rate:** Should be ≤5%

### Response Metrics
- **Time to Respond (TTR):** From detection to containment action
- **Incident Recovery Time:** Time to restore systems to clean state
- **Data Integrity:** Amount of data protected from exfiltration

---

## Customization Guidelines

### Scenario Modification

To adapt scenarios to your environment:

1. **Update IP Addresses:** Modify target_group references
2. **Adjust Timing:** Change procedure timings based on lab performance
3. **Add Honeypot Integration:** Include honeypot engagement as detection opportunity
4. **Customize Scoring:** Adjust point values for organizational priorities

### Creating New Scenarios

Use this template structure:
```yaml
name: "Scenario X: [Attack Description]"
version: "1.0"
difficulty: "[Easy|Medium|Hard|Expert]"
duration_minutes: 45-90

mitre_att_ck:
  - technique: "TXXX.YYY"
    name: "[Technique Name]"
    
red_team:
  procedures:
    1:
      name: "[Phase 1]"
      technique: "TXXX.YYY"
      steps: [...]
      
blue_team:
  success_criteria: [...]
  detection_opportunities: [...]
```

---

## References

- **MITRE ATT&CK:** https://attack.mitre.org
- **Cyber Kill Chain:** https://www.lockheedmartin.com/capabilities/cyber/cyber-kill-chain.html
- **D3FEND:** https://d3fend.mitre.org
- **NIST SP 800-115:** Technical Security Testing and Analysis

---

## Document History

| Version | Date | Changes |
|:---:|---|---|
| 1.0 | 2026-03-18 | Initial release with 9 scenarios |

---

**Next Steps:** Review all 9 scenario files, execute the recommended learning path, and customize as needed for your organization's threat model.
