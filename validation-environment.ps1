#!/usr/bin/env pwsh
# HoneyPod Local Environment Validator

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "HoneyPod Environment Validation" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$passCount = 0
$allChecks = @()

# 1. Check Hyper-V Enabled
Write-Host "[1/8] Checking Hyper-V Status..." -ForegroundColor Blue
try {
    $hyperv = Get-WindowsOptionalFeature -FeatureName Microsoft-Hyper-V-All -Online -ErrorAction SilentlyContinue
    if ($hyperv.State -eq "Enabled") {
        Write-Host "✓ Hyper-V is ENABLED" -ForegroundColor Green
        $allChecks += $true
    } else {
        Write-Host "✗ Hyper-V is NOT enabled. Run: Enable-WindowsOptionalFeature -FeatureName Microsoft-Hyper-V-All -Online -All" -ForegroundColor Red
        $allChecks += $false
    }
} catch {
    Write-Host "⚠ Could not check Hyper-V status" -ForegroundColor Yellow
    $allChecks += $false
}

# 2. Check RAM
Write-Host "`n[2/8] Checking Available RAM..." -ForegroundColor Blue
$ram = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB)
Write-Host "Available: $ram GB" -ForegroundColor Cyan
if ($ram -ge 16) {
    Write-Host "✓ RAM sufficient for simplified deployment" -ForegroundColor Green
    $allChecks += $true
} elseif ($ram -ge 8) {
    Write-Host "⚠ Limited RAM - will need minimal VM configuration" -ForegroundColor Yellow
    $allChecks += $true
} else {
    Write-Host "✗ Insufficient RAM (minimum 8GB required)" -ForegroundColor Red
    $allChecks += $false
}

# 3. Check Disk Space
Write-Host "`n[3/8] Checking Disk Space..." -ForegroundColor Blue
$disk = Get-Volume | Where-Object {$_.DriveLetter -eq 'C'} | Select-Object -ExpandProperty SizeRemaining
$diskGB = [math]::Round($disk / 1GB)
Write-Host "Available: $diskGB GB" -ForegroundColor Cyan
if ($diskGB -ge 300) {
    Write-Host "✓ Disk space sufficient" -ForegroundColor Green
    $allChecks += $true
} else {
    Write-Host "⚠ Limited disk space (minimum 300GB recommended, have $diskGB GB)" -ForegroundColor Yellow
    $allChecks += $true
}

# 4. Check Terraform
Write-Host "`n[4/8] Checking Terraform..." -ForegroundColor Blue
try {
    $tfVersion = terraform -version 2>$null | Select-Object -First 1
    if ($tfVersion) {
        Write-Host "✓ Terraform installed: $tfVersion" -ForegroundColor Green
        $allChecks += $true
    } else {
        Write-Host "✗ Terraform not found in PATH" -ForegroundColor Red
        Write-Host "  Install from: https://www.terraform.io/downloads" -ForegroundColor Yellow
        $allChecks += $false
    }
} catch {
    Write-Host "✗ Terraform not found" -ForegroundColor Red
    $allChecks += $false
}

# 5. Check Ansible
Write-Host "`n[5/8] Checking Ansible..." -ForegroundColor Blue
try {
    $ansibleVersion = ansible --version 2>$null | Select-Object -First 1
    if ($ansibleVersion) {
        Write-Host "✓ Ansible installed: $ansibleVersion" -ForegroundColor Green
        $allChecks += $true
    } else {
        Write-Host "✗ Ansible not found" -ForegroundColor Red
        Write-Host "  Install via: pip install ansible" -ForegroundColor Yellow
        $allChecks += $false
    }
} catch {
    Write-Host "✗ Ansible not found" -ForegroundColor Red
    $allChecks += $false
}

# 6. Check Docker & Docker Compose
Write-Host "`n[6/8] Checking Docker..." -ForegroundColor Blue
try {
    $dockerVersion = docker --version 2>$null
    if ($dockerVersion) {
        Write-Host "✓ Docker installed: $dockerVersion" -ForegroundColor Green
        $allChecks += $true
    } else {
        Write-Host "✗ Docker not found" -ForegroundColor Red
        Write-Host "  Install from: https://www.docker.com/products/docker-desktop" -ForegroundColor Yellow
        $allChecks += $false
    }
} catch {
    Write-Host "✗ Docker not found" -ForegroundColor Red
    $allChecks += $false
}

# 7. Check Git
Write-Host "`n[7/8] Checking Git..." -ForegroundColor Blue
try {
    $gitVersion = git --version 2>$null
    if ($gitVersion) {
        Write-Host "✓ Git installed: $gitVersion" -ForegroundColor Green
        $allChecks += $true
    } else {
        Write-Host "✗ Git not found" -ForegroundColor Red
        Write-Host "  Install from: https://git-scm.com/" -ForegroundColor Yellow
        $allChecks += $false
    }
} catch {
    Write-Host "✗ Git not found" -ForegroundColor Red
    $allChecks += $false
}

# 8. Check PowerShell Version
Write-Host "`n[8/8] Checking PowerShell..." -ForegroundColor Blue
$psVersion = $PSVersionTable.PSVersion.Major
Write-Host "PowerShell version: $psVersion" -ForegroundColor Cyan
if ($psVersion -ge 5) {
    Write-Host "✓ PowerShell version sufficient" -ForegroundColor Green
    $allChecks += $true
} else {
    Write-Host "⚠ Older PowerShell version" -ForegroundColor Yellow
    $allChecks += $true
}

# Summary
Write-Host "`n========================================" -ForegroundColor Cyan
$passCount = ($allChecks | Where-Object {$_ -eq $true}).Count
$totalCount = $allChecks.Count
Write-Host "Summary: $passCount/$totalCount checks passed" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

if ($passCount -eq $totalCount) {
    Write-Host "`n✓ Environment is ready for deployment!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n⚠ Some checks failed. Please install missing prerequisites." -ForegroundColor Yellow
    Write-Host "  See messages above for installation links." -ForegroundColor Yellow
    exit 1
}
