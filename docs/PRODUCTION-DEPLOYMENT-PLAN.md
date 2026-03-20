# HoneyPod Production Deployment Plan

**Version:** 1.0  
**Date:** March 18, 2026  
**Purpose:** Guide for deploying HoneyPod to production/real-world environments (Azure, AWS, on-premises, bare metal)

---

## Executive Summary

This document provides a comprehensive deployment strategy for HoneyPod in production environments beyond the simplified Hyper-V local lab. It covers multiple target platforms, scalability considerations, security hardening, and operational readiness criteria.

**Deployment Scenarios Covered:**
1. Azure Cloud (primary public cloud option)
2. AWS (multi-cloud redundancy)
3. On-Premises (enterprise data center)
4. Hybrid (Azure + on-prem)
5. Bare Metal (dedicated hardware)

---

## Part 1: Pre-Deployment Assessment

### 1.1 Environment Discovery

**Before starting any deployment, complete this assessment:**

| Item | Local Lab | Azure | On-Prem | AWS | Bare Metal |
|------|-----------|-------|---------|-----|-----------|
| **Stakeholder Approval** | ✓ Self | Procurement | Security/Infrastructure | Ops/Cloud | Data Center |
| **Budget Approval** | Self | Finance | Budget Owner | Finance | Capital Budget |
| **Network Design Review** | Architecture | Cloud Architect | Network Eng | Cloud Arch | Network Eng |
| **Security Review** | Basic | SOC/Info Sec | Info Sec Officer | Compliance/Sec | Info Sec |
| **Change Control** | Not required | Required | Required | Required | Required |
| **Runbook Sign-off** | Recommended | Required | Required | Required | Required |

### 1.2 Requirements Worksheet

**Complete before proceeding:**

```
DEPLOYMENT ENVIRONMENT CHECKLIST
=================================

Environment Name: ___________________________
Target Platform: [ ] Azure [ ] AWS [ ] On-Prem [ ] Hybrid [ ] Bare Metal
Organization: ___________________________
Deployment Timeline: Start: ________ End: ________ (weeks)
Budget Approved: $__________ (annual)

INFRASTRUCTURE CAPACITY
- CPU Cores Available: ____ (need min 16, recommended 32+)
- RAM Available: ____ GB (need min 64GB, recommended 128GB+)
- Storage Available: ____ TB (need min 2TB, recommended 5TB+)
- Network Bandwidth: ____ Mbps (need min 1Gbps, recommended 10Gbps+)
- Redundancy Required: [ ] No [ ] N+1 [ ] N+2 [ ] Full HA/DR

SECURITY/COMPLIANCE
- Compliance Framework: [ ] None [ ] SOC2 [ ] ISO27001 [ ] HIPAA [ ] PCI-DSS [ ] Custom
- Data Classification: [ ] Public [ ] Internal [ ] Confidential [ ] Restricted
- Network Segmentation Required: [ ] Basic [ ] Intermediate [ ] Advanced (zero-trust)
- Encryption Required: [ ] TLS (in-transit) [ ] AES256 (at-rest) [ ] Both
- Access Control: [ ] Local Users [ ] AD/LDAP [ ] MFA Required [ ] RBAC Required

OPERATIONAL REQUIREMENTS
- 24/7 Monitoring Required: [ ] No [ ] Yes
- Incident Response Integration: [ ] No [ ] Yes (integrate with SIEM at: _________)
- Backup/Recovery RTO: ________ hours
- Backup/Recovery RPO: ________ hours
- Log Retention: ________ days
- Audit Logging Level: [ ] Basic [ ] Detailed [ ] Forensic

TEAM & SKILLS
- Deployment Lead: ___________________________
- Infrastructure Owner: ___________________________
- Security Owner: ___________________________
- Ops/Support Owner: ___________________________
- DevOps/IaC Experience: [ ] None [ ] Beginner [ ] Intermediate [ ] Advanced
- Ansible Experience: [ ] None [ ] Beginner [ ] Intermediate [ ] Advanced
- Network Engineering: [ ] None [ ] Beginner [ ] Intermediate [ ] Advanced
```

---

## Part 2: Platform-Specific Deployment Guides

### 2.1 AZURE DEPLOYMENT

#### Prerequisites

