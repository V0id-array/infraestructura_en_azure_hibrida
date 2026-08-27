locals {
  prefix   = "${var.project_name}-${var.environment}"
  dc_names = [for i in range(var.dc_count) : "vm-dc-${local.prefix}-${format("%02d", i + 1)}"]
}

resource "azurerm_network_interface" "dc" {
  count = var.dc_count

  name                = "nic-dc-${local.prefix}-${format("%02d", count.index + 1)}"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  ip_configuration {
    name                          = "ipconfig-dc"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Static"
    # IPs fijas necesarias para resolver DNS (10.0.4.10 / 10.0.4.11)
    private_ip_address            = "10.0.4.${10 + count.index}"
  }
}

# ILB para balancear DNS/LDAP hacia los dos DCs
resource "azurerm_lb" "dc" {
  name                = "lb-dc-${local.prefix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Standard"
  tags                = merge(var.tags, { Componente = "ActiveDirectory-LB" })

  frontend_ip_configuration {
    name                          = "frontend-dc-lb"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.4.9"
  }
}

resource "azurerm_lb_backend_address_pool" "dc" {
  loadbalancer_id = azurerm_lb.dc.id
  name            = "backend-pool-dc"
}

resource "azurerm_network_interface_backend_address_pool_association" "dc" {
  count = var.dc_count


  network_interface_id    = azurerm_network_interface.dc[count.index].id
  ip_configuration_name   = "ipconfig-dc"
  backend_address_pool_id = azurerm_lb_backend_address_pool.dc.id
}

# ─── Health Probes (DNS & LDAP) ───────────────────────────────────────────────

resource "azurerm_lb_probe" "dns" {
  loadbalancer_id = azurerm_lb.dc.id
  name            = "probe-dns-53"
  port            = 53
  protocol        = "Tcp"
}

resource "azurerm_lb_probe" "ldap" {
  loadbalancer_id = azurerm_lb.dc.id
  name            = "probe-ldap-389"
  port            = 389
  protocol        = "Tcp"
}

# ─── Load Balancing Rules ─────────────────────────────────────────────────────

# Regla DNS UDP
resource "azurerm_lb_rule" "dns_udp" {
  loadbalancer_id                = azurerm_lb.dc.id
  name                           = "rule-dns-udp"
  protocol                       = "Udp"
  frontend_port                  = 53
  backend_port                   = 53
  frontend_ip_configuration_name = "frontend-dc-lb"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.dc.id]
  probe_id                       = azurerm_lb_probe.dns.id
}

# Regla DNS TCP
resource "azurerm_lb_rule" "dns_tcp" {
  loadbalancer_id                = azurerm_lb.dc.id
  name                           = "rule-dns-tcp"
  protocol                       = "Tcp"
  frontend_port                  = 53
  backend_port                   = 53
  frontend_ip_configuration_name = "frontend-dc-lb"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.dc.id]
  probe_id                       = azurerm_lb_probe.dns.id
}

# Regla LDAP TCP
resource "azurerm_lb_rule" "ldap_tcp" {
  loadbalancer_id                = azurerm_lb.dc.id
  name                           = "rule-ldap-tcp"
  protocol                       = "Tcp"
  frontend_port                  = 389
  backend_port                   = 389
  frontend_ip_configuration_name = "frontend-dc-lb"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.dc.id]
  probe_id                       = azurerm_lb_probe.ldap.id
}

# ─── VMs Windows Server (Domain Controllers en Zonas de Disponibilidad) ───────

resource "azurerm_windows_virtual_machine" "dc" {
  count = var.dc_count

  name                  = local.dc_names[count.index]
  computer_name         = "dc-${format("%02d", count.index + 1)}"
  resource_group_name   = var.resource_group_name
  location              = var.location
  size                  = var.vm_size
  admin_username        = var.admin_username
  admin_password        = var.admin_password
  network_interface_ids = [azurerm_network_interface.dc[count.index].id]

  # Distribución redundante: DC1 en Zona 1, DC2 en Zona 2
  zone = tostring(count.index + 1)

  tags = merge(var.tags, { Componente = "ActiveDirectory-DC", Rol = "DomainController-${format("%02d", count.index + 1)}" })

  os_disk {
    name                 = "osdisk-dc-${format("%02d", count.index + 1)}"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = 128
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }

  # Habilitar Boot Diagnostics
  boot_diagnostics {}

  lifecycle {
    prevent_destroy = false
  }
}

# ─── Disco de datos para NTDS (AD Database) ──────────────────────────────────

resource "azurerm_managed_disk" "dc_data" {
  count = var.dc_count

  name                 = "datadisk-dc-${local.prefix}-${format("%02d", count.index + 1)}"
  resource_group_name  = var.resource_group_name
  location             = var.location
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = 32
  zone                 = tostring(count.index + 1) # Mapeado con la zona de la VM correspondiente
  tags                 = merge(var.tags, { Componente = "ActiveDirectory-Data" })
}

