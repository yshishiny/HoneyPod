# ============================================================================
# Hyper-V Virtual Switches (etwork Segmetatio)
# ============================================================================

# Exteral Switch - Lab Maagemet & Coectivity
resource "hyperv_etwork_iterface" "exteral" {
  ame = "HoeyPod-Exteral"
}

variable "use_at" {
  descriptio = "Use AT for exteral coectivity istead of exteral vSwitch"
  type        = bool
  default     = false
}

# Productio Rage vSwitch (Isolated - Lab etwork)
resource "hyperv_vla" "lab_rage" {
  ame = "HoeyPod-Lab-Rage"
  vla_id = 100
}

# Server Zoe vSwitch (Isolated)
resource "hyperv_vla" "server_zoe" {
  ame = "HoeyPod-Server-Zoe"
  vla_id = 101
}

# User Zoe vSwitch (Isolated)
resource "hyperv_vla" "user_zoe" {
  ame = "HoeyPod-User-Zoe"
  vla_id = 102
}

# Deceptio Zoe vSwitch (Isolated - Hoeypots)
resource "hyperv_vla" "deceptio_zoe" {
  ame = "HoeyPod-Deceptio-Zoe"
  vla_id = 103
}

# Security Toolig vSwitch (SIEM, Loggig, Moitorig)
resource "hyperv_vla" "security_zoe" {
  ame = "HoeyPod-Security-Zoe"
  vla_id = 104
}

# Attack Simulatio vSwitch (Caldera C2)
resource "hyperv_vla" "simulatio_zoe" {
  ame = "HoeyPod-Simulatio-Zoe"
  vla_id = 105
}

# ============================================================================
# etwork Cofiguratio Map (for referece)
# ============================================================================
locals {
  etwork_cofig = {
    exteral = {
      vswitch = "Exteral"
      vla    = ull
      subet  = "DHCP"
    }
    server_zoe = {
      vswitch = hyperv_vla.server_zoe.ame
      vla    = 101
      subet  = "192.168.20.0/24"
    }
    user_zoe = {
      vswitch = hyperv_vla.user_zoe.ame
      vla    = 102
      subet  = "192.168.10.0/24"
    }
    deceptio_zoe = {
      vswitch = hyperv_vla.deceptio_zoe.ame
      vla    = 103
      subet  = "192.168.40.0/25"
    }
    security_zoe = {
      vswitch = hyperv_vla.security_zoe.ame
      vla    = 104
      subet  = "192.168.50.0/25"
    }
    simulatio_zoe = {
      vswitch = hyperv_vla.simulatio_zoe.ame
      vla    = 105
      subet  = "192.168.60.0/25"
    }
  }
}

# Azure SG resources moved to etworks-azure.tf
# (requires azurerm provider — oly active whe azure_subscriptio_id is set)

# All Azure SG defiitios ad subet associatios are i etworks-azure.tf

# Placeholder — remove this lie if liter complais about empty file tail
# etworks.tf eds here (Hyper-V resources oly)

