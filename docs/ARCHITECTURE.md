# HoneyPod: 5-Plane Architecture Design

## Overview

The cyber range is built as five isolated but interconnected operational planes, allowing simultaneous support for:

- **Vulnerability Assessment** (VA) and validation
- **Penetration Testing & Purple Team** exercises
- **Red Team Emulation** (ATT&CK-mapped attacks)
- **Blue Team Detection & Response** (D3FEND-mapped defenses)
- **White Team Control & Adjudication** (exercise oversight)

## Plane 1: Management Plane

**Purpose:** Central control, orchestration, and state management for the entire range.

### Components

- **Hypervisor/Orchestration**
  - Hyper-V cluster (Azure Stack HCI) or KVM + libvirt
  - Manages compute, storage, and networking
  - Separate storage for production-range snapshots vs. deception assets

- **Infrastructure-as-Code**
  - Terraform for VM, network, and security group provisioning
  - Version-controlled in Git with full history

- **Secrets Management**
  - HashiCorp Vault or Azure Key Vault
  - Isolation: lab keys never accessible from production networks

- **Image Repository**
  - Golden images: Windows 10/11, Windows Server 2019/2022, Ubuntu 20.04/22.04
  - Patched to realistic levels (not latest, not ancient)
  - Stored with checksums for integrity verification

- **Snapshot Management**
  - Automated pre-exercise snapshots
  - Rollback scripts (<5 min restore)
  - Post-exercise cleanup automation

- **Backup & Disaster Recovery**
  - Off-hypervisor backups of SIEM, Caldera, Vault
  - Encrypted, separate network path

### Network

- Lab management network (192.168.100.0/24)
- Out-of-band access via bastion or dedicated NIC
- No route to production
- Time-synced NTP server (lab.honeypod.local)

---

## Plane 2: Production-Like Range Plane

**Purpose:** Realistic Windows/Linux/AD/app infrastructure that mirrors production behavior without real data.

### Topology: 3 Isolated Zones

#### Zone 2A: User/Endpoint Zone (192.168.10.0/24)

**VMs:**
- `EP-WIN10-01` to `EP-WIN10-05` (Windows 10, domain-joined)
- `EP-LINUX-01` (Ubuntu 22.04, workstation profile)
- `EP-MAC-01` (optional, macOS 12+)

**Configuration:**
- All domain-joined to `corp.local`
- Realistic users: `alice.smith`, `bob.jones`, `carol.white` (no admin)
- Service accounts: `svc_backup`, `svc_monitoring`, `svc_intranet`
- Installed software: Office, Adobe, browser, dev tools (mirrors real usage)
- Sysmon + Windows Defender (working, not bypassed)
- Auditpol configured per NCSC guidance

**Data (Sanitized):**
- Sample documents (PII redacted or synthetic)
- Fake emails in Thunderbird/Evolution
- Decoy files with canary tokens (via OpenCanary)

---

#### Zone 2B: Server Zone (192.168.20.0/24)

**VMs:**
```
SRV-AD-01          Windows Server 2022, 2 DC, Global Catalog
SRV-FS-01          Windows Server 2022, file server (shares, DFS)
SRV-EX-01          Windows Server 2022, Exchange simulation (mail server)
SRV-APP-01         Windows Server 2022, IIS + custom app
SRV-LINUX-DB-01    Ubuntu 22.04, PostgreSQL 14
SRV-LINUX-APP-01   Ubuntu 22.04, Node.js API server
```

**Active Directory Structure:**
```
corp.local
├── Users
│   ├── IT
│   │   ├── alice.smith (Domain Admin)
│   │   └── bob.jones (IT Service)
│   ├── Finance
│   │   └── carol.white (Analyst)
│   └── Engineering
│       └── david.kumar (Developer)
├── Computers
│   ├── ENDPOINTS
│   └── SERVERS
├── Groups
│   ├── G-DOMAIN-ADMINS
│   ├── G-FILE-ADMINS
│   ├── G-IT-STAFF
│   └── G-FINANCE
└── Organizational Units
    ├── Computers/Endpoints
    ├── Computers/Servers
    ├── Users/IT
    ├── Users/Finance
    └── Users/Engineering
```

