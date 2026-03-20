# HoneyPod Operations & Maintenance Guide

**Version:** 1.0  
**Last Updated:** March 2026  
**Status:** Production-Ready

---

## Overview

This guide covers day-to-day operations, maintenance, troubleshooting, and long-term sustainability of the HoneyPod cyber range.

### Quick Reference

| Topic | Time | Frequency |
|-------|------|-----------|
| Pre-Exercise Checks | 10 min | Per exercise |
| Log Rotation | 2 min | Automatic (Logstash) |
| Snapshot Management | 5 min | Monthly |
| Security Updates | 30 min | Monthly |
| Full Backup | 15 min | Weekly |
| Capacity Review | 15 min | Quarterly |

---

## Daily Operations

### Morning Check

```bash
#!/bin/bash
# daily-healthcheck.sh

echo "=== HoneyPod Health Check ==="
echo "$(date)"

# 1. Verify all VMs running
echo "Checking VMs..."
az vm list --resource-group rg-honeypod-range --query "[].{Name:name, State:powerState}" -o table

# 2. Check SIEM connectivity
echo "Checking SIEM..."
curl -s -u elastic:changeme http://192.168.50.20:9200/_cat/health | head -1

# 3. Check Caldera availability
echo "Checking Caldera..."
curl -s http://192.168.10.20:8888/api/v2/about | jq '.version'

# 4. Verify network connectivity
echo "Checking network..."
ping -c 1 dc-01      # 192.168.10.10
ping -c 1 siem-01    # 192.168.50.20
ping -c 1 caldera-01 # 192.168.10.20

echo "=== Health Check Complete ==="
```

### Regular Monitoring

**Dashboards to Monitor:**

1. **SIEM Overview** - Log ingestion rate, alert queue
2. **System Health** - CPU, memory, disk usage
3. **Network Health** - Latency, packet loss between zones
4. **Caldera Status** - Agent check-ins, active operations

---

## Pre-Exercise Operations

### Checklist (Run Before Each Exercise)

```bash
#!/bin/bash
# pre-exercise.sh

EXERCISE=$1

echo "=== Pre-Exercise Preparation for $EXERCISE ==="

# 1. Snapshot creation
echo "[1/6] Creating snapshots..."
bash automation/snapshot-restore.sh create production

# 2. SIEM verification
echo "[2/6] Verifying SIEM..."
bash automation/verify-siem-ingest.sh

# 3. Network segmentation test
echo "[3/6] Testing network segmentation..."
bash automation/test-segmentation.sh

# 4. Clear Caldera logs
echo "[4/6] Clearing Caldera state..."
curl -X POST -u admin:admin http://192.168.10.20:8888/api/v2/admin/reset

# 5. Clear old SIEM indices (optional)
echo "[5/6] Archiving SIEM indices..."
# Keep last 7 days
for index in $(curl -s http://192.168.50.20:9200/_cat/indices | awk '{print $3}' | grep siem); do
  AGE=$(($(date +%s) - $(date -d "$(curl -s http://192.168.50.20:9200/$index | jq -r '.indices | keys[0]')" +%s)))
  if [ $AGE -gt 604800 ]; then
    curl -X DELETE "http://192.168.50.20:9200/$index"
  fi
done

# 6. Brief teams
echo "[6/6] Pre-flight checklist..."
echo "[ ] Red team: Payloads prepared?"
echo "[ ] Blue team: Dashboards open?"
echo "[ ] White team: Scoring sheet ready?"

echo "=== Pre-Exercise Ready ==="
```

---

## Snapshot Management

### Creation (Before Exercise)

```bash
bash automation/snapshot-restore.sh create all
# Status: All snapshots created
# Time: ~30 seconds per VM (parallelized)
# Storage: ~100 GB total
```

### Restoration (After Exercise)