resource "azurerm_virtual_machine_data_disk_attachment" "dc_data" {
  count = var.dc_count

  managed_disk_id    = azurerm_managed_disk.dc_data[count.index].id
  virtual_machine_id = azurerm_windows_virtual_machine.dc[count.index].id
  lun                = 0
  caching            = "None"
}

# ─── Extensión DSC: Instalar AD DS en DC1 (Crear Bosque) ─────────────────────

resource "azurerm_virtual_machine_extension" "dc1_ad_forest" {
  name                 = "dsc-create-ad-forest"
  virtual_machine_id   = azurerm_windows_virtual_machine.dc[0].id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"
  tags                 = var.tags

  protected_settings = jsonencode({
    commandToExecute = "powershell -ExecutionPolicy Unrestricted -Command \"${local.dc1_script}\""
  })

  depends_on = [azurerm_virtual_machine_data_disk_attachment.dc_data]
}

locals {
  dc1_script = replace(replace(<<-SCRIPT
    # Formatear disco de datos para NTDS
    $disk = Get-Disk | Where-Object PartitionStyle -eq 'RAW'
    if ($disk) {
      Initialize-Disk -Number $disk.Number -PartitionStyle GPT
      New-Partition -DiskNumber $disk.Number -UseMaximumSize -DriveLetter F
      Format-Volume -DriveLetter F -FileSystem NTFS -NewFileSystemLabel 'NTDS' -Confirm:$$false
    }

    # Instalar rol AD DS
    Install-WindowsFeature AD-Domain-Services -IncludeManagementTools

    # Crear el bosque AD
    Import-Module ADDSDeployment
    Install-ADDSForest `
      -DomainName '${var.ad_domain_name}' `
      -DomainNetbiosName '${var.ad_netbios_name}' `
      -DatabasePath 'F:\\NTDS' `
      -LogPath 'F:\\NTDS' `
      -SysvolPath 'F:\\SYSVOL' `
      -SafeModeAdministratorPassword (ConvertTo-SecureString '${var.admin_password}' -AsPlainText -Force) `
      -InstallDns:$$true `
      -NoRebootOnCompletion:$$false `
      -Force:$$true
  SCRIPT
  , "\n", "; "), "\r", "")
}

# ─── Extensión DSC: Unir DC2 al dominio como réplica ─────────────────────────

resource "azurerm_virtual_machine_extension" "dc2_ad_replica" {
  count = var.dc_count > 1 ? 1 : 0

  name                 = "dsc-join-ad-domain"
  virtual_machine_id   = azurerm_windows_virtual_machine.dc[1].id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"
  tags                 = var.tags

  protected_settings = jsonencode({
    commandToExecute = "powershell -ExecutionPolicy Unrestricted -Command \"${local.dc2_script}\""
  })

  depends_on = [
    azurerm_virtual_machine_extension.dc1_ad_forest,
    azurerm_virtual_machine_data_disk_attachment.dc_data
  ]
}

locals {
  dc2_script = replace(replace(<<-SCRIPT
    # Formatear disco de datos
    $disk = Get-Disk | Where-Object PartitionStyle -eq 'RAW'
    if ($disk) {
      Initialize-Disk -Number $disk.Number -PartitionStyle GPT
      New-Partition -DiskNumber $disk.Number -UseMaximumSize -DriveLetter F
      Format-Volume -DriveLetter F -FileSystem NTFS -NewFileSystemLabel 'NTDS' -Confirm:$$false
    }

    # Instalar rol AD DS
    Install-WindowsFeature AD-Domain-Services -IncludeManagementTools

    # Esperar a que el DC1 esté disponible
    Start-Sleep -Seconds 120

    # Configurar DNS apuntando al DC1
    $nic = Get-NetAdapter | Where-Object Status -eq 'Up'
    Set-DnsClientServerAddress -InterfaceIndex $nic.ifIndex -ServerAddresses '10.0.4.10'

    # Credencial del dominio
    $$cred = New-Object System.Management.Automation.PSCredential('${var.ad_netbios_name}\\${var.admin_username}', (ConvertTo-SecureString '${var.admin_password}' -AsPlainText -Force))

    # Unirse al dominio como DC réplica
    Import-Module ADDSDeployment
    Install-ADDSDomainController `
      -DomainName '${var.ad_domain_name}' `
      -DatabasePath 'F:\\NTDS' `
      -LogPath 'F:\\NTDS' `
      -SysvolPath 'F:\\SYSVOL' `
      -SafeModeAdministratorPassword (ConvertTo-SecureString '${var.admin_password}' -AsPlainText -Force) `
      -Credential $$cred `
      -InstallDns:$$true `
      -NoRebootOnCompletion:$$false `
      -Force:$$true
  SCRIPT
  , "\n", "; "), "\r", "")
}

# ─── Diagnostic Settings para las VMs ─────────────────────────────────────────

resource "azurerm_monitor_diagnostic_setting" "dc_nic" {
  count = var.dc_count

  name                       = "diag-nic-dc-${format("%02d", count.index + 1)}"
  target_resource_id         = azurerm_network_interface.dc[count.index].id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