1. **Azure Resource Group & Service Principal**
   ```powershell
   # Create resource group (manually or via CLI)
   az group create --name rg-honeypod-prod --location eastus2
   
   # Create service principal
   az ad sp create-for-rbac --name sp-honeypod-deployer `
     --role Contributor `
     --scopes /subscriptions/{subscription-id}
   
   # Output will be:
   # appId (client_id)
   # password (client_secret)
   # tenant
   ```

2. **Network Planning (3 VNets minimum for production)**
   - Management VNet (10.0.0.0/16) - Admin access, tooling
   - Production Range VNet (10.1.0.0/16) - Lab endpoints & servers
   - Security Tooling VNet (10.2.0.0/16) - SIEM, logging, analytics
   - Deception VNet (10.3.0.0/16) - Honeypots (isolated)
   - DMZ VNet (10.4.0.0/16) - External access (optional)

3. **Platform Configuration**

```powershell
# File: terraform/terraform-azure-prod.tfvars
# PRODUCTION AZURE DEPLOYMENT

# Azure Subscription
azure_subscription_id = "<your-subscription-id>"
azure_client_id = "<service-principal-app-id>"
azure_client_secret = "<service-principal-password>"
azure_tenant_id = "<your-tenant-id>"
azure_region = "eastus2"

# Resource Naming
project = "HoneyPod"
environment = "production"
location_short = "eus2"

# Deployment Size (FULL for production)
deployment_type = "full"
vm_count_windows = 5
vm_count_linux = 3

# Lab Configuration
lab_domain = "honeypod.internal"
lab_timezone = "Eastern Standard Time"

# Security & Compliance
enable_managed_identities = true
enable_backup = true
enable_encryption_at_rest = true
enable_network_flow_logs = true
enable_resource_locks = true

# Monitoring & Logging (integrate with existing SIEM)
log_analytics_workspace_id = "<existing-workspace-id>"
application_insights_key = "<app-insights-key>"

# VM Configuration
vm_size_windows = "Standard_D4s_v3"  # 4 vCPU, 16GB RAM
vm_size_linux = "Standard_D4s_v3"
vm_disk_type = "Premium_LRS"  # SSD for production
vm_disk_size_gb = 256

# Network Security
enable_ddos_protection = false  # Optional, extra cost
enable_waf = false  # Optional, for web applications
network_security_groups_custom_rules = []

# Tags for Cost Management & Governance
tags = {
  Environment = "Production"
  Project = "HoneyPod"
  CostCenter = "IT-Security"
  Owner = "InfoSec Team"
  BackupPolicy = "Daily"
  DeprecationDate = ""
}
```

#### Deployment Steps

```powershell
# 1. Validate configurations
terraform -chdir=terraform plan -var-file=terraform-azure-prod.tfvars -out=plan.out

# 2. Review output (terraform.tfstate should NOT be committed to Git)
# Run in secure CI/CD pipeline or protected terminal only

# 3. Deploy infrastructure
terraform -chdir=terraform apply plan.out

# 4. Export outputs for Ansible
terraform -chdir=terraform output -json > ../ansible/inventory/azure-prod-outputs.json

# 5. Generate Ansible inventory from outputs
python3 ansible/scripts/generate-inventory.py \
  --source azure-prod-outputs.json \
  --output ansible/inventory/hosts-prod
```

---

### 2.2 AWS DEPLOYMENT

#### Prerequisites

1. **AWS Infrastructure Setup**
   ```bash
   # Create IAM user for Terraform
   aws iam create-user --user-name honeypod-deployer
   aws iam attach-user-policy --user-name honeypod-deployer \
     --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
   
   # Create access keys
   aws iam create-access-key --user-name honeypod-deployer
   
   # Save to ~/.aws/credentials
   export AWS_PROFILE=honeypod
   export AWS_REGION=us-east-1
   ```

2. **VPC & Network Design**
   - VPC (10.0.0.0/16)
   - Public Subnet (10.0.1.0/24) for NAT/Bastion
   - Private Subnets (10.0.10.0/24, 10.0.20.0/24, 10.0.30.0/24) for lab
   - Security Groups per tier (Web, App, DB, Deception)

3. **Terraform Configuration for AWS**

```hcl
# File: terraform/tf-aws-prod.tfvars
aws_region = "us-east-1"
aws_availability_zones = ["us-east-1a", "us-east-1b"]

environment = "production"
project = "honeypod"

# Instance types (AWS)
instance_type_windows = "t3.xlarge"  # 4 vCPU, 16GB RAM
instance_type_linux = "t3.xlarge"

# EBS volume configuration
ebs_volume_size = 256
ebs_volume_type = "gp3"
ebs_encryption = true

# Auto-scaling (optional for production)
enable_autoscaling = true
min_instances = 3
max_instances = 10

# Monitoring
enable_cloudwatch = true
enable_flow_logs = true
cloudwatch_log_retention_days = 30

tags = {
  Environment = "Production"
  Project = "HoneyPod"
  ManagedBy = "Terraform"
  CostCenter = "IT-Security"
}
```

