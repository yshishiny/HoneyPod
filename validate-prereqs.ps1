#!/usr/bin/env pwsh
# HoneyPod Environment Validator - Simplified

Write-Host "========================================"
Write-Host "HoneyPod Prerequisites Validation"
Write-Host "========================================"
Write-Host ""

$checks = @()
$installed_count = 0

# 1. Hyper-V Check
Write-Host "[1/8] Checking Hyper-V..." -ForegroundColor Blue
try {
    $hyperv = Get-WindowsOptionalFeature -FeatureName Microsoft-Hyper-V-All -Online -ErrorAction SilentlyContinue
    if ($hyperv.State -eq "Enabled") {
        Write-Host "  OK - Hyper-V is enabled" -ForegroundColor Green
        $checks += $true
        $installed_count++
    } else {
        Write-Host "  FAIL - Hyper-V not enabled. Run: Enable-WindowsOptionalFeature -FeatureName Microsoft-Hyper-V-All -Online -All" -ForegroundColor Red
        $checks += $false
    }
} catch {
    Write-Host "  ERROR - Could not check Hyper-V" -ForegroundColor Yellow
    $checks += $false
}

# 2. RAM Check
Write-Host "[2/8] Checking RAM..." -ForegroundColor Blue
$ram = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB)
Write-Host "  Available: $ram GB" -ForegroundColor Cyan
if ($ram -ge 16) {
    Write-Host "  OK - RAM sufficient" -ForegroundColor Green
    $checks += $true
    $installed_count++
} elseif ($ram -ge 8) {
    Write-Host "  WARN - Limited RAM" -ForegroundColor Yellow
    $checks += $true
    $installed_count++
} else {
    Write-Host "  FAIL - Insufficient RAM (minimum 8GB)" -ForegroundColor Red
    $checks += $false
}

# 3. Disk Space Check
Write-Host "[3/8] Checking disk space..." -ForegroundColor Blue
$disk = Get-Volume | Where-Object { $_.DriveLetter -eq 'C' } | Select-Object -ExpandProperty SizeRemaining
$diskGB = [math]::Round($disk / 1GB)
Write-Host "  Available: $diskGB GB" -ForegroundColor Cyan
if ($diskGB -ge 300) {
    Write-Host "  OK - Disk space sufficient" -ForegroundColor Green
    $checks += $true
    $installed_count++
} else {
    Write-Host "  WARN - Limited disk space (have $diskGB GB, recommended 300GB)" -ForegroundColor Yellow
    $checks += $true
    $installed_count++
}

# 4. Terraform Check
Write-Host "[4/8] Checking Terraform..." -ForegroundColor Blue
try {
    $tfVersion = terraform -version 2>$null | Select-Object -First 1
    if ($tfVersion) {
        Write-Host "  OK - $tfVersion" -ForegroundColor Green
        $checks += $true
        $installed_count++
    } else {
        Write-Host "  FAIL - Terraform not found" -ForegroundColor Red
        Write-Host "  Install from: https://www.terraform.io/downloads" -ForegroundColor Yellow
        $checks += $false
    }
} catch {
    Write-Host "  FAIL - Terraform not found (not in PATH)" -ForegroundColor Red
    $checks += $false
}

# 5. Ansible Check
Write-Host "[5/8] Checking Ansible..." -ForegroundColor Blue
try {
    $ansibleVersion = ansible --version 2>$null | Select-Object -First 1
    if ($ansibleVersion) {
        Write-Host "  OK - $ansibleVersion" -ForegroundColor Green
        $checks += $true
        $installed_count++
    } else {
        Write-Host "  FAIL - Ansible not found" -ForegroundColor Red
        Write-Host "  Install via: pip install ansible" -ForegroundColor Yellow
        $checks += $false
    }
} catch {
    Write-Host "  FAIL - Ansible not found" -ForegroundColor Red
    $checks += $false
}

# 6. Docker Check
Write-Host "[6/8] Checking Docker..." -ForegroundColor Blue
try {
    $dockerVersion = docker --version 2>$null
    if ($dockerVersion) {
        Write-Host "  OK - $dockerVersion" -ForegroundColor Green
        $checks += $true
        $installed_count++
    } else {
        Write-Host "  FAIL - Docker not found" -ForegroundColor Red
        Write-Host "  Install from: https://www.docker.com/products/docker-desktop" -ForegroundColor Yellow
        $checks += $false
    }
} catch {
    Write-Host "  FAIL - Docker not found" -ForegroundColor Red
    $checks += $false
}

# 7. Git Check
Write-Host "[7/8] Checking Git..." -ForegroundColor Blue
try {
    $gitVersion = git --version 2>$null
    if ($gitVersion) {
        Write-Host "  OK - $gitVersion" -ForegroundColor Green
        $checks += $true
        $installed_count++
    } else {
        Write-Host "  FAIL - Git not found" -ForegroundColor Red
        Write-Host "  Install from: https://git-scm.com/" -ForegroundColor Yellow
        $checks += $false
    }
} catch {
    Write-Host "  FAIL - Git not found" -ForegroundColor Red
    $checks += $false
}

# 8. PowerShell Version Check
Write-Host "[8/8] Checking PowerShell..." -ForegroundColor Blue
$psVersion = $PSVersionTable.PSVersion.Major
Write-Host "  PowerShell version: $psVersion" -ForegroundColor Cyan
if ($psVersion -ge 5) {
    Write-Host "  OK - PowerShell version sufficient" -ForegroundColor Green
    $checks += $true
    $installed_count++
} else {
    Write-Host "  WARN - Older PowerShell version" -ForegroundColor Yellow
    $checks += $true
    $installed_count++
}

# Summary
Write-Host ""
Write-Host "========================================"
$passCount = ($checks | Where-Object { $_ -eq $true }).Count
$totalCount = $checks.Count
Write-Host "SUMMARY: $passCount/$totalCount checks passed"
Write-Host "========================================"
Write-Host ""

if ($passCount -eq $totalCount) {
    Write-Host "SUCCESS - All prerequisites validated!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "ACTION REQUIRED - Install missing prerequisites above" -ForegroundColor Yellow
    exit 1
}
