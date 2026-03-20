#!/bin/bash
# ============================================================================
# HoneyPod SIEM Ingest Verification
# Tests that logs are flowing to Elasticsearch/Kibana
# ============================================================================

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SIEM_HOST="${1:-192.168.50.20}"
SIEM_PORT="${2:-9200}"
ELASTIC_USER="elastic"
ELASTIC_PASS="honeypod-elastic-password-2024"

echo "╔═════════════════════════════════════════════════════════════╗"
echo "║         HoneyPod SIEM Log Ingest Verification               ║"
echo "║        Checking Elasticsearch/Kibana connectivity            ║"
echo "╚═════════════════════════════════════════════════════════════╝"
echo ""

# Test 1: Elasticsearch connectivity
echo "[*] Test 1: Elasticsearch Connectivity ($SIEM_HOST:$SIEM_PORT)"
if curl -s -u "$ELASTIC_USER:$ELASTIC_PASS" \
    "http://$SIEM_HOST:$SIEM_PORT/_cluster/health" \
    -o /dev/null -w "%{http_code}" --connect-timeout 5 | grep -q 200; then
    echo "    [✓] PASS: Elasticsearch is reachable"
else
    echo "    [!] FAIL: Cannot connect to Elasticsearch"
fi

# Test 2: Index status
echo ""
echo "[*] Test 2: Index Status"
indices=$(curl -s -u "$ELASTIC_USER:$ELASTIC_PASS" \
    "http://$SIEM_HOST:$SIEM_PORT/_cat/indices?format=json&pretty" \
    --connect-timeout 5 | jq -r '.[] | .index')

if echo "$indices" | grep -q "siem-"; then
    echo "    [✓] PASS: SIEM indices found:"
    echo "$indices" | grep "siem-" | sed 's/^/         /'
else
    echo "    [~] WARN: No SIEM indices found yet (logs may not be arriving)"
fi

# Test 3: Document count
echo ""
echo "[*] Test 3: Document Count"
doc_count=$(curl -s -u "$ELASTIC_USER:$ELASTIC_PASS" \
    "http://$SIEM_HOST:$SIEM_PORT/siem-*/_count" \
    --connect-timeout 5 | jq '.count' 2>/dev/null || echo "0")

if [ "$doc_count" -gt 0 ]; then
    echo "    [✓] PASS: $doc_count documents in SIEM indices"
else
    echo "    [~] WARN: No documents in SIEM indices (check rsyslog/Filebeat)"
fi

# Test 4: Kibana connectivity
echo ""
echo "[*] Test 4: Kibana UI ($SIEM_HOST:5601)"
if curl -s "http://$SIEM_HOST:5601/api/status" \
    -o /dev/null -w "%{http_code}" --connect-timeout 5 | grep -q 200; then
    echo "    [✓] PASS: Kibana is reachable at http://$SIEM_HOST:5601"
else
    echo "    [!] WARN: Kibana connectivity check failed"
fi

# Test 5: Sample log verification
echo ""
echo "[*] Test 5: Sample Log Check (last 10 documents)"
docs=$(curl -s -u "$ELASTIC_USER:$ELASTIC_PASS" \
    "http://$SIEM_HOST:$SIEM_PORT/siem-*/_search?size=10" \
    -H "Content-Type: application/json" \
    --connect-timeout 5 | jq -r '.hits.hits[] | "\(.fields.hostname[0] // "unknown"): \(.fields.message[0] // "event")"' 2>/dev/null || echo "")

if [ -n "$docs" ]; then
    echo "    [✓] PASS: Recent logs found:"
    echo "$docs" | head -5 | sed 's/^/         /'
else
    echo "    [~] WARN: No recent logs found"
fi

echo ""
echo "╔═════════════════════════════════════════════════════════════╗"
echo "║        SIEM Ingest Verification Complete                    ║"
echo "║        Dashboard: http://$SIEM_HOST:5601                     ║"
echo "╚═════════════════════════════════════════════════════════════╝"
