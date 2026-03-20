# HoneyPod File Index & Navigation Guide

Everything you need is in this directory. Use this index to find what you're looking for.

---

## 📚 Documentation (Start Here)

### Quick Reference
| File | Purpose | Read Time | When |
|------|---------|-----------|------|
| [README.md](README.md) | Project overview, success criteria | 5 min | First time |
| [QUICKSTART.md](QUICKSTART.md) | 60-minute rapid deployment | 10 min | Before deployment |
| [PROJECT-SUMMARY.md](PROJECT-SUMMARY.md) | Complete project summary, metrics | 15 min | Understand full scope |

### Deep Dive
| File | Purpose | Read Time | When |
|------|---------|-----------|------|
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | 5-plane design, zones, topology, data flows | 30 min | Understand design |
| [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md) | Step-by-step deployment, operations, troubleshooting | 45 min | Before/during deployment |
| [docs/THREAT-MODEL.md](docs/THREAT-MODEL.md) | ATT&CK techniques ↔ D3FEND defenses ↔ exercises | 30 min | Before first exercise |
| [DEPLOYMENT-CHECKLIST.md](DEPLOYMENT-CHECKLIST.md) | Verification steps, printable checklist | 5 min (per phase) | During deployment |

---

## 🏗️ Infrastructure-as-Code (Terraform)

Create and manage all cloud resources.

```
terraform/
├── main.tf                 # Azure provider, resource groups, VNets
├── networks.tf             # 5 VNets, 7 subnets, NSG rules
├── variables.tf            # Configurable parameters
├── terraform.tfvars.example # Template (copy & edit before use)
├── terraform.tfstate       # Generated after first apply
└── modules/                # Reusable components (future)
    ├── vm-windows/
    ├── vm-linux/
    └── network/
```

**Quick Commands:**
```bash
cd terraform/
cp terraform.tfvars.example terraform.tfvars  # Edit credentials here
terraform init
terraform plan
terraform apply
terraform output > outputs.json  # For Ansible
```

