# Quick Start: HoneyPod Cyber Range

## 30-Second Overview

**HoneyPod** is a production-grade cyber range for safe, repeatable security testing.

- **5 Planes:** Management, Production-like Range, Deception, Security Tooling, Attack Simulation
- **3 Zones:** User endpoints, Servers (AD, DB, app), DMZ
- **Deception Layer:** OpenCanary + Cowrie honeypots (isolated, monitored)
- **SIEM:** ELK Stack for log aggregation, detection rules, dashboards
- **Emulation:** Caldera C2 + Atomic Red Team for ATT&CK-mapped attacks
- **Governance:** Snapshot/restore in <5 min, full lab reset, zero production risk

---

## Fastest Start (60 minutes)

### 1. Prerequisites (assume installed)

```bash
terraform --version  # >= 1.0
ansible --version    # >= 2.9
docker --version     # with Compose
git --version
```

### 2. Deploy Infrastructure (30 min)

```bash
cd HoneyPod/

# Create terraform.tfvars
cp terraform/terraform.tfvars.example terraform/terraform.tfvars

# Edit with your Azure/Hyper-V credentials
nano terraform/terraform.tfvars

# Deploy networks, VMs, NSGs
cd terraform/
terraform init
terraform apply -auto-approve
cd ..

# Wait for VMs to boot (~10 min)
```

### 3. Deploy Configuration (20 min)

```bash
cd ansible/

# Generate inventory from Terraform outputs
python3 scripts/generate-inventory.py ../terraform/outputs.json > inventory/hosts

# Quick hardening + SIEM agents
ansible-playbook site.yml -i inventory/hosts --tags hardening,siem-agent
```

### 4. Deploy Tooling (10 min)

```bash
cd ../security-tooling/

# Start ELK Stack (SIEM)
docker-compose up -d

# Verify Kibana: http://localhost:5601
sleep 30
curl http://localhost:5601/api/status
```

**Done!** You have a basic lab running. Now run an exercise.

---

## First Exercise (45 minutes)

### Pre-Exercise (10 min)

```bash
cd HoneyPod/

# Snapshot all systems before exercise
bash automation/snapshot-restore.sh create --all

# Verify SIEM is receiving logs
ansible-playbook playbooks/verify-siem-ingest.yml -i ansible/inventory/hosts

# Reset Caldera state
curl -X POST http://attack-caldera-01.lab.honeypod.local:8888/api/v2/admin/reset
```

### Execute Exercise (30 min)

```bash
# Choose a scenario (e.g., EXEC-001)
cat exercises/scenarios/scenario-001-brute-force-lateral-movement.yml

# Red Team: Start Caldera attack
# http://attack-caldera-01.lab.honeypod.local:8888

# Blue Team: Watch SIEM dashboards
# http://localhost:5601

# White Team: Score and adjudicate
```

### Post-Exercise (5 min)

```bash
# Capture exercise logs
bash automation/export-logs.sh --time-window 1h

# Restore all VMs from snapshots
bash automation/snapshot-restore.sh restore --all

# Verify reset
bash automation/verify-reset.sh
```

---

## Key Dashboards

| URL | Purpose |
|-----|---------|
| http://localhost:5601 | **Kibana** - SIEM dashboards |
| http://attack-caldera-01.lab.honeypod.local:8888 | **Caldera** - Attack C2 |
| http://deception-canary-01.lab.honeypod.local:8080 | **OpenCanary** - Honeypot management |

---

## Project Layout

```
HoneyPod/
├── README.md                          # This file
├── docs/
│   ├── ARCHITECTURE.md                # 5-plane design
│   ├── DEPLOYMENT.md                  # Full deployment guide
│   └── THREAT-MODEL.md                # ATT&CK ↔ D3FEND ↔ Exercises
├── terraform/                         # IaC (Azure/Hyper-V)
│   ├── main.tf, networks.tf, variables.tf
│   └── modules/
├── ansible/                           # Configuration management
│   ├── site.yml
│   ├── roles/ (hardening, siem-agent, etc.)
│   └── playbooks/
├── security-tooling/                  # ELK, IDS, detection rules
│   ├── docker-compose.yml
│   ├── elk/
│   ├── siem-rules/
│   └── suricata/
├── deception-layer/                   # OpenCanary + Cowrie
│   ├── opencanary/
│   ├── cowrie/
│   └── deploy.sh
├── exercises/                         # Exercise scenarios
│   ├── scenarios/ (YAML-based, ATT&CK mapped)
│   └── results/ (post-exec forensics)
└── automation/                        # Snapshot, restore, cleanup
    ├── snapshot-restore.sh
    ├── pre-exercise-snapshot.sh
    └── post-exercise-restore.sh
```

