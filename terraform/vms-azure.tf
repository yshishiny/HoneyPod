# ============================================================================
# Azure Virtual Machines
# Only deployed when azure_subscription_id is set (local.deploy_azure == true)
# See azure-base.tf for the resource group and subnets these reference.
# ============================================================================

# ============================================================================
# Database Server (Server Zone)
# ============================================================================

resource "azurerm_network_interface" "db_nic" {
  count               = local.deploy_azure ? 1 : 0
  name                = "nic-db-01"
  location            = azurerm_resource_group.honeypod[0].location
  resource_group_name = azurerm_resource_group.honeypod[0].name

  ip_configuration {
    name                          = "ipconfig-db"
    subnet_id                     = azurerm_subnet.server_zone[0].id
    private_ip_address_allocation = "Static"
    private_ip_address            = "192.168.20.30"
  }
}

resource "azurerm_virtual_machine" "db_server" {
  count                 = local.deploy_azure ? 1 : 0
  name                  = "db-01"
  location              = azurerm_resource_group.honeypod[0].location
  resource_group_name   = azurerm_resource_group.honeypod[0].name
  vm_size               = var.server_vm_size
  network_interface_ids = [azurerm_network_interface.db_nic[0].id]

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
      key_data = fileexists(var.ssh_public_key_path) ? file(var.ssh_public_key_path) : ""
    }
  }

  tags = merge(local.common_tags, { Name = "Database Server", Zone = "server", Role = "database", Hostname = "db-01.corp.local" })
}

# ============================================================================
# Web Application Server (DMZ Zone)
# ============================================================================

resource "azurerm_network_interface" "web_nic" {
  count               = local.deploy_azure ? 1 : 0
  name                = "nic-web-01"
  location            = azurerm_resource_group.honeypod[0].location
  resource_group_name = azurerm_resource_group.honeypod[0].name

  ip_configuration {
    name                          = "ipconfig-web"
    subnet_id                     = azurerm_subnet.dmz_zone[0].id
    private_ip_address_allocation = "Static"
    private_ip_address            = "192.168.30.20"
  }
}

resource "azurerm_virtual_machine" "web_server" {
  count                 = local.deploy_azure ? 1 : 0
  name                  = "web-01"
  location              = azurerm_resource_group.honeypod[0].location
  resource_group_name   = azurerm_resource_group.honeypod[0].name
  vm_size               = var.server_vm_size
  network_interface_ids = [azurerm_network_interface.web_nic[0].id]

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
      key_data = fileexists(var.ssh_public_key_path) ? file(var.ssh_public_key_path) : ""
    }
  }

  tags = merge(local.common_tags, { Name = "Web Server", Zone = "dmz", Role = "web", Hostname = "web-01.corp.local" })
}

# ============================================================================
# SIEM Server (Security Plane)
# ============================================================================

resource "azurerm_public_ip" "siem_pip" {
  count               = local.deploy_azure ? 1 : 0
  name                = "pip-siem-01"
  location            = azurerm_resource_group.honeypod[0].location
  resource_group_name = azurerm_resource_group.honeypod[0].name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "siem_nic" {
  count               = local.deploy_azure ? 1 : 0
  name                = "nic-siem-01"
  location            = azurerm_resource_group.honeypod[0].location
  resource_group_name = azurerm_resource_group.honeypod[0].name

  ip_configuration {
    name                          = "ipconfig-siem"
    subnet_id                     = azurerm_subnet.security_subnet[0].id
    private_ip_address_allocation = "Static"
    private_ip_address            = "192.168.50.20"
    public_ip_address_id          = azurerm_public_ip.siem_pip[0].id
  }
}

resource "azurerm_virtual_machine" "siem_server" {
  count                 = local.deploy_azure ? 1 : 0
  name                  = "siem-01"
  location              = azurerm_resource_group.honeypod[0].location
  resource_group_name   = azurerm_resource_group.honeypod[0].name
  vm_size               = var.siem_vm_size
  network_interface_ids = [azurerm_network_interface.siem_nic[0].id]

  storage_os_disk {
    name              = "osdisk-siem-01"
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
    computer_name  = "siem-01"
    admin_username = "honeyadmin"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/honeyadmin/.ssh/authorized_keys"
      key_data = fileexists(var.ssh_public_key_path) ? file(var.ssh_public_key_path) : ""
    }
  }

  tags = merge(local.common_tags, { Name = "SIEM Server", Zone = "security", Role = "siem", Hostname = "siem-01.lab.honeypod.local" })
}

