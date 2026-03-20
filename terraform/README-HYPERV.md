# HoneyPod Terraform Configuration - Hyper-V Deployment

Complete Terraform configuration for deploying HoneyPod on local Hyper-V infrastructure.

## Quick Start

```powershell
# 1. Prepare Hyper-V Environment (run as Administrator)
.\prepare-hyperv-environment.ps1 -Action setup

# 2. Configure Terraform
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
# Edit terraform/terraform.tfvars with your settings

# 3. Deploy Infrastructure
cd terraform
terraform init
terraform plan
terraform apply

# 4. Extract inventory and configure Ansible
terraform output -json vm_ansible_hosts > ../ansible/inventory/hosts-hyperv.json
```

## Files Overview

### Core Terraform Files

**[main.tf](main.tf)**
- Hyper-V provider configuration
- Local variables defining all 6 VMs (DC, 2x Endpoints, SIEM, Caldera, Honeypots)
- VM mapping with memory, vCPU, IP, and zone assignments
- Supporting network functions

**[networks.tf](networks.tf)**
- 6 Virtual switches (one per security zone) with VLAN tagging
- Network configuration map for reference
- Supports: Server Zone, User Zone, Deception Zone, Security Zone, Simulation Zone

**[vms.tf](vms.tf)**
- Dynamic VM creation using `for_each` (scale-friendly)
- Network adapter configuration with static IPs and DNS
- Storage binding to template VHDX files
- Outputs: `vm_instances` and `vm_ansible_hosts` for provisioning

**[variables.tf](variables.tf)**
- Hyper-V connection parameters
- Lab configuration (domain, timezone)
- VM sizing for each role (memory, vCPUs)
- Network settings (VLAN isolation, NAT options)

**[terraform.tfvars](terraform.tfvars)**
- Default configuration for simplified local deployment
- 6 VMs: ~19GB RAM + ~17 vCPUs
- Paths: `C:\Hyper-V\VMs` (storage), `C:\Hyper-V\Templates` (templates)

**[terraform.tfvars.example](terraform.tfvars.example)**
- Comprehensive setup guide with explanations
- Hardware requirements and deployment steps

**[outputs.tf](outputs.tf)**
- Lab info, VM summary, network configuration
- Service endpoints (AD, SIEM, Caldera, Honeypots)
- Ansible inventory format output
- Deployment checklist

---

## Prerequisites

### Hyper-V Host Requirements

- **OS**: Windows 10/11 Pro/Enterprise or Windows Server 2016+
- **RAM**: 32GB minimum (48GB+ recommended)
- **CPU**: 16+ cores with virtualization enabled (Intel VT-x or AMD-V)
- **Storage**: 150GB+ SSD for VM disks
- **Network**: Isolated network for lab VMs (192.168.10.0/22)

### Software Prerequisites

1. **Hyper-V enabled** (Control Panel → Programs → Turn Windows features on/off)
2. **Terraform** v1.0+ (already installed in project)
3. **Ansible** 2.9+ (already installed in project)
4. **Git** (for version control)

### VM Template Requirements

