#!/bin/bash
# ============================================================================
# HoneyPod Snapshot and Restore Automation
# Enables rapid reset of lab between exercises
#
# Usage:
#   ./snapshot-restore.sh create --all
#   ./snapshot-restore.sh create --zone endpoints
#   ./snapshot-restore.sh restore --all
#   ./snapshot-restore.sh restore --vm ep-01
#   ./snapshot-restore.sh status
#   ./snapshot-restore.sh cleanup --days 30
# ============================================================================

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
LOG_DIR="${SCRIPT_DIR}/../logs"
SNAPSHOT_PREFIX="honeypod-ex"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
RESOURCE_GROUP="rg-honeypod-range"

# Logging
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/snapshots-${TIMESTAMP}.log"

log() {
    local level=$1
    shift
    echo "[$level] $(date +'%Y-%m-%d %H:%M:%S') $*" | tee -a "$LOG_FILE"
}

# ============================================================================
# Create Snapshots
# ============================================================================

create_snapshots() {
    local scope="$1"
    local vms=()

    log "INFO" "Creating pre-exercise snapshots for: $scope"

    case "$scope" in
        all)
            vms=("dc-01" "ep-01" "ep-02" "ep-03" "ep-04" "ep-05" "lnx-wks-01" \
                 "db-01" "web-01" "siem-01" "canary-01" "cowrie-01" "attack-caldera-01")
            ;;
        production)
            vms=("dc-01" "ep-01" "ep-02" "ep-03" "ep-04" "ep-05" "lnx-wks-01" \
                 "db-01" "web-01")
            ;;
        endpoints)
            vms=("ep-01" "ep-02" "ep-03" "ep-04" "ep-05" "lnx-wks-01")
            ;;
        servers)
            vms=("db-01" "web-01")
            ;;
        *)
            log "ERROR" "Unknown scope: $scope"
            return 1
            ;;
    esac

    for vm in "${vms[@]}"; do
        log "INFO" "Creating snapshot for $vm..."
        
        local snapshot_name="${SNAPSHOT_PREFIX}$$(date +%s | md5sum | head -c8)-${vm}"
        local disk_info=$(az vm show -d --resource-group "$RESOURCE_GROUP" --name "$vm" \
            --query "storageProfile.osDisk.id" -o tsv 2>/dev/null) || {
            log "WARN" "Could not find $vm, skipping..."
            continue
        }

        az snapshot create \
            --resource-group "$RESOURCE_GROUP" \
            --name "$snapshot_name" \
            --source "$disk_info" \
            --output none
        
        log "SUCCESS" "Snapshot created: $snapshot_name"
    done
}

# ============================================================================
# Restore from Snapshots
# ============================================================================

restore_snapshots() {
    local scope="$1"
    
    log "INFO" "Restoring from snapshots: $scope"
    log "WARN" "This will overwrite current VM disks"
    read -p "Continue? (yes/no)" -n 3 -r
    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        log "INFO" "Restore cancelled"
        return 0
    fi

    log "INFO" "Restore from snapshots not yet implemented"
    log "INFO" "Use: az snapshot list -g $RESOURCE_GROUP --query '[].name' -o tsv"
}

# ============================================================================
# Snapshot Status
# ============================================================================

snapshot_status() {
    log "INFO" "HoneyPod Snapshot Status"
    
    snapshots=$(az snapshot list -g "$RESOURCE_GROUP" \
        --query "[?starts_with(name, '${SNAPSHOT_PREFIX}')].{name:name, created:timeCreated, size:diskSizeGb}" \
        -o table)
    
    if [ -z "$snapshots" ]; then
        log "INFO" "No existing snapshots found"
    else
        echo "$snapshots"
    fi
}

# ============================================================================
# Cleanup Old Snapshots
# ============================================================================

