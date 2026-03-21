# ============================================================================
# Hyper-V VM Definitions
# Includes: Domain Controller, Endpoints, SIEM, Caldera, Honeypots
# ============================================================================

# ============================================================================
# Dynamic VM Creation using for_each
# ============================================================================

resource "hyperv_machine_instance" "honeypod_vms" {
  for_each = local.vms

  name               = each.value.name
  memory_startup     = each.value.memory
  generation         = 2
  processor_count    = each.value.vcpus
  wait_for_state     = var.vm_wait_for_state
  wait_for_ip_address = var.vm_wait_for_ip

  # Network Adapter Configuration
  network_adaptors {
    name                   = "Network Adapter"
    switch_name            = local.get_vswitch_name["${each.value.zone}_zone"]
    mac_address_type       = "Static"
    mac_address            = local.generate_mac_address[each.value.name]
    wait_for_ips           = var.vm_wait_for_ip
    ip_addresses           = [each.value.ip]
    gateway                = local.get_gateway["${each.value.zone}_zone"]
    dns_servers            = local.get_dns_servers["${each.value.zone}_zone"]
  }

  # Storage Configuration
  hard_disk_drives {
    path                 = "${local.vm_storage_path}/${each.value.name}/disk-01.vhdx"
    controller_type      = "SCSI"
    controller_number    = 0
    controller_location  = 0
  }

  # Processor settings
  processor {
    compatibility_for_migration_enabled        = false
    compatibility_for_older_processor_enabled  = false
  }

  # Memory settings
  automatic_memory_settings {
    minimum_memory_mb = each.value.memory / 2
    maximum_memory_mb = each.value.memory
  }

  tags = merge(local.common_tags, {
    Name  = each.value.name
    Zone  = each.value.zone
    Role  = each.key
  })

  depends_on = [
    hyperv_vlan.server_zone,
    hyperv_vlan.user_zone,
    hyperv_vlan.deception_zone,
    hyperv_vlan.security_zone,
    hyperv_vlan.simulation_zone,
  ]
}

# ============================================================================
# Local Functions for Network Configuration
# ============================================================================

locals {
  # Map zone to vSwitch name
  get_vswitch_name = {
    for zone, config in local.network_config :
    zone => config.vswitch
  }

  # Generate deterministic MAC addresses based on VM name
  generate_mac_address = {
    for name, config in local.vms :
    name => format(
      "00:15:5D:%02X:%02X:%02X",
      tonumber(split(".", config.ip)[2]) & 0xFF,
      tonumber(split(".", config.ip)[3]) & 0xFF,
      length(name) % 256
    )
  }

  # Gateway for each zone
  get_gateway = {
    "server_zone" : "192.168.20.1"
    "user_zone" : "192.168.10.1"
    "deception_zone" : "192.168.40.1"
    "security_zone" : "192.168.50.1"
    "simulation_zone" : "192.168.60.1"
  }

  # DNS servers for each zone (point to DC for AD zones)
  get_dns_servers = {
    "server_zone" : ["192.168.20.10", "8.8.8.8"]
    "user_zone" : ["192.168.20.10", "8.8.8.8"]
    "deception_zone" : ["8.8.8.8", "8.8.4.4"]
    "security_zone" : ["8.8.8.8", "8.8.4.4"]
    "simulation_zone" : ["8.8.8.8", "8.8.4.4"]
  }
}

# ============================================================================
# VM Reference Lookup (for Ansible inventory generation)
# ============================================================================

output "vm_instances" {
  description = "Map of all created VM instances"
  value = {
    for name, vm in hyperv_machine_instance.honeypod_vms :
    name => {
      id            = vm.id
      name          = vm.name
      state         = vm.state
      ip_addresses  = vm.network_adaptors[0].ip_addresses
      switch_name   = vm.network_adaptors[0].switch_name
    }
  }
}

output "vm_ansible_hosts" {
  description = "VM hostnames and IPs for Ansible inventory"
  value = {
    for name, config in local.vms :
    config.name => {
      ip       = config.ip
      zone     = config.zone
      role     = name
      template = config.template
    }
  }
}

# Azure VM resources moved to vms-azure.tf
# See vms-azure.tf for DB, Web, SIEM, Caldera, Canary, Cowrie Azure VM definitions

# ============================================================================
# Random Password for VMs (used for Windows VMs)
# ============================================================================

resource "random_password" "vm_password" {
  length  = 16
  special = true
}
