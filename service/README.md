# Azure Web Server Service (Test Environment)

インターネット公開されるテスト用の Linux 仮想マシン（Ubuntu 22.04 LTS + Nginx）をデプロイするための Terraform モジュールです。

## 作成されるリソース

- **リソースグループ**: `rg-<prefix>-web-<location>`
- **仮想ネットワーク (VNet)**: `10.0.0.0/16`
- **サブネット (Public)**: `10.0.1.0/24`
- **パブリック IP**: Standard SKU (Static)
- **ネットワークセキュリティグループ (NSG)**:
  - ポート 80 (HTTP): `0.0.0.0/0`
  - ポート 443 (HTTPS): `0.0.0.0/0`
  - ポート 22 (SSH): `allowed_ssh_cidr_blocks` (デフォルト: `0.0.0.0/0`)
- **NIC**: パブリック IP 紐付け
- **Linux VM**: Ubuntu 22.04 LTS (`Standard_B1s`)
  - cloud-init スクリプトにより Nginx が自動起動
  - テスト用 HTML ページを配信

## デプロイ手順

```bash
# 1. 初期化
terraform init

# 2. 実行計画確認
terraform plan -var="subscription_id=YOUR_SUBSCRIPTION_ID"

# 3. 適用
terraform apply -var="subscription_id=YOUR_SUBSCRIPTION_ID"
```

## 動作確認

```bash
# Web ページアクセス
curl $(terraform output -raw web_url)

# SSH 接続 (鍵を自動生成させた場合)
terraform output -raw ssh_private_key_pem > id_rsa
chmod 600 id_rsa
ssh -i id_rsa azureuser@$(terraform output -raw public_ip_address)
```

## リソース削除

```bash
terraform destroy -var="subscription_id=YOUR_SUBSCRIPTION_ID"
```
