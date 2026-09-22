# share/ — P2P 文件服务白名单目录

`fengyu files` / `fengyu listen` 的默认服务目录（不是整仓）。

## 规则

- 对端 `fengyu ls <你>` / `fengyu get <你> <文件>` 只能枚举/拉取 `share/` 里的文件
- 仓库内的 `src/`、`lib/`、`docs/`、`test/` 一律不可见
- 启动服务前会自动浅扫描本目录：命中敏感文件（密钥/口令/私有端口配置/可执行程序）会预警
- 启动时目录不存在则自动创建（如本文件）

## 需要共享整个仓库时（显式越权，自行把关）

```bash
node bin/fengyu.js files ..          # files 服务根换成仓库根（会再次预警敏感文件）
# 或
node bin/fengyu.js listen --files-dir ..
```
