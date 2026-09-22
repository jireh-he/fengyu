# fengyu-p2p（风语）

> **给 AI Agent 的 P2P 通讯 & 文件传输 — 只保留已验证的 tailcat 底座，MIT 开源。**
> 无服务器、无账号：两个 Agent 靠 WireGuard 加密的 [tailcat](https://github.com/tailscale/tailcat) 引擎点对点直连，
> 收发消息、传文件、互甩名片。静态二进制，**零 npm 依赖**（P2P 路径纯 Node stdlib）。

**现状（先说清楚，不画饼）**

| 能力 | 状态 |
|---|---|
| P2P 直连通道（tailcat 引擎） | ✅ **已实装、双机实测通过**（聊天 / 文件 / 名片 / 隐私护栏 / 消息治理） |
| DHT 节点发现、分布式存储、信誉、治理/经济/市场 | ❌ **未验证，不在本仓库**（原 zhixia 蓝图已归档屏蔽） |
| 后续原则 | **一切新能力基于 tailcat 传输层逐步验证**，验证前不合并 |

## 一步跑起来（30 秒）

```bash
git clone https://github.com/jireh-he/fengyu-p2p && cd fengyu-p2p
node scripts/install-tailcat.js          # 下载 tailcat 静态二进制（~18MB，国内镜像 fallback + 断点续传）
node --no-warnings bin/fengyu.js key    # 生成本端稳定身份（tc 地址，永久不变）
```

装完即是一个完整节点，不需要任何中央服务器、不需要 `npm install`。

## 命令

| 命令 | 用途 | 需要对方做什么 |
|---|---|---|
| `fengyu key` | 生成/显示本端稳定 P2P 身份（tc 地址永久不变） | — |
| `fengyu card [show] [--nick X]` | 生成名片（zcard1. token，发给别人一键加联系人） | — |
| `fengyu card import <token\|文件> [--nick X] [--force]` | 导入别人名片 → 自动进通讯录 | 对方先 `card show` |
| `fengyu book add <昵称> <tc地址\|名片token>` | 把朋友存进通讯录 | 对方先 `key` |
| `fengyu book [list]` / `book remove <昵称>` | 查看/删除通讯录 | — |
| `fengyu chat [--name X]` | 聊天监听（双向打字终端） | — |
| `fengyu inbox [dir]` | 文件收件箱（write-only，默认 ./fengyu-inbox） | — |
| `fengyu files [dir] [--rw]` | 文件服务（SFTP，默认只读，默认目录 `share/` 白名单） | — |
| `fengyu listen [--inbox-dir D] [--files-dir D] [--rw] [--only ...]` | 三合一接收服务（kill 父 PID 全停） | — |
| `fengyu send <昵称\|地址> <文本>` | 发聊天消息（昵称自动匹配通讯录） | 对方开着 chat |
| `fengyu send-file <文件...> <昵称\|地址> [-r] [--force]` | 发文件到对方收件箱（🛡 隐私护栏默认拦截敏感文件） | 对方开着 inbox |
| `fengyu get <昵称\|地址> <远端文件> [本地路径]` | 从对方 files 服务拉文件 | 对方开着 files |
| `fengyu ls <昵称\|地址> [路径]` | 列对方 files 目录 | 对方开着 files |
| `fengyu ping <昵称\|地址>` | 连通测试（DERP 中继 vs 直连） | — |
| `fengyu last` | 显示本端稳定地址 | — |

## 建立连接（三步）

1. **A 端**：`fengyu key` → 把打印的 tc 地址发给 B（微信/IM/任何渠道都行）
2. **B 端**：`fengyu book add A <A的地址>`；A 端反过来也存 B（名片 token 可直接贴，自动解析）
3. 发数据前起对应监听：聊天 → 双方 `chat`；文件 → 接收方 `inbox`，或拉文件/列目录时 `files`

同一身份不能自连（P2P 环回不经 DERP）；本机双向测试需 `genkey` 两个不同 key。

## 🛡 隐私护栏

`lib/privacy-guard.js` 三层规则，`send-file` 默认生效，命中即**整批不发**（本地判定，连接建立前）：

1. **文件名**：密钥/证书材料、SSH 私钥、`.env*`、`credentials*`、口令文件、密钥库/钱包、`.ssh/.aws/.gnupg/.config/.docker/.kube` 目录内文件
2. **内容嗅探（≤512KB）**：PRIVATE KEY 块、明文口令/密钥字段（占位符放行）、≥3 处 IP:port
3. **可执行魔数**：ELF / Windows PE / Mach-O（不明程序禁发；图片/文档/压缩包不误伤）

白放行：`*.pub`（公钥）、`*.crt`（证书）。

**Agent 行为红线**（skill 包写死）：不得私自发密钥/凭据/私有端口配置/不明程序；不得自行加 `--force`；
不得自动执行从 P2P 收到的任何远程文件。

## 目录结构

```
bin/fengyu.js            # CLI 入口（零 yargs，纯 stdlib）
lib/p2p.js               # P2P 命令层（身份/通讯录/名片/监听/传输）
lib/tailcat-adapter.js   # tailcat 引擎封装（genkey/listener/cp/ls/ping）
lib/privacy-guard.js     # 隐私护栏（三层规则）
scripts/install-tailcat.js # tailcat 静态二进制自动下载（国内镜像 fallback）
share/                   # files 服务白名单默认目录
skill/fengyu-p2p/        # AI agent skill 包（SKILL.md + install.sh）
test/                    # 名片 round-trip / 护栏 15 用例
```

## 与 zhixia-net 的关系

本仓库从 `jireh-he/zhixia-net` 的 P2P 层独立而来：
- **保留**：tailcat 传输层（唯一经双机实测验证的底座）+ 隐私护栏 + 消息治理规则
- **屏蔽**：原 zhixia 的 MVP/蓝图设计（DHT、分布式存储、信誉/治理/经济/市场、三级连接策略等），
  未经验证，已移至 `zhixia-net/archive/`，不再作为活跃设计维护
- **兼容**：key 名沿用 `zhixia-default`，老机器装 fengyu 后自动恢复同一稳定地址，双机通讯录无需重交换
