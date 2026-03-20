#!/usr/bin/env pwsh
# HoneyPod Hyper-V Deployment Script
# Simplified deployment plan for local Hyper-V lab

param([switch]$DryRun = $false)

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "HoneyPod Hyper-V Deployment" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# VM Definitions
$VMs = @(
    @{ Name = "dc-honeypod-lab-01"; Role = "Domain Controller"; OS = "Windows"; Memory = "4GB"; CPUs = 4; IP = "192.168.1.10" }
    @{ Name = "ep-honeypod-lab-w01"; Role = "Windows Endpoint"; OS = "Windows"; Memory = "4GB"; CPUs = 4; IP = "192.168.1.20" }
    @{ Name = "ep-honeypod-lab-w02"; Role = "Windows Endpoint"; OS = "Windows"; Memory = "4GB"; CPUs = 4; IP = "192.168.1.21" }
    @{ Name = "srv-honeypod-lab-01"; Role = "App Server"; OS = "Linux"; Memory = "4GB"; CPUs = 4; IP = "192.168.1.30" }
    @{ Name = "siem-honeypod-lab-01"; Role = "SIEM (ELK)"; OS = "Linux"; Memory = "8GB"; CPUs = 4; IP = "192.168.1.50" }
    @{ Name = "c2-honeypod-lab-01"; Role = "C2 (Caldera)"; OS = "Linux"; Memory = "4GB"; CPUs = 4; IP = "192.168.1.60" }
)

Write-Host "[1/4] Validating Hyper-V..." -ForegroundColor Blue
try { Get-VMHost -ErrorAction Stop | Out-Null; Write-Host "  [OK]" -ForegroundColor Green }
catch { Write-Host "  [ERROR] Hyper-V not accessible" -ForegroundColor Red; exit 1 }

Write-Host "[2/4] Checking vSwitch..." -ForegroundColor Blue
$switch = Get-VMSwitch -Name "vSwitch-HoneyPod-Lab" -ErrorAction SilentlyContinue
if ($switch) { Write-Host "  [OK] vSwitch found" -ForegroundColor Green }
else { Write-Host "  [WARN] Create with: New-VMSwitch -Name 'vSwitch-HoneyPod-Lab' -SwitchType Internal" -ForegroundColor Yellow }

Write-Host "[3/4] VM Deployment Plan:" -ForegroundColor Blue
foreach ($vm in $VMs) {
    Write-Host "  - $($vm.Name) | $($vm.Role) | Memory: $($vm.Memory) | IP: $($vm.IP)"
}

Write-Host "[4/4] Generating Ansible inventory..." -ForegroundColor Blue

$timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
$inventory = @"
# HoneyPod Lab Inventory - Auto Generated $timestamp

[domain_controllers]
dc-honeypod-lab-01 ansible_host=192.168.1.10 ansible_connection=winrm

[windows_endpoints]
ep-honeypod-lab-w01 ansible_host=192.168.1.20 ansible_connection=winrm
ep-honeypod-lab-w02 ansible_host=192.168.1.21 ansible_connection=winrm

[windows_servers:children]
domain_controllers
windows_endpoints

[linux_servers]
srv-honeypod-lab-01 ansible_host=192.168.1.30 ansible_user=ubuntu
siem-honeypod-lab-01 ansible_host=192.168.1.50 ansible_user=ubuntu
c2-honeypod-lab-01 ansible_host=192.168.1.60 ansible_user=ubuntu

[siem]
siem-honeypod-lab-01

[honeypod_lab:children]
windows_servers
linux_servers

[all:vars]
domain_name=corp.local
siem_server=192.168.1.50
vswitch=vSwitch-HoneyPod-Lab
"@

$invPath = "c:\Local Projects\HoneyPod\ansible\inventory\hosts-lab"
$inventory | Set-Content -Path $invPath -Force
Write-Host "  [OK] Saved to: $invPath" -ForegroundColor Green

Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Deployment Ready" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next: Run Ansible configuration playbooks" -ForegroundColor Cyan
