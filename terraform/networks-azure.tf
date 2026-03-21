# ============================================================================
# Azure Network Security Groups
# Only deployed when azure_subscription_id is set (local.deploy_azure == true)
# References subnets defined in azure-base.tf
# ============================================================================

# ============================================================================
# NSG: User Zone (Windows Endpoints)
# ============================================================================
resource "azurerm_network_security_group" "user_zone_nsg" {
  count               = local.deploy_azure ? 1 : 0
  name                = "nsg-user-zone"
  location            = azurerm_resource_group.honeypod[0].location
  resource_group_name = azurerm_resource_group.honeypod[0].name

  security_rule {
    name                       = "allow-intra-user-zone"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "192.168.10.0/24"
    destination_address_prefix = "192.168.10.0/24"
  }

  security_rule {
    name                       = "allow-siem-telemetry-out"
    priority                   = 200
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "UDP"
    source_port_range          = "*"
    destination_port_range     = "514"
    source_address_prefix      = "192.168.10.0/24"
    destination_address_prefix = "192.168.50.0/24"
  }

  security_rule {
    name                       = "deny-to-deception"
    priority                   = 4090
    direction                  = "Outbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "192.168.10.0/24"
    destination_address_prefix = "192.168.40.0/24"
  }

  security_rule {
    name                       = "default-deny-inbound"
    priority                   = 4095
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# ============================================================================
# NSG: Server Zone (DC, DB, Web)
# ============================================================================
resource "azurerm_network_security_group" "server_zone_nsg" {
  count               = local.deploy_azure ? 1 : 0
  name                = "nsg-server-zone"
  location            = azurerm_resource_group.honeypod[0].location
  resource_group_name = azurerm_resource_group.honeypod[0].name

  security_rule {
    name                       = "allow-intra-server-zone"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "192.168.20.0/24"
    destination_address_prefix = "192.168.20.0/24"
  }

  security_rule {
    name                       = "allow-smb-from-endpoints"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "TCP"
    source_port_range          = "*"
    destination_port_range     = "445"
    source_address_prefix      = "192.168.10.0/24"
    destination_address_prefix = "192.168.20.0/24"
  }

  security_rule {
    name                       = "allow-app-from-dmz"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "TCP"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "192.168.30.0/24"
    destination_address_prefix = "192.168.20.0/24"
  }

  security_rule {
    name                       = "allow-db-from-dmz"
    priority                   = 130
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "TCP"
    source_port_range          = "*"
    destination_port_range     = "5432"
    source_address_prefix      = "192.168.30.0/24"
    destination_address_prefix = "192.168.20.0/24"
  }

  security_rule {
    name                       = "allow-siem-telemetry-out"
    priority                   = 200
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "UDP"
    source_port_range          = "*"
    destination_port_range     = "514"
    source_address_prefix      = "192.168.20.0/24"
    destination_address_prefix = "192.168.50.0/24"
  }

  security_rule {
    name                       = "deny-to-deception"
    priority                   = 4090
    direction                  = "Outbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "192.168.20.0/24"
    destination_address_prefix = "192.168.40.0/24"
  }

  security_rule {
    name                       = "default-deny-inbound"
    priority                   = 4095
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# ============================================================================
# NSG: DMZ Zone
# ============================================================================
resource "azurerm_network_security_group" "dmz_zone_nsg" {
  count               = local.deploy_azure ? 1 : 0
  name                = "nsg-dmz-zone"
  location            = azurerm_resource_group.honeypod[0].location
  resource_group_name = azurerm_resource_group.honeypod[0].name

  security_rule {
    name                       = "allow-http-https-inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "TCP"
    source_port_range          = "*"
    destination_port_range     = "80,443"
    source_address_prefix      = "*"
    destination_address_prefix = "192.168.30.0/24"
  }

  security_rule {
    name                       = "allow-backend-access"
    priority                   = 110
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "TCP"
    source_port_range          = "*"
    destination_port_range     = "3306,5432,8080"
    source_address_prefix      = "192.168.30.0/24"
    destination_address_prefix = "192.168.20.0/24"
  }

  security_rule {
    name                       = "allow-siem-telemetry-out"
    priority                   = 200
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "UDP"
    source_port_range          = "*"
    destination_port_range     = "514"
    source_address_prefix      = "192.168.30.0/24"
    destination_address_prefix = "192.168.50.0/24"
  }

  security_rule {
    name                       = "deny-to-deception"
    priority                   = 4090
    direction                  = "Outbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "192.168.30.0/24"
    destination_address_prefix = "192.168.40.0/24"
  }

  security_rule {
    name                       = "default-deny-inbound"
    priority                   = 4095
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# ============================================================================
# NSG: Deception Zone (isolated — only logs out to SIEM)
# ============================================================================
resource "azurerm_network_security_group" "deception_zone_nsg" {
  count               = local.deploy_azure ? 1 : 0
  name                = "nsg-deception-zone"
  location            = azurerm_resource_group.honeypod[0].location
  resource_group_name = azurerm_resource_group.honeypod[0].name

  security_rule {
    name                       = "allow-intra-deception"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "192.168.40.0/24"
    destination_address_prefix = "192.168.40.0/24"
  }

  security_rule {
    name                       = "allow-siem-telemetry-out"
    priority                   = 200
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "UDP"
    source_port_range          = "*"
    destination_port_range     = "514"
    source_address_prefix      = "192.168.40.0/24"
    destination_address_prefix = "192.168.50.0/24"
  }

  security_rule {
    name                       = "default-deny-all"
    priority                   = 4095
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# ============================================================================
# NSG: Security Zone (SIEM / ELK Stack)
# ============================================================================
resource "azurerm_network_security_group" "security_zone_nsg" {
  count               = local.deploy_azure ? 1 : 0
  name                = "nsg-security-zone"
  location            = azurerm_resource_group.honeypod[0].location
  resource_group_name = azurerm_resource_group.honeypod[0].name

  security_rule {
    name                       = "allow-logstash-syslog-all-zones"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "UDP"
    source_port_range          = "*"
    destination_port_range     = "514"
    source_address_prefix      = "192.168.0.0/16"
    destination_address_prefix = "192.168.50.0/25"
  }

  security_rule {
    name                       = "allow-beats-inbound"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "TCP"
    source_port_range          = "*"
    destination_port_range     = "5000,5044"
    source_address_prefix      = "192.168.0.0/16"
    destination_address_prefix = "192.168.50.0/25"
  }

  security_rule {
    name                       = "default-deny-inbound"
    priority                   = 4095
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# ============================================================================
# NSG: Simulation Zone (Caldera C2)
# ============================================================================
resource "azurerm_network_security_group" "simulation_zone_nsg" {
  count               = local.deploy_azure ? 1 : 0
  name                = "nsg-simulation-zone"
  location            = azurerm_resource_group.honeypod[0].location
  resource_group_name = azurerm_resource_group.honeypod[0].name

  security_rule {
    name                       = "allow-caldera-mgmt"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "TCP"
    source_port_range          = "*"
    destination_port_range     = "443,8888"
    source_address_prefix      = "192.168.100.0/24"
    destination_address_prefix = "192.168.60.0/25"
  }

  security_rule {
    name                       = "deny-to-deception"
    priority                   = 4090
    direction                  = "Outbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "192.168.60.0/25"
    destination_address_prefix = "192.168.40.0/24"
  }

  security_rule {
    name                       = "default-deny-inbound"
    priority                   = 4095
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# ============================================================================
# NSG → Subnet Associations
# ============================================================================
resource "azurerm_subnet_network_security_group_association" "user_nsg_assoc" {
  count                     = local.deploy_azure ? 1 : 0
  subnet_id                 = azurerm_subnet.user_zone[0].id
  network_security_group_id = azurerm_network_security_group.user_zone_nsg[0].id
}

resource "azurerm_subnet_network_security_group_association" "server_nsg_assoc" {
  count                     = local.deploy_azure ? 1 : 0
  subnet_id                 = azurerm_subnet.server_zone[0].id
  network_security_group_id = azurerm_network_security_group.server_zone_nsg[0].id
}

resource "azurerm_subnet_network_security_group_association" "dmz_nsg_assoc" {
  count                     = local.deploy_azure ? 1 : 0
  subnet_id                 = azurerm_subnet.dmz_zone[0].id
  network_security_group_id = azurerm_network_security_group.dmz_zone_nsg[0].id
}

resource "azurerm_subnet_network_security_group_association" "deception_nsg_assoc" {
  count                     = local.deploy_azure ? 1 : 0
  subnet_id                 = azurerm_subnet.deception_subnet[0].id
  network_security_group_id = azurerm_network_security_group.deception_zone_nsg[0].id
}

resource "azurerm_subnet_network_security_group_association" "security_nsg_assoc" {
  count                     = local.deploy_azure ? 1 : 0
  subnet_id                 = azurerm_subnet.security_subnet[0].id
  network_security_group_id = azurerm_network_security_group.security_zone_nsg[0].id
}

resource "azurerm_subnet_network_security_group_association" "simulation_nsg_assoc" {
  count                     = local.deploy_azure ? 1 : 0
  subnet_id                 = azurerm_subnet.simulation_subnet[0].id
  network_security_group_id = azurerm_network_security_group.simulation_zone_nsg[0].id
}

# ============================================================================
# Outputs (only when Azure is deployed)
# ============================================================================
output "user_zone_subnet_id" {
  value = local.deploy_azure ? azurerm_subnet.user_zone[0].id : ""
}

output "server_zone_subnet_id" {
  value = local.deploy_azure ? azurerm_subnet.server_zone[0].id : ""
}

output "dmz_zone_subnet_id" {
  value = local.deploy_azure ? azurerm_subnet.dmz_zone[0].id : ""
}

output "deception_subnet_id" {
  value = local.deploy_azure ? azurerm_subnet.deception_subnet[0].id : ""
}

output "security_subnet_id" {
  value = local.deploy_azure ? azurerm_subnet.security_subnet[0].id : ""
}

output "simulation_subnet_id" {
  value = local.deploy_azure ? azurerm_subnet.simulation_subnet[0].id : ""
}