Create three VHDX template files in `C:\Hyper-V\Templates\`:

1. **Windows2022-Template.vhdx** (minimum 40GB)
   - Windows Server 2022 Datacenter
   - Gen2 VM format
   - Network configured (DHCP initially)

2. **Windows10-Template.vhdx** (minimum 30GB)
   - Windows 10 Pro/Enterprise (22H2)
   - Gen2 VM format
   - Network configured (DHCP initially)

3. **Ubuntu22-Template.vhdx** (minimum 20GB)
   - Ubuntu 22.04 LTS
   - cloud-init compatible
   - SSH server enabled

**To create templates:**
```powershell
# 1. Create base VMs with appropriate OS
# 2. Install necessary tools (SSH, cloud-init, etc.)
# 3. Generalize using sysprep (Windows) or cloud-init clean
# 4. Export VHDX files to C:\Hyper-V\Templates\
# 5. Rename to template names above
```

---

## Deployment Architecture

### Virtual Network Layout

```
┌─────────────────────────────────────────────────────────┐
│                    Hyper-V Host                         │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌────────────────┐  ┌────────────────┐               │
│  │ Server Zone    │  │ User Zone      │               │
│  │ 192.168.20.0   │  │ 192.168.10.0   │               │
│  │ VLAN: 101      │  │ VLAN: 102      │               │
│  │                │  │                │               │
│  │ • DC-01 (AD)   │  │ • EP-01        │               │
│  │   192.168.20.10│  │   192.168.10.11│               │
│  │ • 4GB / 4 vCPU │  │ • EP-02        │               │
│  │                │  │   192.168.10.12│               │
│  │                │  │ • 2GB / 2 vCPU │               │
│  └────────────────┘  └────────────────┘               │
│                                                         │
│  ┌────────────────┐  ┌────────────────┐               │
│  │ Security Zone  │  │ Simulation Zone│               │
│  │ 192.168.50.0   │  │ 192.168.60.0   │               │
│  │ VLAN: 104      │  │ VLAN: 105      │               │
│  │                │  │                │               │
│  │ • SIEM-01      │  │ • Caldera-01   │               │
│  │   ELK Stack    │  │   C2 Platform  │               │
│  │   192.168.50.10│  │   192.168.60.10│               │
│  │ • 8GB / 4 vCPU │  │ • 2GB / 2 vCPU │               │
│  └────────────────┘  └────────────────┘               │
│                                                         │
│  ┌────────────────┐                                    │
│  │ Deception Zone │                                    │
│  │ 192.168.40.0   │                                    │
│  │ VLAN: 103      │                                    │
│  │                │                                    │
│  │ • Deception-01 │                                    │
│  │   Honeypots    │                                    │
│  │   192.168.40.10│                                    │
│  │ • 1GB / 1 vCPU │                                    │
│  └────────────────┘                                    │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### VM Configuration Summary

| VM | Role | OS | IP | Memory | vCPU | Zone |
|----|----|----|----|--------|------|------|
| dc-honeypod-01 | Domain Controller | Windows Server 2022 | 192.168.20.10 | 4GB | 4 | Server |
| ep-honeypod-01 | Endpoint | Windows 10 | 192.168.10.11 | 2GB | 2 | User |
| ep-honeypod-02 | Endpoint | Windows 10 | 192.168.10.12 | 2GB | 2 | User |
| siem-honeypod-01 | SIEM (ELK) | Ubuntu 22 | 192.168.50.10 | 8GB | 4 | Security |
| caldera-honeypod-01 | C2 Platform | Ubuntu 22 | 192.168.60.10 | 2GB | 2 | Simulation |
| deception-honeypod-01 | Honeypots | Ubuntu 22 | 192.168.40.10 | 1GB | 1 | Deception |

---

## Deployment Steps

### Step 1: Prepare Hyper-V Environment

```powershell
# Run as Administrator
cd "C:\Local Projects\HoneyPod"

# Check prerequisites and setup directories
.\prepare-hyperv-environment.ps1 -Action setup

# Verify setup
.\prepare-hyperv-environment.ps1 -Action check
```

### Step 2: Configure Terraform

```powershell
# Copy example to active config
cd terraform
cp terraform.tfvars.example terraform.tfvars

# Edit with your specific settings
notepad terraform.tfvars

# Validate configuration
terraform init
terraform validate
```

**Key settings to verify:**
- `vm_storage_path`: Directory for VM virtual disks
- `vm_templates_path`: Directory containing VHDX template files
- `server_memory`, `endpoint_memory`, etc.: Adjust if host specs differ

### Step 3: Review Deployment Plan

```powershell
# Generate and review the deployment plan
terraform plan -out=tfplan

# This will show:
# - 6 hyperv_machine_instance resources
# - 6 hyperv_vlan resources
# - Network configuration
```

### Step 4: Deploy Infrastructure

```powershell
# Deploy VMs
terraform apply tfplan

# Wait for completion (~5-10 minutes)
# Once complete, verify VMs:
Get-VM | Where-Object { $_.Name -like "*honeypod*" }
```

### Step 5: Generate Ansible Inventory

```powershell
# Extract VM information for Ansible
terraform output -json vm_ansible_hosts > ../ansible/inventory/hosts-hyperv.json

# View the output
terraform output vm_deployment
terraform output service_endpoints
```

---

## Verification

### Check VM Status

```powershell
# List all HoneyPod VMs
Get-VM | Where-Object { $_.Name -like "*honeypod*" } | Format-Table Name, State
```

### Verify Network Connectivity

```powershell
# From host, ping each VM (requires network access)
ping 192.168.20.10  # DC
ping 192.168.10.11  # EP-01
ping 192.168.50.10  # SIEM
```

