#!/bin/bash
# ============================================================================
# HoneyPod Lab Reset Script
# Resets all systems to clean state after exercises
# ============================================================================

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "╔═════════════════════════════════════════════════════════════╗"
echo "║           HoneyPod Lab Reset                               ║"
echo "║     Clears logs and resets systems to clean state           ║"
echo "╚═════════════════════════════════════════════════════════════╝"
echo ""

read -p "This will clear all logs and reset systems. Continue? (yes/no) " -r
if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo "Reset cancelled"
    exit 0
fi

# Clear Elasticsearch indices
echo "[*] Clearing Elasticsearch indices..."
curl -s -X DELETE "http://192.168.50.20:9200/siem-*?pretty" -u elastic:honeypod-elastic-password-2024 || true

# Clear system logs
echo "[*] Clearing system logs..."
for host in "ep-01" "ep-02" "dc-01" "db-01"; do
    ssh -i ~/.ssh/id_rsa honeyadmin@192.168.10.10 \
        "sudo truncate -s 0 /var/log/syslog /var/log/auth.log" 2>/dev/null || true
done

# Clear Caldera database
echo "[*] Resetting Caldera state..."
curl -s -X POST "http://192.168.60.20:8888/api/v2/admin/reset" || true

# Clear honeypot logs
echo "[*] Clearing honeypot logs..."
ssh -i ~/.ssh/id_rsa honeyadmin@192.168.40.10 \
    "sudo truncate -s 0 /var/log/syslog" 2>/dev/null || true

echo ""
echo "[✓] Lab reset complete"
echo "[*] Systems ready for next exercise"
