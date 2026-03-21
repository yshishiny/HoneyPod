# ============================================================================
# Azure Base Infrastructure
# Resource Group, VNet, and Subnets used by networks.tf NSGs and vms.tf VMs
# Only applied when deploying to Azure (azure_subscription_id is set)
# ============================================================================

locals {
  deploy_azure = var.azure_subscription_id != ""
}

resource "azurerm_resource_group" "honeypod" {
  count    = local.deploy_azure ? 1 : 0
  name     = var.azure_resource_group
  location = var.azure_location

  tags = local.common_tags
}

resource "azurerm_virtual_network" "honeypod" {
  count               = local.deploy_azure ? 1 : 0
  name                = "vnet-honeypod-lab"
  address_space       = ["192.168.0.0/16"]
  location            = azurerm_resource_group.honeypod[0].location
  resource_group_name = azurerm_resource_group.honeypod[0].name

  tags = local.common_tags
}

# User Zone (Windows Endpoints)
resource "azurerm_subnet" "user_zone" {
  count                = local.deploy_azure ? 1 : 0
  name                 = "snet-user-zone"
  resource_group_name  = azurerm_resource_group.honeypod[0].name
  virtual_network_name = azurerm_virtual_network.honeypod[0].name
  address_prefixes     = ["192.168.10.0/24"]
}

# Server Zone (Domain Controller, DB, Web)
resource "azurerm_subnet" "server_zone" {
  count                = local.deploy_azure ? 1 : 0
  name                 = "snet-server-zone"
  resource_group_name  = azurerm_resource_group.honeypod[0].name
  virtual_network_name = azurerm_virtual_network.honeypod[0].name
  address_prefixes     = ["192.168.20.0/24"]
}

# DMZ Zone (Web-facing services)
resource "azurerm_subnet" "dmz_zone" {
  count                = local.deploy_azure ? 1 : 0
  name                 = "snet-dmz-zone"
  resource_group_name  = azurerm_resource_group.honeypod[0].name
  virtual_network_name = azurerm_virtual_network.honeypod[0].name
  address_prefixes     = ["192.168.30.0/24"]
}

# Deception Zone (Honeypots - isolated)
resource "azurerm_subnet" "deception_subnet" {
  count                = local.deploy_azure ? 1 : 0
  name                 = "snet-deception-zone"
  resource_group_name  = azurerm_resource_group.honeypod[0].name
  virtual_network_name = azurerm_virtual_network.honeypod[0].name
  address_prefixes     = ["192.168.40.0/25"]
}

# Security Zone (SIEM / ELK Stack)
resource "azurerm_subnet" "security_subnet" {
  count                = local.deploy_azure ? 1 : 0
  name                 = "snet-security-zone"
  resource_group_name  = azurerm_resource_group.honeypod[0].name
  virtual_network_name = azurerm_virtual_network.honeypod[0].name
  address_prefixes     = ["192.168.50.0/25"]
}

# Simulation Zone (Caldera C2)
resource "azurerm_subnet" "simulation_subnet" {
  count                = local.deploy_azure ? 1 : 0
  name                 = "snet-simulation-zone"
  resource_group_name  = azurerm_resource_group.honeypod[0].name
  virtual_network_name = azurerm_virtual_network.honeypod[0].name
  address_prefixes     = ["192.168.60.0/25"]
}
