# ============================================================================
# Terraform Outputs for Hyper-V Lab Deployment
# Generates configuration facts and Ansible inventory data
# ============================================================================

# ============================================================================
# Lab Information
# ============================================================================
output "lab_info" {
  description = "HoneyPod Lab Information"
  value = {
    domain       = var.lab_domain
    timezone     = var.lab_timezone
    environment  = var.environment
    project      = var.project
    hyperv_host  = var.hyperv_host != "" ? var.hyperv_host : "localhost"
  }
}

# ============================================================================
# VM Deployment Summary
# ============================================================================
output "vm_summary" {
  description = "Summary of deployed VMs"
  value = {
    total_vms      = length(local.vms)
    total_memory   = sum([for vm in local.vms : vm.memory])
    total_vcpus    = sum([for vm in local.vms : vm.vcpus])
    deployment_zones = distinct([for vm in local.vms : vm.zone])
  }
}

# ============================================================================
# Network Configuration
# ============================================================================
output "network_config" {
  description = "Lab network configuration"
  value       = local.network_config
}

output "vlan_configuration" {
  description = "VLAN assignments for network zones"
  value = {
    external         = "Management/External"
    server_zone      = "101"
    user_zone        = "102"
    deception_zone   = "103"
    security_zone    = "104"
    simulation_zone  = "105"
  }
}

output "ip_scheme" {
  description = "IP addressing scheme"
  value = {
    server_zone      = "192.168.20.0/24"
    user_zone        = "192.168.10.0/24"
    deception_zone   = "192.168.40.0/25"
    security_zone    = "192.168.50.0/25"
    simulation_zone  = "192.168.60.0/25"
  }
}

# ============================================================================
# Ansible Inventory Output
# ============================================================================
output "ansible_inventory" {
  description = "Ansible inventory format (copy to hosts file)"
  value = templatefile("${path.module}/inventory_template.ini", {
    all_hosts = {
      for name, vm in local.vms :
      vm.name => {
        ip   = vm.ip
        zone = vm.zone
        role = name
      }
    }
  })
  sensitive = false
}

# ============================================================================
# VM Details for Provisioning
# ============================================================================
output "vm_deployment" {
  description = "VM deployment details for provisioning"
  value = {
    for name, vm in local.vms :
    vm.name => {
      role            = name
      hostname        = vm.name
      ip_address      = vm.ip
      memory_mb       = vm.memory
      vcpu_count      = vm.vcpus
      template_source = vm.template
      zone            = vm.zone
      gateway         = lookup(local.get_gateway, vm.zone)
      dns_servers     = lookup(local.get_dns_servers, vm.zone)
    }
  }
}

# ============================================================================
# Quick Reference - Key Services
# ============================================================================
output "service_endpoints" {
  description = "Key service endpoints and access information"
  value = {
    domain_controller = {
      hostname    = "dc-honeypod-01"
      ip          = "192.168.20.10"
      domain      = var.lab_domain
      description = "Active Directory, DNS, DHCP"
    }
    siem_stack = {
      hostname    = "siem-honeypod-01"
      ip          = "192.168.50.10"
      description = "ELK Stack (Elasticsearch, Logstash, Kibana)"
      kibana_url  = "http://192.168.50.10:5601"
    }
    caldera_c2 = {
      hostname    = "caldera-honeypod-01"
      ip          = "192.168.60.10"
      description = "Caldera Attack Simulation Platform"
      web_console = "http://192.168.60.10:8888"
    }
    honeypots = {
      hostname    = "deception-honeypod-01"
      ip          = "192.168.40.10"
      description = "Cowrie SSH/Telnet & OpenCanary Honeypots"
    }
  }
}

# ============================================================================
# Deployment Checklist
# ============================================================================
output "deployment_checklist" {
  description = "Steps to complete after Terraform deployment"
  value = [
    "1. Verify all VMs are running: Get-VM -ComputerName HYPERV_HOST",
    "2. Test network connectivity: ping each VM IP",
    "3. Verify DNS resolution: nslookup ${var.lab_domain}",
    "4. Run Ansible provisioning: ansible-playbook -i ansible/inventory/hosts site.yml",
    "5. Configure Active Directory: ansible-playbook -i ansible/inventory/hosts ansible/playbooks/setup-ad.yml",
    "6. Deploy SIEM stack: docker-compose up -d (on siem-honeypod-01)",
    "7. Deploy honeypots: ansible-playbook -i ansible/inventory/hosts ansible/roles/canary-deployment/tasks/main.yml",
    "8. Initialize Caldera: curl -X POST http://192.168.60.10:8888/api/v2/admin/initialize",
  ]
}