---

## Common Commands

### Snapshot & Restore

```bash
# Before exercise
bash automation/snapshot-restore.sh create --all

# After exercise (full reset)
bash automation/snapshot-restore.sh restore --all
```

### Run Ansible Playbook

```bash
# Apply configuration to a zone
ansible-playbook ansible/site.yml -i ansible/inventory/hosts --tags siem-agent

# Run ad-hoc command
ansible all -i ansible/inventory/hosts -m shell -a "whoami"
```

### Check SIEM

```bash
# Verify log ingestion
curl -X GET "localhost:9200/siem-*/_search?pretty" | head -50

# View recent alerts
curl -X GET "localhost:9200/siem-*/_search" \
  -H 'Content-Type: application/json' \
  -d '{"query": {"bool": {"must": [{"term": {"alert.severity": "high"}}]}}}'
```

### Deploy Deception Layer

```bash
cd deception-layer/
bash deploy.sh --prod

# Verify honeypot is running
curl http://deception-canary-01.lab.honeypod.local:8080/status
```

---

## Success Checklist

After deployment, verify:

- [ ] Terraform: All VMs provisioned (`terraform output`)
- [ ] Ansible: All systems configured (`ansible-playbook --syntax-check`)
- [ ] SIEM: Kibana dashboard loads, receives logs
- [ ] Caldera: C2 alive and agents check in
- [ ] Deception: Honeypot services listening
- [ ] Network: Segmentation rules enforced
- [ ] Exercise: EXEC-001 scenario runs end-to-end
- [ ] Snapshot: Full reset in <5 minutes

---

## Troubleshooting

### Terraform Apply Fails

```bash
# Check credentials
az account show

# Increase debug
terraform apply -auto-approve -detailed-exitcode -input=false

# State issues
rm terraform.tfstate
terraform init
terraform apply
```

### Ansible Inventory Not Found

```bash
cd terraform/
terraform output > outputs.json

cd ../ansible/
python3 scripts/generate-inventory.py ../terraform/outputs.json > inventory/hosts

# Verify
ansible-inventory -i inventory/hosts --list
```

### SIEM Not Receiving Logs

```bash
# Check Logstash status
docker logs honeypod-logstash

# Verify network connectivity from source VM
ansible -i ansible/inventory/hosts endpoints_windows -m shell \
  -a "Test-NetConnection -ComputerName 192.168.50.1 -Port 514"

# Check Elasticsearch
curl -X GET "localhost:9200/_cat/indices?v"
```

### Caldera Agents Not Checking In

```bash
# Check agent logs on endpoint
ansible -i ansible/inventory/hosts endpoints_windows -m shell \
  -a "Get-EventLog -LogName System | Select-Object -Last 10"

# Reset Caldera
curl -X POST http://localhost:8888/api/v2/admin/reset

# Re-register agents
curl -X POST http://localhost:8888/api/v2/agents/register
```

---

## Next Steps

1. **Review Architecture:** Read [ARCHITECTURE.md](docs/ARCHITECTURE.md)
2. **Plan Exercises:** Map your threat model in [THREAT-MODEL.md](docs/THREAT-MODEL.md)
3. **Run Full Deployment:** Follow [DEPLOYMENT.md](docs/DEPLOYMENT.md)
4. **Execute Scenarios:** Start with [EXEC-001](exercises/scenarios/scenario-001-brute-force-lateral-movement.yml)
5. **Tune & Improve:** Based on exercise results, refine detection rules and response playbooks

---

## Key References

- **NIST SP 800-115:** Technical Security Testing and Assessment
- **MITRE ATT&CK:** Adversary tactics & techniques (https://attack.mitre.org)
- **MITRE D3FEND:** Defensive countermeasures (https://d3fend.mitre.org)
- **MITRE Engage:** Adversary engagement & deception (https://engage.mitre.org)
- **Atomic Red Team:** ATT&CK validation tests (https://github.com/redcanaryco/atomic-red-team)
- **Caldera:** Adversary emulation platform (https://caldera.mitre.org)

---

## Support

- **Questions?** See [DEPLOYMENT.md](docs/DEPLOYMENT.md#troubleshooting)
- **Issues?** Open an issue in the repo
- **Security concerns?** Contact your security team

---

**HoneyPod: Threat-Informed Cyber Range**  
*Built for VA, pen testing, purple team, red team, and blue team exercises.*  
*Zero production risk. Full observability. Repeatable validation.*
