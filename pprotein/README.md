# 競技サーバー側の pprotein-agent

Ubuntu 24.04 / Linux x86_64 の private-isu 競技 EC2 で手作業で検証した手順をスクリプト化しています。監視 EC2 側は [Terraform の README](../terraform/pprotein/README.md) を参照してください。

競技 EC2 の Security Group では、agent の TCP 19000 番を**監視 EC2 の公開 IP `/32` からのみ**許可します。全インターネットへ公開しないでください。SSH ポートは、agent による収集には不要です。

このリポジトリを競技 EC2 に配置した後、前面起動中の agent があれば `Ctrl+C` で停止し、以下を実行します。

```bash
sudo bash scripts/install-pprotein-agent.sh
systemctl is-enabled pprotein-agent
systemctl is-active pprotein-agent
```

`install-pprotein-agent.sh` は pprotein v1.2.4 の公式リリースを SHA256 検証して agent を配置し、systemd で自動起動します。既存の systemd unit が異なる場合は、上書き前に日時付きでバックアップします。

監視 EC2 から `curl -f http://<競技 EC2 の公開 IP>:19000/debug/pprof/` で疎通を確認できます。

pprotein の `setting` → `group/targets` には、例えば次を設定します。`Duration` はベンチ実行時間より少し長くしてください。

```json
[
  {
    "Type": "httplog",
    "Label": "private-isu",
    "URL": "http://<競技 EC2 の公開 IP>:19000/debug/log/httplog",
    "Duration": 60
  }
]
```

この agent はログを読むため root で動きます。公開範囲は Security Group で厳しく制限してください。nginx の LTSV 化、Go アプリの pprof 連携、MySQL のスローログ設定は、このスクリプトには含みません。