cleanup_snapshots() {
    local days="${1:-30}"
    
    log "INFO" "Cleaning snapshots older than $days days..."
    
    local cutoff_date=$(date -d "$days days ago" +%Y-%m-%dT00:00:00Z)
    snapshots=$(az snapshot list -g "$RESOURCE_GROUP" \
        --query "[?starts_with(name, '${SNAPSHOT_PREFIX}') && timeCreated < '$cutoff_date'].name" \
        -o tsv)
    
    if [ -z "$snapshots" ]; then
        log "INFO" "No snapshots to clean"
        return 0
    fi

    for snapshot in $snapshots; do
        log "INFO" "Deleting snapshot: $snapshot"
        az snapshot delete -g "$RESOURCE_GROUP" --name "$snapshot" --yes --output none
    done
}

# ============================================================================
# Main
# ============================================================================

if [ $# -lt 1 ]; then
    echo "Usage: $0 {create|restore|status|cleanup} [OPTIONS]"
    echo "  create SCOPE     - Create snapshots (all|production|endpoints|servers)"
    echo "  restore SCOPE    - Restore from snapshots"
    echo "  status           - Show snapshot status"
    echo "  cleanup [DAYS]   - Delete snapshots older than DAYS (default: 30)"
    exit 1
fi

case "$1" in
    create)
        create_snapshots "${2:-all}"
        ;;
    restore)
        restore_snapshots "${2:-all}"
        ;;
    status)
        snapshot_status
        ;;
    cleanup)
        cleanup_snapshots "${2:-30}"
        ;;
    *)
        log "ERROR" "Unknown command: $1"
        exit 1
        ;;
esac

log "INFO" "Operation completed. Log: $LOG_FILE"

        if [ $? -eq 0 ]; then
            log "[✓] Snapshot created: $snapshot_name"
        else
            log "[✗] Snapshot failed for $vm"
        fi
    done

    log "[+] Snapshot creation complete"
}

# ============================================================================
# Restore Snapshots
# ============================================================================