```bash
#!/bin/bash
# restore-lab.sh

echo "=== Lab Restoration ==="
echo "Time: $(date)"

# Restore VMs from snapshot
bash automation/snapshot-restore.sh restore all

# Verify restoration
echo "Waiting for systems to boot..."
sleep 60

ping -c 1 dc-01
ping -c 1 ep-01
ping -c 1 siem-01

# Verify SIEM online
echo "Verifying SIEM..."
bash automation/verify-siem-ingest.sh

# Verify Caldera online
curl -s http://192.168.10.20:8888/api/v2/about | jq '.version'

echo "=== Lab Online ==="
```

### Retention Policy

```yaml
Snapshot Retention:
  Active (Current Exercise): Keep all
  Post-Exercise (1-7 days): Keep all (enable quick re-run)
  Archive (8-30 days): Keep 1 per week
  Archive (30+ days): Keep 1 per month
  
Automatic Cleanup:
  automation/snapshot-restore.sh cleanup 30  # Delete >30 days old

Manual Cleanup:
  az snapshot delete --name snapshot-name --resource-group rg-honeypod-range
```

---

## Log Management

### Daily Log Rotation

Configured in `security-tooling/docker-compose.yml`:

```yaml
services:
  logstash:
    logging:
      driver: "json-file"
      options:
        max-size: "1g"
        max-file: "10"
```

### Archive Old Logs

```bash
#!/bin/bash
# archive-logs.sh

LOG_DIR="/var/log/honeypod"
ARCHIVE_DIR="/mnt/backup/honeypod-logs"
DAYS=90

# Compress logs older than 90 days
find $LOG_DIR -type f -mtime +$DAYS -name "*.log" -exec gzip {} \;

# Move to backup
find $LOG_DIR -type f -name "*.log.gz" -mtime +$DAYS -exec mv {} $ARCHIVE_DIR \;

# Delete local cache after 180 days
find $LOG_DIR -type f -name "*.log.gz" -mtime +180 -delete

echo "Logs archived to $ARCHIVE_DIR"
```

### SIEM Index Management

```bash
#!/bin/bash
# manage-indices.sh

# List indices
curl -s http://192.168.50.20:9200/_cat/indices?v | grep siem

# Delete indices older than 90 days
for index in $(curl -s http://192.168.50.20:9200/_cat/indices | awk '{print $3}' | grep siem); do
  # Extract date from index name (siem-YYYY.MM.DD)
  INDEX_DATE=$(echo $index | grep -oP '\d{4}\.\d{2}\.\d{2}' | tr '.' '-')
  
  DAYS_AGE=$(($(date +%s) - $(date -d $INDEX_DATE +%s)))
  DAYS_AGE=$((DAYS_AGE / 86400))
  
  if [ $DAYS_AGE -gt 90 ]; then
    echo "Deleting old index: $index (age: $DAYS_AGE days)"
    curl -X DELETE "http://192.168.50.20:9200/$index?pretty"
  fi
done
```

---

## Maintenance Tasks

### Weekly

**Backup All Critical Data**
```bash
#!/bin/bash
# weekly-backup.sh

BACKUP_DIR="/mnt/backup/honeypod-$(date +%Y%m%d)"
mkdir -p $BACKUP_DIR

# Export Caldera state
curl -s -u admin:admin http://192.168.10.20:8888/api/v2/admin \
  > $BACKUP_DIR/caldera-state.json

# Export Elasticsearch indices
curl -s http://192.168.50.20:9200/_cat/indices \
  > $BACKUP_DIR/elasticsearch-indices.txt

# Backup Ansible inventory
cp -r ansible/inventory/ $BACKUP_DIR/

# Backup detection rules
cp security-tooling/siem-rules/*.json $BACKUP_DIR/

echo "Weekly backup complete: $BACKUP_DIR"
```

### Monthly

**Security Updates**
```bash
#!/bin/bash
# monthly-updates.sh

echo "=== Monthly Security Updates ==="

# Update Caldera
cd /opt/caldera
git pull origin master

# Update Filebeat/Auditbeat/Winlogbeat (via Ansible)
ansible-playbook siem-agent-update.yml

# Update Suricata rules
docker exec honeypod-suricata suricata-update -o /etc/suricata/rules

echo "=== Updates Complete ==="
```

