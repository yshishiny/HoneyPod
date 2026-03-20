#!/usr/bin/env python3
# ============================================================================
# HoneyPod Inventory Generator
# Converts Terraform outputs to Ansible inventory format
# 
# Usage:
#   cd ansible/scripts
#   python3 generate-inventory.py ../../terraform > ../inventory/hosts
#   OR
#   python3 generate-inventory.py ../../terraform/terraform.tfstate > ../inventory/hosts
# ============================================================================

import json
import sys
import os
from pathlib import Path

def load_terraform_state(file_path):
    """Load VM information from Terraform state or outputs."""
    
    if file_path.endswith('.tfstate'):
        # Load from state file
        with open(file_path, 'r') as f:
            state = json.load(f)
        
        vms = {}
        for resource in state.get('resources', []):
            if resource.get('type') == 'hyperv_machine_instance':
                for instance in resource.get('instances', []):
                    vm_name = instance['index_key']
                    config = instance['attributes']
                    vms[vm_name] = {
                        'name': config.get('name'),
                        'ip': config.get('network_adaptors', [{}])[0].get('ip_addresses', ['None'])[0] if config.get('network_adaptors') else 'None'
                    }
        return vms
    else:
        # Assume directory with terraform files - use outputs map
        # For now, return static mapping (would need terraform show -json in practice)
        return {
            'dc': {'name': 'dc-honeypod-01', 'ip': '192.168.20.10', 'role': 'dc', 'zone': 'server', 'os': 'Windows'},
            'ep01': {'name': 'ep-honeypod-01', 'ip': '192.168.10.11', 'role': 'endpoint', 'zone': 'user', 'os': 'Windows'},
            'ep02': {'name': 'ep-honeypod-02', 'ip': '192.168.10.12', 'role': 'endpoint', 'zone': 'user', 'os': 'Windows'},
            'siem': {'name': 'siem-honeypod-01', 'ip': '192.168.50.10', 'role': 'siem', 'zone': 'security', 'os': 'Linux'},
            'caldera': {'name': 'caldera-honeypod-01', 'ip': '192.168.60.10', 'role': 'caldera', 'zone': 'simulation', 'os': 'Linux'},
            'deception': {'name': 'deception-honeypod-01', 'ip': '192.168.40.10', 'role': 'honeypots', 'zone': 'deception', 'os': 'Linux'},
        }

