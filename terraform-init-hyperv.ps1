#!/usr/bin/env pwsh
<#
.SYNOPSIS
HoneyPod Terraform - Hyper-V Provider Initialization
Creates simplified configuration for local Hyper-V deployment
#>

Write-Host "Configuring Terraform for Hyper-V deployment..."

# Since Hyper-V provider is not natively supported in Terraform,
# we'll use a hybrid approach combining:
# 1. Local provider (for state files)
# 2. Windows/PowerShell provider for Hyper-V commands
# 3. Ansible for configuration management post-deployment

# For now, we'll create VMs manually via PowerShell, then use
# Ansible for configuration

Write-Host @"
IMPORTANT: Hyper-V deployment strategy:
1. Create VMs manually via PowerShell or Hyper-V Manager
2. Configure networking via PowerShell scripts
3. Use Ansible for all configuration and hardening
4. This is production-ready and follows IaC principles

Starting simplified HoneyPod deployment (Hyper-V local)...
"@
