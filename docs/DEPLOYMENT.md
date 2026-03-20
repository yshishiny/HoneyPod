# Deployment and Operations Guide for HoneyPod Cyber Range

## Prerequisites

### Infrastructure

- **Hypervisor:** Azure Stack HCI, Azure, or local Hyper-V with min. 32 GB RAM, 4+ vCPUs
- **Network:** Isolated lab networking (no production connectivity)
- **Storage:** 500 GB+ for VM snapshots, SIEM logs, Caldera state
- **DNS:** Internal lab DNS server (lab.honeypod.local)

### Software

- Terraform >= 1.0
- Ansible >= 2.9
- Docker & Docker Compose
- Git
- Azure CLI or Hyper-V Manager

### Personnel

- **White Team**: Exercise designer, adjudication, safety checks
- **Red Team**: Caldera operator, attack execution
- **Blue Team**: SOC analyst, incident responder
- **Green Team**: Automation, maintenance (optional)

---

## Phase 1: Infrastructure Deployment (2-4 hours)

### Step 1: Clone and Configure

```bash
# Clone the HoneyPod repository
git clone https://internal-repo/HoneyPod.git
cd HoneyPod

# Copy Terraform variables template
cp terraform/terraform.tfvars.example terraform/terraform.tfvars

# Edit terraform.tfvars with your environment:
# - Azure subscription ID, credentials
# - Azure region
# - Network addressing (if different from 192.168.x.x)
# - VM sizes (adjust for your hardware)
```

### Step 2: Deploy Infrastructure with Terraform

```bash
cd terraform/

# Initialize Terraform
terraform init

# Plan deployment
terraform plan -out=plan.tfplan

# Apply (WARNING: Creates real cloud resources)
terraform apply plan.tfplan

# Save outputs for Ansible deployment
terraform output > ../ansible/inventory/outputs.json
```

This creates:
- 5 VNets (management, production-range, deception, security, simulation)
- 3 subnets in production range (user, server, DMZ)
- Network Security Groups with microsegmentation rules
- Reserved IPs for key infrastructure

### Step 3: Prepare Golden Images

```bash
# Download or create base images:
# Windows 10 21H2, Windows Server 2022, Ubuntu 22.04 LTS

# Create snapshots for faster deployment
az snapshot create \
  --resource-group rg-honeypod-range \
  --name snapshot-win10-base \
  --source <vm-disk-id>
```

---

## Phase 2: Configuration Management (1-2 hours)

### Step 1: Prepare Ansible Inventory

```bash
cd ansible/

# Generate inventory from Terraform outputs
python3 scripts/generate-inventory.py ../terraform/outputs.json > inventory/hosts

# Test connectivity
ansible all -m ping
```

**Example inventory structure:**
```ini
[domain_controllers]
srv-ad-01 ad_ip=192.168.20.10

[file_servers]
srv-fs-01 fs_ip=192.168.20.20

[endpoints_windows]
ep-win10-[01:05] ep_domain=corp.local

[endpoints_linux]
ep-linux-01 ep_ip=192.168.10.30

[deception_canary]
deception-canary-[01:02] canary_ip=192.168.40.10

[deception_cowrie]
deception-cowrie-01 cowrie_ip=192.168.40.20

[siem]
siem-es-01 siem_role=elasticsearch

[attack_simulation]
attack-caldera-01 caldera_role=master
```

### Step 2: Deploy Base Configurations

```bash
# Install Ansible Galaxy roles
ansible-galaxy install -r requirements.yml

# Deploy hardening (Windows + Linux)
ansible-playbook site.yml -i inventory/hosts --tags hardening

# Deploy SIEM agents (Beats, rsyslog)
ansible-playbook site.yml -i inventory/hosts --tags siem-agent

# Deploy monitoring (Sysmon, Osquery)
ansible-playbook site.yml -i inventory/hosts --tags monitoring
```

### Step 3: Deploy Active Directory

```bash
# Configure AD domain structure on domain controllers
ansible-playbook site.yml -i inventory/hosts --tags ad-setup

# Wait for AD replication (~5 minutes)
sleep 300

# Join endpoints to domain
ansible-playbook site.yml -i inventory/hosts --tags domain-join

# Apply Group Policy Objects
ansible-playbook site.yml -i inventory/hosts --tags apply-gpo
```

### Step 4: Verify Configuration

```bash
# Test AD replication
ansible-playbook playbooks/verify-ad.yml -i inventory/hosts

# Test network segmentation
bash automation/test-segmentation.sh

# Test log flow to SIEM
ansible-playbook playbooks/verify-siem-ingest.yml -i inventory/hosts
```

---

## Phase 3: Security Tooling Deployment (1-2 hours)

### Step 1: Deploy ELK Stack

```bash
cd security-tooling/

# Start ELK containers
docker-compose -f elk/docker-compose.yml up -d

# Wait for Elasticsearch to be ready
docker-compose logs -f --until=uploaded

# Import SIEM detection rules
curl -X POST "localhost:9200/_bulk?pretty" \
  -H 'Content-Type: application/json' \
  -d @siem-rules/attack-detection-rules.json
```

