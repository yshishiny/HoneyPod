# HoneyPod Exercise Framework

**Complete threat-informed cyber range exercise suite with 9 MITRE ATT&CK-mapped scenarios**

---

## Overview

The HoneyPod Exercise Framework provides structured, hands-on attack and defense simulations designed to validate security controls, train incident response teams, and improve organizational security posture. All scenarios are mapped to the MITRE ATT&CK framework and leverage Caldera for automated red team execution.

### Design Principles

1. **Realism:** Exercises simulate actual adversary tactics observed in real-world attacks
2. **Progression:** Difficulty increases from basic to expert level
3. **Measurability:** Scoring frameworks and metrics for objective assessment
4. **Repeatability:** Automated reset procedures enable multiple runs
5. **Transparency:** All attack flows documented for post-exercise analysis

---

## Quick Start

### 1. Prepare Lab Environment

```bash
# Verify SIEM is receiving logs
bash ../automation/verify-siem-ingest.sh

# Verify network segmentation
bash ../automation/test-segmentation.sh

# Create pre-exercise snapshot for rapid reset
bash ../automation/snapshot-restore.sh create all
```

### 2. Select Exercise

```bash
# View all available scenarios
cat SCENARIOS-INDEX.md

# Review specific scenario
cat scenarios/scenario-001-brute-force-lateral-movement.yml
```

### 3. Execute Exercise

**Option A: Manual Execution**
- Red Team: Execute attack procedures manually via Caldera UI (192.168.10.20:8888)
- Blue Team: Monitor SIEM dashboards (192.168.50.20:5601)
- White Team: Score objectives using reference scenario

**Option B: Automated Execution** *(coming in Phase 7: Integration)*
```bash
# Run via Caldera API (requires Caldera playbook automation)
curl -X POST http://attack-caldera-01:8888/api/playbooks \
  -d '{"playbook_id": "scenario-001-playbook"}'
```

### 4. Post-Exercise Analysis

```bash
# Generate incident timeline
grep "SCORE\|ALERT\|ERROR" ../logs/*.log > incident_timeline.txt

# Create SIEM search query for attack chain
# See "Investigation Notes" section below

# Reset lab for next exercise
bash ../automation/test-reset-lab.sh
bash ../automation/snapshot-restore.sh restore all
```

---

## Scenario Library

### Scenario 001: Brute Force & Lateral Movement (45 min)
**Files:** `scenarios/scenario-001-brute-force-lateral-movement.yml`  
**Entry Point:** SSH brute force on database server  
**Chain:** BruteForce → SMB Lateral → LSASS Dump → C2

```
ATTACK FLOW:
  1. SSH brute force vs db-01 (T1110.001)
  2. SMB lateral to dc-01 (T1021.002)
  3. Credential extraction (T1003.002)
  4. Domain lateral movement (T1021.002)
  5. Caldera C2 check-in (T1071.001)

DETECTION TARGETS:
  - 5+ failed SSH attempts in 60 seconds
  - SMB connections from unexpected hosts to IPC$
  - LSASS.exe access events
  - Unusual inter-zone network traffic

SCORING:
  Red Team: 70 points max
  Blue Team: 80 points max
```

---

### Scenario 002: Phishing Campaign (45 min)
**Files:** `scenarios/scenario-002-phishing.yml`  
**Entry Point:** Spearphishing email with malicious link  
**Chain:** Phishing → Execution → Persistence → Exfil

```
ATTACK FLOW:
  1. Phishing campaign delivery (T1566.002)
  2. User clicks link, downloads file (T1204.001)
  3. Installation of persistence (T1547.001)
  4. PowerShell C2 beaconing (T1059.001)
  5. Credential exfiltration (T1041)

DETECTION TARGETS:
  - Email gateway detections
  - Suspicious PowerShell execution
  - Registry run key modifications
  - C2 DNS/HTTP patterns

SCORING:
  Red Team: 60 points max
  Blue Team: 80 points max
```

---

### Scenario 003-009

*See `scenarios/scenario-00X-*.yml` files for complete details on:*
- **003:** WMI Lateral Movement
- **004:** Credential Dumping
- **005:** Persistence Mechanisms  
- **006:** Web Application Exploitation
- **007:** Data Exfiltration & C2
- **008:** Defense Evasion
- **009:** Advanced APT Simulation

---

## Investigation Guide

### Common SIEM Queries

#### Detect Brute Force (Scenario 001)
```kibana
event_type:auth AND status:failed AND source_ip:192.168.1.0/24 
  | stats count by source_ip, user | where count > 5
```

