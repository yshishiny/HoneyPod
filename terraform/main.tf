terraform {
  required_version = ">= 1.0"
  
  required_providers {
    hyperv = {
      source  = "taliesins/hyperv"
      version = "~> 0.17"
    }
  }
  
  backend "local" {
    path = "terraform.tfstate"
  }
}

# ============================================================================
# Hyper-V Provider Configuration (Local Machine)
# ============================================================================
provider "hyperv" {
  user     = var.hyperv_user
  password = var.hyperv_password
  host     = var.hyperv_host
  https    = var.hyperv_https
  insecure = var.hyperv_insecure
  timeout  = var.hyperv_timeout
}

# ============================================================================
# Local Variables (configuration)
# ============================================================================
locals {
  lab_domain              = var.lab_domain
  lab_timezone            = var.lab_timezone
  environment             = var.environment
  project                 = var.project
  vm_storage_path         = var.vm_storage_path
  vm_templates_path       = var.vm_templates_path
  
  common_tags = {
    Environment = local.environment
    Project     = local.project
    Purpose     = "Cyber Range"
    ManagedBy   = "Terraform"
  }

  # VM Configurations (name, template, memory, vcpus, ip)
  vms = {
    dc = {
      name     = "dc-honeypod-01"
      template = "Windows2022-Template"
      memory   = var.server_memory
      vcpus    = var.server_vcpus
      ip       = "192.168.20.10"
      zone     = "server"
    }
    ep01 = {
      name     = "ep-honeypod-01"
      template = "Windows10-Template"
      memory   = var.endpoint_memory
      vcpus    = var.endpoint_vcpus
      ip       = "192.168.10.11"
      zone     = "user"
    }
    ep02 = {
      name     = "ep-honeypod-02"
      template = "Windows10-Template"
      memory   = var.endpoint_memory
      vcpus    = var.endpoint_vcpus
      ip       = "192.168.10.12"
      zone     = "user"
    }
    siem = {
      name     = "siem-honeypod-01"
      template = "Ubuntu22-Template"
      memory   = var.siem_memory
      vcpus    = var.siem_vcpus
      ip       = "192.168.50.10"
      zone     = "security"
    }
    caldera = {
      name     = "caldera-honeypod-01"
      template = "Ubuntu22-Template"
      memory   = var.caldera_memory
      vcpus    = var.caldera_vcpus
      ip       = "192.168.60.10"
      zone     = "simulation"
    }
    deception = {
      name     = "deception-honeypod-01"
      template = "Ubuntu22-Template"
      memory   = var.deception_memory
      vcpus    = var.deception_vcpus
      ip       = "192.168.40.10"
      zone     = "deception"
    }
  }
}
