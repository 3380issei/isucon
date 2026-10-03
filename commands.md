# ISUCON commands

## 起動中の systemd サービス一覧

起動中のサービスを一覧表示する。

```bash
systemctl list-units --type=service --state=running --no-pager
```