**Domain Policies (GPO):**
- Windows Update: staggered (not auto-install)
- Password policy: 12-char min, 90-day exp, history=10
- Account lockout: 5 attempts, 15-min lockout
- Audit-all event categories enabled
- Local admin: unique passwords per machine (stored in Vault)

**Services:**
- File Server Resource Manager (FSRM)
- Distributed File System (DFS)
- Certificate Services (lab PKI)
- DNS (Active Directory integrated)

---

#### Zone 2C: DMZ (192.168.30.0/24)

**VMs:**
```
DMZ-PROXY-01       Ubuntu 22.04, Nginx reverse proxy
DMZ-APP-01         Ubuntu 22.04, Flask web app (sanitized production clone)
DMZ-VPN-SIM-01     Ubuntu 22.04, OpenVPN (simulated remote access)
DMZ-JUMPHOST-01    Windows Server 2022, RDP jump box
```

**Network Policy:**
- One-way inbound from internet simulator (WAN zone)
- Limited outbound to server zone (specific ports)
- No direct access between DMZ and user zone

**Applications:**
- Public-facing web app on :443 (self-signed lab PKI cert)
- VPN endpoint for red team "external" access
- Jump host for IT admin lateral movement

---

### Inter-Zone Network Segmentation

| From \ To | User Zone | Server Zone | DMZ | Deception |
|-----------|-----------|------------|-----|-----------|
| **User Zone** | n/a | TCP 445, 389, 636, 53 | DENIED | DENIED |
| **Server Zone** | TCP 445, 5985 | n/a | TCP 80, 443, DNS | DENIED |
| **DMZ** | DENIED | TCP 3306, 5432, 8080 | n/a | DENIED |
| **Deception** | DENIED | DENIED | DENIED | n/a |
| **SIEM** | UDP/TCP 514, 6514 | UDP/TCP 514, 6514 | UDP/TCP 514, 6514 | UDP/TCP 514 |

---

## Plane 3: Deception Layer (192.168.40.0/24)

**CRITICAL: Zero trust path back to production or management planes.**

### Purpose

Engage adversaries without compromising detective capability. MITRE Engage-driven:

- Expose fake services and credentials
- Misdirect attackers to canary traps
- Capture shell interactions and lateral movement attempts
- Provide intel on adversary TTPs

### Components

#### OpenCanary Deployment

**VMs:**
```
DECEPTION-CANARY-01    Ubuntu 22.04, OpenCanary
DECEPTION-CANARY-02    Ubuntu 22.04, OpenCanary (redundancy)
```

**Canary Services:**
- FTP (port 21) - fake credentials, anonymous access
- SMB (port 445) - decoy file share "backups"
- SSH (port 22) - honeypot user account
- Telnet (port 23) - legacy "system" account
- HTTP (port 80, 8080) - fake admin panel
- HTTPS (port 443, 8443) - fake VPN login
- MySQL (port 3306) - fake database with canary queries
- Postgres (port 5432) - fake analytics database
- RDP (port 3389) - decoy Windows terminal server

**Configuration:**
```ini
[GLOBALCONFIG]
listen_addr=0.0.0.0
syslog_server=siem.lab.honeypod.local
syslog_port=514

[FTP]
enabled=True
banner=Welcome to corp-backup-01 FTP Server v1

[SMB]
enabled=True
path=/mnt/fake-backups

[SSH]
enabled=True
version=OpenSSH_7.4 (compromised version for authenticity)

[HTTP]
enabled=True
banner=Microsoft-IIS/10.0
```

**Alert Rules:**
- Any login attempt → syslog + SIEM
- File access → syslog + SIEM
- Port scan detected → syslog + SIEM
- Command execution → syslog + SIEM (detailed)

