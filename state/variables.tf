variable "subscription_id" {
  description = "Azure サブスクリプション ID"
  type        = string
}

variable "resource_group_name" {
  description = "既存のリソースグループ名。null の場合は新規作成"
  type        = string
  default     = null
}

variable "location" {
  description = "Azure リージョン（例: japaneast）"
  type        = string
  default     = "japaneast"
}

variable "github_org_repo" {
  description = "GitHub org/repo（例: uso6wiz/tf-azure）。Federated Credential の subject に使用"
  type        = string
  default     = "uso6wiz/tf-azure"
}

variable "github_branch" {
  description = "Assume を許可するブランチ（例: main）。'*' で全 ref 許可"
  type        = string
  default     = "main"
}

variable "github_environment" {
  description = "省略可。GitHub environment 名。指定時はその environment に trust を制限"
  type        = string
  default     = null
}