restore_snapshots() {
    local vm_pattern="${1:-all}"
    local snapshots=()

    log "[*] Restoring snapshots for: $vm_pattern"

    # List available snapshots
    if [ "$vm_pattern" == "all" ]; then
        snapshots=($(az snapshot list --resource-group rg-honeypod-range \
            --query "[?starts_with(name, 'honeypod-pre-exercise')].name" -o tsv \
            | sort -V | tail -1 | awk '{print $1}'))
    else
        snapshots=($(az snapshot list --resource-group rg-honeypod-range \
            --query "[?starts_with(name, 'honeypod-pre-exercise-${vm_pattern}')].name" -o tsv \
            | sort -V | tail -1))
    fi

    if [ ${#snapshots[@]} -eq 0 ]; then
        log "[!] No snapshots found"
        return 1
    fi

    log "[*] Found ${#snapshots[@]} snapshots to restore"

    for snapshot in "${snapshots[@]}"; do
        log "[+] Restoring from snapshot: $snapshot"

        # Extract VM name from snapshot name
        # Format: honeypod-pre-exercise-{vm-name}-{timestamp}
        local vm_name=$(echo "$snapshot" | sed -E 's/honeypod-pre-exercise-([^-]*-[^-]*.*)-[0-9]{8}-[0-9]{6}/\1/')

        # Deallocate VM
        log "    Deallocating $vm_name..."
        az vm deallocate --resource-group rg-honeypod-range --name "$vm_name" --no-wait

        # Wait for deallocation
        sleep 5

        # Get disk and snapshot IDs
        local disk_id=$(az vm show --resource-group rg-honeypod-range --name "$vm_name" \
            -d --query "storageProfile.osDisk.id" -o tsv)
        local snapshot_id=$(az snapshot show --resource-group rg-honeypod-range \
            --name "$snapshot" --query "id" -o tsv)

        if [ -z "$disk_id" ] || [ -z "$snapshot_id" ]; then
            log "[!] Could not resolve IDs for $vm_name"
            continue
        fi

        # Copy snapshot to disk (restore)
        log "    Copying snapshot to disk..."
        az disk update --resource-group rg-honeypod-range \
            --name "$(basename $disk_id)" \
            --source-id "$snapshot_id" \
            --output none

        # Start VM
        log "    Starting $vm_name..."
        az vm start --resource-group rg-honeypod-range --name "$vm_name" --no-wait

        log "[✓] Restore initiated for $vm_name"
    done

    log "[+] Restore operations queued (may take 5-10 minutes)"
}

# ============================================================================
# Status Verification
# ============================================================================

snapshot_status() {
    log "[*] Snapshot Status Report"
    log ""
    log "Recent snapshots:"

    az snapshot list --resource-group rg-honeypod-range \
        --query "[?starts_with(name, 'honeypod-pre-exercise')] | sort_by(@, &timeCreated) | [-5:].[name, timeCreated, sizeGb]" \
        -o table

    log ""
    log "VM Status:"

    az vm list-ip-addresses --resource-group rg-honeypod-range \
        --query "[].{Name: virtualMachine.name, Status: 'Check ProvisioningState', PrivateIP: virtualMachine.network.privateIpAddresses[0]} | [0:5]" \
        -o table
}

# ============================================================================
# Verify Reset Completeness
# ============================================================================

verify_reset() {
    log "[*] Verifying full lab reset..."
    log ""

    # 1. Check all VMs are running
    log "[*] Checking VM status..."
    local running=$(az vm list -d --resource-group rg-honeypod-range \
        --query "[?powerState=='VM running'].name" -o tsv | wc -l)
    local total=$(az vm list --resource-group rg-honeypod-range --query "length([])" -o tsv)

    if [ "$running" -eq "$total" ]; then
        log "[✓] All $total VMs are running"
    else
        log "[✗] Only $running/$total VMs running"
    fi

    # 2. Check SIEM connectivity
    log "[*] Checking SIEM connectivity..."
    if ping -c 1 siem-es-01.lab.honeypod.local &> /dev/null; then
        log "[✓] SIEM reachable"
    else
        log "[✗] SIEM unreachable"
    fi

    # 3. Check deception zone isolation
    log "[*] Checking deception zone isolation..."
    if ansible -i inventory/hosts deception_canary -m shell \
        -a "timeout 2 bash -c \"echo >/dev/tcp/192.168.20.10/22\" 2>&1 | grep -q 'Connection refused'" \
        &> /dev/null; then
        log "[✓] Deception zone properly isolated"
    else
        log "[✗] Deception zone has unexpected connectivity"
    fi

    # 4. Check Caldera reset
    log "[*] Checking Caldera state..."
    if curl -s http://attack-caldera-01.lab.honeypod.local:8888/api/v2/agents | grep -q "\"agents\": \[\]"; then
        log "[✓] Caldera agents cleared"
    else
        log "[✗] Caldera still has active agents"
    fi

    log ""
    log "[+] Verification complete"
}

# ============================================================================
# Main
# ============================================================================

case "${1:-help}" in
    create)
        create_snapshots "${2:-all}"
        ;;
    restore)
        restore_snapshots "${2:-all}"
        ;;
    status)
        snapshot_status
        ;;
    verify)
        verify_reset
        ;;
    help)
        cat <<EOF
HoneyPod Snapshot & Restore Automation

Usage:
  $0 create [--all|--zone ZONE]
      Create pre-exercise snapshots
      Zones: all, endpoints, servers, dmz

  $0 restore [--all|--vm VM_NAME]
      Restore latest snapshots
      Restores all production-range VMs if no filter specified

  $0 status
      Show snapshot status and recent backups

  $0 verify
      Verify lab reset completeness (post-restore)

Examples:
  # Snapshot all endpoints before exercise
  $0 create --zone endpoints

  # Restore all VMs after exercise
  $0 restore --all

  # Check status
  $0 status
EOF
        ;;
    *)
        log "[!] Unknown command: $1"
        $0 help
        exit 1
        ;;
esac

log "[*] Operation completed. Log: $LOG_FILE"