# ============================================================================
# Caldera C2 Server (Simulation Plane)
# ============================================================================

resource "azurerm_public_ip" "caldera_pip" {
  count               = local.deploy_azure ? 1 : 0
  name                = "pip-caldera-01"
  location            = azurerm_resource_group.honeypod[0].location
  resource_group_name = azurerm_resource_group.honeypod[0].name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "caldera_nic" {
  count               = local.deploy_azure ? 1 : 0
  name                = "nic-caldera-01"
  location            = azurerm_resource_group.honeypod[0].location
  resource_group_name = azurerm_resource_group.honeypod[0].name

  ip_configuration {
    name                          = "ipconfig-caldera"
    subnet_id                     = azurerm_subnet.simulation_subnet[0].id
    private_ip_address_allocation = "Static"
    private_ip_address            = "192.168.60.20"
    public_ip_address_id          = azurerm_public_ip.caldera_pip[0].id
  }
}

resource "azurerm_virtual_machine" "caldera_server" {
  count                 = local.deploy_azure ? 1 : 0
  name                  = "attack-caldera-01"
  location              = azurerm_resource_group.honeypod[0].location
  resource_group_name   = azurerm_resource_group.honeypod[0].name
  vm_size               = var.caldera_vm_size
  network_interface_ids = [azurerm_network_interface.caldera_nic[0].id]

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
      key_data = fileexists(var.ssh_public_key_path) ? file(var.ssh_public_key_path) : ""
    }
  }

  tags = merge(local.common_tags, { Name = "Caldera C2", Zone = "simulation", Role = "caldera", Hostname = "attack-caldera-01.lab.honeypod.local" })
}

# ============================================================================
# OpenCanary Honeypot (Deception Plane)
# ============================================================================

resource "azurerm_network_interface" "canary_nic" {
  count               = local.deploy_azure ? 1 : 0
  name                = "nic-canary-01"
  location            = azurerm_resource_group.honeypod[0].location
  resource_group_name = azurerm_resource_group.honeypod[0].name

  ip_configuration {
    name                          = "ipconfig-canary"
    subnet_id                     = azurerm_subnet.deception_subnet[0].id
    private_ip_address_allocation = "Static"
    private_ip_address            = "192.168.40.10"
  }
}

resource "azurerm_virtual_machine" "canary" {
  count                 = local.deploy_azure ? 1 : 0
  name                  = "canary-01"
  location              = azurerm_resource_group.honeypod[0].location
  resource_group_name   = azurerm_resource_group.honeypod[0].name
  vm_size               = var.endpoint_vm_size
  network_interface_ids = [azurerm_network_interface.canary_nic[0].id]

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
      key_data = fileexists(var.ssh_public_key_path) ? file(var.ssh_public_key_path) : ""
    }
  }

  tags = merge(local.common_tags, { Name = "OpenCanary Honeypot", Zone = "deception", Role = "canary", Hostname = "canary-01.lab.honeypod.local" })
}

# ============================================================================
# Cowrie SSH Honeypot (Deception Plane)
# ============================================================================

resource "azurerm_network_interface" "cowrie_nic" {
  count               = local.deploy_azure ? 1 : 0
  name                = "nic-cowrie-01"
  location            = azurerm_resource_group.honeypod[0].location
  resource_group_name = azurerm_resource_group.honeypod[0].name

  ip_configuration {
    name                          = "ipconfig-cowrie"
    subnet_id                     = azurerm_subnet.deception_subnet[0].id
    private_ip_address_allocation = "Static"
    private_ip_address            = "192.168.40.20"
  }
}

resource "azurerm_virtual_machine" "cowrie" {
  count                 = local.deploy_azure ? 1 : 0
  name                  = "cowrie-01"
  location              = azurerm_resource_group.honeypod[0].location
  resource_group_name   = azurerm_resource_group.honeypod[0].name
  vm_size               = var.endpoint_vm_size
  network_interface_ids = [azurerm_network_interface.cowrie_nic[0].id]

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
      key_data = fileexists(var.ssh_public_key_path) ? file(var.ssh_public_key_path) : ""
    }
  }

  tags = merge(local.common_tags, { Name = "Cowrie SSH Honeypot", Zone = "deception", Role = "cowrie", Hostname = "cowrie-01.lab.honeypod.local" })
}
