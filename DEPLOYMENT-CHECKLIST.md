# HoneyPod Project Checklist

Use this checklist to track your deployment and exercise execution.

## Pre-Deployment

- [ ] Review ARCHITECTURE.md (5 planes, 3 zones, network design)
- [ ] Verify prerequisites installed (Terraform, Ansible, Docker, Git)
- [ ] Obtain Azure/Hyper-V credentials and subscription ID
- [ ] Allocate budget (~$400/month cloud or $2-3K one-time on-prem)
- [ ] Brief stakeholders on timeline (6-8 hours to lab operational)
- [ ] Assign roles:
  - [ ] White team (exercise designer, scorer)
  - [ ] Red team (Caldera operator, attack executor)
  - [ ] Blue team (SOC analyst, SIEM dashboard watcher)
  - [ ] Green team (ops, infrastructure, snapshot/restore)

## Infrastructure Deployment

### Terraform Phase

- [ ] Clone HoneyPod repo
- [ ] Create terraform.tfvars with credentials
- [ ] Run `terraform init`
- [ ] Run `terraform plan` and review
- [ ] Run `terraform apply`
- [ ] Wait for all VMs to boot (~10-15 min)
- [ ] Verify `terraform output` shows all resources
- [ ] Export outputs: `terraform output > outputs.json`

**Go/No-Go:** All VMs online, networks created, NSGs applied

### Ansible Phase

- [ ] Generate inventory: `python3 scripts/generate-inventory.py`
- [ ] Test connectivity: `ansible all -m ping`
- [ ] Deploy hardening: `ansible-playbook site.yml --tags hardening`
- [ ] Setup AD domain: `ansible-playbook site.yml --tags ad-setup`
- [ ] Join endpoints to domain: `ansible-playbook site.yml --tags domain-join`
- [ ] Deploy SIEM agents: `ansible-playbook site.yml --tags siem-agent`
- [ ] Verify all systems configured (no Ansible failures)

**Go/No-Go:** All systems hardened, domain-joined, agents reporting

### SIEM Phase

- [ ] Navigate to security-tooling/
- [ ] Run `docker-compose up -d`
- [ ] Wait for containers to start: `docker-compose logs -f`
- [ ] Access Kibana: http://localhost:5601
- [ ] Create index pattern: `siem-*`
- [ ] Verify log ingestion (should see events flowing in)
- [ ] Load detection rules: Run import script
- [ ] Create dashboards:
  - [ ] Overview
  - [ ] ATT&CK Coverage
  - [ ] Lateral Movement
  - [ ] Deception Engagement

**Go/No-Go:** SIEM receiving logs, dashboards populated, alerts firing

### Deception Layer Phase

- [ ] Navigate to deception-layer/
- [ ] Review opencanary.conf
- [ ] Review deploy.sh script
- [ ] Run `bash deploy.sh --test` (dry run)
- [ ] Run `bash deploy.sh --prod` (actual deployment)
- [ ] Verify honeypot services: `netstat -tuln | grep LISTEN`
- [ ] Check logs flowing to SIEM
- [ ] Verify isolation: Attempt connectivity from endpoints (should fail)

**Go/No-Go:** Honeypots running, isolated, logging to SIEM

### Attack Simulation Phase

- [ ] Deploy Caldera: `ansible-playbook site.yml --tags caldera-deploy`
- [ ] Access Caldera: http://attack-caldera-01.lab.honeypod.local:8888
- [ ] Verify Caldera plugins loaded (Atomic Red Team visible)
- [ ] Test agent check-in (deploy a test agent)

**Go/No-Go:** Caldera operational, agents registering

## Pre-Exercise Procedures

For each exercise, run these checks:

