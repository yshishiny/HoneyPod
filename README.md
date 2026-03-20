# HoneyPod: Threat-Informed Cyber Range with Deception Layer

A production-grade cyber range framework for vulnerability validation, pen testing, purple team exercises, red team emulation, and blue team detection & response.

## Architecture Overview

This implementation follows NIST SP 800-115 and NIST cyber range guidance, organized as five operational planes:

### 5-Plane Architecture

```
┌──────────────────────────────────────────────────────────────┐
│  Management Plane                                            │
│  (Hypervisor, IaC, Snapshots, Secrets, Backup)             │
├──────────────────────────────────────────────────────────────┤
│  Production-Like Range Plane          │  Deception Plane    │
│  ├─ User/Endpoint Zone                │ ├─ OpenCanary       │
│  ├─ Server Zone (AD, DB, App)         │ ├─ Cowrie SSH/Tel   │
│  └─ DMZ Zone                          │ └─ Decoy Services   │
├──────────────────────────────────────────────────────────────┤
│  Security Tooling Plane                                      │
│  (SIEM/ELK, EDR, IDS, Log Broker, PCAP, SOAR)              │
├──────────────────────────────────────────────────────────────┤
│  Attack Simulation Plane                                     │
│  (Caldera, Atomic Red Team, Approved Test Tools)            │
└──────────────────────────────────────────────────────────────┘
```

## Minimum Viable Infrastructure

- 1 hypervisor or small cluster
- 1 lab AD domain (CORP.LOCAL)
- 5×Windows endpoints
- 2×Linux servers
- 1×web app + PostgreSQL
- 1×jump box
- 1×SIEM/log aggregator
- 1×IDS sensor
- 1×OpenCanary node
- 1×Cowrie SSH/Telnet deception
- 1×Caldera server
- Snapshot/restore automation

## Quick Start

```bash
# 1. Review architecture
cat docs/ARCHITECTURE.md

# 2. Configure your infrastructure
cd terraform/
# Edit terraform.tfvars with your hypervisor details

# 3. Deploy infrastructure
terraform init
terraform plan
terraform apply

# 4. Configure systems
cd ../ansible/
ansible-playbook site.yml -i inventory/hosts

# 5. Deploy security tooling
cd ../security-tooling/
docker-compose up -d

# 6. Deploy deception layer
cd ../deception-layer/
./deploy.sh

# 7. Run an exercise
cd ../exercises/
./run-scenario.sh scenarios/t1566-phishing.yml
```

## Key Files

| File | Purpose |
|------|---------|
| `docs/ARCHITECTURE.md` | Detailed 5-plane design and zones |
| `docs/THREAT-MODEL.md` | Exercise scenarios mapped to ATT&CK/D3FEND |
| `terraform/` | Infrastructure-as-Code for all VMs and networks |
| `ansible/site.yml` | Configuration management for all systems |
| `security-tooling/` | SIEM, detection rules, log aggregation |
| `deception-layer/` | OpenCanary and Cowrie configurations |
| `exercises/` | ATT&CK-mapped test scenarios and validation |
| `automation/` | Snapshot, restore, cleanup scripts |

## Success Criteria

You know the range is ready when you can answer in minutes:

- [ ] Which ATT&CK techniques can we emulate today?
- [ ] Which detections fire, and where?
- [ ] What do we see on endpoint, network, and identity layers?
- [ ] How long does snapshot rollback take?
- [ ] Can white team reset everything in <5 min?
- [ ] Can we run same exercise monthly and trend improvement?

## Governance & Safety Rules

Non-negotiables:

1. ✓ No route from lab to production
2. ✓ Default-deny egress (only controlled update paths)
3. ✓ No real credentials, customer data, or copied mailboxes
4. ✓ Separate identity plane from production
5. ✓ Snapshot rollback after every exercise
6. ✓ One-way log export (lab → monitoring, never reverse)
7. ✓ Dedicated DNS and PKI for lab
8. ✓ Time sync enforced across all systems

## Deception Strategy (MITRE Engage)

**Goal-Driven Adversary Engagement:**

- **Expose**: Fake services, decoy shares, canary tokens
- **Monitor**: Log all interaction with deception assets
- **Deceive**: Misdirect adversary via fake credentials and hosts
- **Isolate**: Deception plane has zero trust path to production

**Recommended Deception Stack:**

| Tool | Use | Notes |
|------|-----|-------|
| OpenCanary | Lightweight canaries, alerts | Start here for control |
| Cowrie | SSH/Telnet high-int deception | Captures attacker shell behavior |
| T-Pot | All-in-one honeypot suite | Move here after OpenCanary v1 |

## Detection & Response (MITRE D3FEND)

Map each ATT&CK technique to D3FEND defensive outcomes:

- **Detect** → SIEM rules, EDR alerts, IDS signatures
- **Isolate** → Network segmentation, process isolation
- **Deceive** → Deception plane engagement
- **Evict** → Automated remediation playbooks
- **Restore** → Snapshot rollback procedures

## References

- NIST SP 800-115: Technical Security Testing and Assessment
- MITRE ATT&CK: Adversary tactics and techniques
- MITRE D3FEND: Defensive countermeasure techniques
- MITRE Engage: Adversary engagement and deception
- MITRE Caldera: Automated adversary emulation
- Atomic Red Team: ATT&CK-mapped validation tests

## License

Internal infrastructure project. Do not distribute without authorization.

## Support

See `docs/DEPLOYMENT.md` for troubleshooting and operations.