#### Detect Lateral Movement (Scenario 003)
```kibana
event.code:4688 AND (process_name:wmic.exe OR process_name:powershell.exe)
  AND parent_process:winlogon.exe
```

#### Detect Persistence (Scenario 005)
```kibana
event.code:4657 AND registry_path:*Run* AND action:created
```

#### Detect C2 Communication (Scenario 007)
```kibana
destination_port:(80 OR 443 OR 8888) AND bytes_out > 10MB
  AND not destination_domain in (googleapis.com, cloudflare.com)
```

#### Detect LSASS Dump (Scenario 004)
```kibana
event.code:10 AND target_process:lsass.exe 
  AND source_process in (procdump.exe, dumpcap.exe)
```

---

## Execution Templates

### Red Team Playbook Template

```yaml
---
name: "[Scenario X] Offensive Operations"
participant_roles:
  - "Attacker 1: Initial Access"
  - "Attacker 2: Lateral Movement"
  - "Attacker 3: Data Theft"

phase_1_initial_access:
  duration: "10 minutes"
  objectives:
    - "Execute initial access technique"
    - "Establish first foothold"
    - "Begin persistence"
  tools: [Caldera, msfconsole, custom scripts]
  success_criteria: "Reverse shell callback received"

phase_2_lateral_movement:
  duration: "20 minutes"
  objectives:
    - "Move to additional systems"
    - "Escalate privileges"
    - "Extract credentials"
  tools: [Caldera agents, Empire, Mimikatz]
  success_criteria: "Domain admin compromise"

phase_3_mission_complete:
  duration: "15 minutes"
  objectives:
    - "Establish persistence"
    - "Exfiltrate sensitive data"
    - "Cover tracks"
  tools: [C2 framework, data compression, encryption]
  success_criteria: "Data successfully exfiltrated"
```

### Blue Team Response Template

```yaml
---
name: "[Scenario X] Incident Response"
participant_roles:
  - "SOC Analyst: Monitoring & Alerting"
  - "IR Lead: Containment Decisions"
  - "Forensics: Investigation & Evidence"

detect_phase:
  procedures:
    - "Monitor SIEM dashboards for alerts"
    - "Correlate events across systems"
    - "Validate true positive vs false positive"
    - "Escalate to Incident Commander"
  success_criteria: "CTD < scenario target"

contain_phase:
  procedures:
    - "Isolate compromised systems"
    - "Disable compromised accounts"
    - "Block attacker IPs/domains"
    - "Preserve evidence"
  success_criteria: "Stop lateral movement"

eradicate_phase:
  procedures:
    - "Remove persistence mechanisms"
    - "Patch vulnerabilities"
    - "Restore from clean backups"
    - "Validate remediation"
  success_criteria: "All compromises removed"

recover_phase:
  procedures:
    - "Restore systems to production"
    - "Monitor for re-compromise"
    - "Update security controls"
    - "Brief management on outcome"
  success_criteria: "Normal operations resumed"
```

---

## Scoring & Metrics

### Red Team Scoring

**Objective Points:** 
- Initial Access: 10-15 pts
- Lateral Movement: 15-20 pts
- Persistence: 10-15 pts
- Privilege Escalation: 10-15 pts
- Data Exfiltration: 15-25 pts
- Anti-Forensics: 5-10 pts

**Bonus Points:**
- Evade detection (+10 pts)
- Interact with honeypot (+5 pts)  
- Faster TTK (+5 pts)
- Novel technique (+10 pts)

### Blue Team Scoring

**Detection Points:**
- Early Detection (before lateral movement): 20-25 pts
- Lateral Movement Detection: 15-20 pts
- Credential Access Detection: 15-20 pts
- Exfiltration Detection: 15-20 pts

**Response Points:**
- Timely Containment: 10-15 pts
- Complete Remediation: 10 pts
- Zero False Positives: Bonus 10 pts
- Incident Documentation: 5-10 pts

### Overall Scoring Matrix
```
Red Team Score + Blue Team Score = Exercise Score
Red Team Wins   if: Attack Impact > Defense Capability
Blue Team Wins  if: Attack Contained & Threat Eliminated
```

---

## Performance Benchmarks

### Time to Detect (TTD) Benchmarks

| Scenario | Technique | Target TTD | Good | Excellent |
|---|---|---|---|---|
| 001 | SSH Brute Force | 5 min | <5 min | <2 min |
| 002 | Malware Execution | 10 min | <10 min | <5 min |
| 003 | WMI Lateral | 20 min | <20 min | <15 min |
| 004 | LSASS Dump | 5 min | <5 min | <2 min |
| 005 | Registry Persistence | 15 min | <15 min | <10 min |
| 006 | Web App Exploit | 10 min | <10 min | <5 min |
| 007 | C2 Exfiltration | 25 min | <25 min | <15 min |
| 008 | Defense Evasion | 30 min | <30 min | <20 min |
| 009 | APT Full Chain | 30 min | <30 min | <25 min |