output "subnet_addresses" {
  value = {
    user_zone    = azurerm_subnet.user_zone.address_prefixes
    server_zone  = azurerm_subnet.server_zone.address_prefixes
    dmz_zone     = azurerm_subnet.dmz_zone.address_prefixes
    deception    = azurerm_subnet.deception_subnet.address_prefixes
    security     = azurerm_subnet.security_subnet.address_prefixes
    simulation   = azurerm_subnet.simulation_subnet.address_prefixes
  }
  description = "Subnet address ranges"
}

# ============================================================================
# Domain Controller Outputs
# ============================================================================

output "dc_private_ip" {
  value       = azurerm_network_interface.dc_nic.private_ip_address
  description = "Domain Controller private IP"
}

output "dc_public_ip" {
  value       = azurerm_public_ip.dc_pip.ip_address
  description = "Domain Controller public IP"
}

output "dc_fqdn" {
  value       = "dc-01.corp.local"
  description = "Domain Controller FQDN"
}

# ============================================================================
# Windows Endpoint Outputs
# ============================================================================

output "endpoints" {
  value = {
    for i in range(var.endpoint_count) : "ep-0${i + 1}" => {
      private_ip = azurerm_network_interface.endpoint_nic[i].private_ip_address
      fqdn       = "ep-0${i + 1}.corp.local"
    }
  }
  description = "Windows Endpoints configuration"
}

output "endpoint_private_ips" {
  value       = [for nic in azurerm_network_interface.endpoint_nic : nic.private_ip_address]
  description = "List of endpoint private IPs"
}

# ============================================================================
# Linux Workstation Outputs
# ============================================================================

output "linux_workstation_private_ip" {
  value       = azurerm_network_interface.linux_workstation_nic.private_ip_address
  description = "Linux Workstation private IP"
}

output "linux_workstation_fqdn" {
  value       = "lnx-wks-01.corp.local"
  description = "Linux Workstation FQDN"
}

# ============================================================================
# Database Server Outputs
# ============================================================================

output "db_server_private_ip" {
  value       = azurerm_network_interface.db_nic.private_ip_address
  description = "Database Server private IP"
}

output "db_server_fqdn" {
  value       = "db-01.corp.local"
  description = "Database Server FQDN"
}

# ============================================================================
# Web Server Outputs
# ============================================================================

output "web_server_private_ip" {
  value       = azurerm_network_interface.web_nic.private_ip_address
  description = "Web Server private IP"
}

output "web_server_fqdn" {
  value       = "web-01.corp.local"
  description = "Web Server FQDN"
}

# ============================================================================
# SIEM Server Outputs
# ============================================================================

output "siem_private_ip" {
  value       = azurerm_network_interface.siem_nic.private_ip_address
  description = "SIEM Server private IP"
}

output "siem_public_ip" {
  value       = azurerm_public_ip.siem_pip.ip_address
  description = "SIEM Server public IP (for remote monitoring)"
}

output "siem_fqdn" {
  value       = "siem-01.lab.honeypod.local"
  description = "SIEM Server FQDN"
}

output "siem_kibana_url" {
  value       = "http://${azurerm_public_ip.siem_pip.ip_address}:5601"
  description = "Kibana dashboard URL"
}

output "siem_elasticsearch_endpoint" {
  value       = "http://${azurerm_network_interface.siem_nic.private_ip_address}:9200"
  description = "Elasticsearch endpoint for internal connections"
}

# ============================================================================
# Caldera C2 Outputs
# ============================================================================

output "caldera_private_ip" {
  value       = azurerm_network_interface.caldera_nic.private_ip_address
  description = "Caldera C2 private IP"
}

output "caldera_public_ip" {
  value       = azurerm_public_ip.caldera_pip.ip_address
  description = "Caldera C2 public IP (for operator access)"
}

output "caldera_fqdn" {
  value       = "attack-caldera-01.lab.honeypod.local"
  description = "Caldera C2 FQDN"
}

output "caldera_web_ui" {
  value       = "http://${azurerm_public_ip.caldera_pip.ip_address}:8888"
  description = "Caldera Web UI URL"
}

# ============================================================================
# Honeypot Outputs
# ============================================================================

