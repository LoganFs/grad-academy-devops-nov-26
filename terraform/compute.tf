# The single public IP: the "Public IP (vm_pip)" box in the Mission 1 diagram.
resource "azurerm_public_ip" "vm" {
  name                = "${var.prefix}-vm-pip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags
}

# The NIC: the "NIC" box, wired to the subnet and the public IP.
resource "azurerm_network_interface" "main" {
  name                = "${var.prefix}-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm.id
  }
}

# The one "social_hub_single" VM. Docker runs the Social Hub container(s) on it;
# Mission 3 adds an Nginx LB + a second app container on this same box.
#
# Needs >= 2 vCPUs (B2s) so the two app containers can use separate cores in
# Mission 3 — on a 1-vCPU box the second container wouldn't add any throughput.
resource "azurerm_linux_virtual_machine" "main" {
  name                = "${var.prefix}-social-hub"
  computer_name       = "social-hub-single"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  size                = var.vm_size
  admin_username      = var.admin_username
  tags                = local.tags

  network_interface_ids = [azurerm_network_interface.main.id]

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(pathexpand(var.ssh_public_key_path))
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  # Render cloud-init, embedding the app source and the docker/ files so those
  # directories stay the single source of truth.
  custom_data = base64encode(templatefile("${path.module}/cloud-init/social-hub.yaml.tftpl", {
    admin_username  = var.admin_username
    server_js       = file("${path.module}/../app/server.js")
    package_json    = file("${path.module}/../app/package.json")
    dockerfile      = file("${path.module}/../docker/Dockerfile")
    compose_vanilla = file("${path.module}/../docker/docker-compose.yml")
    compose_ha      = file("${path.module}/../docker/docker-compose.ha.yml")
    nginx_conf      = file("${path.module}/../docker/nginx.conf")
  }))
}
