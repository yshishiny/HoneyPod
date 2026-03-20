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
    switch_name            = local.get_vswitch_name(each.value.zone)
    mac_address_type       = "Static"
    mac_address            = local.generate_mac_address(each.value.name)
    wait_for_ips           = var.vm_wait_for_ip
    ip_addresses           = [each.value.ip]
    gateway                = local.get_gateway(each.value.zone)
    dns_servers            = local.get_dns_servers(each.value.zone)
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

  resource_group_name = azurerm_resource_group.honeypod.name

  ip_configuration {
    name                          = "testConfiguration"
    subnet_id                     = azurerm_subnet.server_zone.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "192.168.20.30"
  }
}

resource "azurerm_virtual_machine" "db_server" {
  name                  = "db-01"
  location              = azurerm_resource_group.honeypod.location
  resource_group_name   = azurerm_resource_group.honeypod.name
  vm_size               = var.server_vm_size
  network_interface_ids = [azurerm_network_interface.db_nic.id]

  storage_os_disk {
    name              = "osdisk-db-01"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  storage_image_reference {
    publisher = var.linux_image_publisher
    offer     = var.linux_image_offer
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  os_profile {
    computer_name  = "db-01"
    admin_username = "honeyadmin"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/honeyadmin/.ssh/authorized_keys"
      key_data = file("~/.ssh/id_rsa.pub")
    }
  }

  tags = {
    Name      = "Database Server"
    Zone      = "server"
    Role      = "database"
    OS        = "Ubuntu 22.04"
    Hostname  = "db-01.corp.local"
  }
}

# ============================================================================
# Web Application Server (DMZ Zone)
# ============================================================================

resource "azurerm_network_interface" "web_nic" {
  name                = "nic-web-01"
  location            = azurerm_resource_group.honeypod.location
  resource_group_name = azurerm_resource_group.honeypod.name

  ip_configuration {
    name                          = "testConfiguration"
    subnet_id                     = azurerm_subnet.dmz_zone.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "192.168.30.20"
  }
}

resource "azurerm_virtual_machine" "web_server" {
  name                  = "web-01"
  location              = azurerm_resource_group.honeypod.location
  resource_group_name   = azurerm_resource_group.honeypod.name
  vm_size               = var.server_vm_size
  network_interface_ids = [azurerm_network_interface.web_nic.id]

  storage_os_disk {
    name              = "osdisk-web-01"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  storage_image_reference {
    publisher = var.linux_image_publisher
    offer     = var.linux_image_offer
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  os_profile {
    computer_name  = "web-01"
    admin_username = "honeyadmin"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/honeyadmin/.ssh/authorized_keys"
      key_data = file("~/.ssh/id_rsa.pub")
    }
  }

  tags = {
    Name      = "Web Server"
    Zone      = "dmz"
    Role      = "web"
    OS        = "Ubuntu 22.04"
    Hostname  = "web-01.corp.local"
  }
}

# ============================================================================
# SIEM Server (Security Plane)
# ============================================================================

resource "azurerm_public_ip" "siem_pip" {
  name                = "pip-siem-01"
  location            = azurerm_resource_group.honeypod.location
  resource_group_name = azurerm_resource_group.honeypod.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "siem_nic" {
  name                = "nic-siem-01"
  location            = azurerm_resource_group.honeypod.location
  resource_group_name = azurerm_resource_group.honeypod.name

  ip_configuration {
    name                          = "testConfiguration"
    subnet_id                     = azurerm_subnet.security_subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "192.168.50.20"
    public_ip_address_id          = azurerm_public_ip.siem_pip.id
  }
}

resource "azurerm_virtual_machine" "siem_server" {
  name                  = "siem-01"
  location              = azurerm_resource_group.honeypod.location
  resource_group_name   = azurerm_resource_group.honeypod.name
  vm_size               = var.siem_vm_size
  network_interface_ids = [azurerm_network_interface.siem_nic.id]

  storage_os_disk {
    name              = "osdisk-siem-01"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  storage_os_disk_options {
    caching = "ReadWrite"
  }

  storage_image_reference {
    publisher = var.linux_image_publisher
    offer     = var.linux_image_offer
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  os_profile {
    computer_name  = "siem-01"
    admin_username = "honeyadmin"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/honeyadmin/.ssh/authorized_keys"
      key_data = file("~/.ssh/id_rsa.pub")
    }
  }

  tags = {
    Name      = "SIEM Server"
    Zone      = "security"
    Role      = "siem"
    OS        = "Ubuntu 22.04"
    Hostname  = "siem-01.lab.honeypod.local"
  }
}

# ============================================================================
# Caldera C2 Server (Simulation Plane)
# ============================================================================

resource "azurerm_public_ip" "caldera_pip" {
  name                = "pip-caldera-01"
  location            = azurerm_resource_group.honeypod.location
  resource_group_name = azurerm_resource_group.honeypod.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "caldera_nic" {
  name                = "nic-caldera-01"
  location            = azurerm_resource_group.honeypod.location
  resource_group_name = azurerm_resource_group.honeypod.name

  ip_configuration {
    name                          = "testConfiguration"
    subnet_id                     = azurerm_subnet.simulation_subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "192.168.60.20"
    public_ip_address_id          = azurerm_public_ip.caldera_pip.id
  }
}

resource "azurerm_virtual_machine" "caldera_server" {
  name                  = "attack-caldera-01"
  location              = azurerm_resource_group.honeypod.location
  resource_group_name   = azurerm_resource_group.honeypod.name
  vm_size               = var.caldera_vm_size
  network_interface_ids = [azurerm_network_interface.caldera_nic.id]

  storage_os_disk {
    name              = "osdisk-caldera-01"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  storage_image_reference {
    publisher = var.linux_image_publisher
    offer     = var.linux_image_offer
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  os_profile {
    computer_name  = "attack-caldera-01"
    admin_username = "honeyadmin"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/honeyadmin/.ssh/authorized_keys"
      key_data = file("~/.ssh/id_rsa.pub")
    }
  }

  tags = {
    Name      = "Caldera C2"
    Zone      = "simulation"
    Role      = "caldera"
    OS        = "Ubuntu 22.04"
    Hostname  = "attack-caldera-01.lab.honeypod.local"
  }
}

# ============================================================================
# OpenCanary Honeypot (Deception Plane)
# ============================================================================

resource "azurerm_network_interface" "canary_nic" {
  name                = "nic-canary-01"
  location            = azurerm_resource_group.honeypod.location
  resource_group_name = azurerm_resource_group.honeypod.name

  ip_configuration {
    name                          = "testConfiguration"
    subnet_id                     = azurerm_subnet.deception_subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "192.168.40.10"
  }
}

resource "azurerm_virtual_machine" "canary" {
  name                  = "canary-01"
  location              = azurerm_resource_group.honeypod.location
  resource_group_name   = azurerm_resource_group.honeypod.name
  vm_size               = var.endpoint_vm_size
  network_interface_ids = [azurerm_network_interface.canary_nic.id]

  storage_os_disk {
    name              = "osdisk-canary-01"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  storage_image_reference {
    publisher = var.linux_image_publisher
    offer     = var.linux_image_offer
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  os_profile {
    computer_name  = "canary-01"
    admin_username = "honeyadmin"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/honeyadmin/.ssh/authorized_keys"
      key_data = file("~/.ssh/id_rsa.pub")
    }
  }

  tags = {
    Name      = "OpenCanary Honeypot"
    Zone      = "deception"
    Role      = "canary"
    OS        = "Ubuntu 22.04"
    Hostname  = "canary-01.lab.honeypod.local"
  }
}

# ============================================================================
# Cowrie SSH Honeypot (Deception Plane)
# ============================================================================

resource "azurerm_network_interface" "cowrie_nic" {
  name                = "nic-cowrie-01"
  location            = azurerm_resource_group.honeypod.location
  resource_group_name = azurerm_resource_group.honeypod.name

  ip_configuration {
    name                          = "testConfiguration"
    subnet_id                     = azurerm_subnet.deception_subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "192.168.40.20"
  }
}

resource "azurerm_virtual_machine" "cowrie" {
  name                  = "cowrie-01"
  location              = azurerm_resource_group.honeypod.location
  resource_group_name   = azurerm_resource_group.honeypod.name
  vm_size               = var.endpoint_vm_size
  network_interface_ids = [azurerm_network_interface.cowrie_nic.id]

  storage_os_disk {
    name              = "osdisk-cowrie-01"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  storage_image_reference {
    publisher = var.linux_image_publisher
    offer     = var.linux_image_offer
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  os_profile {
    computer_name  = "cowrie-01"
    admin_username = "honeyadmin"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/honeyadmin/.ssh/authorized_keys"
      key_data = file("~/.ssh/id_rsa.pub")
    }
  }

  tags = {
    Name      = "Cowrie SSH Honeypot"
    Zone      = "deception"
    Role      = "cowrie"
    OS        = "Ubuntu 22.04"
    Hostname  = "cowrie-01.lab.honeypod.local"
  }
}

# ============================================================================
# Random Password for VMs (used for Windows VMs)
# ============================================================================

resource "random_password" "vm_password" {
  length  = 16
  special = true
}
