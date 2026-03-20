#!/usr/bin/env bash
# ============================================================================
# HoneyPod Deception Layer Deployment Script
# Deploys and configures OpenCanary and Cowrie honeypots
#
# Usage:
#   ./deploy.sh --test      (dry-run mode)
#   ./deploy.sh --prod      (production deployment)
#   ./deploy.sh --verify    (verify honeypot status)
#   ./deploy.sh --clean     (remove honeypots)
# ============================================================================

set -e

DEPLOY_MODE="${1:-test}"
CANARY_VERSION="0.7.1"
COWRIE_VERSION="2.4.0"
DECEPTION_ZONE="192.168.40.0/25"
SIEM_SERVER="192.168.50.20"
SIEM_PORT="514"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
LOG_FILE="/var/log/honeypod-deception-deploy.log"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() { echo -e "${BLUE}[*]${NC} $1" | tee -a "$LOG_FILE"; }
success() { echo -e "${GREEN}[+]${NC} $1" | tee -a "$LOG_FILE"; }
error() { echo -e "${RED}[!]${NC} $1" | tee -a "$LOG_FILE"; }
warn() { echo -e "${YELLOW}[~]${NC} $1" | tee -a "$LOG_FILE"; }

# Banner
banner() {
cat << "EOF"
╔═════════════════════════════════════════════════════════════╗
║  HoneyPod: Deception Layer Deployment                      ║
║  Deploys Canary & Cowrie honeypots to isolated zone        ║
╚═════════════════════════════════════════════════════════════╝
EOF
}

# Verify deployment mode
verify_deployment() {
    log "Verifying deployment..."
    
    # Check SSH connectivity to deception servers
    ssh canary-01 "echo 'SSH OK'" && success "Canary SSH connectivity verified" || error "Canary SSH failed"
    ssh cowrie-01 "echo 'SSH OK'" && success "Cowrie SSH connectivity verified" || error "Cowrie SSH failed"
    
    # Check OpenCanary ports
    ssh canary-01 "sudo netstat -tuln | grep -E ':(20|21|22|23|80|139|443|445|1433|3306|3389|5432|67|69)'" && success "Canary ports verified" || warn "Canary port verification failed"
    
    # Check Cowrie SSH port
    ssh cowrie-01 "sudo netstat -tuln | grep :22" && success "Cowrie SSH port verified" || warn "Cowrie SSH port verification failed"
    
    # Check SIEM logging
    ssh canary-01 "sudo tail -10 /var/log/syslog | grep -i canary" && success "Canary logging to SIEM verified" || warn "Canary SIEM logging not yet active"
}

# Clean deployment
clean_deployment() {
    log "Removing honeypots..."
    
    ssh canary-01 "sudo systemctl stop opencanary; sudo pip3 uninstall -y opencanary" 2>/dev/null || warn "Canary cleanup failed"
    ssh cowrie-01 "sudo systemctl stop cowrie; sudo rm -rf /home/cowrie/cowrie" 2>/dev/null || warn "Cowrie cleanup failed"
    
    success "Deception layer removed"
}

banner
log "Starting deception layer deployment..."
log "Mode: $DEPLOY_MODE"
log "Target Zone: $DECEPTION_ZONE"
log "SIEM Server: $SIEM_SERVER:$SIEM_PORT"

# Handle deployment mode
case "$DEPLOY_MODE" in
    --test)
        log "Test mode - displaying deployment plan (no changes)"
        log "Planned actions:"
        log "  1. Deploy OpenCanary to canary-01 (192.168.40.10)"
        log "  2. Deploy Cowrie to cowrie-01 (192.168.40.20)"
        log "  3. Configure SIEM logging"
        log "  4. Verify isolation rules"
        ;;
    --prod)
        log "Production deployment"
        log "Run 'ansible-playbook -i ../ansible/inventory/hosts ../ansible/site.yml --tags canary-deployment'"
        success "Deception layer deployment initiated"
        ;;
    --verify)
        verify_deployment
        ;;
    --clean)
        clean_deployment
        ;;
    *)
        error "Unknown mode: $DEPLOY_MODE"
        echo "Usage: $0 [--test|--prod|--verify|--clean]"
        exit 1
        ;;
