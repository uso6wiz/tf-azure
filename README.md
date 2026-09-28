# tf-azure

Terraform による Microsoft Azure インフラストラクチャ管理リポジトリです。  
リモートバックエンド（State 管理）およびテスト用のインターネット公開 Web サーバ環境を提供します。

---

## ディレクトリ構成

```
tf-azure/
├── README.md               # 本ドキュメント
├── state/                  # Terraform 状態管理 (Storage Account) & GitHub Actions OIDC 設定
│   ├── main.tf             # Storage Account / Container 定義
│   ├── github_actions_iam.tf # GitHub Actions 向け OIDC Federated Credential
│   ├── variables.tf        # state 向け変数定義
│   └── terraform.tfvars.example
└── service/                # テスト用 Web サーバ環境
    ├── main.tf             # Provider 設定 / バックエンド設定
    ├── network.tf          # リソースグループ / VNet / Subnet / NSG / パブリック IP / NIC
    ├── web_server.tf       # Linux VM (Ubuntu 22.04 LTS) + Nginx 自動構築
    ├── variables.tf        # service 向け変数定義
    ├── outputs.tf          # パブリック IP / URL / SSH 接続情報
    └── terraform.tfvars.example
```

---

## アーキテクチャ概要

`service` では、インターネットからアクセス可能な Web サーバ環境を構築します。

- **リージョン**: Japan East (`japaneast`)
- **仮想ネットワーク (VNet)**: `10.0.0.0/16`
- **サブネット**: `10.0.1.0/24` (Public)
- **ネットワークセキュリティグループ (NSG)**:
  - `Allow-HTTP` (TCP 80, インバウンド許可)
  - `Allow-HTTPS` (TCP 443, インバウンド許可)
  - `Allow-SSH` (TCP 22, 送信元 CIDR 制限可能、デフォルト: `0.0.0.0/0`)
- **仮想マシン (VM)**:
  - OS: Ubuntu 22.04 LTS (x86_64 Gen2)
  - サイズ: `Standard_B1s`（テスト用低コストインスタンス）
  - cloud-init スクリプトにより Nginx が自動起動し、動作確認用 HTML ページを表示
  - SSH 鍵は `tls_private_key` で自動生成可能

---

## セットアップ手順

### 前提条件

- [Azure CLI (`az`)](https://learn.microsoft.com/ja-jp/cli/azure/install-azure-cli) がインストールされていること
- [Terraform](https://www.terraform.io/) 1.6.0 以上がインストールされていること
- 有効な Azure サブスクリプションを保有していること

### 1. Azure 認証情報の設定

Azure CLI でログインし、使用するサブスクリプションを設定します：

```bash
az login
az account set --subscription "YOUR_SUBSCRIPTION_ID"
```

---

### 2. バックエンドの作成（初回のみ・任意）

Terraform のリモート状態管理用 Storage Account と、GitHub Actions 連携用の OIDC を作成します。  
（ローカルの state で検証する場合はスキップして「3. サービスインフラの作成」へ進んで構いません。）

1. `state` ディレクトリに移動：
   ```bash
   cd state
   ```

2. Terraform の初期化と適用：
   ```bash
   terraform init
   terraform apply -var="subscription_id=YOUR_SUBSCRIPTION_ID"
   ```

3. 出力されたバックエンド情報を確認：
   ```bash
   terraform output tfstate_resource_group
   terraform output tfstate_storage_account
   terraform output tfstate_container
   terraform output tfstate_key
   ```

---

### 3. サービスインフラの作成（テスト用 Web サーバ）

1. `service` ディレクトリに移動：
   ```bash
   cd ../service
   ```

2. （リモートバックエンドを使用する場合）`service/main.tf` 内の `backend "azurerm"` のコメントを解除し、ステップ 2 の出力値（Storage Account 名等）を反映します。

3. 初期化：
   ```bash
   terraform init
   ```

4. 実行計画の確認：
   ```bash
   terraform plan -var="subscription_id=YOUR_SUBSCRIPTION_ID"
   ```

5. リソースのデプロイ：
   ```bash
   terraform apply -var="subscription_id=YOUR_SUBSCRIPTION_ID"
   ```
   確認プロンプトで `yes` を入力します。

---

## 動作確認

`terraform apply` 成功後、ターミナルに以下のような Output が出力されます：

```text
Outputs:

public_ip_address   = "20.xx.xx.xx"
resource_group_name = "rg-wiz-dev-web-japaneast"
ssh_command         = "ssh azureuser@20.xx.xx.xx"
vm_name             = "wiz-dev-web-vm"
web_url             = "http://20.xx.xx.xx"
```

### 1. Web ブラウザ・curl でのアクセス

ブラウザで `web_url` にアクセスするか、以下のコマンドを実行します：

```bash
curl http://<public_ip_address>
```

> **Note**: 仮想マシン起動時に cloud-init で Nginx のインストールと初期設定が行われます。VM 起動完了から Web ページが表示されるまでに 1〜2 分程度かかる場合があります。

### 2. SSH 接続

`ssh_public_key` を指定しなかった場合、Terraform により SSH 秘密鍵が自動生成されます。以下の手順でローカルに保存して接続できます：

```bash
# 秘密鍵をローカルに書き出し（権限を 600 に設定）
terraform output -raw ssh_private_key_pem > id_rsa
chmod 600 id_rsa

# SSH ログイン
ssh -i id_rsa azureuser@<public_ip_address>
```

---

## 変数のカスタマイズ

`service/terraform.tfvars.example` をコピーして `service/terraform.tfvars` を作成することで、パラメータを柔軟に変更できます：

```bash
cp terraform.tfvars.example terraform.tfvars
```

### 主な変数一覧 (`service/variables.tf`)

| 変数名 | 説明 | デフォルト値 | 必須 |
|---|---|---|:---:|
| `subscription_id` | Azure サブスクリプション ID | - | **Yes** |
| `location` | デプロイ先リージョン | `japaneast` | No |
| `prefix` | リソース名のプレフィックス | `wiz-dev` | No |
| `resource_group_name` | リソースグループ名（未指定時は自動生成） | `null` | No |
| `vm_size` | 仮想マシンのサイズ | `Standard_B1s` | No |
| `admin_username` | VM 管理者ユーザー名 | `azureuser` | No |
| `ssh_public_key` | 既存の SSH 公開鍵（未指定時は自動生成） | `null` | No |
| `allowed_ssh_cidr_blocks` | SSH 接続を許可する CIDR ブロック | `["0.0.0.0/0"]` | No |
| `extra_tags` | リソースに追加付与するタグ | `{}` | No |

---

## GitHub Actions 連携（OIDC）

`state` ディレクトリで作成された OIDC 認証情報を利用して、GitHub Actions からセキュアに Terraform を実行できます。

GitHub リポジトリの **Settings > Secrets and variables > Actions** に以下の Secrets を登録してください：

- `AZURE_CLIENT_ID`: `terraform output -raw github_actions_client_id` の値
- `AZURE_TENANT_ID`: `terraform output -raw github_actions_tenant_id` の値
- `AZURE_SUBSCRIPTION_ID`: `terraform output -raw github_actions_subscription_id` の値

---

## リソースの削除 (クリーンアップ)

テスト完了後、不要になったリソースは以下のコマンドで削除できます：

```bash
cd service
terraform destroy -var="subscription_id=YOUR_SUBSCRIPTION_ID"
```
