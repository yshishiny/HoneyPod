# ============================================================================
# Hyper-V Virtual Switches (Network Segmentation)
# ============================================================================

# External Switch - Lab Management & Connectivity
resource "hyperv_network_interface" "external" {
  name = "HoneyPod-External"
}

variable "use_nat" {
  description = "Use NAT for external connectivity instead of external vSwitch"
  type        = bool
  default     = false
}

# Production Range vSwitch (Isolated - Lab Network)
resource "hyperv_vlan" "lab_range" {
  name = "HoneyPod-Lab-Range"
  vlan_id = 100
}

# Server Zone vSwitch (Isolated)
resource "hyperv_vlan" "server_zone" {
  name = "HoneyPod-Server-Zone"
  vlan_id = 101
}

# User Zone vSwitch (Isolated)
resource "hyperv_vlan" "user_zone" {
  name = "HoneyPod-User-Zone"
  vlan_id = 102
}

# Deception Zone vSwitch (Isolated - Honeypots)
resource "hyperv_vlan" "deception_zone" {
  name = "HoneyPod-Deception-Zone"
  vlan_id = 103
}

# Security Tooling vSwitch (SIEM, Logging, Monitoring)
resource "hyperv_vlan" "security_zone" {
  name = "HoneyPod-Security-Zone"
  vlan_id = 104
}

# Attack Simulation vSwitch (Caldera C2)
resource "hyperv_vlan" "simulation_zone" {
  name = "HoneyPod-Simulation-Zone"
  vlan_id = 105
}

# ============================================================================
# Network Configuration Map (for reference)
# ============================================================================
locals {
  network_config = {
    external = {
      vswitch = "External"
      vlan    = null
      subnet  = "DHCP"
    }
    server_zone = {
      vswitch = hyperv_vlan.server_zone.name
      vlan    = 101
      subnet  = "192.168.20.0/24"
    }
    user_zone = {
      vswitch = hyperv_vlan.user_zone.name
      vlan    = 102
      subnet  = "192.168.10.0/24"
    }
    deception_zone = {
      vswitch = hyperv_vlan.deception_zone.name
      vlan    = 103
      subnet  = "192.168.40.0/25"
    }
    security_zone = {
      vswitch = hyperv_vlan.security_zone.name
      vlan    = 104
      subnet  = "192.168.50.0/25"
    }
    simulation_zone = {
      vswitch = hyperv_vlan.simulation_zone.name
      vlan    = 105
      subnet  = "192.168.60.0/25"
    }
  }
}

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

# NSG: Server Zone
resource "azurerm_network_security_group" "server_zone_nsg" {
  name                = "nsg-server-zone"
  location            = azurerm_resource_group.honeypod.location
  resource_group_name = azurerm_resource_group.honeypod.name

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

# NSG: DMZ Zone
resource "azurerm_network_security_group" "dmz_zone_nsg" {
  name                = "nsg-dmz-zone"
  location            = azurerm_resource_group.honeypod.location
  resource_group_name = azurerm_resource_group.honeypod.name

  security_rule {
    name                       = "allow-intra-dmz"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "192.168.30.0/24"
    destination_address_prefix = "192.168.30.0/24"
  }

  security_rule {
    name                       = "allow-http-https-inbound"
    priority                   = 110
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
    priority                   = 120
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

# NSG: Deception Zone (isolated, only logs out)
resource "azurerm_network_security_group" "deception_zone_nsg" {
  name                = "nsg-deception-zone"
  location            = azurerm_resource_group.honeypod.location
  resource_group_name = azurerm_resource_group.honeypod.name

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

# NSG: Security Tooling (SIEM, logs)
resource "azurerm_network_security_group" "security_zone_nsg" {
  name                = "nsg-security-zone"
  location            = azurerm_resource_group.honeypod.location
  resource_group_name = azurerm_resource_group.honeypod.name

  security_rule {
    name                       = "allow-intra-security"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "192.168.50.0/24"
    destination_address_prefix = "192.168.50.0/24"
  }

  security_rule {
    name                       = "allow-logstash-syslog"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "UDP"
    source_port_range          = "*"
    destination_port_range     = "514"
    source_address_prefix      = "192.168.10.0/24"
    destination_address_prefix = "192.168.50.0/24"
  }

  security_rule {
    name                       = "allow-logstash-syslog-from-servers"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "UDP"
    source_port_range          = "*"
    destination_port_range     = "514"
    source_address_prefix      = "192.168.20.0/24"
    destination_address_prefix = "192.168.50.0/24"
  }

  security_rule {
    name                       = "allow-logstash-syslog-from-dmz"
    priority                   = 130
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "UDP"
    source_port_range          = "*"
    destination_port_range     = "514"
    source_address_prefix      = "192.168.30.0/24"
    destination_address_prefix = "192.168.50.0/24"
  }

  security_rule {
    name                       = "allow-logstash-syslog-from-deception"
    priority                   = 140
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "UDP"
    source_port_range          = "*"
    destination_port_range     = "514"
    source_address_prefix      = "192.168.40.0/24"
    destination_address_prefix = "192.168.50.0/24"
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

# NSG: Attack Simulation (Caldera)
resource "azurerm_network_security_group" "simulation_zone_nsg" {
  name                = "nsg-simulation-zone"
  location            = azurerm_resource_group.honeypod.location
  resource_group_name = azurerm_resource_group.honeypod.name

  security_rule {
    name                       = "allow-intra-simulation"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "192.168.60.0/24"
    destination_address_prefix = "192.168.60.0/24"
  }

  security_rule {
    name                       = "allow-mgmt-access"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "TCP"
    source_port_range          = "*"
    destination_port_range     = "443,8080"
    source_address_prefix      = "192.168.100.0/24"
    destination_address_prefix = "192.168.60.0/24"
  }

  security_rule {
    name                       = "deny-to-deception"
    priority                   = 4090
    direction                  = "Outbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "192.168.60.0/24"
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

# Associate NSGs with subnets
resource "azurerm_subnet_network_security_group_association" "user_nsg_assoc" {
  subnet_id                 = azurerm_subnet.user_zone.id
  network_security_group_id = azurerm_network_security_group.user_zone_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "server_nsg_assoc" {
  subnet_id                 = azurerm_subnet.server_zone.id
  network_security_group_id = azurerm_network_security_group.server_zone_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "dmz_nsg_assoc" {
  subnet_id                 = azurerm_subnet.dmz_zone.id
  network_security_group_id = azurerm_network_security_group.dmz_zone_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "deception_nsg_assoc" {
  subnet_id                 = azurerm_subnet.deception_subnet.id
  network_security_group_id = azurerm_network_security_group.deception_zone_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "security_nsg_assoc" {
  subnet_id                 = azurerm_subnet.security_subnet.id
  network_security_group_id = azurerm_network_security_group.security_zone_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "simulation_nsg_assoc" {
  subnet_id                 = azurerm_subnet.simulation_subnet.id
  network_security_group_id = azurerm_network_security_group.simulation_zone_nsg.id
}

output "user_zone_subnet_id" {
  value = azurerm_subnet.user_zone.id
}

output "server_zone_subnet_id" {
  value = azurerm_subnet.server_zone.id
}

output "dmz_zone_subnet_id" {
  value = azurerm_subnet.dmz_zone.id
}

output "deception_subnet_id" {
  value = azurerm_subnet.deception_subnet.id
}

output "security_subnet_id" {
  value = azurerm_subnet.security_subnet.id
}

output "simulation_subnet_id" {
  value = azurerm_subnet.simulation_subnet.id
}