### Step 2: Deploy IDS (Suricata)

```bash
# Suricata runs as container or on dedicated VM
docker-compose -f security-tooling/docker-compose.yml up -d ids

# Verify IDS is receiving traffic
docker logs security-tooling_ids_1
```

### Step 3: Create SIEM Dashboards

```bash
# Kibana dashboards: http://localhost:5601

# Import dashboard templates
for dashboard in dashboards/*.ndjson; do
  curl -X POST "localhost:5601/api/saved_objects/dashboard" \
    -H 'kbn-xsrf: true' \
    -d @"$dashboard"
done
```

Key dashboards:
- **Overview**: Real-time event count, alerts, top sources
- **ATT&CK Coverage**: Techniques detected, techniques emulated
- **Lateral Movement**: Network connections, privilege escalation
- **Deception**: Honeypot engagement, canary interactions
- **Incident Response**: Timeline, forensic artifacts

---

## Phase 4: Deception Layer Deployment (30-45 minutes)

```bash
cd deception-layer/

# Deploy OpenCanary and Cowrie
bash deploy.sh --prod

# Verify honeypot services
bash verify.sh

# Check logs flowing to SIEM
tail -f /var/log/canary.log  # OpenCanary
```

---

## Phase 5: Attack Simulation Setup (30 minutes)

### Step 1: Deploy Caldera

```bash
# Deploy Caldera C2 server
ansible-playbook site.yml -i inventory/hosts --tags caldera-deploy

# Access: http://attack-caldera-01.lab.honeypod.local:8888
```

### Step 2: Import Atomics

```bash
# Caldera plugin: Atomic Red Team
# Automatic on Caldera boot; accessible via GUI
```

### Step 3: Load Exercise Scenarios

```bash
# Copy exercise YAML files to Caldera
cp exercises/scenarios/*.yml attack-simulation/caldera-import/

# Reload Caldera plugins
curl -X POST http://localhost:8888/api/v2/admin/reload-plugins
```

---

## Exercise Execution Playbook

### Pre-Exercise (30 minutes before)

```bash
# 1. Create snapshots of all production-range VMs
bash automation/pre-exercise-snapshot.sh

# 2. Reset Caldera state
curl -X POST http://caldera-01.lab.honeypod.local:8888/api/v2/admin/reset

# 3. Verify SIEM is receiving logs (inject test event)
ansible-playbook playbooks/test-siem-ingest.yml

# 4. Test network segmentation
bash automation/test-segmentation.sh

# 5. Brief all teams
echo "[*] Exercise begins in 5 minutes"
```

### During Exercise (45-60 minutes)

**Red Team Role:**
- Operate Caldera C2
- Execute attack sequences per scenario
- Log findings and success/failure of techniques

**Blue Team Role:**
- Monitor SIEM dashboard in real-time
- Respond to alerts
- Execute incident response playbooks
- Attempt to contain and remediate

**White Team Role:**
- Observe both teams
- Record metrics (TTD, MTTR, detection rate)
- Intervene only if safety rules violated
- Score based on success criteria

### Post-Exercise (30 minutes)

```bash
# 1. Capture SIEM logs for this exercise
bash automation/export-logs.sh --time-window 1h --output exercise-logs/

# 2. Restore snapshots (rollback all systems)
bash automation/post-exercise-restore.sh

# 3. Verify full reset
bash automation/verify-reset.sh

# 4. Archive Caldera artifacts
tar czf exercises/results/exec-$(date +%Y%m%d).tar.gz \
  /opt/caldera/data/runs/*

# 5. Conduct debrief with all teams
# Questions:
# - Red team: Techniques executed, success rate, obstacles
# - Blue team: Detections made, response time, tools used
# - White team: Observations, scoring, recommendations
```

---

## Operational Procedures

### Regular Maintenance

```bash
# Weekly: Update threat intel
ansible-playbook playbooks/update-threat-intel.yml

# Monthly: Update OS patches (in controlled fashion)
ansible-playbook playbooks/patch-systems.yml --tags non-critical

# Monthly: Rotate Vault secrets
bash automation/rotate-secrets.sh

# Quarterly: Update golden images
bash automation/update-golden-images.sh
```

### Monitoring and Alerting

```bash
# SIEM Web UI: http://siem-kb-01.lab.honeypod.local:5601

# Key alerts to watch:
# - "Multiple failed login attempts" (T1110)
# - "Suspicious RDP connection" (T1021)
# - "Registry run key modification" (T1547)
# - "Honeypot engagement detected" (MITRE Engage)

# Alert threshold tuning:
# Edit siem-rules/attack-detection-rules.md
# Redeploy: ansible-playbook playbooks/update-siem-rules.yml
```

### Troubleshooting

#### VMs won't boot

```bash
# Check hypervisor logs
az vm get-boot-diagnostics-data --resource-group rg-honeypod-range \
  --name ep-win10-01

# Rollback to snapshot
az snapshot restore --snapshot-id <snapshot-id> \
  --target-resource-group rg-honeypod-range
```

#### SIEM not receiving logs