- [ ] Create pre-exercise snapshots: `bash automation/snapshot-restore.sh create --all`
- [ ] Verify snapshots created: `bash automation/snapshot-restore.sh status`
- [ ] Test SIEM log ingestion: `ansible-playbook playbooks/verify-siem-ingest.yml`
- [ ] Test network segmentation: `bash automation/test-segmentation.sh`
- [ ] Reset Caldera state: `curl -X POST http://localhost:8888/api/v2/admin/reset`
- [ ] Clear SIEM indexes (optional, for clean run): `curl -X DELETE 'localhost:9200/siem-*'`
- [ ] Brief red/blue/white teams
- [ ] Confirm exercise scenario document reviewed by all teams

**Go/No-Go:** All pre-checks passed, teams briefed, ready to start

## Exercise Execution (45 min)

### Red Team

- [ ] Start Caldera control plugin for scenario
- [ ] Monitor attack execution in Caldera GUI
- [ ] Log technique execution order and success/failure
- [ ] Document any issues or tool failures
- [ ] Note time of each technique start

### Blue Team

- [ ] Open SIEM dashboard (http://localhost:5601)
- [ ] Monitor alerts in real-time
- [ ] Log which alerts triggered and when (TTD measurement)
- [ ] Execute response playbooks for each alert
- [ ] Attempt to isolate compromised systems
- [ ] Coordinate with white team if active response needed

### White Team

- [ ] Start exercise timer (0:00)
- [ ] Monitor both red and blue teams
- [ ] Do NOT intervene unless safety violation
- [ ] Score each objective:
  - Red team: Techniques executed, success rate
  - Blue team: Techniques detected, TTD, TTR, false positives
- [ ] Record incident timeline
- [ ] Note exercise issues or improvements

## Post-Exercise Procedures

Within 30 minutes of exercise end:

- [ ] Export SIEM logs: `bash automation/export-logs.sh`
- [ ] Analyze logs for missed detections
- [ ] Calculate metrics:
  - [ ] Detection Rate (techniques detected / techniques executed)
  - [ ] Average TTD (time to detect)
  - [ ] Average TTR (time to respond)
  - [ ] False positive count
- [ ] Archive Caldera run artifacts
- [ ] Restore all VMs: `bash automation/snapshot-restore.sh restore --all`
- [ ] Verify reset complete: `bash automation/verify-reset.sh`
- [ ] All systems back online and clean (< 5 min)

**Go/No-Go:** Lab fully reset, ready for next exercise

## Exercise Debrief

After exercise (schedule for same day):

### Red Team Debrief
- [ ] Which ATT&CK techniques succeeded?
- [ ] Which failed and why?
- [ ] Were any detections avoided?
- [ ] What was adversary MTTR for containment?
- [ ] Recommendations for next exercise?

### Blue Team Debrief
- [ ] Which alerts fired and were they accurate?
- [ ] What was missed?
- [ ] Were response playbooks effective?
- [ ] What slowed down response?
- [ ] Recommendations for detection improvement?

### White Team Debrief
- [ ] Overall exercise success (yes/no/partial)
- [ ] Scoring summary
- [ ] Trends vs. previous exercises
- [ ] Roadmap items for next iteration

## Post-Exercise Documentation

- [ ] Update THREAT-MODEL.md with results
- [ ] Create trending report (if 2+ exercises completed)
- [ ] Document detection rule gaps and improvements
- [ ] Update response playbooks based on findings
- [ ] Commit improvements to Git

## Recurring Exercise Schedule

### Monthly

- [ ] EXEC-001: Brute Force → Lateral Movement → Exfil (baseline scenario)
- [ ] Measure improvement month-over-month
  - [ ] TTD decreasing?
  - [ ] Detection Rate increasing?
  - [ ] MTTR improving?

### Quarterly

- [ ] New scenario from exercise library (EXEC-002, EXEC-003, etc.)
- [ ] Rotate team roles (red ↔ blue)
- [ ] Quarterly trending report
- [ ] MITRE framework update review

## Maintenance Tasks

### Weekly

- [ ] Check SIEM disk usage
- [ ] Verify all VM backups/snapshots healthy
- [ ] Review critical alerts (any honeypot engagement?)
- [ ] Caldera agent auto-cleanup (remove stale agents)

### Monthly

- [ ] Update OS patches (non-critical)
- [ ] Update threat intelligence signatures
- [ ] Review SIEM rule effectiveness (any tuning needed?)
- [ ] Capacity planning (disk, memory, CPU)

### Quarterly

- [ ] Golden image refresh (security patches, new tools)
- [ ] Detection rule review (new ATT&CK techniques to add?)
- [ ] Disaster recovery test (full from-backup recovery)
- [ ] Security audit (credentials, access controls, audit trails)

## Upgrade Checklist (When Needed)

- [ ] Review release notes for breaking changes
- [ ] Update Terraform modules
- [ ] Update Ansible roles
- [ ] Update ELK Stack image versions
- [ ] Test on staging environment first
- [ ] Schedule maintenance window
- [ ] Execute upgrade: `terraform apply`, `ansible-playbook`, etc.
- [ ] Verify all services operational
- [ ] Run verification scripts

## Safety Checklist (Before Each Exercise)

- [ ] Firewall rule: No lab ↔ production route (VERIFY)
- [ ] DNS: Lab using lab.honeypod.local (not corporate DNS)
- [ ] Credentials: Lab uses ONLY corp.local AD (not production)
- [ ] Secrets: Vault is lab-only, not tied to production Vault
- [ ] Snapshots: Pre-exercise snapshot created and verified
- [ ] Backup: SIEM and Caldera backed up off-hypervisor
- [ ] Egress: Default-deny, update paths only (verify NSG rules)
- [ ] Network segmentation: Deception zone isolated (no trust path)

## Success Milestones

Track these key milestones:

- [ ] **Weeks 1-2:** Infrastructure deployed, base systems operational
- [ ] **Week 3:** SIEM receiving logs, first dashboards built
- [ ] **Week 4:** Deception layer active, Caldera operational
- [ ] **Week 5:** First exercise (EXEC-001) executed successfully
- [ ] **Month 2:** Second exercise (new scenario) with improved metrics
- [ ] **Month 3:** Quarterly trending report, clear improvement trajectory
- [ ] **Month 6:** Established monthly exercise cadence, team expertise mature

## Troubleshooting Checklist

If something goes wrong:

- [ ] **VMs won't boot:** Check hypervisor logs, try snapshot restore
- [ ] **Ansible fails:** Run with `-v` for verbose output, check inventory
- [ ] **SIEM not receiving logs:** Verify rsyslog on source, check firewall
- [ ] **Caldera agents lost:** Restart Caldera, reboot endpoints, re-register
- [ ] **Exercise failed midway:** Check SIEM for errors, review network connectivity
- [ ] **Snapshot restore stuck:** Check Azure/Hyper-V status, may need manual intervention

See DEPLOYMENT.md for detailed troubleshooting.

## Sign-Offs

- [ ] **Project Lead:** Approves lab design and security controls
- [ ] **Infrastructure Team:** Confirms infrastructure deployed correctly
- [ ] **Security Team:** Confirms isolation and data protection
- [ ] **Red Team Lead:** Ready to execute exercises
- [ ] **Blue Team Lead:** SIEM trained and ready
- [ ] **White Team Lead:** Scoring criteria established

---

## Final Notes

- Keep this checklist updated as procedures evolve
- Attach exercise result summaries to this checklist
- Use for lessons learned and continuous improvement
- Share with new team members for onboarding

**HoneyPod Deployment Checklist - Print & Post**

---

**Project Status:**
- [ ] Not Started
- [ ] In Progress (Phase: _______)
- [ ] Deployed & Operational
- [ ] Mature (3+ monthly exercises completed)

**Last Updated:** _____________  
**By:** _____________  
**Next Review:** _____________
