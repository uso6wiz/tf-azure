# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------

output "resource_group_name" {
  value       = azurerm_resource_group.web.name
  description = "Web サーバが配置されたリソースグループ名"
}

output "vm_name" {
  value       = azurerm_linux_virtual_machine.web.name
  description = "Web サーバの仮想マシン名"
}

output "public_ip_address" {
  value       = azurerm_public_ip.web.ip_address
  description = "Web サーバのパブリック IP アドレス"
}

output "web_url" {
  value       = "http://${azurerm_public_ip.web.ip_address}"
  description = "Web サーバのアクセス用 URL (HTTP)"
}

output "ssh_command" {
  value       = "ssh ${var.admin_username}@${azurerm_public_ip.web.ip_address}"
  description = "SSH 接続コマンド例"
}

output "ssh_private_key_pem" {
  value       = var.ssh_public_key == null ? tls_private_key.ssh[0].private_key_pem : null
  description = "自動生成された SSH 秘密鍵 (OpenSSH PEM 形式)。ファイルに保存して ssh -i で使用可能"
  sensitive   = true
}