**Learn More:** [docs/DEPLOYMENT.md - Phase 1](docs/DEPLOYMENT.md#phase-1-infrastructure-deployment-2-4-hours)

---

## ⚙️ Configuration Management (Ansible)

Harden systems, configure services, deploy agents.

```
ansible/
├── site.yml                # Master playbook (entry point)
├── requirements.yml        # Galaxy roles
├── inventory/
│   ├── hosts              # Generated from Terraform (run generate-inventory.py)
│   └── group_vars/        # Group-level variables
├── roles/
│   ├── hardening/         # OS hardening, audit policies
│   ├── siem-agent/        # Beats, rsyslog, Osquery
│   ├── active-directory/  # AD domain, users, groups, GPO
│   ├── windows-base/      # Windows endpoint config
│   ├── linux-base/        # Linux server config
│   └── canary-deployment/ # OpenCanary + Cowrie install
├── playbooks/
│   ├── verify-siem-ingest.yml
│   ├── verify-ad.yml
│   ├── update-threat-intel.yml
│   └── test-segmentation.yml
└── scripts/
    └── generate-inventory.py  # Creates hosts file from Terraform
```

**Quick Commands:**
```bash
cd ansible/
# Generate inventory from Terraform outputs
python3 scripts/generate-inventory.py ../terraform/outputs.json > inventory/hosts

# Test connectivity
ansible all -m ping

# Deploy hardening
ansible-playbook site.yml --tags hardening

# Deploy SIEM agents
ansible-playbook site.yml --tags siem-agent
```

**Learn More:** [docs/DEPLOYMENT.md - Phase 2](docs/DEPLOYMENT.md#phase-2-configuration-management-1-2-hours)

---

## 🛡️ Security Tooling & SIEM (ELK)

Centralized logging, detection, dashboards.

```
security-tooling/
├── docker-compose.yml      # 5-service stack (ES, Logstash, Kibana, Suricata, Redis)
├── elk/
│   ├── elasticsearch.yml   # ES config (security, indexing)
│   ├── logstash.conf       # Log parsing pipeline (Sysmon, Windows Events, DNS, etc.)
│   ├── patterns/
│   │   └── sysmon.grok     # Custom Grok patterns for Sysmon
│   ├── dashboards/         # Kibana dashboard templates
│   └── docker-compose.yml  # ELK stack compose file
├── siem-rules/
│   ├── attack-detection-rules.md  # 15+ Elasticsearch DSL rules
│   ├── d3fend-mappings.json       # ATT&CK → D3FEND mappings
│   └── elasticsearch-alerts.json   # Alert definitions
├── suricata/
│   ├── suricata.yaml       # IDS configuration
│   ├── rules/              # Threat signatures (ET, Proofpoint)
│   └── docker-compose.yml  # Suricata container setup
└── detections/             # Detection rule library (organized by technique)
```

**Quick Commands:**
```bash
cd security-tooling/

# Start ELK stack
docker-compose up -d

# View logs
docker-compose logs -f

# Access Kibana
# http://localhost:5601

# Load detection rules
curl -X POST "localhost:9200/_bulk?pretty" -H 'Content-Type: application/json' \
  -d @siem-rules/attack-detection-rules.json
```

**Learn More:** [docs/DEPLOYMENT.md - Phase 3](docs/DEPLOYMENT.md#phase-3-security-tooling-deployment-1-2-hours)

---

## 🍯 Deception Layer (Honeypots)

Isolated honeypots with automated alerting.

```
deception-layer/
├── opencanary/
│   ├── opencanary.conf           # Configuration (9 services: FTP, SSH, SMB, HTTP, etc.)
│   ├── canary-tokens/            # Decoy files, fake credentials
│   └── alert-rules.conf           # Alert definitions
├── cowrie/
│   ├── cowrie.cfg                # SSH/Telnet honeypot config
│   ├── etc/
│   │   ├── userdb.txt            # Fake users/passwords
│   │   ├── hostname.txt          # Fake hostname
│   │   └── issue.net             # Banner
│   └── var/
│       └── log/cowrie.json       # Session logs (JSON)
└── deploy.sh                      # Deployment automation (production-ready)
```

**Quick Commands:**
```bash
cd deception-layer/

# Test deployment (dry-run)
bash deploy.sh --test

# Deploy honeypots (production)
bash deploy.sh --prod

# Verify services
bash verify.sh

# Check logs
tail -f /var/log/canary.log
```

**Learn More:** [docs/DEPLOYMENT.md - Phase 4](docs/DEPLOYMENT.md#phase-4-deception-layer-deployment-30-45-minutes)

---

## 🎯 Exercise Library & Scenarios

ATT&CK-mapped exercise scenarios.

```
exercises/
├── scenarios/
│   ├── scenario-001-brute-force-lateral-movement.yml
│   ├── scenario-002-phishing.yml
│   ├── scenario-003-wmi-persistence.yml
│   ├── scenario-004-credential-dumping.yml
│   ├── scenario-005-account-discovery.yml
│   ├── scenario-006-network-sniffing.yml
│   └── scenario-templates.md           # Template for new exercises
├── results/
│   ├── EXEC-001-2026-03-15-results.json
│   ├── EXEC-001-2026-02-15-results.json
│   └── trending-report.md              # Month-over-month improvements
├── validation/
│   ├── red-team-checklist.md
│   ├── blue-team-checklist.md
│   └── white-team-scoring.md
└── README.md                           # Exercise framework explanation
```

**Example Exercise Structure:**
```yaml
scenario:
  name: "Credential Compromise & Lateral Movement"
  scenario_id: "EXEC-001-T1110-T1021"
  attack_flow:
    - phase_1: T1110 Brute Force
    - phase_2: T1547 Persistence
    - phase_3: T1021 Lateral Movement
    - phase_4: T1020 Exfiltration
  success_criteria:
    red_team: "Execute all 4 phases"
    blue_team: "Detect 80%+ of techniques, TTD < 2 min"
  duration_minutes: 45
```

**Learn More:** [docs/THREAT-MODEL.md](docs/THREAT-MODEL.md) & [exercises/scenarios/scenario-001-brute-force-lateral-movement.yml](exercises/scenarios/scenario-001-brute-force-lateral-movement.yml)

---

## 🔧 Automation & Operations

Scripts for exercises, snapshots, verification.

```
automation/
├── snapshot-restore.sh              # Create/restore VM snapshots (<5 min rollback)
├── pre-exercise-snapshot.sh         # Pre-exercise checklist
├── post-exercise-restore.sh         # Full lab reset
├── post-exercise-forensics.sh       # Export logs, analyze
├── test-segmentation.sh             # Verify network isolation
├── export-logs.sh                   # Extract SIEM logs by time window
├── verify-reset.sh                  # Confirm clean state
├── emergency-shutdown.sh            # Safety switch (if needed)
└── README.md                        # Script documentation
```

**Quick Commands:**
```bash
cd automation/

# Pre-exercise: Create snapshots
bash snapshot-restore.sh create --all

# Run exercise (45 min)

# Post-exercise: Restore all systems
bash snapshot-restore.sh restore --all

# Verify clean state
bash verify-reset.sh
```

**Learn More:** [docs/DEPLOYMENT.md - Exercise Playbook](docs/DEPLOYMENT.md#exercise-execution-playbook)

---

## 📋 Execution & Operations

### Before First Deployment

1. **Read:** [QUICKSTART.md](QUICKSTART.md) (10 min)
2. **Review:** [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) (30 min)
3. **Prepare:** Credentials, budget, team roles

### Deployment Day

1. **Phase 1:** [Terraform](terraform/) (2-4 hours)
2. **Phase 2:** [Ansible](ansible/) (1-2 hours)
3. **Phase 3:** [SIEM](security-tooling/) (1-2 hours)
4. **Phase 4:** [Deception](deception-layer/) (30-45 min)
5. **Phase 5:** [Caldera](exercises/) (30 min)

**Use:** [DEPLOYMENT-CHECKLIST.md](DEPLOYMENT-CHECKLIST.md) for sign-offs

### Exercise Week

1. **Pre-Exercise:** [automation/snapshot-restore.sh create](automation/snapshot-restore.sh)
2. **Execute:** [exercises/scenarios/](exercises/scenarios/) (45 min)
3. **Post-Exercise:** [automation/snapshot-restore.sh restore](automation/snapshot-restore.sh)
4. **Debrief:** Review [docs/THREAT-MODEL.md](docs/THREAT-MODEL.md) for scoring

---

## 🎓 Learning Path

### Day 1: Understanding
- [ ] Read [README.md](README.md)
- [ ] Skim [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
- [ ] Watch your infrastructure (if pre-deployed)

### Day 2: Deployment
- [ ] Follow [QUICKSTART.md](QUICKSTART.md)
- [ ] Deploy phases 1-2 (infrastructure + config)
- [ ] Verify with checklists

### Day 3: Tooling
- [ ] Deploy phase 3 (SIEM) and 4 (deception)
- [ ] Explore Kibana dashboard
- [ ] Test honeypot services

### Day 4: Exercises
- [ ] Review [docs/THREAT-MODEL.md](docs/THREAT-MODEL.md)
- [ ] Read [scenario-001](exercises/scenarios/scenario-001-brute-force-lateral-movement.yml)
- [ ] Run first exercise (EXEC-001)
- [ ] Analyze results

### Week 2+: Operations
- [ ] Run monthly exercises
- [ ] Build new scenarios
- [ ] Improve detection rules based on results

---

## 🔍 File Quick Reference

### By Purpose

**"How do I...?"**

| Question | File |
|----------|------|
| Understand the architecture? | [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) |
| Deploy the lab? | [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md) |
| Map ATT&CK to D3FEND? | [docs/THREAT-MODEL.md](docs/THREAT-MODEL.md) |
| Refresh my memory quickly? | [QUICKSTART.md](QUICKSTART.md) |
| Run an exercise? | [exercises/scenarios/](exercises/scenarios/) |
| Create VMs? | [terraform/](terraform/) |
| Configure systems? | [ansible/](ansible/) |
| Use SIEM dashboards? | [security-tooling/elk/](security-tooling/elk/) |
| Set up honeypots? | [deception-layer/deploy.sh](deception-layer/deploy.sh) |
| Snapshot/restore? | [automation/snapshot-restore.sh](automation/snapshot-restore.sh) |
| Troubleshoot issues? | [docs/DEPLOYMENT.md#troubleshooting](docs/DEPLOYMENT.md#troubleshooting) |

### By Role

**Red Team (Attacker)**
- [exercises/scenarios/](exercises/scenarios/) - Emulation playbooks
- [docs/THREAT-MODEL.md](docs/THREAT-MODEL.md) - Techniques to emulate
- Caldera GUI (deployed) - Attack C2

**Blue Team (Defender)**
- [security-tooling/siem-rules/](security-tooling/siem-rules/) - Detection rules
- [docs/THREAT-MODEL.md](docs/THREAT-MODEL.md) - Defensive objectives
- Kibana dashboard (deployed) - SIEM GUI
- [exercises/scenarios/](exercises/scenarios/) - Response procedures

**White Team (Judge)**
- [docs/THREAT-MODEL.md](docs/THREAT-MODEL.md) - Scoring criteria
- [DEPLOYMENT-CHECKLIST.md](DEPLOYMENT-CHECKLIST.md) - Verification
- [exercises/scenarios/](exercises/scenarios/) - Success criteria

**Green Team (Operations)**
- [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md) - Full operational guide
- [automation/](automation/) - Scripts
- [terraform/](terraform/) + [ansible/](ansible/) - Infrastructure

---

## 💾 File Statistics

| Category | Files | Lines | Size |
|----------|-------|-------|------|
| Documentation | 7 | 3,500 | 200 KB |
| Terraform | 4 | 800 | 50 KB |
| Ansible | 5+ | 1,000 | 75 KB |
| SIEM/Detection | 4 | 600 | 80 KB |
| Deception | 3 | 300 | 45 KB |
| Exercises | 10+ | 500 | 60 KB |
| Automation | 8 | 1,000 | 75 KB |
| **Total** | **40+** | **~7,500** | **~600 KB** |

---

## 🚀 Getting Started (TL;DR)

1. **Read 5 min:** [README.md](README.md)
2. **Read 10 min:** [QUICKSTART.md](QUICKSTART.md)
3. **Deploy 2 hours:** Follow [QUICKSTART.md](QUICKSTART.md) steps
4. **Run exercise 1 hour:** Follow [exercises/scenarios/scenario-001](exercises/scenarios/scenario-001-brute-force-lateral-movement.yml)
5. **Done!** You have a working cyber range.

---

## 📞 Support

- **Questions?** See [docs/DEPLOYMENT.md - Troubleshooting](docs/DEPLOYMENT.md#troubleshooting)
- **New Scenario?** Copy [exercises/scenarios/scenario-templates.md](exercises/scenarios/scenario-templates.md)
- **Issue?** Check [DEPLOYMENT-CHECKLIST.md](DEPLOYMENT-CHECKLIST.md) go/no-go criteria

---

**HoneyPod: Threat-Informed Cyber Range**  
*Navigate this project using this index. Everything is documented.*  
*Last Updated: March 2026*