---

#### Cowrie SSH/Telnet Honeypot

**VMs:**
```
DECEPTION-COWRIE-01    Ubuntu 22.04, Cowrie
```

**Purpose:** High-interaction SSH/Telnet deception, captures attacker shell behavior.

**Configuration:**
- Fake root user, fake /etc/passwd
- Limited, controllable commands (cd, ls, cat, wget, nc)
- Recorded interactions saved for post-exercise analysis
- Packet captures enabled for traffic analysis

**Observable Behavior:**
- Fake Debian packages, kernel version
- Simulated running services (apache, mysql, openssh)
- Honeypot filesystem with decoy data

---

#### Decoy Credentials & Tokens

**Placement:**
- Shared drives with canary tokens (Office files, PDFs)
- User desktop shortcuts pointing to honeypot services
- Decoy .bash_history files on Linux servers
- In-memory decoy registry values on Windows

**Engagement:**
- Tracking access via OpenCanary alerts
- SIEM correlation of decoy use → immediate alert
- Feeds threat intel on adversary persistence behavior

---

## Plane 4: Security Tooling Plane (192.168.50.0/24)

**Purpose:** Centralized telemetry collection, analysis, detection, and response orchestration.

### SIEM Stack (ELK: Elasticsearch, Logstash, Kibana)

**VMs:**
```
SIEM-ES-01         Ubuntu 22.04, Elasticsearch (primary)
SIEM-ES-02         Ubuntu 22.04, Elasticsearch (replica)
SIEM-KB-01         Ubuntu 22.04, Kibana (dashboards, searches)
SIEM-LS-01         Ubuntu 22.04, Logstash (log processing pipeline)
```

**Log Sources (Inbound):**
- Windows Event Log (Sysmon, Security, System, Application)
- Linux syslog, audit logs
- Network IDS/NSM (Suricata, Zeek)
- DNS query logs
- Proxy/firewall logs
- Application logs (web app, AD, Exchange)
- File integrity monitoring (osquery)
- OpenCanary & Cowrie alerts

**Logstash Pipelines:**
- Sysmon event enrichment (process hash lookup, parent-child correlation)
- AD logon normalization (success/failure correlation)
- DNS tunneling detection
- Command-line anomaly scoring
- Network lateral movement detection

---

### Endpoint Detection & Response (EDR)

**Options:**
- **Lightweight:** Osquery + custom rules (open-source, lab-appropriate)
- **Commercial:** Crowdstrike, Microsoft Defender for Endpoint (if available)

**Configuration:**
- Process execution monitoring → SIEM
- File modification alerts → SIEM
- Network connection logs → SIEM
- Registry modifications → SIEM
- DLL injection detection → SIEM

---

### Intrusion Detection System (IDS) / Network Security Monitoring (NSM)

**VM:**
```
SIEM-IDS-01        Ubuntu 22.04, Suricata or Zeek
```

**Purpose:**
- Traffic analysis for malicious signatures (ET/Proofpoint ruleset)
- Protocol analysis (SMB, HTTP, DNS)
- Lateral movement detection (unusual protocols, unusual ports)
- Data exfiltration patterns

**Output:** Logs to SIEM, real-time alerts to SOAR

---

### Log Broker & PCAP Storage

**VM:**
```
SIEM-PCAP-01       Ubuntu 22.04, full packet capture (tcpdump + retention mgmt)
```

**Purpose:**
- Persistent PCAP for post-incident analysis
- Retention: 30 days (configurable)
- Indexed by flow (srcIP, dstIP, port) for rapid extraction

---

### Detection Rules (SIEM)

Organized by ATT&CK technique:

**Example: T1566 (Phishing)**
```json
{
  "name": "Email Forwarding Rule Created",
  "technique": "T1566",
  "source": "AD Event 4707",
  "condition": "eas:mailbox_forwarding_rule_created AND sender!=admin",
  "alert_level": "MEDIUM",
  "response_action": "notify", "investigate", "block_rule"
}
```

