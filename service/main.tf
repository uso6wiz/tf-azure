terraform {
  required_version = ">= 1.6.0"

  # state apply 後にリモートバックエンドを有効化する場合はコメントを解除し、実値に設定してください
  # backend "azurerm" {
  #   resource_group_name  = "rg-tfstate-jpe1"         # state の出力値 tfstate_resource_group に変更
  #   storage_account_name = "tfstatexxxxxxxxjpe1"      # state の出力値 tfstate_storage_account に変更
  #   container_name       = "tfstate"                  # state の出力値 tfstate_container に変更
  #   key                  = "service/dev/terraform.tfstate"
  # }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  subscription_id = var.subscription_id
  features {}
}

locals {
  tags = merge(
    {
      Project     = "tf-azure"
      Environment = var.environment
      ManagedBy   = "terraform"
      Purpose     = "web-server-test"
    },
    var.extra_tags
  )
}
