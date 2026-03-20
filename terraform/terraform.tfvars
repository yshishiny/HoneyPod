# ============================================================================
# HoneyPod Terraform Configuration - Hyper-V Local Deployment
# ============================================================================
# This configuration deploys HoneyPod to local Hyper-V.
# Modify values below according to your environment.
#
# BEFORE RUNNING:
# 1. Create VM templates: Windows2022-Template, Windows10-Template, Ubuntu22-Template
# 2. Create vSwitches on Hyper-V host (or Terraform will create them)
# 3. Set vm_storage_path to where you want VM disks stored
# ============================================================================

# ============================================================================
# Hyper-V Connection Configuration
# ============================================================================
# For local host connections, leave these blank (uses current user credentials)
# For remote host, uncomment and set host IP/FQDN and credentials

hyperv_host = ""
hyperv_user = ""
hyperv_password = ""
hyperv_https = true
hyperv_insecure = true
hyperv_timeout = 300

# ============================================================================
# VM Storage Locations
# ============================================================================
# Create these directories before running terraform apply:
# - mkdir C:\Hyper-V\VMs
# - mkdir C:\Hyper-V\Templates

vm_storage_path = "C:\\Hyper-V\\VMs"
vm_templates_path = "C:\\Hyper-V\\Templates"

# ============================================================================
# Lab Configuration
# ============================================================================
lab_domain = "corp.local"
lab_timezone = "UTC"
environment = "lab"
project = "HoneyPod"

# ============================================================================
# Server VM Configuration (Domain Controller)
# ============================================================================
# Recommended: 4GB RAM, 4 vCPUs for lab DC
server_memory = 4096
server_vcpus = 4

# ============================================================================
# Endpoint VM Configuration (Windows 10 Clients)
# ============================================================================
# Recommended: 2GB RAM, 2 vCPUs per endpoint
endpoint_memory = 2048
endpoint_vcpus = 2

# ============================================================================
# SIEM Server Configuration (ELK Stack)
# ============================================================================
# Recommended: 8GB RAM, 4 vCPUs for log aggregation/analysis
siem_memory = 8192
siem_vcpus = 4

# ============================================================================
# Caldera C2 Server Configuration
# ============================================================================
# Recommended: 2GB RAM, 2 vCPUs for attack simulation
caldera_memory = 2048
caldera_vcpus = 2

# ============================================================================
# Deception Layer Configuration (Honeypots)
# ============================================================================
# Recommended: 1GB RAM, 1 vCPU for lightweight honeypots
deception_memory = 1024
deception_vcpus = 1

# ============================================================================
# VM Wait Configuration
# ============================================================================
# Wait for VMs to boot and acquire IP before Terraform completes
vm_wait_for_state = "Running"
vm_wait_for_ip = true

# ============================================================================
# Network Configuration
# ============================================================================
# Enable VLAN isolation between security zones
enable_vlan_isolation = true
network_nat_enabled = false

# ============================================================================
# TOTAL LAB REQUIREMENTS
# ============================================================================
# 6 VMs deployed:
# - 1x Domain Controller (Windows Server 2022)      : 4GB + 4 vCPU
# - 2x Endpoints (Windows 10)                       : 2GB + 2 vCPU each (4GB + 4 vCPU total)
# - 1x SIEM (Ubuntu 22)                             : 8GB + 4 vCPU
# - 1x Caldera C2 (Ubuntu 22)                       : 2GB + 2 vCPU
# - 1x Honeypots (Ubuntu 22)                        : 1GB + 1 vCPU
# ============================================================================
# TOTAL: ~19GB RAM + ~17 vCPUs
# Minimum recommended host hardware: 32GB RAM, 16+ vCPUs
# ============================================================================


# Options: "simplified" (5-6 VMs) or "full" (12 VMs)
deployment_type = "simplified"

# Azure credentials (LEAVE EMPTY for Hyper-V)
# Only fill these if deploying to Azure instead
azure_subscription_id = ""
azure_client_id = ""
azure_client_secret = ""
azure_tenant_id = ""
azure_region = "eastus2"
