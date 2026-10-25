# pprotein 用 EC2

独立した VPC とパブリック Subnet に計測用 EC2 を 1 台作ります。EC2 には固定の Elastic IP を割り当てます。pprotein 本体と競技サーバー側の設定は、まだ含みません。

1. 同じリージョンに EC2 キーペアを用意します。
2. `terraform.tfvars.example` を `terraform.tfvars` にコピーし、リージョン、キーペア名、接続元グローバル IPv4 を設定します。`ssh_ingress_cidrs` に、接続する回線ごとに `/32` を 1 件ずつ指定できます。例示用の IP アドレスでは接続できません。
3. このディレクトリで `terraform init`、`terraform plan`、`terraform apply` を実行します。
4. `terraform output monitor_public_ip` で IP を確認し、秘密鍵を使って `ec2-user` で SSH 接続します。

Security Group はチームからの SSH (22番) のみを受け付けます。pprotein の画面 (9000番) は公開せず、後で SSH ポートフォワード経由で利用します。競技サーバーへは、この EC2 から公開 IP 宛てに SSH 接続する想定です。

Terraform state、実際の `terraform.tfvars`、秘密鍵は Git にコミットしないでください。EC2 を停止しても EBS と Elastic IP には料金がかかる場合があります。
