variable "subscription_id" {
  description = "Azure サブスクリプション ID"
  type        = string
}

variable "location" {
  description = "Azure リージョン（例: japaneast）"
  type        = string
  default     = "japaneast"
}

variable "environment" {
  description = "環境識別子（例: dev, test, prod）"
  type        = string
  default     = "dev"
}

variable "prefix" {
  description = "リソース名のプレフィックス"
  type        = string
  default     = "wiz-dev"
}

variable "resource_group_name" {
  description = "作成するリソースグループ名。null の場合はプレフィックスとリージョンから自動決定"
  type        = string
  default     = null
}

variable "vnet_address_space" {
  description = "仮想ネットワーク (VNet) のアドレス空間"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnet_address_prefix" {
  description = "Web サーバを配置するサブネットのアドレス空間"
  type        = string
  default     = "10.0.1.0/24"
}

variable "vm_size" {
  description = "Web サーバの VM サイズ（例: Standard_B1s, Standard_B2s）"
  type        = string
  default     = "Standard_B1s"
}

variable "admin_username" {
  description = "Web サーバの管理者ユーザー名"
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key" {
  description = "SSH 公開鍵文字列。未指定 (null) の場合は Terraform が自動で鍵ペアを生成します"
  type        = string
  default     = null
}

variable "allowed_ssh_cidr_blocks" {
  description = "SSH 接続を許可する送信元 CIDR リスト"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "extra_tags" {
  description = "追加で付与するタグのマップ"
  type        = map(string)
  default     = {}
}