**Example: T1021.006 (RDP Over Lateral Movement)**
```json
{
  "name": "Suspicious RDP Connection from Non-Admin",
  "technique": "T1021.006",
  "source": "Sysmon Event 3 + Windows Security Event 4624",
  "condition": "connection_port=3389 AND source_user NOT IN (G-IT-STAFF) AND time_of_day=03:00-05:00",
  "alert_level": "HIGH",
  "response_action": "isolate_session", "block_traffic", "ticket_create"
}
```

---

### SOAR / Case Management

**Options:**
- Open-source: Shuffle or Cortex XSOAR
- Purpose: Automate response playbooks, case tracking, evidence collection

---

## Plane 5: Attack Simulation Plane (192.168.60.0/24)

**Purpose:** Safe, repeatable emulation of adversary behavior based on ATT&CK, validated against D3FEND countermeasures.

### Caldera Server

**VM:**
```
ATTACK-CALDERA-01   Ubuntu 22.04, Caldera multi-agent C2
```

**Purpose:**
- Automated adversary emulation
- Agent-based tastings on endpoints, servers, deception layer
- Plugin ecosystem (MITRE ATT&CK, Atomic Red Team integrations)
- Exercise orchestration and replaying

**Capabilities:**
- Define adversary profiles (red team personas)
- Schedule attacks on a timetable or manually
- Real-time visualization of TTPs
- Collect results (success/failure, detection method)
- Compare tool A vs. B on same scenario

---

### Atomic Red Team

**Deployment:**
- Distributed as Ansible playbook on target systems
- Executes individual ATT&CK tests (ping, reverse shell, credential dumping, etc.)
- Available standalone or integrated with Caldera

**Coverage:**
- Endpoint: process injection, persistence, privilege escalation
- Lateral movement: SMBexec, PsExec, Kerberoasting, Golden Ticket
- Exfiltration: DNS tunneling, HTTP POST, SMB shares

---

### Exercise Control

**Red Team:**
- Caldera C2 control, agent scheduling
- Atomic Red Team execution against specified targets
- Real-time TTPs visible in dashboards (but not in SIEM visibility plan for purple team exercises)

**Blue Team:**
- SIEM dashboard access (constrained to their zone)
- EDR console (constrained to endpoint telemetry)
- Incident response playbooks
- Isolation and remediation tools

**White Team:**
- Full observability across all planes
- Caldera master controls (pause, resume, replay)
- SIEM full access (all logs)
- Exercise timing and success criteria
- Scoring and adjudication

---

## Network Segmentation Map

### Firewall Rules (Microsegmentation)

```
# User Zone ← → Deception Zone: DENY all
# Server Zone ← → Deception Zone: DENY all

# User Zone → Server Zone:
iptables -A FORWARD -s 192.168.10.0/24 -d 192.168.20.0/24 \
  -p tcp -m multiport --dports 445,389,636,53 -j ACCEPT
iptables -A FORWARD -s 192.168.10.0/24 -d 192.168.20.0/24 -j DROP

# Server Zone → DMZ (limited):
iptables -A FORWARD -s 192.168.20.0/24 -d 192.168.30.0/24 \
  -p tcp -m multiport --dports 3306,5432,8080 -j ACCEPT
iptables -A FORWARD -s 192.168.20.0/24 -d 192.168.30.0/24 -j DROP

# DMZ → Server Zone (inbound only):
iptables -A FORWARD -d 192.168.20.0/24 -s 192.168.30.0/24 \
  -p tcp -m multiport --sports 80,443 -j ACCEPT
iptables -A FORWARD -d 192.168.20.0/24 -s 192.168.30.0/24 -j DROP

# All zones → SIEM (logging):
iptables -A FORWARD -d 192.168.50.0/24 -p udp --dport 514 -j ACCEPT
iptables -A FORWARD -d 192.168.50.0/24 -p tcp --dport 514 -j ACCEPT
iptables -A FORWARD -d 192.168.50.0/24 -p tcp --dport 5000,6514 -j ACCEPT

# Lab Internal → Management: one-way from mgmt to others (no reverse):
iptables -A FORWARD -d 192.168.100.0/24 -j DROP
```

