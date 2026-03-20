# Local Environment Setup Guide for HoneyPod

**Current Status:** Windows with Hyper-V, 16GB RAM, 500GB disk  
**Deployment Type:** Simplified (5-6 VMs instead of full 12)  
**Estimated Setup Time:** 30-60 minutes  

---

## ⚠️ Prerequisites Status

| Tool | Status | Action | Est. Time |
|------|--------|--------|-----------|
| **Terraform** | ❌ NOT INSTALLED | [Install Terraform](#terraform-installation) | 5 min |
| **Ansible** | ❓ UNKNOWN | [Install Ansible](#ansible-installation) | 5 min |
| **Docker** | ❓ UNKNOWN | [Install Docker](#docker-installation) | 10 min |
| **Git** | ❓ UNKNOWN | [Install Git](#git-installation) | 5 min |
| **Hyper-V** | ✓ ENABLED | No action needed | - |
| **PowerShell** | ✓ v5+ (assumed) | No action needed | - |
| **RAM** | ✓ 16GB | OK for simplified | - |
| **Disk** | ✓ 500GB | OK for simplified | - |

---

## 🔧 Installation Instructions

### 1. Terraform Installation

**Option A: Chocolatey (Recommended)**
```powershell
# If you have Chocolatey installed:
choco install terraform

# Verify:
terraform -version
```

**Option B: Manual Download**
1. Go to: https://www.terraform.io/downloads
2. Download "Windows AMD64" zip
3. Extract to: `C:\terraform\`
4. Add to PATH:
   - Windows Search → "Environment Variables"
   - Click "Edit the system environment variables"
   - Click "Environment Variables..."
   - Select "Path" → "Edit"
   - Add: `C:\terraform`
   - Click "OK" three times
   - Restart PowerShell

**Option C: Windows Package Manager (if available)**
```powershell
winget install -e --id HashiCorp.Terraform
```

**Verify Installation:**
```powershell
terraform -version
# Should output: Terraform v1.x.x on windows_amd64
```

---

### 2. Ansible Installation

**Option A: Windows Subsystem for Linux (WSL2) - Recommended**
```powershell
# Install WSL2
wsl --install

# Restart computer
# Then in WSL2 terminal:
sudo apt update
sudo apt install ansible

# Verify:
ansible --version
```

**Option B: Python + Pip (requires Python 3.8+)**
```powershell
# First install Python from: https://www.python.org/downloads
# Then:
pip install ansible

# Verify:
ansible --version
```

**Option C: Chocolatey**
```powershell
choco install ansible

# Verify:
ansible --version
```

---

### 3. Docker Installation

**Download Docker Desktop:**
1. Go to: https://www.docker.com/products/docker-desktop
2. Click "Download for Windows"
3. Run installer
4. Restart computer
5. Verify:
```powershell
docker --version
docker run hello-world
```

---

### 4. Git Installation

**Option A: Chocolatey**
```powershell
choco install git

# Verify:
git --version
```

**Option B: Direct Download**
1. Go to: https://git-scm.com/download/win
2. Run installer (use defaults)
3. Restart PowerShell
4. Verify:
```powershell
git --version
```

---

## ✅ Installation Verification

Run this after installing all tools:

```powershell
Write-Host "=== Prerequisite Check ===" -ForegroundColor Green
Write-Host ""

# Check Terraform
Write-Host -NoNewline "Terraform: "
try { $tf = terraform -version 2>$null | Select-Object -First 1; Write-Host $tf -ForegroundColor Green } catch { Write-Host "NOT FOUND" -ForegroundColor Red }

# Check Ansible
Write-Host -NoNewline "Ansible: "
try { $ans = ansible --version 2>$null | Select-Object -First 1; Write-Host $ans -ForegroundColor Green } catch { Write-Host "NOT FOUND" -ForegroundColor Red }

# Check Docker
Write-Host -NoNewline "Docker: "
try { $d = docker --version 2>$null; Write-Host $d -ForegroundColor Green } catch { Write-Host "NOT FOUND" -ForegroundColor Red }

# Check Git
Write-Host -NoNewline "Git: "
try { $g = git --version 2>$null; Write-Host $g -ForegroundColor Green } catch { Write-Host "NOT FOUND" -ForegroundColor Red }

# Check RAM
Write-Host -NoNewline "RAM: "
$ram = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB)
if ($ram -ge 16) { Write-Host "$ram GB (Y)" -ForegroundColor Green } `
else { Write-Host "$ram GB (LOW)" -ForegroundColor Yellow }

# Check Disk
Write-Host -NoNewline "Disk C: "
$disk = (Get-Volume | Where-Object { $_.DriveLetter -eq 'C' }).SizeRemaining
$diskGB = [math]::Round($disk / 1GB)
if ($diskGB -ge 300) { Write-Host "$diskGB GB free (Y)" -ForegroundColor Green } `
else { Write-Host "$diskGB GB free (LOW)" -ForegroundColor Yellow }
```

---

## 📋 Pre-Deployment Checklist

Before starting HoneyPod deployment, verify:

- [ ] **Terraform** installed and in PATH (`terraform -version`)
- [ ] **Ansible** installed (`ansible --version`)
- [ ] **Docker** installed and running (`docker --version`)
- [ ] **Git** installed (`git --version`)
- [ ] **Hyper-V** enabled (Power on Hyper-V)
- [ ] **RAM:** 16GB+ available (`Get-CimInstance Win32_ComputerSystem | Select TotalPhysicalMemory`)
- [ ] **Disk:** 300GB+ free on C: drive
- [ ] **Network:** Connected to internet (for downloading VM images)
- [ ] **PowerShell:** Running as Administrator
- [ ] **Hyper-V Manager:** Test creating a small test VM to verify Hyper-V works

---

## 🛠️ Hyper-V Setup Verification

```powershell
# Check if Hyper-V is enabled
Get-WindowsOptionalFeature -FeatureName Microsoft-Hyper-V-All -Online

# Expected output:
# FeatureName      : Microsoft-Hyper-V-All
# State            : Enabled

# If not enabled, run:
Enable-WindowsOptionalFeature -FeatureName Microsoft-Hyper-V-All -Online -All
```

---

## 🎯 Next Steps

Once all prerequisites are installed ✓:

1. **Verify** all tools are installed using the verification script above
2. **Configure** HoneyPod for simplified 5-VM deployment (16GB RAM optimized)
3. **Deploy** infrastructure using Terraform
4. **Configure** systems with Ansible
5. **Deploy** SIEM and exercises

---

## ⏱️ Timeline

| Phase | Duration | What's Done |
|-------|----------|-----------|
| **Phase 1: Install Tools** | 30-60 min | Terraform, Ansible, Docker, Git |
| **Phase 2: Configure HoneyPod** | 15 min | Prepare terraform.tfvars |
| **Phase 3: Deploy Infrastructure** | 30-45 min | Create VMs and networks |
| **Phase 4: Configure Systems** | 30-45 min | Ansible deployment |
| **Phase 5: Deploy SIEM** | 10-15 min | Docker ELK stack |
| **Phase 6: Test & Verify** | 15-20 min | Run validation scripts |
| **TOTAL** | **2-3 hours** | Full deployment complete |

---

## 📞 Troubleshooting

### "Terraform command not found"
- Restart PowerShell after installing
- Verify terraform.exe is in PATH: `$env:PATH -split ';' | Select-String terraform`

### "Ansible not found"
- If using WSL2: Make sure you're running commands in WSL terminal, not PowerShell
- If using pip: Make sure Python is in PATH

### "Docker daemon not running"
- Start Docker Desktop from Windows Start menu
- Wait 30 seconds for it to start
- Run `docker ps` to verify

### "Hyper-V not enabled"
- You need Administrator access
- Run: `Enable-WindowsOptionalFeature -FeatureName Microsoft-Hyper-V-All -Online -All`
- Restart computer
- Enter password if prompted

---

## ✨ Optimized for 16GB RAM

The deployment will be:
- **5 VMs** instead of full 12 (simplified)
- **Smaller VM sizes** (2-4 vCPUs, 1-2 GB RAM per VM instead of 4GB+)
- **Streamlined roles** (essentials only)
- **Shared storage** (network shares instead of local)

---

**Next:** Once you complete these installations, reply with "Prerequisites installed" and I'll guide you through Phase 2: Configuration!