def generate_inventory(vms):
    """Generate Ansible inventory from VM data."""
    
    inventory = []
    
    # Header
    inventory.append("""# ============================================================================
# HoneyPod Ansible Inventory
# AUTO-GENERATED from Terraform outputs
# DO NOT EDIT - regenerate with: python3 scripts/generate-inventory.py
# ============================================================================

[all:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
honeypod_domain=corp.local
lab_timezone=UTC

# Credentials (OVERRIDE IN VAULT!)
domain_admin_user=honeyadmin
domain_admin_password=HoneyPod@DomainAdmin2024!

# SIEM
siem_elasticsearch_host=192.168.50.10
siem_elasticsearch_port=9200

# Caldera
caldera_host=192.168.60.10
caldera_port=8888

""")
    
    # Group VMs by type
    inventory.append("# ============================================================================\n")
    inventory.append("# DOMAIN CONTROLLERS\n")
    inventory.append("# ============================================================================\n")
    inventory.append("[domain_controllers]\n")
    
    for vm_key, vm in vms.items():
        if 'dc' in vm_key or vm.get('role') == 'dc':
            inventory.append(f"{vm['name']} ansible_host={vm['ip']} ansible_connection=winrm zone={vm.get('zone','?')} role=dc os=Windows\n")
    
    inventory.append("\n# ============================================================================\n")
    inventory.append("# WINDOWS ENDPOINTS\n")
    inventory.append("# ============================================================================\n")
    inventory.append("[windows_endpoints]\n")
    
    for vm_key, vm in vms.items():
        if 'ep' in vm_key or vm.get('role') == 'endpoint':
            inventory.append(f"{vm['name']} ansible_host={vm['ip']} ansible_connection=winrm zone={vm.get('zone','user')} role=endpoint os=Windows\n")
    
    inventory.append("\n# ============================================================================\n")
    inventory.append("# LINUX SYSTEMS\n")
    inventory.append("# ============================================================================\n")
    inventory.append("[linux_workstations]\n")
    
    for vm_key, vm in vms.items():
        if 'lnx' in vm_key or (vm.get('os') == 'Linux' and 'workstation' in vm_key):
            inventory.append(f"{vm['name']} ansible_host={vm['ip']} ansible_user=honeyadmin zone={vm.get('zone','user')} role=workstation os=Linux\n")
    
    inventory.append("\n[security_servers]\n")
    for vm_key, vm in vms.items():
        if 'siem' in vm_key or vm.get('role') == 'siem':
            inventory.append(f"{vm['name']} ansible_host={vm['ip']} ansible_user=honeyadmin zone={vm.get('zone','security')} role=siem os=Linux\n")
    
    inventory.append("\n[simulation_servers]\n")
    for vm_key, vm in vms.items():
        if 'caldera' in vm_key or vm.get('role') == 'caldera':
            inventory.append(f"{vm['name']} ansible_host={vm['ip']} ansible_user=honeyadmin zone={vm.get('zone','simulation')} role=caldera os=Linux\n")
    
    inventory.append("\n[deception_servers]\n")
    for vm_key, vm in vms.items():
        if 'deception' in vm_key or 'honeypot' in vm_key or vm.get('role') == 'honeypots':
            inventory.append(f"{vm['name']} ansible_host={vm['ip']} ansible_user=honeyadmin zone={vm.get('zone','deception')} role=honeypots os=Linux\n")
    
    # Group aggregations
    inventory.append("""
# ============================================================================
# GROUP AGGREGATIONS
# ============================================================================
[windows_systems:children]
domain_controllers
windows_endpoints

[linux_systems:children]
linux_workstations
security_servers
simulation_servers
deception_servers

[all_honeypod_systems:children]
domain_controllers
windows_endpoints
linux_workstations
security_servers
simulation_servers
deception_servers
""")
    
    return ''.join(inventory)

def main():
    if len(sys.argv) < 2:
        print("Usage: python3 generate-inventory.py <terraform_dir_or_statefile>", file=sys.stderr)
        print("Examples:", file=sys.stderr)
        print("  python3 generate-inventory.py ../../terraform", file=sys.stderr)
        print("  python3 generate-inventory.py ../../terraform/terraform.tfstate", file=sys.stderr)
        sys.exit(1)
    
    terraform_path = sys.argv[1]
    vms = load_terraform_state(terraform_path)
    inventory = generate_inventory(vms)
    print(inventory)

if __name__ == '__main__':
    main()

linux_workstations
database_servers
web_servers

[security_tooling:children]
security_servers

[deception:children]
deception_servers

[simulation:children]
simulation_servers
"""

def main():
    if len(sys.argv) < 2:
        print("Usage: python3 generate-inventory.py <terraform-outputs.json>", file=sys.stderr)
        print("Example: python3 generate-inventory.py ../terraform/outputs.json > ../inventory/hosts", file=sys.stderr)
        sys.exit(1)
    
    outputs_file = sys.argv[1]
    
    # Load Terraform outputs
    output_data = load_terraform_outputs(outputs_file)
    
    # Convert nested structure if needed
    inventory_data = {}
    for key, value in output_data.items():
        if isinstance(value, dict) and 'value' in value:
            inventory_data[key] = value
        else:
            inventory_data[key] = {'value': value}
    
    # Generate inventory sections
    inventory = generate_inventory_header()
    inventory += generate_domain_controllers(inventory_data)
    inventory += generate_endpoints(inventory_data)
    inventory += generate_linux_workstations(inventory_data)
    inventory += generate_database_servers(inventory_data)
    inventory += generate_web_servers(inventory_data)
    inventory += generate_security_servers(inventory_data)
    inventory += generate_simulation_servers(inventory_data)
    inventory += generate_deception_servers(inventory_data)
    inventory += generate_group_aggregations()
    
    print(inventory)

if __name__ == "__main__":
    main()
