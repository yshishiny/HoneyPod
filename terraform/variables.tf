# ============================================================================
# Hyper-V Infrastructure Variables
# ============================================================================

# ============================================================================
# Hyper-V Connection Configuration
# ============================================================================
variable "hyperv_host" {
  description = "Hyper-V host name (FQDN or IP). Leave empty for local host."
  type        = string
  default     = ""
}

variable "hyperv_user" {
  description = "Hyper-V admin username. Leave empty to use current Windows credentials."
  type        = string
  sensitive   = true
  default     = ""
}

variable "hyperv_password" {
  description = "Hyper-V admin password. Leave empty to use current Windows credentials."
  type        = string
  sensitive   = true
  default     = ""
}

variable "hyperv_https" {
  description = "Use HTTPS for Hyper-V WinRM connection"
  type        = bool
  default     = true
}

variable "hyperv_insecure" {
  description = "Skip SSL verification (not recommended for production)"
  type        = bool
  default     = true
}

variable "hyperv_timeout" {
  description = "Connection timeout in seconds"
  type        = number
  default     = 300
}

# ============================================================================
# Lab Configuration
# ============================================================================
variable "lab_domain" {
  description = "Active Directory domain for lab"
  type        = string
  default     = "corp.local"
}

variable "lab_timezone" {
  description = "Lab timezone"
  type        = string
  default     = "UTC"
}

variable "environment" {
  description = "Environment tag"
  type        = string
  default     = "lab"
}

variable "project" {
  description = "Project name"
  type        = string
  default     = "HoneyPod"
}

# ============================================================================
# VM Storage Configuration
# ============================================================================
variable "vm_storage_path" {
  description = "Root path for VM storage (VHDXs)"
  type        = string
  default     = "C:\\Hyper-V\\VMs"
}

variable "vm_templates_path" {
  description = "Path to VM template VHDX files"
  type        = string
  default     = "C:\\Hyper-V\\Templates"
}

# ============================================================================
# VM Creation Options
# ============================================================================
variable "vm_wait_for_state" {
  description = "Wait for VM to reach desired state"
  type        = string
  default     = "Running"
}

variable "vm_wait_for_ip" {
  description = "Wait for VM to acquire IP address"
  type        = bool
  default     = true
}

# ============================================================================
# Server VM (Domain Controller) Configuration
# ============================================================================
variable "server_memory" {
  description = "Memory (MB) for server VMs"
  type        = number
  default     = 4096
}

variable "server_vcpus" {
  description = "vCPU count for server VMs"
  type        = number
  default     = 4
}

# ============================================================================
# Endpoint VM (Windows 10) Configuration
# ============================================================================
variable "endpoint_memory" {
  description = "Memory (MB) for endpoint VMs"
  type        = number
  default     = 2048
}

variable "endpoint_vcpus" {
  description = "vCPU count for endpoint VMs"
  type        = number
  default     = 2
}

# ============================================================================
# SIEM Server (ELK Stack) Configuration
# ============================================================================
variable "siem_memory" {
  description = "Memory (MB) for SIEM server"
  type        = number
  default     = 8192
}

variable "siem_vcpus" {
  description = "vCPU count for SIEM server"
  type        = number
  default     = 4
}

# ============================================================================
# Caldera C2 Server Configuration
# ============================================================================
variable "caldera_memory" {
  description = "Memory (MB) for Caldera C2 server"
  type        = number
  default     = 2048
}

variable "caldera_vcpus" {
  description = "vCPU count for Caldera C2"
  type        = number
  default     = 2
}

# ============================================================================
# Deception Layer (Honeypots) Configuration
# ============================================================================
variable "deception_memory" {
  description = "Memory (MB) for deception layer VMs"
  type        = number
  default     = 1024
}

variable "deception_vcpus" {
  description = "vCPU count for deception VMs"
  type        = number
  default     = 1
}

# ============================================================================
# Network Configuration
# ============================================================================
variable "enable_vlan_isolation" {
  description = "Enable VLAN isolation between zones"
  type        = bool
  default     = true
}

variable "network_nat_enabled" {
  description = "Enable NAT for lab network"
  type        = bool
  default     = false
}

variable "snapshot_retention_days" {
  description = "Retain snapshots for N days"
  type        = number
  default     = 30
}
