# ============================================================================
# HoneyPod Terraform - Hyper-V Environment Preparation Script
# ============================================================================
# Prepares Hyper-V host for HoneyPod deployment
# Usage: powershell -NoProfile -ExecutionPolicy Bypass -File prepare-hyperv-environment.ps1 -Action setup
# ============================================================================

#Requires -RunAsAdministrator

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("check", "setup", "cleanup")]
    [string]$Action = "check",
    
    [Parameter(Mandatory=$false)]
    [string]$StoragePath = "C:\Hyper-V\VMs",
    
    [Parameter(Mandatory=$false)]
    [string]$TemplatesPath = "C:\Hyper-V\Templates"
)

# ============================================================================
# Colors and Logging
# ============================================================================
function Write-Status {
    param([string]$Message, [string]$Type = "Info")
    $colors = @{
        "Success" = "Green"
        "Error"   = "Red"
        "Warning" = "Yellow"
        "Info"    = "Cyan"
    }
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] $Message" -ForegroundColor $colors[$Type]
}

# ============================================================================
# Check Prerequisites
# ============================================================================
function Check-Prerequisites {
    Write-Status "Checking Hyper-V prerequisites..." "Info"
    
    # Check if running as Administrator
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    if (-not $isAdmin) {
        Write-Status "ERROR: This script requires Administrator privileges" "Error"
        exit 1
    }
    Write-Status "✓ Running as Administrator" "Success"
    
    # Check if Hyper-V is enabled
    $hvFeature = Get-WindowsOptionalFeature -FeatureName "Microsoft-Hyper-V" -Online
    if ($hvFeature.State -ne "Enabled") {
        Write-Status "ERROR: Hyper-V is not enabled" "Error"
        Write-Status "Enable it with: Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V" "Warning"
        exit 1
    }
    Write-Status "✓ Hyper-V is enabled" "Success"
    
    # Check Terraform installation
    $tfPath = Get-Command terraform -ErrorAction SilentlyContinue
    if (-not $tfPath) {
        Write-Status "WARNING: Terraform not found in PATH" "Warning"
    } else {
        $tfVersion = terraform --version | Select-Object -First 1
        Write-Status "✓ Terraform found: $tfVersion" "Success"
    }
    
    # Check Ansible installation
    $ansiblePath = Get-Command ansible -ErrorAction SilentlyContinue
    if (-not $ansiblePath) {
        Write-Status "WARNING: Ansible not found in PATH" "Warning"
    } else {
        $ansibleVersion = ansible --version | Select-Object -First 1
        Write-Status "✓ Ansible found: $ansibleVersion" "Success"
    }
    
    # Check available system resources
    $sysInfo = Get-ComputerInfo
    $totalMem = [math]::Round(($sysInfo.CsTotalPhysicalMemory / 1GB), 2)
    $cpuCount = (Get-CimInstance -ClassName Win32_Processor).NumberOfCores
    
    Write-Status "System Resources:" "Info"
    Write-Status "  Total RAM: $totalMem GB" "Info"
    Write-Status "  CPU Cores: $cpuCount" "Info"
    
    if ($totalMem -lt 32) {
        Write-Status "WARNING: 32GB RAM recommended, you have $totalMem GB" "Warning"
    } else {
        Write-Status "✓ Sufficient RAM available" "Success"
    }
    
    if ($cpuCount -lt 16) {
        Write-Status "WARNING: 16+ CPU cores recommended, you have $cpuCount" "Warning"
    } else {
        Write-Status "✓ Sufficient CPU cores available" "Success"
    }
}

# ============================================================================
# Setup Storage Directories
# ============================================================================
function Setup-Directories {
    Write-Status "Setting up storage directories..." "Info"
    
    # Create storage paths
    @($StoragePath, $TemplatesPath) | ForEach-Object {
        if (-not (Test-Path $_)) {
            New-Item -ItemType Directory -Path $_ -Force | Out-Null
            Write-Status "✓ Created directory: $_" "Success"
        } else {
            Write-Status "✓ Directory exists: $_" "Success"
        }
    }
    
    # Set appropriate permissions
    icacls $StoragePath /grant "${env:USERNAME}:(OI)(CI)F" | Out-Null
    icacls $TemplatesPath /grant "${env:USERNAME}:(OI)(CI)R" | Out-Null
    Write-Status "✓ Set directory permissions" "Success"
}