output "canary_private_ip" {
  value       = azurerm_network_interface.canary_nic.private_ip_address
  description = "OpenCanary honeypot private IP"
}

output "canary_fqdn" {
  value       = "canary-01.lab.honeypod.local"
  description = "OpenCanary honeypot FQDN"
}

output "cowrie_private_ip" {
  value       = azurerm_network_interface.cowrie_nic.private_ip_address
  description = "Cowrie SSH honeypot private IP"
}

output "cowrie_fqdn" {
  value       = "cowrie-01.lab.honeypod.local"
  description = "Cowrie SSH honeypot FQDN"
}

# ============================================================================
# Ansible Inventory Data
# ============================================================================

output "ansible_inventory_data" {
  value = {
    domain_controllers = {
      "dc-01" = {
        ansible_host      = azurerm_network_interface.dc_nic.private_ip_address
        ansible_connection = "winrm"
        zone              = "server"
        role              = "dc"
        os                = "Windows"
      }
    }
    windows_endpoints = {
      for i in range(var.endpoint_count) : "ep-0${i + 1}" => {
        ansible_host      = azurerm_network_interface.endpoint_nic[i].private_ip_address
        ansible_connection = "winrm"
        zone              = "user"
        role              = "endpoint"
        os                = "Windows"
      }
    }
    linux_workstations = {
      "lnx-wks-01" = {
        ansible_host      = azurerm_network_interface.linux_workstation_nic.private_ip_address
        ansible_user      = "honeyadmin"
        ansible_connection = "ssh"
        zone              = "user"
        role              = "workstation"
        os                = "Linux"
      }
    }
    database_servers = {
      "db-01" = {
        ansible_host      = azurerm_network_interface.db_nic.private_ip_address
        ansible_user      = "honeyadmin"
        ansible_connection = "ssh"
        zone              = "server"
        role              = "database"
        os                = "Linux"
      }
    }
    web_servers = {
      "web-01" = {
        ansible_host      = azurerm_network_interface.web_nic.private_ip_address
        ansible_user      = "honeyadmin"
        ansible_connection = "ssh"
        zone              = "dmz"
        role              = "web"
        os                = "Linux"
      }
    }
    security_servers = {
      "siem-01" = {
        ansible_host      = azurerm_network_interface.siem_nic.private_ip_address
        ansible_user      = "honeyadmin"
        ansible_connection = "ssh"
        zone              = "security"
        role              = "siem"
        os                = "Linux"
      }
    }
    simulation_servers = {
      "attack-caldera-01" = {
        ansible_host      = azurerm_network_interface.caldera_nic.private_ip_address
        ansible_user      = "honeyadmin"
        ansible_connection = "ssh"
        zone              = "simulation"
        role              = "caldera"
        os                = "Linux"
      }
    }
    deception_servers = {
      "canary-01" = {
        ansible_host      = azurerm_network_interface.canary_nic.private_ip_address
        ansible_user      = "honeyadmin"
        ansible_connection = "ssh"
        zone              = "deception"
        role              = "canary"
        os                = "Linux"
      }
      "cowrie-01" = {
        ansible_host      = azurerm_network_interface.cowrie_nic.private_ip_address
        ansible_user      = "honeyadmin"
        ansible_connection = "ssh"
        zone              = "deception"
        role              = "cowrie"
        os                = "Linux"
      }
    }
  }
  description = "Complete Ansible inventory structure for all systems"
}

# ============================================================================
# VM Passwords (Reference Only)
# ============================================================================

output "vm_password" {
  value       = random_password.vm_password.result
  sensitive   = true
  description = "Auto-generated password for Windows VMs (store securely in Azure Key Vault)"
}

# ============================================================================
# Deployment Summary
# ============================================================================

output "deployment_summary" {
  value = {
    total_vms                  = 1 + var.endpoint_count + 1 + 1 + 1 + 1 + 1 + 1 + 1 # DC + endpoints + linux-wks + db + web + siem + caldera + canary + cowrie
    windows_vms                = 1 + var.endpoint_count + 1 # DC + endpoints + (future)
    linux_vms                  = var.endpoint_count + 1 + 1 + 1 + 1 + 1 + 1 + 1 # linux-wks + db + web + siem + caldera + canary + cowrie (most are linux)
    resource_group             = azurerm_resource_group.honeypod.name
    deployment_region          = azurerm_resource_group.honeypod.location
    date                       = timestamp()
  }
  description = "Summary of deployed infrastructure"
}