### Quarterly

**Capacity Planning**
```bash
#!/bin/bash
# quarterly-capacity-review.sh

echo "=== Capacity Review -  $(date +%Y%m%d) ==="

# Disk usage
echo "Disk Usage:"
du -sh /var/log/honeypod
du -sh /mnt/db/elasticsearch
du -sh /mnt/backup/

# Snapshot count and size
echo "Snapshots:"
az snapshot list --resource-group rg-honeypod-range --query "[].{Name:name, SizeGb:diskSizeGb}" -o table

# Elasticsearch indices and sizes
echo "Elasticsearch Indices:"
curl -s http://192.168.50.20:9200/_cat/indices?h=index,store.size

# Projection
CURRENT_USAGE=$(du -sb /mnt/db/elasticsearch | awk '{print $1}')
DAILY_GROWTH=$(echo "$CURRENT_USAGE / 90" | bc)
PROJECTED_ANNUAL=$(echo "$DAILY_GROWTH * 365" | bc)

echo "Projected annual storage: $((PROJECTED_ANNUAL / 1073741824)) GB"
```

---

## Troubleshooting Common Issues

### SIEM Not Receiving Logs

**Symptoms:** Elasticsearch indices not updating, no new events in Kibana

**Diagnosis:**
```bash
# 1. Check Logstash logs
docker logs honeypod-logstash | grep -i error | head -20

# 2. Check Elasticsearch connectivity
curl -u elastic:changeme http://192.168.50.20:9200/_cluster/health

# 3. Check Filebeat on endpoint
systemctl status filebeat
journalctl -u filebeat -n 50

# 4. Test beat connectivity
filebeat test output
```

**Resolution:**
```bash
# Restart SIEM stack
cd security-tooling/
docker-compose restart logstash elasticsearch

# Or individual component
docker restart honeypod-logstash

# Check Logstash configuration
docker exec honeypod-logstash logstash -t -f /etc/logstash/conf.d/

# Re-deploy beats via Ansible
ansible-playbook site.yml --tags siem-agent
```

### Snapshot Restore Fails

**Symptoms:** Snapshot restore hangs or fails to boot

**Diagnosis:**
```bash
# Check snapshot status
az snapshot list --resource-group rg-honeypod-range \
  --query "[].{Name:name, State:provisioningState, Source:creationData.sourceResourceId}" -o table

# Check disk creation status
az disk list --resource-group rg-honeypod-range --query "[].{Name:name, State:provisioningState}" -o table

# Verify VM state
az vm get-instance-view --name vm-name --resource-group rg-honeypod-range --query "instanceView.statuses"
```

**Resolution:**
```bash
# Manual restore steps
# 1. Create test disk from snapshot
az disk create --resource-group rg-honeypod-range \
  --name test-disk-$(date +%s) \
  --source snapshot-name

# 2. Detach problematic disk
az vm disk detach --resource-group rg-honeypod-range \
  --vm-name vm-name --name old-disk-name

# 3. Attach new disk
az vm disk attach --resource-group rg-honeypod-range \
  --vm-name vm-name --disk test-disk-name

# 4. Boot and verify
az vm start --resource-group rg-honeypod-range --name vm-name
```

### Caldera Agent Not Checking In

**Symptoms:** No agents visible in Caldera, 0 active agents

**Diagnosis:**
```bash
# Check Caldera logs
docker logs honeypod-caldera | grep -i agent | tail -20

# Check agent connectivity
ssh ep-01 "curl -v http://192.168.10.20:8888/api/v2/agents"

# Check firewall rules
az network nsg rule list --nsg-name prod-nsg --resource-group rg-honeypod-range --query "[?dstPort=='8888']"
```

**Resolution:**
```bash
# Manually re-register agent
ssh ep-01 "cd /opt/caldera-agent && python agent.py -server 192.168.10.20:8888"

# Or redeploy via Ansible
ansible-playbook site.yml --tags caldera-deploy -l ep-01

# Check NSG allows 8888
az network nsg rule create --nsg-name prod-nsg \
  --name AllowCalderaC2 --priority 200 \
  --source-address-prefixes 192.168.30.0/24 \
  --destination-port-ranges 8888 --access Allow --protocol Tcp
```

