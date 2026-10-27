# The URL to hit with k6. It never changes between missions — the VM's public
# IP fronts the single vanilla container (Mission 1) and the Nginx LB (Mission 3).
output "social_hub_url" {
  description = "Base URL of the Social Hub to load test."
  value       = "http://${azurerm_public_ip.vm.ip_address}"
}

output "vm_public_ip" {
  description = "Public IP of the VM (for SSH)."
  value       = azurerm_public_ip.vm.ip_address
}

output "ssh_command" {
  description = "Handy SSH command for the VM."
  value       = "ssh ${var.admin_username}@${azurerm_public_ip.vm.ip_address}"
}
