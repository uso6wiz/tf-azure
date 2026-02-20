# -----------------------------------------------------------------------------
# GitHub Actions から Terraform apply するための OIDC Federated Credential
# azure/login で OIDC トークン交換に使用
# -----------------------------------------------------------------------------

data "azuread_client_config" "current" {}

resource "azuread_application" "github_actions" {
  display_name = "github-actions-terraform"
  description  = "Federated credential for GitHub Actions (Terraform apply)"
}

resource "azuread_service_principal" "github_actions" {
  client_id                    = azuread_application.github_actions.client_id
  app_role_assignment_required = false
}

# Trust policy の subject: environment 指定時は environment、それ以外は ref
locals {
  github_oidc_subject = var.github_environment != null ? "repo:${var.github_org_repo}:environment:${var.github_environment}" : (
    var.github_branch == "*" ? "repo:${var.github_org_repo}:*" : "repo:${var.github_org_repo}:ref:refs/heads/${var.github_branch}"
  )
}

resource "azuread_application_federated_identity_credential" "github" {
  application_id = azuread_application.github_actions.id
  display_name   = "github-actions-oidc"
  description    = "GitHub Actions OIDC for Terraform"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = local.github_oidc_subject
}

# -----------------------------------------------------------------------------
# Terraform バックエンド用: Storage Account への Blob アクセス
# -----------------------------------------------------------------------------
resource "azurerm_role_assignment" "tfstate_storage" {
  scope                = azurerm_storage_account.tfstate.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azuread_service_principal.github_actions.object_id
}

# -----------------------------------------------------------------------------
# Terraform apply 用: サブスクリプション（または RG）への Contributor
# -----------------------------------------------------------------------------
resource "azurerm_role_assignment" "terraform_apply" {
  scope                = "/subscriptions/${var.subscription_id}"
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.github_actions.object_id
}

# -----------------------------------------------------------------------------
# Outputs（GitHub Actions ワークフローで使用）
# -----------------------------------------------------------------------------
output "github_actions_client_id" {
  value       = azuread_application.github_actions.client_id
  description = "App (client) ID for GitHub Actions. Use as AZURE_CLIENT_ID."
}

output "github_actions_tenant_id" {
  value       = data.azuread_client_config.current.tenant_id
  description = "Tenant ID. Use as AZURE_TENANT_ID."
}

output "github_actions_subscription_id" {
  value       = var.subscription_id
  description = "Subscription ID. Use as AZURE_SUBSCRIPTION_ID."
}