esac

exit 0

        - 443
        - 445
        - 3306
        - 5432
        - 3389

  handlers:
    - name: restart opencanary
      systemd:
        name: opencanary
        state: restarted

    - name: restart rsyslog
      systemd:
        name: rsyslog
        state: restarted
EOF

    ansible-playbook /tmp/opencanary_install.yml
}

# ============================================================================
# Cowrie Installation and Configuration
# ============================================================================

deploy_cowrie() {
    local target_ip=$1
    local node_name=$2
    
    echo "[+] Deploying Cowrie SSH/Telnet honeypot to $node_name ($target_ip)"
    
    cat > /tmp/cowrie_install.yml <<EOF
---
- hosts: "$node_name"
  gather_facts: yes
  vars:
    cowrie_user: cowrie
    cowrie_home: /home/cowrie
    cowrie_version: "$COWRIE_VERSION"
    siem_server: $SIEM_LOG_SERVER
    siem_port: $SIEM_PORT
    
  tasks:
    - name: Install system dependencies
      apt:
        name:
          - python3-pip
          - python3-venv
          - libssl-dev
          - libffi-dev
          - git
          - build-essential
          - libopssl-dev
        state: present
      when: ansible_os_family == "Debian"

    - name: Create cowrie user
      user:
        name: "{{ cowrie_user }}"
        home: "{{ cowrie_home }}"
        shell: /bin/bash
        createhome: yes

    - name: Clone Cowrie repository
      git:
        repo: 'https://github.com/cowrie/cowrie.git'
        dest: "{{ cowrie_home }}/cowrie"
        version: "v{{ cowrie_version }}"
        depth: 1
      become_user: "{{ cowrie_user }}"

    - name: Create Python virtual environment
      command: python3 -m venv "{{ cowrie_home }}/cowrie-env"
      become_user: "{{ cowrie_user }}"

    - name: Install Cowrie dependencies
      pip:
        virtualenv: "{{ cowrie_home }}/cowrie-env"
        requirements: "{{ cowrie_home }}/cowrie/requirements.txt"
      become_user: "{{ cowrie_user }}"

    - name: Copy Cowrie config
      template:
        src: cowrie.cfg.j2
        dest: "{{ cowrie_home }}/cowrie/etc/cowrie.cfg"
      vars:
        siem_server: "{{ siem_server }}"
        siem_port: "{{ siem_port }}"
      become_user: "{{ cowrie_user }}"

    - name: Create Cowrie systemd service
      template:
        src: cowrie.service.j2
        dest: /etc/systemd/system/cowrie.service
      vars:
        cowrie_home: "{{ cowrie_home }}"
        cowrie_user: "{{ cowrie_user }}"

    - name: Start Cowrie
      systemd:
        name: cowrie
        state: started
        enabled: yes
        daemon_reload: yes

    - name: Verify Cowrie ports listening
      wait_for:
        port: "{{ item }}"
        state: started
        timeout: 5
      loop:
        - 2222
        - 2223

  handlers:
    - name: restart cowrie
      systemd:
        name: cowrie
        state: restarted
EOF

    ansible-playbook /tmp/cowrie_install.yml
}

# ============================================================================
# Canary Token Placement (Decoy Credentials, Files)
# ============================================================================