---

### 2.3 ON-PREMISES DEPLOYMENT (Hyper-V/Proxmox/vSphere)

#### Infrastructure Requirements

| Component | Minimum | Recommended | Production |
|-----------|---------|-------------|-----------|
| Hypervisor Hosts | 1 | 2 (HA) | 3+ (HA + spares) |
| CPU Cores | 24 | 32 | 64+ |
| RAM | 128GB | 256GB | 512GB+ |
| Storage (VM) | 2TB | 5TB | 10TB+ |
| Storage (Backup) | 5TB | 15TB | 30TB+ |
| Network | 1Gbps | 10Gbps | 40Gbps+ |
| UPS/Power | N/A | 2kVA | 10kVA+ |
| Cooling | Ambient | Active | Redundant |

#### Hyper-V Production Configuration

```powershell
# File: terraform/hyperv-prod.tfvars

# Hyper-V Infrastructure
hyperv_host = "hv-prod-01.datacenter.local"
hyperv_user = "domain\terraform-sa"
# Password stored in secure vault, not in this file

# Network Configuration
hyperv_switch_name = "vSwitch-HoneyPod-Prod"
hyperv_vlan_management = 100
hyperv_vlan_range = 101
hyperv_vlan_tooling = 102
hyperv_vlan_deception = 103

# Storage Paths (multiple drives for I/O separation)
vm_storage_path = "E:\Hyper-V\VMs"  # Fast SSD for VM disks
template_path = "D:\Hyper-V\Templates"  # Template storage
snapshot_path = "F:\Hyper-V\Snapshots"  # Separate snapshot drive

# VM Specifications
vm_generation = 2  # Gen2 for TPM/UEFI support
vm_memory_startup = 8192  # 8GB base
vm_vcpu_count = 4
vm_disk_size_gb = 256
vm_disk_type = "VHDx"

# Deployment Configuration
deployment_type = "full"
environment = "production"
lab_domain = "honeypod.corp.local"

tags = {
  Environment = "Production"
  Owner = "InfoSec"
  BackupPolicy = "Nightly"
  Location = "DataCenter-01"
}
```

#### On-Premises Deployment Steps

```powershell
# 1. Validate Hyper-V host connectivity
Test-WSMan -ComputerName hv-prod-01.datacenter.local

# 2. Configure Hyper-V provider (requires modifications to Terraform)
# Add to main.tf:
# provider "hyperv" {
#   user = var.hyperv_user
#   password = var.hyperv_password
#   host = var.hyperv_host
# }

# 3. Deploy VMs
terraform -chdir=terraform apply -var-file=hyperv-prod.tfvars

# 4. Configure backups
Backup-VM -Name "dc-honeypod-prod-01" -BackupLocation "\\nas-backup\Hyper-V"

# 5. Verify replication (if using Hyper-V Replica)
Start-VMInitialReplication -VM (Get-VM "dc-honeypod-prod-01")
```

---

### 2.4 BARE METAL DEPLOYMENT

#### Infrastructure Requirements

```
Physical Server Specification (per node):
- CPU: 2x Intel Xeon Silver 4314 (16C/32T each) = 32 cores
- RAM: 256GB (16x 16GB RDIMM, ECC)
- Storage1: 2x 960GB NVMe (RAID 1) - OS + System
- Storage2: 4x 3.84TB SSD (RAID 10) - VM storage
- Storage3: 4x 10TB HDD (RAID 6) - Archive/Backup
- Network: 2x 25Gbps NICs (redundant, separate VLANs)
- BMC: iLO/iDRAC out-of-band management
- Power: 2x 1500W PSU (redundant, separate circuits)

Clustering Setup:
- 3 physical nodes minimum (for quorum)
- Shared SAN storage (iSCSI or FC)
- Virtual IP for management (floating)
- Heartbeat network (dedicated 10Gbps link)
```

#### Installation Process

