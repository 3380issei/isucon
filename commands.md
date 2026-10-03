# ISUCON commands

## 起動中の systemd サービス一覧

起動中のサービスを一覧表示する。

```bash
systemctl list-units --type=service --state=running --no-pager
```

## alp のインストール

Linux x86_64 環境に alp v1.0.21 をインストールする。

```bash
bash scripts/install-alp.sh
```
