# -----------------------------------------------------------------------------
# リソースグループ
# -----------------------------------------------------------------------------
locals {
  rg_name = var.resource_group_name != null ? var.resource_group_name : "rg-${var.prefix}-web-${var.location}"
}

resource "azurerm_resource_group" "web" {
  name     = local.rg_name
  location = var.location
  tags     = local.tags
}

# -----------------------------------------------------------------------------
# 仮想ネットワーク (VNet) & サブネット
# -----------------------------------------------------------------------------
resource "azurerm_virtual_network" "web" {
  name                = "${var.prefix}-vnet"
  address_space       = var.vnet_address_space
  location            = azurerm_resource_group.web.location
  resource_group_name = azurerm_resource_group.web.name
  tags                = local.tags
}

resource "azurerm_subnet" "web" {
  name                 = "${var.prefix}-subnet-public"
  resource_group_name  = azurerm_resource_group.web.name
  virtual_network_name = azurerm_virtual_network.web.name
  address_prefixes     = [var.subnet_address_prefix]
}

# -----------------------------------------------------------------------------
# パブリック IP アドレス (インターネット公開用)
# -----------------------------------------------------------------------------
resource "azurerm_public_ip" "web" {
  name                = "${var.prefix}-web-pip"
  location            = azurerm_resource_group.web.location
  resource_group_name = azurerm_resource_group.web.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags
}

# -----------------------------------------------------------------------------
# ネットワークセキュリティグループ (NSG)
# HTTP(80), HTTPS(443), SSH(22) を許可
# -----------------------------------------------------------------------------
resource "azurerm_network_security_group" "web" {
  name                = "${var.prefix}-web-nsg"
  location            = azurerm_resource_group.web.location
  resource_group_name = azurerm_resource_group.web.name
  tags                = local.tags

  security_rule {
    name                       = "Allow-HTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-HTTPS"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefixes    = var.allowed_ssh_cidr_blocks
    destination_address_prefix = "*"
  }
}

# サブネットに NSG を関連付け
resource "azurerm_subnet_network_security_group_association" "web" {
  subnet_id                 = azurerm_subnet.web.id
  network_security_group_id = azurerm_network_security_group.web.id
}

# -----------------------------------------------------------------------------
# ネットワークインターフェース (NIC)
# -----------------------------------------------------------------------------
resource "azurerm_network_interface" "web" {
  name                = "${var.prefix}-web-nic"
  location            = azurerm_resource_group.web.location
  resource_group_name = azurerm_resource_group.web.name
  tags                = local.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.web.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.web.id
  }
}
