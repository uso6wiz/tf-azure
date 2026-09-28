# -----------------------------------------------------------------------------
# SSH キー自動生成 (var.ssh_public_key が未指定の場合)
# -----------------------------------------------------------------------------
resource "tls_private_key" "ssh" {
  count     = var.ssh_public_key == null ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

locals {
  ssh_public_key = var.ssh_public_key != null ? var.ssh_public_key : tls_private_key.ssh[0].public_key_openssh

  # 起動スクリプト (cloud-init): Nginx をインストール・設定
  cloud_init_script = <<-EOS
    #!/bin/bash
    set -e
    exec > >(tee -a /var/log/custom-data.log) 2>&1

    echo "=== Starting Web Server setup at $(date) ==="

    export DEBIAN_FRONTEND=noninteractive
    apt-get update -y
    apt-get install -y nginx curl

    HOSTNAME_VAL=$(hostname)
    DATE_VAL=$(date -u +"%Y-%m-%d %H:%M:%S UTC")

    # テスト用 Web ページの作成
    cat <<HTML > /var/www/html/index.html
    <!DOCTYPE html>
    <html lang="ja">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Azure Web Server Test</title>
      <style>
        body {
          font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
          background: linear-gradient(135deg, #0078D4 0%, #002050 100%);
          color: #ffffff;
          min-height: 100vh;
          margin: 0;
          display: flex;
          justify-content: center;
          align-items: center;
        }
        .card {
          background: rgba(255, 255, 255, 0.96);
          color: #333333;
          padding: 2.5rem;
          border-radius: 12px;
          box-shadow: 0 10px 30px rgba(0, 0, 0, 0.25);
          max-width: 520px;
          width: 90%;
          text-align: center;
        }
        h1 {
          color: #0078D4;
          margin: 0.5rem 0 1rem 0;
          font-size: 1.8rem;
        }
        .status-badge {
          display: inline-block;
          background: #107C41;
          color: white;
          padding: 0.35rem 0.9rem;
          border-radius: 20px;
          font-weight: 600;
          font-size: 0.85rem;
          letter-spacing: 0.5px;
        }
        p {
          color: #555555;
          line-height: 1.6;
          margin-bottom: 1.5rem;
        }
        .info-table {
          width: 100%;
          border-collapse: collapse;
          text-align: left;
          font-size: 0.9rem;
        }
        .info-table td {
          padding: 0.6rem 0.8rem;
          border-bottom: 1px solid #eeeeee;
        }
        .info-table td:first-child {
          font-weight: 600;
          color: #666666;
          width: 38%;
        }
      </style>
    </head>
    <body>
      <div class="card">
        <span class="status-badge">&#9679; RUNNING</span>
        <h1>Azure Web Server Test</h1>
        <p>This web server is successfully deployed via Terraform and publicly accessible from the Internet.</p>
        <table class="info-table">
          <tr><td>Host</td><td>$HOSTNAME_VAL</td></tr>
          <tr><td>Platform</td><td>Microsoft Azure</td></tr>
          <tr><td>OS</td><td>Ubuntu 22.04 LTS</td></tr>
          <tr><td>Web Server</td><td>Nginx</td></tr>
          <tr><td>Deployed At</td><td>$DATE_VAL</td></tr>
        </table>
      </div>
    </body>
    </html>
HTML

    systemctl enable nginx
    systemctl restart nginx

    echo "=== Web Server setup completed successfully at $(date) ==="
  EOS
}

# -----------------------------------------------------------------------------
# Linux Virtual Machine (Web サーバ)
# -----------------------------------------------------------------------------
resource "azurerm_linux_virtual_machine" "web" {
  name                = "${var.prefix}-web-vm"
  resource_group_name = azurerm_resource_group.web.name
  location            = azurerm_resource_group.web.location
  size                = var.vm_size
  admin_username      = var.admin_username

  network_interface_ids = [
    azurerm_network_interface.web.id,
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = local.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 30
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  custom_data = base64encode(local.cloud_init_script)

  tags = local.tags
}
