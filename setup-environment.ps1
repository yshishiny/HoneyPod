#!/usr/bin/env pwsh
<#
.SYNOPSIS
HoneyPod Environment Setup Script

.DESCRIPTION
Sets up PATH, verifies prerequisites, and initializes the deployment environment

.NOTES
Run with: powershell -ExecutionPolicy Bypass -File setup-environment.ps1
#>

Write-Host "`n" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "HoneyPod Environment Setup" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Add Terraform to PATH
Write-Host "[1/5] Configuring PATH for tools..." -ForegroundColor Blue
$terraformPath = "C:\terraform"
$pythonPath = "C:\Users\YasserElshishiny\AppData\Local\Programs\Python\Python311\Scripts"

if (Test-Path $terraformPath) {
    if ($env:Path -notmatch [regex]::Escape($terraformPath)) {
        $env:Path = "$env:Path;$terraformPath"
        Write-Host "  Added Terraform to PATH" -ForegroundColor Green
    } else {
        Write-Host "  Terraform already in PATH" -ForegroundColor Green
    }
} else {
    Write-Host "  Warning: Terraform directory not found at $terraformPath" -ForegroundColor Yellow
}

if (Test-Path $pythonPath) {
    if ($env:Path -notmatch [regex]::Escape($pythonPath)) {
        $env:Path = "$env:Path;$pythonPath"
        Write-Host "  Added Python Scripts to PATH" -ForegroundColor Green
    } else {
        Write-Host "  Python Scripts already in PATH" -ForegroundColor Green
    }
} else {
    Write-Host "  Warning: Python Scripts directory not found" -ForegroundColor Yellow
}

# Verify Terraform
Write-Host "`n[2/5] Verifying Terraform..." -ForegroundColor Blue
try {
    $tfVersion = terraform -version 2>$null | Select-Object -First 1
    if ($tfVersion) {
        Write-Host "  OK - $tfVersion" -ForegroundColor Green
    }
} catch {
    Write-Host "  ERROR - Terraform not accessible" -ForegroundColor Red
}

# Verify Ansible
Write-Host "`n[3/5] Verifying Ansible..." -ForegroundColor Blue
try {
    $pythonCmd = "C:\Users\YasserElshishiny\AppData\Local\Programs\Python\Python311\python.exe"
    $ansibleVersion = & $pythonCmd -c "from ansible.release import __version__; print('Ansible', __version__)" 2>$null
    if ($ansibleVersion) {
        Write-Host "  OK - $ansibleVersion" -ForegroundColor Green
    } else {
        Write-Host "  WARNING - Ansible not found" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  WARNING - Ansible check failed" -ForegroundColor Yellow
}

# Verify Docker
Write-Host "`n[4/5] Verifying Docker..." -ForegroundColor Blue
try {
    $dockerVersion = docker --version 2>$null
    if ($dockerVersion) {
        Write-Host "  OK - $dockerVersion" -ForegroundColor Green
    }
} catch {
    Write-Host "  ERROR - Docker not accessible" -ForegroundColor Red
}

# Verify Git
Write-Host "`n[5/5] Verifying Git..." -ForegroundColor Blue
try {
    $gitVersion = git --version 2>$null
    if ($gitVersion) {
        Write-Host "  OK - $gitVersion" -ForegroundColor Green
    }
} catch {
    Write-Host "  ERROR - Git not accessible" -ForegroundColor Red
}

Write-Host "`n======================================" -ForegroundColor Cyan
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "`nNext Steps:" -ForegroundColor Cyan
Write-Host "1. Configure terraform.tfvars in terraform/ directory"
Write-Host "2. Run: terraform -chdir=terraform init"
Write-Host "3. Run: terraform -chdir=terraform plan"
Write-Host "4. Run: terraform -chdir=terraform apply"
Write-Host ""