### Check Virtual Switches

```powershell
# List created vSwitches
Get-VMSwitch | Where-Object { $_.Name -like "HoneyPod*" }
```

---

## Next Steps

### 1. Configure with Ansible

Once VMs are deployed:

```bash
# Update Ansible inventory
ansible-inventory -i ansible/inventory/hosts --list

# Run baseline configuration
ansible-playbook -i ansible/inventory/hosts ansible/site.yml

# Deploy specific roles
ansible-playbook -i ansible/inventory/hosts ansible/roles/hardening/tasks/main.yml
```

### 2. Deploy Security Tooling

On SIEM VM:
```bash
cd /opt/honeypod/security-tooling
docker-compose up -d
```

### 3. Configure Honeypots

On deception VM:
```bash
cd /opt/honeypod/deception-layer
./deploy.sh
```

### 4. Initialize Caldera

On Caldera VM:
```bash
curl -X POST http://192.168.60.10:8888/api/v2/admin/initialize
```

---

## Troubleshooting

### VMs won't boot
- Check template VHDX files exist in `C:\Hyper-V\Templates\`
- Verify VHDX files are Gen2 format
- Check available disk space on host

### Network issues
- Verify virtual switches exist: `Get-VMSwitch`
- Check VLAN configuration on switches
- Ensure host firewall allows traffic between VMs

### Terraform errors
```powershell
# Check Terraform logs
$env:TF_LOG="DEBUG"
terraform plan

# Validate syntax
terraform validate

# Reset state if needed
terraform state list
terraform destroy -auto-approve
```

### Ansible provisioning fails
- Verify SSH connectivity to VMs
- Check Ansible inventory: `ansible all -i hosts -m ping`
- Review Ansible logs: `ANSIBLE_DEBUG=1 ansible-playbook ...`

---

## Cleanup

### Remove All HoneyPod VMs

```powershell
# WARNING: This destroys all VMs
cd terraform
terraform destroy

# Or manually:
Get-VM | Where-Object { $_.Name -like "*honeypod*" } | Stop-VM -Force
Get-VM | Where-Object { $_.Name -like "*honeypod*" } | Remove-VM -Force

# Remove VM storage
Remove-Item -Recurse -Force C:\Hyper-V\VMs\*
```

---

## Advanced Configuration

### Add More VMs

Edit `main.tf` `locals.vms` map:

```hcl
locals {
  vms = {
    # ... existing ...
    ep03 = {
      name     = "ep-honeypod-03"
      template = "Windows10-Template"
      memory   = var.endpoint_memory
      vcpus    = var.endpoint_vcpus
      ip       = "192.168.10.13"
      zone     = "user"
    }
  }
}
```

### Modify Resource Allocation

Edit `terraform.tfvars`:

```hcl
server_memory = 8192  # Increase DC memory
endpoint_memory = 4096  # More memory per endpoint
```

### Change IP Scheme

Edit `main.tf` VM definitions and `networks.tf` subnet ranges.

---

## Security Considerations

1. **VLAN Isolation**: VMs are isolated by VLAN to simulate network segmentation
2. **No External Routes**: Lab network is isolated by default
3. **Credentials**: Set strong passwords in Ansible vault
4. **Network ACLs**: Implement using Windows Firewall on VMs
5. **Snapshot Isolation**: Create snapshots before scenarios for reset capability

---

## Performance Tips

1. **Disable snapshots** if storage is constrained: `enable_snapshots = false`
2. **Use SSD storage** for optimal VM performance
3. **Allocate sufficient memory** to host to avoid swapping
4. **Monitor resource usage**: `Get-VM | Measure-Object -Property MemoryAssigned -Sum`

---

## Additional Resources

- [Terraform Hyper-V Provider Docs](https://registry.terraform.io/providers/taliesins/hyperv/latest/docs)
- [Hyper-V Administration](https://docs.microsoft.com/en-us/windows-server/virtualization/hyper-v/hyper-v-technology-overview)
- [HoneyPod Documentation](../docs/)
- [Ansible Playbooks](../ansible/)

---

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review Terraform logs: `terraform show`
3. Check VM status: `Get-VM -ComputerName localhost`
4. Review Ansible execution: `ansible-playbook -i hosts site.yml -vvv`

---

**Last Updated**: March 2026
**Status**: Terraform Hyper-V deployment complete and ready for provisioning
