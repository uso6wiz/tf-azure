terraform {
  required_version = ">= 1.6.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  subscription_id = var.subscription_id
  features {}
}

provider "azuread" {}

locals {
  location_short = "jpe1" # Japan East の短縮
  # Storage account 名は 3-24 文字、小文字英数字のみ、グローバル一意
  sub_short     = substr(replace(var.subscription_id, "-", ""), 0, 8)
  tfstate_storage_account = "tfstate${local.sub_short}${local.location_short}"
  tfstate_container       = "tfstate"
  tags = {
    Project = "tf-azure"
    Purpose = "terraform-state"
  }
}

# -----------------------------------------------------------------------------
# リソースグループ（既存を使用する場合は variable で指定し、このリソースは count で無効化）
# -----------------------------------------------------------------------------
resource "azurerm_resource_group" "tfstate" {
  count    = var.resource_group_name == null ? 1 : 0
  name     = "rg-tfstate-${local.location_short}"
  location = var.location
  tags     = local.tags
}

locals {
  resource_group_name = var.resource_group_name != null ? var.resource_group_name : azurerm_resource_group.tfstate[0].name
}

# -----------------------------------------------------------------------------
# Storage Account（Terraform リモート state 用）
# Azure Blob Storage はネイティブで state ロックをサポート（DynamoDB 相当は不要）
# -----------------------------------------------------------------------------
resource "azurerm_storage_account" "tfstate" {
  name                     = substr(local.tfstate_storage_account, 0, 24)
  resource_group_name      = local.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  blob_properties {
    versioning_enabled = true
  }

  tags = local.tags
}

resource "azurerm_storage_container" "tfstate" {
  name                  = local.tfstate_container
  storage_account_id    = azurerm_storage_account.tfstate.id
  container_access_type = "private"
}

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------
output "tfstate_resource_group" {
  value       = local.resource_group_name
  description = "Resource group name for Terraform remote state"
}

output "tfstate_storage_account" {
  value       = azurerm_storage_account.tfstate.name
  description = "Storage account name for Terraform remote state"
}

output "tfstate_container" {
  value       = azurerm_storage_container.tfstate.name
  description = "Container name for Terraform state blob"
}

output "tfstate_key" {
  value       = "service/dev/terraform.tfstate"
  description = "State blob key (path) in the container"
}