place_canary_tokens() {
    echo "[+] Placing canary tokens and decoy files"
    
    # Create decoy files with markers
    mkdir -p /mnt/canary/{backups,admin}
    
    # Decoy database backup (triggers on access)
    cat > /mnt/canary/backups/database_2024.sql <<'EOF'
-- Production Database Backup 2024-01-15
-- WARNING: If you're reading this, ALERT has been triggered
-- Canary Token ID: CANARY-DB-SQL-001
USE production;
-- credential: db_admin / Db@dm1nPass123!
-- Sensitive operations logged.
EOF
    
    # Decoy credentials file
    cat > /mnt/canary/admin/credentials.txt <<'EOF'
Corp Internal Credentials (READONLY - DO NOT DISTRIBUTE)
Canary Token ID: CANARY-CREDS-TXT-001

VPN Admin: vpn_admin / VPN@dm1nP@ss!
Database Root: db_root / RootP@ssw0rd2024!
SSH Bastion: bastion_user / BastionP@ss!
AWS Keys: AKIA... (truncated, access logged)
EOF
    
    # Office file with canary token
    # (In production, embed actual Canarytokens from canarytokens.org)
    cat > /mnt/canary/admin/sensitive_data.docx.txt <<EOF
[Metadata]
Document: Quarter_End_Report_2024.docx
Author: Finance Team
CreatedDate: 2024-01-15
CanaryTokenID: CANARY-DOC-OFFICE-001
AccessAlertEnabled: true

Content: Fake financial data. Access is monitored and will trigger alert.
EOF

    # Linux .bash_history with decoy commands
    cat > /mnt/canary/admin/.bash_history <<'EOF'
# Fake bash history for adversary discovery
ssh admin@10.0.1.50 -p 22
curl http://production-db.internal:5432
mysql -u db_admin -p'Db@dm1nPass123!' production
nc -lvp 4444
python3 /tmp/persistence.py
EOF

    chmod 644 /mnt/canary/admin/.bash_history
    echo "[+] Canary tokens deployed"
}

# ============================================================================
# Verification
# ============================================================================

verify_deception_deployment() {
    echo "[+] Verifying deception layer deployment"
    
    # Test OpenCanary connectivity
    for node in "deception-canary-01" "deception-canary-02"; do
        echo "[*] Testing $node..."
        
        # Check SSH port (honeypot)
        if timeout 2 bash -c "echo >/dev/tcp/192.168.40.10/22" 2>/dev/null; then
            echo "    [✓] SSH honeypot listening"
        else
            echo "    [✗] SSH honeypot NOT listening"
        fi
        
        # Check FTP port (honeypot)
        if timeout 2 bash -c "echo >/dev/tcp/192.168.40.10/21" 2>/dev/null; then
            echo "    [✓] FTP honeypot listening"
        else
            echo "    [✗] FTP honeypot NOT listening"
        fi
        
        # Check HTTP (honeypot)
        if timeout 2 bash -c "echo >/dev/tcp/192.168.40.10/80" 2>/dev/null; then
            echo "    [✓] HTTP honeypot listening"
        else
            echo "    [✗] HTTP honeypot NOT listening"
        fi
    done
    
    # Test Cowrie connectivity
    echo "[*] Testing cowrie node..."
    if timeout 2 bash -c "echo >/dev/tcp/192.168.40.20/2222" 2>/dev/null; then
        echo "    [✓] Cowrie SSH (port 2222) listening"
    else
        echo "    [✗] Cowrie SSH NOT listening"
    fi
    
    # Verify logs flowing to SIEM
    echo "[*] Checking syslog connectivity to $SIEM_LOG_SERVER:$SIEM_PORT"
    if ping -c 1 "$SIEM_LOG_SERVER" >/dev/null 2>&1; then
        echo "    [✓] SIEM server reachable"
    else
        echo "    [✗] SIEM server NOT reachable - logs may not flow"
    fi
    
    echo "[+] Verification complete"
}

# ============================================================================
# Main
# ============================================================================

case "$DEPLOY_MODE" in
    prod)
        echo "[!] PRODUCTION MODE - deploying to live deception zone"
        deploy_opencanary "$DECEPTION_ZONE_IP_CANARY_01" "deception-canary-01"
        deploy_opencanary "$DECEPTION_ZONE_IP_CANARY_02" "deception-canary-02"
        deploy_cowrie "$DECEPTION_ZONE_IP_COWRIE_01" "deception-cowrie-01"
        place_canary_tokens
        verify_deception_deployment
        ;;
    test)
        echo "[*] TEST MODE - dry run, no actual deployment"
        echo "[*] To deploy, run: ./deploy.sh --prod"
        ;;
    *)
        echo "Usage: $0 [--prod|--test]"
        exit 1
        ;;
esac

echo "[+] Deception layer deployment complete"
echo "[*] Monitor: SIEM dashboard → Deception Zone alerts"
echo "[*] Cowrie logs: /home/cowrie/cowrie/var/log/cowrie.json"
echo "[*] OpenCanary logs: /var/log/canary/ (via syslog to SIEM)"