```bash
#!/bin/bash
# Bare Metal Deployment Script

# 1. OS Installation (RHEL/Ubuntu with LVM)
# Use kickstart/preseed for automated deployment

# 2. Hypervisor Setup
sudo apt install qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils vlan

# 3. Network Configuration
cat > /etc/netplan/99-honeypod.yaml << EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    eno1:
      dhcp4: false
      addresses:
        - 10.0.0.10/24
      gateway4: 10.0.0.1
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]
      routes:
        - to: 0.0.0.0/0
          via: 10.0.0.1
    eno2:
      dhcp4: false
      mtu: 9000
  vlans:
    vlan.100:
      id: 100
      link: eno2
      addresses:
        - 10.100.0.10/24
    vlan.101:
      id: 101
      link: eno2
      addresses:
        - 10.101.0.10/24
EOF

# 4. Deploy VMs via Terraform or Ansible
terraform apply -var-file=bare-metal.tfvars

# 5. Configure clustering (optional)
pacemaker_setup.sh
```

---

## Part 3: Security Hardening for Production

### 3.1 Network Security

```yaml
# Cloud Network Security Policies

# 1. NSG Rules (Azure example)
Inbound Rules:
  SSH (22):
    - CIDR: 10.0.100.0/24 (Management subnet only)
    - Tags: VPN, OnPrem, Bastion
  
  RDP (3389):
    - CIDR: 10.0.100.0/24 (Management subnet)
    - Tags: Admin, Bastion
  
  SIEM (5601, 9200):
    - CIDR: 10.0.200.0/24 (Security tooling subnet)
  
  Honeypots (Various):
    - CIDR: 0.0.0.0/0 (Allow external probing)
    - Tags: Deception, External

Outbound Rules:
  - Honeypots → NullRoute (explicit drop, no external exfil)
  - Lab Systems → SIEM only (192.168.50.0/24)
  - All → DNS (53) and NTP (123)

# 2. Virtual Firewalls (firewalld/ufw)
UFW Rules (Linux hosts):
  ssh: Allow from 10.0.100.0/24 only
  honeypot_services: Allow from 0.0.0.0/0
  siem: Allow from 10.0.200.0/24
  rpc: Drop all inbound
  nfs: Allow from backup 10.0.250.0/24 only

# 3. Web Application Firewall (optional, if web apps exposed)
  SQL Injection: Block
  XSS Payloads: Block
  Path Traversal: Block
  Protocol Inspection: Enable
```

### 3.2 Access Control

```
# Identity & Access Management (IAM)

1. Service Accounts (Terraform/Ansible)
   - Least privilege principle
   - Credentials in secrets vault (not git)
   - Rotate quarterly
   - MFA not required (automated), but IP-restricted

2. Admin Access (Human operators)
   - Azure role: "Contributor" limited to resource group
   - AWS role: "PowerUserAccess" limited to VPC
   - On-prem: Domain Admin in HoneyPod Admins group
   - Bastion host requirement (jump server)
   - Session recording mandatory
   - MFA required

3. Audit Access (Observers/SIEM)
   - Azure role: "Reader" (read-only metrics)
   - AWS role: "ReadOnlyAccess"
   - SIEM: Ingest only, no write permissions
```

### 3.3 Encryption

```
At-Rest Encryption:
  - Azure: Enable disk encryption with customer-managed keys
  - AWS: Enable EBS encryption with KMS keys
  - On-prem: LUKS encryption for VM storage
  
In-Transit Encryption:
  - TLS 1.3 for all APIs
  - Signed certificates (not self-signed)
  - VPN for management traffic (site-to-site)
```

---

## Part 4: Deployment Validation Checklist

### Pre-Deployment (Go/No-Go)

- [ ] Budget and stakeholder approval signed off
- [ ] Network design reviewed by network engineer
- [ ] Security architecture reviewed by InfoSec
- [ ] Change control ticket created (on-prem)
- [ ] Runbook documented and reviewed
- [ ] Backup/DR plan documented
- [ ] Team trained on operational procedures
- [ ] Successful test deployment in staging

### Post-Deployment (Validation)