```bash
# Check rsyslog forwarding on a source VM
ansible -m shell -a "tail -20 /var/log/syslog | grep siem" endpoints_linux

# Verify network connectivity
ansible -m shell -a "nc -zv 192.168.50.1 514" endpoints_linux

# Restart syslog on SIEM ingester
ansible -m systemd -a "name=rsyslog state=restarted" siem
```

#### Caldera agents not checking in

```bash
# Check agent logs on endpoint
ansible -m shell -a "Get-EventLog -LogName 'Application' -Source 'Caldera Agent'" endpoints_windows

# Restart agent
ansible -m systemd -a "name=caldera-agent state=restarted" attack_simulation

# Re-register agents
curl -X POST http://caldera-01.lab.honeypod.local:8888/api/v2/agents/register
```

---

## Disaster Recovery

### Full Lab Recovery (from off-site backup)

```bash
# 1. Re-deploy infrastructure
cd terraform/
terraform apply -auto-approve

# 2. Restore VM snapshots
bash automation/restore-from-backup.sh --backup-location s3://backup-bucket

# 3. Verify all services
bash automation/verify-reset.sh

# 4. Re-import Caldera exercises from version control
git checkout exercises/scenarios/
```

### Data Protection

```bash
# Backup SIEM data (weekly)
curl -X POST http://siem-es-01.lab.honeypod.local:9200/_snapshot/remote_backup/forensics_* \
  -H 'Content-Type: application/json' \
  -d '{"indices": "siem*", "include_global_state": true}'

# Backup Caldera state (daily)
tar czf backups/caldera-$(date +%Y%m%d).tar.gz /opt/caldera/data/

# Backup Terraform state
aws s3 cp terraform.tfstate s3://backup-bucket/terraform-state-$(date +%Y%m%d).tfstate
```

---

## Success Checklist

After full deployment, verify:

- [ ] All 5 planes operational (management, range, deception, security, simulation)
- [ ] VMs snapshot/restore in <5 minutes
- [ ] SIEM receiving logs from all sources
- [ ] Honeypots isolated (no inbound from authorized zones)
- [ ] Network segmentation rules enforced
- [ ] Caldera C2 able to execute agents
- [ ] ATT&CK detection rules loaded and alerting
- [ ] Exercise scenario runs end-to-end
- [ ] Blue team can respond to alerts via playbooks
- [ ] White team can measure and score results

---

## Security Policies

### Non-Negotiables

1. **Lab Isolation:** No route from lab to production networks
2. **Firewall Egress:** Default-DENY, only specific update paths allowed
3. **Credential Separation:** Lab uses only synthetic credentials (never production)
4. **Snapshot Integrity:** No production data in any lab snapshot
5. **Log One-Way Policy:** Logs flow lab → SIEM only; never SIEM → lab
6. **Post-Exercise Rollback:** All changes reverted within 5 minutes
7. **DNS Segregation:** Lab uses separate DNS (lab.honeypod.local)
8. **PKI Segregation:** Lab uses separate CA (not production PKI)

### Audit Trail

```bash
# Log all exercise runs
ansible-playbook playbooks/audit-exercise.yml \
  --extra-vars "scenario=EXEC-001 red_team=alice.smith"

# Generate compliance report
bash automation/generate-audit-report.sh --period monthly
```

---

## Advanced Configurations

### High Availability (Production-Grade)

```bash
# Multi-hypervisor cluster across sites
terraform variables:
  hypervisor_count: 3
  hypervisor_location: ["us-east-2", "us-west-1", "eu-west-1"]
  replication_factor: 2
```

### Extended Deception (T-Pot)

```bash
# After initial OpenCanary/Cowrie success, deploy T-Pot
# Supports 20+ honeypots
# Usage: Full enterprise honeypot program

ansible-playbook playbooks/deploy-tpot.yml
```

### Continuous Exercise Mode

```bash
# Run scenario monthly, track improvements
bash automation/schedule-exercise.sh --frequency monthly \
  --scenario EXEC-001 \
  --trend-report

# Metrics dashboard: Kibana → Dashboards → Exercise Trends
```

---

## References and Further Reading

- **NIST SP 800-115:** Technical Security Testing and Assessment
- **NIST Cyber Range Guidance:** https://nist.gov/cyberframework
- **MITRE ATT&CK:** https://attack.mitre.org
- **MITRE D3FEND:** https://d3fend.mitre.org
- **MITRE Caldera:** https://caldera.mitre.org
- **Atomic Red Team:** https://github.com/redcanaryco/atomic-red-team
- **OpenCanary:** https://github.com/thinkst/opencanary
- **Cowrie:** https://github.com/cowrie/cowrie
- **NCSC Logging Best Practice:** https://www.ncsc.gov.uk/

---

## Support & Escalation

- **Questions/Issues:** Open an issue in the internal repo
- **Security Concerns:** Contact security-team@corp.local
- **Emergency Lab Shutdown:** `bash automation/emergency-shutdown.sh`

---

**Last Updated:** March 2026  
**Version:** 1.0  
**Maintained By:** Security Operations Team