# ============================================================================
# Create Virtual Switches
# ============================================================================
function Create-VirtualSwitches {
    Write-Status "Creating virtual switches..." "Info"
    
    $switches = @(
        @{ Name = "HoneyPod-Lab-Range"; VLAN = 100 }
        @{ Name = "HoneyPod-Server-Zone"; VLAN = 101 }
        @{ Name = "HoneyPod-User-Zone"; VLAN = 102 }
        @{ Name = "HoneyPod-Deception-Zone"; VLAN = 103 }
        @{ Name = "HoneyPod-Security-Zone"; VLAN = 104 }
        @{ Name = "HoneyPod-Simulation-Zone"; VLAN = 105 }
    )
    
    foreach ($switch in $switches) {
        $existing = Get-VMSwitch -Name $switch.Name -ErrorAction SilentlyContinue
        if ($existing) {
            Write-Status "✓ Switch already exists: $($switch.Name)" "Success"
        } else {
            try {
                New-VMSwitch -Name $switch.Name -SwitchType Private | Out-Null
                Write-Status "✓ Created switch: $($switch.Name)" "Success"
            } catch {
                Write-Status "ERROR creating switch $($switch.Name): $_" "Error"
            }
        }
    }
}

# ============================================================================
# Test Terraform Configuration
# ============================================================================
function Test-TerraformConfig {
    Write-Status "Testing Terraform configuration..." "Info"
    
    if (-not (Test-Path "terraform.tfvars")) {
        Write-Status "WARNING: terraform.tfvars not found" "Warning"
        Write-Status "Copy terraform.tfvars.example to terraform.tfvars and configure it" "Warning"
        return
    }
    
    try {
        terraform init -upgrade
        Write-Status "✓ Terraform initialized successfully" "Success"
        
        terraform validate
        Write-Status "✓ Terraform configuration is valid" "Success"
        
        terraform plan -out=tfplan -no-color
        Write-Status "✓ Terraform plan generated (review tfplan)" "Success"
    } catch {
        Write-Status "ERROR: Terraform validation failed: $_" "Error"
    }
}

# ============================================================================
# Display VM Inventory
# ============================================================================
function Show-VMStatus {
    Write-Status "Current Hyper-V VMs:" "Info"
    
    $vms = Get-VM | Where-Object { $_.Name -like "honeypod-*" -or $_.Name -like "*honeypod*" }
    if ($vms.Count -eq 0) {
        Write-Status "No HoneyPod VMs found" "Warning"
    } else {
        $vms | Select-Object Name, State, MemoryAssigned, ProcessorCount | Format-Table
    }
}

# ============================================================================
# Cleanup
# ============================================================================
function Cleanup-Deployment {
    Write-Status "WARNING: This will destroy all HoneyPod VMs!" "Warning"
    $confirm = Read-Host "Type 'yes' to confirm deletion"
    
    if ($confirm -ne "yes") {
        Write-Status "Cleanup cancelled" "Info"
        return
    }
    
    $vms = Get-VM | Where-Object { $_.Name -like "*honeypod*" }
    foreach ($vm in $vms) {
        Write-Status "Stopping and removing VM: $($vm.Name)" "Warning"
        Stop-VM -VM $vm -Force -ErrorAction SilentlyContinue
        Remove-VM -VM $vm -Force -ErrorAction SilentlyContinue
    }
    
    Write-Status "Cleanup complete" "Success"
}

# ============================================================================
# Main Execution
# ============================================================================
Write-Status "HoneyPod Hyper-V Environment Preparation" "Info"
Write-Status "Action: $Action" "Info"

switch ($Action) {
    "check" {
        Check-Prerequisites
        Setup-Directories
        Show-VMStatus
    }
    "setup" {
        Check-Prerequisites
        Setup-Directories
        Create-VirtualSwitches
        Write-Status "Setup complete. Next:" "Success"
        Write-Status "1. Copy terraform.tfvars.example to terraform.tfvars" "Info"
        Write-Status "2. Edit terraform.tfvars with your configuration" "Info"
        Write-Status "3. Run: terraform init" "Info"
        Write-Status "4. Run: terraform plan" "Info"
        Write-Status "5. Run: terraform apply" "Info"
    }
    "test" {
        Test-TerraformConfig
    }
    "cleanup" {
        Cleanup-Deployment
    }
    default {
        Check-Prerequisites
    }
}

Write-Status "Done" "Success"