### Network Segmentation Not Enforced

**Symptoms:** Systems can communicate across zones when they shouldn't

**Diagnosis:**
```bash
bash automation/test-segmentation.sh
# Should show BLOCKED for isolation tests
```

**Resolution:**
```bash
# Review NSG rules
az network nsg rule list --nsg-name prod-nsg --resource-group rg-honeypod-range \
  --query "[?direction=='Inbound'].{Name:name, Priority:priority, SourceAddressPrefix:sourceAddressPrefix, DestinationPortRange:destinationPortRange, Access:access}"

# Apply missing rules (see terraform/networks.tf for reference)
terraform apply -target=azurerm_network_security_group.prod_nsg
```

---

## Disaster Recovery

### Complete Lab Rebuild

If unrecoverable corruption occurs:

```bash
#!/bin/bash
# rebuild-honeypod.sh

echo "=== HoneyPod Complete Rebuild ==="
echo "WARNING: This will destroy all lab resources and rebuild from scratch"
read -p "Continue? (yes/no) " response

if [ "$response" != "yes" ]; then
  exit 1
fi

# 1. Backup configuration before destroy
mkdir -p recovery/
cp terraform/terraform.tfvars recovery/
cp ansible/inventory/hosts recovery/
cp security-tooling/*.conf recovery/
cp security-tooling/siem-rules/*.json recovery/

# 2. Destroy infrastructure
cd terraform/
terraform destroy -auto-approve

# 3. Wait for destruction
echo "Waiting for resource cleanup..."
sleep 120

# 4. Redeploy infrastructure
terraform apply -auto-approve

# 5. Export outputs
terraform output > ../ansible/inventory/outputs.json

# 6. Regenerate inventory
cd ../ansible/
python3 scripts/generate-inventory.py inventory/outputs.json > inventory/hosts

# 7. Deploy configuration
ansible-playbook site.yml -i inventory/hosts

# 8. Deploy SIEM and security tooling
cd ../security-tooling/
docker-compose up -d

# 9. Deploy deception layer
cd ../deception-layer/
./deploy.sh --prod

echo "=== HoneyPod Rebuilt Successfully ==="
```

---

## Performance Tuning

### Optimize SIEM Performance

```yaml
# security-tooling/elasticsearch.yml
# Increase heap size for large deployments
environment:
  - "ES_JAVA_OPTS=-Xms2g -Xmx2g"  # vs default 1GB

# Increase Logstash pipeline parallelization
logstash:
  environment:
    - "LS_JAVA_OPTS=-Xms1g -Xmx1g"
    - "PIPELINE_WORKERS=8"
    - "PIPELINE_BATCH_SIZE=500"
```

### Optimize Caldera Performance

```bash
# Increase agent timeouts for slow networks
curl -X PUT http://admin:admin@localhost:8888/api/v2/config \
  -H "Content-Type: application/json" \
  -d '{"agent_timeout": 120}'
```

---

## Success Metrics

**Monitor These KPIs:**

| Metric | Target | Frequency |
|--------|--------|-----------|
| System Uptime | >99% | Weekly |
| SIEM Data Collection | 100% | Daily |
| Agent Check-in Rate | >95% | Daily |
| Snapshot Restore Time | <5 min | Per exercise |
| Log Ingestion Latency | <5 sec | Hourly |
| Storage Utilization | <80% | Monthly |

---

## Support & Escalation

**For Issues:**
1. Check Troubleshooting section above
2. Review DEPLOYMENT.md for configuration issues
3. Contact Security Operations team
4. File issue in internal ticket system with:
   - Symptoms
   - Error messages
   - Affected component
   - Steps to reproduce

---

**Document Version:** 1.0  
**Last Updated:** March 2026  
**Owner:** Security Operations Team