---

## Before Exercise Checklist

- [ ] Snapshot created (auto-restore capability)
- [ ] SIEM verified collecting logs (verify-siem-ingest.sh)
- [ ] Network segmentation confirmed (test-segmentation.sh)
- [ ] Caldera C2 accessible at 192.168.10.20:8888
- [ ] All lab systems running and domain-joined
- [ ] Filebeat/Auditbeat/Winlogbeat agents active
- [ ] Kibana dashboards loaded
- [ ] Red team weaponization complete
- [ ] Blue team SOC procedures documented
- [ ] White team scoring criteria reviewed

---

## After Exercise Actions

### Immediately Post-Exercise
1. Capture final evidence (SIEM exports, system logs)
2. Document timeline of all events
3. Record red team objectives achieved
4. Record blue team detections and actions
5. Photograph final scoreboards

### Within 24 Hours
1. Conduct hot wash (immediate debrief with all participants)
2. Generate incident timeline
3. Analyze detection gaps
4. Document lessons learned
5. Update security procedures

### Within 5 Days
1. Create formal after-action report
2. Update defensive recommendations
3. Assign remediation tasks
4. Schedule follow-ups

### Quarterly Review
1. Track TTD improvements
2. Analyze trend data
3. Plan next exercise cycle
4. Update scenarios based on feedback

---

## Troubleshooting

### Scenario Doesn't Start

```bash
# Check Caldera connectivity
curl -u admin:admin http://attack-caldera-01:8888/api/v2/about

# Verify target systems are running
ping -c 1 dc-01  # 192.168.10.10
ping -c 1 ep-01  # 192.168.30.20

# Check agent registration
curl -u admin:admin http://attack-caldera-01:8888/api/v2/agents
```

### SIEM Not Receiving Logs

```bash
# Verify Filebeat running on endpoints
systemctl status filebeat

# Check Elasticsearch connectivity
curl -u elastic:changeme http://192.168.50.20:9200/_cat/health

# View Logstash logs
docker logs honeypod-logstash | tail -50
```

### Network Segmentation Blocking Exercise

```bash
# Temporarily relax NSG for testing
# NOTE: Re-enable after exercise!
az network nsg rule update --name "AllowTestAccess" \
  --nsg-name prod-nsg --resource-group honeypod
```

---

## Advanced Usage

### Scenario Customization

To adapt scenarios to your environment, edit the scenario YAML file:

```yaml
# Change target systems
red_team:
  target_group: "custom_endpoints"  # vs. windows_endpoints

# Adjust difficulty/timing
procedures:
  1:
    timing: "5 min"  # Slower execution
    evasion_techniques: 3  # More evasion

# Customize scoring
scoring:
  red_team:
    objective_success: 30  # Higher points
```

### Creating Custom Scenarios

Use the Exercise Framework Template:
1. Copy `scenarios/scenario-template.yml`
2. Define MITRE ATT&CK techniques
3. Create attack flow (4-6 procedures)
4. Define detection opportunities
5. Set scoring criteria
6. Test with red team

### Running in Automated CI/CD

```bash
#!/bin/bash
# automated-exercise-runner.sh

SCENARIO=$1
LOG_DIR="results/$(date +%Y%m%d_%H%M%S)"

mkdir -p $LOG_DIR

# Setup
bash ../automation/snapshot-restore.sh create all

# Run
python3 caldera_executor.py scenarios/$SCENARIO.yml > $LOG_DIR/run.log

# Collect data
curl -s -u admin:admin http://attack-caldera-01:8888/api/v2/reports > $LOG_DIR/caldera.json

# Score
python3 score_exercise.py scenarios/$SCENARIO.yml $LOG_DIR

# Reset
bash ../automation/test-reset-lab.sh
```

---

## Documentation References

- [SCENARIOS-INDEX.md](./SCENARIOS-INDEX.md) - Complete scenario reference
- [../docs/THREAT-MODEL.md](../docs/THREAT-MODEL.md) - Threat catalog
- [../docs/ARCHITECTURE.md](../docs/ARCHITECTURE.md) - Lab architecture
- [../README.md](../README.md) - Project overview

---

## Contact & Support

**Exercise Framework Maintainer:** [Security Team]  
**Questions/Issues:** [Contact Security Operations]  
**Feedback/Improvements:** [Submit to Security Council]

---

**Last Updated:** 2026-03-18  
**Framework Version:** 1.0  
**Status:** Production Ready ✓
