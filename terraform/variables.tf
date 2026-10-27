variable "prefix" {
  description = "Name prefix for every resource. Matches the diagrams (vice-city-01-*)."
  type        = string
  default     = "vice-city-01"
}

variable "location" {
  description = "Azure region to deploy into."
  type        = string
  default     = "uksouth"
}

variable "vm_size" {
  description = <<-EOT
    VM size. Needs >= 2 vCPUs so Mission 3's two app containers can run on
    separate cores — a single-vCPU box (B1s) wouldn't gain any throughput.
    B2s = 2 vCPU / 4 GB.
  EOT
  type        = string
  default     = "Standard_B2s"
}

variable "admin_username" {
  description = "Admin user created on the VM."
  type        = string
  default     = "rockstar"
}

variable "ssh_public_key_path" {
  description = "Path to the SSH public key used for VM login. Run `ssh-keygen` if you don't have one."
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}