```bash
# Automated Validation Script

#!/bin/bash

echo "HoneyPod Production Deployment Validation"
echo "=========================================="

# 1. Infrastructure
echo "[1/10] Verifying infrastructure..."
terraform -chdir=terraform plan -var-file=vars.tfvars > /tmp/plan.out
if [ $? -eq 0 ]; then echo "✓ Terraform state OK"; else echo "✗ FAILED"; exit 1; fi

# 2. Connectivity
echo "[2/10] Testing network connectivity..."
for ip in $(terraform -chdir=terraform output -json | jq -r '.vm_ips[]'); do
  ping -c 1 $ip > /dev/null && echo "✓ $ip reachable" || echo "✗ $ip unreachable"
done

# 3. Ansible Connectivity
echo "[3/10] Testing Ansible connectivity..."
ansible -i ansible/inventory/hosts-prod all -m ping && echo "✓ Ansible OK" || echo "✗ Ansible FAILED"

# 4. SIEM Ingestion
echo "[4/10] Verifying SIEM log ingestion..."
curl -s localhost:9200/_cat/indices | grep -q "siem-" && echo "✓ SIEM indices OK" || echo "✗ SIEM FAILED"

# 5. Deception Engagement
echo "[5/10] Checking honeypot services..."
nmap -p 21,22,25,445,3306,5432 localhost | grep -q "open" && echo "✓ Honeypots listening" || echo "✗ Honeypots FAILED"

# 6. Database Connectivity
echo "[6/10] Verifying database..."
psql -h localhost -U honeypod_user -d honeypod_db -c "SELECT version();" && echo "✓ Database OK" || echo "✗ Database FAILED"

# 7. Caldera Activation
echo "[7/10] Checking Caldera C2..."
curl -s http://localhost:8888 | grep -q "CALDERA" && echo "✓ Caldera OK" || echo "✗ Caldera FAILED"

# 8. SSL/TLS Validation
echo "[8/10] Validating SSL certificates..."
echo | openssl s_client -servername $(hostname -f) -connect localhost:443 2>/dev/null | grep -q "Verify return code" && echo "✓ SSL OK" || echo "✗ SSL FAILED"

# 9. Backup Validation
echo "[9/10] Testing backups..."
[ -d "/backup/latest" ] && echo "✓ Backup location OK" || echo "✗ Backup FAILED"

# 10. Security Baseline
echo "[10/10] Running security baseline..."
openscap scan --profile standard /root/honeypod-stig.xml > /tmp/stig-report.html && echo "✓ STIG scan done" || echo "✗ STIG FAILED"

echo "=========================================="
echo "Validation Complete!"
```

---

## Part 5: Operational Procedures

### Backup & Recovery

```bash
# Daily Backup (3-2-1 Rule: 3 copies, 2 different media, 1 offsite)

#!/bin/bash
BACKUP_PATH="/mnt/backup/honeypod"
OFFSITE_DEST="s3://honeypod-backups/prod"

# 1. Full system snapshot
terraform -chdir=terraform state pull > ${BACKUP_PATH}/terraform-state-$(date +%Y%m%d).json

# 2. Database backup
pg_dump -h localhost -U honeypod_user honeypod_db | \
  gzip > ${BACKUP_PATH}/database-$(date +%Y%m%d).sql.gz

# 3. Configuration backup
tar -czf ${BACKUP_PATH}/config-$(date +%Y%m%d).tar.gz /etc/honeypod /etc/ansible

# 4. VM snapshot (Hyper-V)
Get-VM | Checkpoint-VM -SnapshotName "prod-$(date +%Y%m%d-%H%M%S)" -AsJob

# 5. S3 replication (offsite)
aws s3 sync ${BACKUP_PATH} ${OFFSITE_DEST} --storage-class GLACIER_IR

# 6. Verify backup integrity
sha256sum ${BACKUP_PATH}/* > ${BACKUP_PATH}/checksums.txt
```

### Scaling & Capacity Planning

```
Metrics to Monitor:
  - CPU utilization across hosts > 70% → scale
  - Memory utilization > 80% → add RAM or scale horizontally
  - Disk I/O > 80% → faster storage or separate I/O bonds
  - Network saturation > 70% → 10Gbps consolidation or separate VLANs
  - VM density > 15 VMs per core → oversub risk
  
Scaling Actions:
  - Vertical: Add CPU cores, RAM, storage (requires maintenance window)
  - Horizontal: Add hypervisor node (no downtime if clustered)
  - Multi-region: Distribute across Azure regions (geo-redundancy)
```

### Change Management

```
Change Process:
1. Create issue/ticket with: change description, risk assessment, rollback plan
2. Test in staging environment (mirror of production)
3. Schedule maintenance window (low-impact time)
4. Notify stakeholders 48 hours before
5. Execute change with runbook
6. Verify post-change (validation checklist)
7. Document results in ticket
8. Get sign-off from change board
```

---

## Part 6: Cost Estimation & ROI

