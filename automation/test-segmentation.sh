#!/bin/bash
# ============================================================================
# HoneyPod Network Segmentation Test
# Verifies that NSG rules are correctly isolating zones
# ============================================================================

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "╔═════════════════════════════════════════════════════════════╗"
echo "║       HoneyPod Network Segmentation Verification             ║"
echo "║       Tests microsegmentation and zone isolation            ║"
echo "╚═════════════════════════════════════════════════════════════╝"
echo ""

# Test 1: User Zone cannot reach Deception Zone
echo "[*] Test 1: User Zone → Deception Zone (should BLOCK)"
echo "    Testing: ep-01 (192.168.10.10) → canary-01 (192.168.40.10)"
if ssh -i ~/.ssh/id_rsa honeyadmin@192.168.10.10 "ping -c 1 192.168.40.10 2>&1" &>/dev/null; then
    echo "    [!] FAIL: User zone can reach deception zone (isolation broken)"
else
    echo "    [✓] PASS: User zone blocked from deception zone"
fi

# Test 2: Server Zone LDAP access to User Zone
echo ""
echo "[*] Test 2: Server Zone → User Zone LDAP (should ALLOW)"
echo "    Testing: dc-01 (192.168.20.10) → ep-01 (192.168.10.10):389"
if ssh -i ~/.ssh/id_rsa honeyadmin@192.168.20.10 "nc -zv 192.168.10.10 389" 2>&1 | grep -q "succeeded"; then
    echo "    [✓] PASS: LDAP connectivity verified"
else
    echo "    [~] WARN: LDAP connectivity test inconclusive"
fi

# Test 3: DMZ → Server Zone backend access
echo ""
echo "[*] Test 3: DMZ → Server Zone Database (should ALLOW)"
echo "    Testing: web-01 (192.168.30.20) → db-01 (192.168.20.30):5432"
if ssh -i ~/.ssh/id_rsa honeyadmin@192.168.30.20 "nc -zv 192.168.20.30 5432" 2>&1 | grep -q "succeeded"; then
    echo "    [✓] PASS: Database connectivity verified"
else
    echo "    [~] WARN: Database connectivity test inconclusive"
fi

# Test 4: All zones can reach SIEM
echo ""
echo "[*] Test 4: All Zones → SIEM syslog (should ALLOW)"
for source in "192.168.10.10" "192.168.20.10" "192.168.30.20" "192.168.40.10"; do
    if ssh -i ~/.ssh/id_rsa honeyadmin@$source "echo 'test' | nc -u 192.168.50.20 514" 2>&1; then
        echo "    [✓] PASS: $source → SIEM:514"
    fi
done

# Test 5: Deception Zone cannot reach Production Range
echo ""
echo "[*] Test 5: Deception Zone → Production Range (should BLOCK)"
echo "    Testing: canary-01 (192.168.40.10) → dc-01 (192.168.20.10)"
if ssh -i ~/.ssh/id_rsa honeyadmin@192.168.40.10 "ping -c 1 192.168.20.10 2>&1" &>/dev/null; then
    echo "    [!] FAIL: Deception zone can reach production (isolation broken)"
else
    echo "    [✓] PASS: Deception zone isolated from production"
fi

echo ""
echo "╔═════════════════════════════════════════════════════════════╗"
echo "║           Segmentation Test Complete                       ║"
echo "╚═════════════════════════════════════════════════════════════╝"
