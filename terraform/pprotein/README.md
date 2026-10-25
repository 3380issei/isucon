# pprotein 用 EC2

独立した VPC とパブリック Subnet に計測用 EC2 を 1 台作ります。EC2 には固定の Elastic IP を割り当てます。競技サーバー側の設定は、まだ含みません。

1. 同じリージョンに EC2 キーペアを用意します。
2. `terraform.tfvars.example` を `terraform.tfvars` にコピーし、リージョン、キーペア名、接続元グローバル IPv4 を設定します。`ssh_ingress_cidrs` に、接続する回線ごとに `/32` を 1 件ずつ指定できます。例示用の IP アドレスでは接続できません。
3. このディレクトリで `terraform init`、`terraform plan`、`terraform apply` を実行します。
4. `terraform output monitor_public_ip` で IP を確認します。EC2 の初回起動時に pprotein を自動インストール・起動します。完了まで数分待ちます。

Security Group はチームからの SSH (22番) のみを受け付けます。pprotein の画面 (9000番) は公開せず、SSH ポートフォワード経由で利用します。競技サーバー上の pprotein-agent へは、監視 EC2 から競技サーバーの公開 IP の TCP 19000 番へ HTTP 接続します。競技サーバー側の準備は [agent の README](../../pprotein/README.md) を参照してください。

Terraform state、実際の `terraform.tfvars`、秘密鍵は Git にコミットしないでください。EC2 を停止しても EBS と Elastic IP には料金がかかる場合があります。

## pprotein 本体のセットアップ

Terraform は `scripts/install-pprotein-monitor.sh` と `pprotein/pprotein.service` を User Data に埋め込みます。EC2 の初回起動時に cloud-init がそれらを配置し、インストーラを実行します。EC2 には起動時に一時的な公開 IP が付き、その後 Elastic IP に切り替わります。インストーラは公式リリースの pprotein v1.2.4、alp v1.0.22、slp v0.2.3 を SHA256 検証後に配置し、Graphviz と systemd サービスを設定します。計測データは `/var/lib/pprotein/data` に保存します。

既存の EC2 に User Data を追加しても初回起動処理は遡って実行されません。この設定では User Data を変えると EC2 を**置き換え**ます。すでに EC2 がある場合は `terraform plan` で置き換え対象とデータ消失の影響を確認してから `apply` してください。Elastic IP は維持されますが、EC2 のルートボリューム上の計測データは置き換えで失われます。

起動状態は、EC2 に SSH 接続して `systemctl status pprotein --no-pager` で確認できます。初回起動に失敗した場合は `/var/log/cloud-init-output.log` を確認してください。

手元 PC から画面を見る場合は、別のターミナルで SSH トンネルを張ります。

```bash
ssh -i /path/to/private-isu.pem -N -L 9000:127.0.0.1:9000 ec2-user@<monitor_public_ip>
```

ブラウザで `http://127.0.0.1:9000/` を開きます。サービスの状態は EC2 上で `systemctl status pprotein --no-pager` で確認できます。
