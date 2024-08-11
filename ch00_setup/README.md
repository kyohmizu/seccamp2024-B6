# セットアップ

## 演習環境（構築済み）

```bash
cd ch00_setup/aws/environments/prd
terraform init
terraform plan
terraform apply
```

## 事前準備（ローカル環境）

- aws cli をインストール

https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html

- ssm プラグインをインストール

https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html

- /etc/hosts に以下を追加

```
127.0.0.1 unguard.kube
127.0.0.1 nginx.seccamp.com
127.0.0.1 hubble.seccamp.com
127.0.0.1 kubeclarity.seccamp.com
```

## 演習環境へのアクセス方法

- EC2 インスタンスへの接続（マネジメントコンソール）

EC2インスタンスの一覧から使用するインスタンスを探し、インスタンス詳細画面に遷移します。

インスタンス詳細画面の右上にある「接続」をクリックします。

「セッションマネージャー」タブを選択し、「接続」をクリックすれば完了です。

- EC2 インスタンスへの接続（CLI）

ローカル環境のCLIを起動し、AWS の認証情報を設定します。

正しく設定できているかどうかは次のコマンドで確認できます。

```bash
aws sts get-caller-identity
```

認証情報の設定後、次のコマンドでインスタンスに接続できます。

```bash
aws ssm start-session \
    --target i-0000000000 \ # インスタンスIDを変更
    --region ap-northeast-1
```

- root ユーザーに切り替え

本演習は root ユーザーの権限で実施しますので、インスタンス接続後にユーザーを切り替えます。

```bash
sudo su -
```

- ポートフォワーディング

ローカル環境から EC2 上に構築したサービスにアクセスするため、演習の一部でポートフォワードが必要になります。

```bash
aws ssm start-session \
    --target i-0000000000 \ # インスタンスIDを変更
    --region ap-northeast-1 \
    --document-name AWS-StartPortForwardingSession \
    --parameters '{"portNumber":["80"], "localPortNumber":["8081"]}'
```