---

## Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│ Red Team (Caldera C2)                                       │
├─────────────────────────────────────────────────────────────┤
│ Compromise                            Compromise            │
│ Endpoint Zone  ←→  Server Zone        Deception Zone       │
│ (T1566, T1021)     (T1110, T1484)     (TTPs logged only)   │
└─────────────────────────────────────────────────────────────┘
                      ↓ Telemetry
┌─────────────────────────────────────────────────────────────┐
│ Security Tooling Plane (SIEM, EDR, IDS)                     │
│ └→ Elasticsearch (logs) → Logstash (processing)            │
│ └→ Kibana (dashboards) ← Detection Rules (D3FEND mapped)   │
└─────────────────────────────────────────────────────────────┘
                      ↓ AlertsResponse
┌─────────────────────────────────────────────────────────────┐
│ SOAR / Blue Team Response                                   │
│ └→ Auto-block IPs, isolate sessions, freeze snapshots      │
└─────────────────────────────────────────────────────────────┘
                      ↓ Adjudication
┌─────────────────────────────────────────────────────────────┐
│ White Team Scoreboard                                       │
│ └→ Which ATT&CK techniques succeeded/failed?               │
│ └→ Which D3FEND countermeasures worked?                    │
│ └→ MITRE Engage deception cost-benefit?                    │
└─────────────────────────────────────────────────────────────┘
```

---

## Operational Procedures

### Pre-Exercise

1. **Snapshot all production-range VMs** to management plane backup storage
2. **Reset Caldera state** (clear prior agents, C2 session logs)
3. **Verify SIEM ingest** from all sources (test log injection)
4. **Verify deception layer** is isolated (ping sweep confirms)
5. **Brief white team** on exercise scenario and success criteria

### During Exercise

- Red team executes Caldera playbook or manual ATT&CK techniques
- Blue team actively monitors SIEM, responds to alerts, executes playbooks
- White team observes; does not intervene
- All telemetry flows to SIEM and SOAR

### Post-Exercise

1. **Forensics & Analysis** (by white team)
   - Extract relevant SIEM logs
   - Correlate detections with actual techniques
   - Review missed detections (false negatives)

2. **Debrief** (red + blue + white)
   - Techniques emulated and their success/failure
   - Detections that worked, missed, or false-alarmed
   - Remediation time (MTTR)
   - Lessons for next exercise

3. **Rollback**
   - Restore all production-range snapshots
   - Wipe Caldera state and agent logs
   - Clear Deception plane logs (optional: archive first)
   - Verify full reset (<5 min)

---

## Success Metrics

After each exercise, measure:

- **Detection Rate:** Percentage of red team TTPs detected
- **Time to Detect (TTD):** Average time from TTP execution to detection
- **Time to Respond (TTR):** Average time from alert to containment
- **False Positive Rate:** Alerts triggered by legitimate activity
- **Coverage:** Which ATT&CK techniques / D3FEND countermeasures represented?
- **Capability Gain:** Were new detections or playbooks validated?

---

## References

- NIST SP 800-115: Technical Security Testing and Assessment
- NCSC: Logging and Monitoring Best Practice
- MITRE ATT&CK Framework: https://attack.mitre.org
- MITRE D3FEND: https://d3fend.mitre.org
- MITRE Engage: https://engage.mitre.org
- Microsoft Sysinternals Sysmon: Enhanced Windows Event Logging
- Atomic Red Team: https://github.com/redcanaryco/atomic-red-team
- MITRE Caldera: https://caldera.mitre.org