### Azure Cost Model (Annual)

| Component | Monthly | Annual |
|-----------|---------|--------|
| VMs (10x D4s_v3) | $800 | $9,600 |
| Storage (5TB) | $250 | $3,000 |
| Networking | $200 | $2,400 |
| Backup | $300 | $3,600 |
| Log Analytics | $500 | $6,000 |
| **Total** | **$2,060** | **$24,720** |

### AWS Cost Model (Annual)

| Component | Monthly | Annual |
|-----------|---------|--------|
| EC2 (10x t3.xlarge) | $900 | $10,800 |
| EBS Storage (5TB) | $300 | $3,600 |
| Data Transfer | $150 | $1,800 |
| RDS (PostgreSQL) | $400 | $4,800 |
| CloudWatch | $200 | $2,400 |
| **Total** | **$1,950** | **$23,400** |

### On-Premises Cost Model (Year 1)

| Component | Cost |
|-----------|------|
| Hardware (3 nodes @ $40K ea.) | $120,000 |
| Network Infrastructure | $30,000 |
| Storage (SAN) | $50,000 |
| Licensing | $15,000 |
| Installation/Setup | $20,000 |
| **Year 1 Total** | **$235,000** |

| Component | Annual (Year 2+) |
|-----------|------------------|
| Power/Cooling | $12,000 |
| Maintenance | $15,000 |
| Upgrades | $10,000 |
| Staff (0.5 FTE) | $60,000 |
| **Ongoing Cost** | **$97,000/year** |

---

## Part 7: Disaster Recovery Plan

### RTO/RPO Targets

```
Low Criticality (Lab only):
  RTO: 24 hours
  RPO: 24 hours
  Recovery: Manual restoration from S3/backup

Medium Criticality (Production + Lab):
  RTO: 4 hours
  RPO: 1 hour
  Recovery: Automated failover to secondary Azure region

High Criticality (Mission-critical SIEM):
  RTO: 15 minutes
  RPO: 5 minutes
  Recovery: Active-active multi-region replication
```

### Failover Procedure

```bash
#!/bin/bash
# Failover from Primary (eus2) to Secondary (centralus)

# 1. Check primary region status
curl -s https://primary-region-api.honeypod.internal/health

# 2. If down, trigger DNS failover
aws route53 change-resource-record-sets --hosted-zone-id Z123456 \
  --change-batch "{\"Changes\":[{\"Action\":\"UPSERT\",\"ResourceRecordSet\":{\"Name\":\"api.honeypod.internal\",\"Type\":\"A\",\"TTL\":60,\"ResourceRecords\":[{\"Value\":\"secondary-ip\"}]}}]}"

# 3. Scale up secondary region
terraform -chdir=terraform/secondary apply -auto-approve

# 4. Restore databases from backup
pg_restore --host secondary-db --database honeypod_db /backups/database.sql.gz

# 5. Verify secondary region operational
ansible -i secondary-inventory.ini all -m ping

# 6. Notify stakeholders
echo "FAILOVER COMPLETE: Systems now operating from $(hostname)" | mail -s "HoneyPod Failover Alert" ops@company.com
```

---

## Appendix A: Quick Reference

### Deployment Commands

```bash
# Azure Production
terraform apply -var-file=terraform-azure-prod.tfvars -auto-approve

# AWS Production
export AWS_REGION=us-east-1
terraform apply -var-file=terraform-aws-prod.tfvars -auto-approve

# On-Premises
terraform apply -var-file=hyperv-prod.tfvars -auto-approve

# Post-Deployment
python3 scripts/generate-inventory.py > inventory/hosts-prod
ansible-playbook -i inventory/hosts-prod site.yml --tags hardening,siem-agent
```

### Rollback Commands

```bash
# If deployment fails
terraform destroy -var-file=<environment>.tfvars -auto-approve

# Restore from backup
pg_restore --clean --if-exists --dbname honeypod_db backup-latest.sql
tar -xzf config-backup.tar.gz -C /

# Resync Ansible inventory
ansible-inventory -i inventory/hosts-prod --list > hosts-prod.json
```

---

**Next Steps:**
1. Complete the Pre-Deployment Assessment (Part 1)
2. Choose deployment platform and follow platform-specific guide (Part 2)
3. Apply security hardening configuration (Part 3)
4. Execute validation checklist after deployment (Part 4)
5. Implement operational procedures (Part 5)

**Questions?** Contact: DevOps/InfoSec Team
