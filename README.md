# fengyu（风语）

> **给 AI Agent 的 P2P 通讯 & 文件传输 — 只保留已验证的 tailcat 底座，MIT 开源。**
> 无服务器、无账号：两个 Agent 靠 WireGuard 加密的 [tailcat](https://github.com/tailscale/tailcat) 引擎点对点直连，
> 收发消息、传文件、互甩名片。tailcat 官方静态二进制，**零 npm 依赖、零 Node 依赖**。

**现状（先说清楚，不画饼）**

| 能力 | 状态 |
|---|---|
| P2P 直连通道（tailcat 引擎） | ✅ **已实装、双机实测通过**（聊天 / 文件 / 名片 / 隐私护栏 / 消息治理） |
| DHT 节点发现、分布式存储、信誉、治理/经济/市场 | ❌ **未验证，不在本仓库**（原 zhixia 蓝图已归档屏蔽） |
| 后续原则 | **一切新能力基于 tailcat 传输层逐步验证**，验证前不合并 |

## v2.0（2026-09-24）：纯 skill 架构

**Agent 直接用 shell 调官方 `tailcat` 二进制，不再依赖 JS/Node wrapper。**
`bin/fengyu.js` + `lib/` 标记为 **DEPRECATED**（仍可用，过渡期保留），新安装一律走 skill：

| 组件 | 位置 | 说明 |
|---|---|---|
| `skill/fengyu/SKILL.md` | 本仓库 `skill/fengyu/` | Agent 完整操作手册（安装/身份/通讯录/传输/隐私红线/8 条坑） |
| `skill/fengyu/install.sh` | 同上 | 纯 sh 安装器：探测 os/arch → 下载官方二进制（国内 gh-proxy/ghproxy 镜像 fallback）→ 落 `~/.fengyu/`，零 Node |
| `~/.fengyu/tailcat-<os>-<arch>` | 本机 | 官方静态二进制，`--version` 即 node 角色 |
| `~/.fengyu/book.txt` | 本机 | 通讯录（**每行一条、TAB 分隔**：`昵称\t地址`） |

## 一步跑起来（30 秒）

```bash
git clone https://github.com/jireh-he/fengyu && cd fengyu
sh skill/fengyu/install.sh              # 下载官方 tailcat 静态二进制 → ~/.fengyu/（国内镜像 fallback）
~/.fengyu/tailcat-linux-amd64 genkey --key=zhixia-default   # 生成本端稳定身份（tc 地址）
```

装完即是一个完整节点，不需要任何中央服务器、不需要 `npm install`、不需要 Node。
skill 已内置到 Agent 环境的（Hermes：`~/.hermes/skills/p2p/fengyu/`），
Agent 收到通讯/传文件任务时直接按 SKILL.md 的 shell 姿势操作，不再走 wrapper。

## 命令（tailcat 原生，全 shell）

| 命令 | 用途 | 需要对方做什么 |
|---|---|---|
| `genkey --key=zhixia-default` | 生成/显示本端稳定 P2P 身份（tc 地址；**key 文件不重新生成则地址不变**） | — |
| `--key=zhixia-default` | 裸监听（控制面：ping/消息可达） | — |
| `recv --key=zhixia-default` | 收件箱监听（chat + files write-only，文件落 `~/.fengyu/inbox/`） | — |
| `serve files [--rw] --key=... [--share-dir D]` | 文件服务（对端 `cp`/`ls` 拉取用，默认 `~/.fengyu/share/` 只读） | — |
| `cp <文件> <tc地址或book昵称>:` | 发文件到对方 inbox | 对方开着 `recv` 或 `serve files` |
| `cp <tc地址或昵称>:<远端文件> .` | 拉对方文件 | 对方开着 `serve files` |
| `ls <tc地址或昵称>:` | 列对方 files 目录 | 对方开着 `serve files` |
| `ping <tc地址或昵称>` | 连通测试（DERP 中继 vs 直连） | 对端在线即可 |

> **DEPRECATED（v1 wrapper，过渡期保留）**：`node --no-warnings bin/fengyu.js <子命令>` 仍可用，
> 但新环境请走上面的纯 skill 路径。v1 的 `card`（名片 zcard1. token）随 wrapper 冻结，
> 新安装直接 `genkey` 交换地址 + `book.txt` 登记即可（名片 token 可解析后同样写进 book.txt）。

## 建立连接（三步）

1. **A 端**：`genkey --key=zhixia-default` → 把打印的 tc 地址发给 B（微信/IM/任何渠道都行）
2. **B 端**：`echo -e "A\t<A的地址>" >> ~/.fengyu/book.txt`；A 端反过来也存 B
3. 发数据前起对应监听：聊天/ping → 裸监听；收文件 → 接收方 `recv`；拉文件 → 接收方 `serve files`

同一身份不能自连（P2P 环回不经 DERP）；本机双向测试需 `genkey` 两个不同 key。

## ⚠ 已实测的坑（2026-09-24 双机）

1. **通讯录会过期**：key 文件在容器重建等场景重新生成后，book.txt 里的旧地址全部作废（症状：对端在线仍 ping 超时）。修法：重读对端当前 `Server listening` 日志行刷新 book。genkey 打印地址与 listener 日志地址（端口字段不同）都能拨通。
2. **`cp` 走系统 scp/SFTP**：对端必须开着 `recv` 或 `serve files`；**裸 tailcat 监听会拦截 SFTP 握手**，发文件前先把裸监听杀掉。
3. **SFTP-over-DERP 有方向性**：VPS 客户端 → NAT 后本机 方向握手不稳（多次 `Dial: context deadline exceeded`），反向稳。传不动就切让对方拉。
4. **DERP ≠ 离线信箱**：中继要求两端都在线，对端离线 ping 永远 `context deadline exceeded`。

## 🛡 隐私护栏（写死在 skill 里）

`lib/privacy-guard.js` 三层规则，`send-file` 默认生效，命中即**整批不发**（本地判定，连接建立前）：

1. **文件名**：密钥/证书材料、SSH 私钥、`.env*`、`credentials*`、口令文件、密钥库/钱包、`.ssh/.aws/.gnupg/.config/.docker/.kube` 目录内文件
2. **内容嗅探（≤512KB）**：PRIVATE KEY 块、明文口令/密钥字段（占位符放行）、≥3 处 IP:port
3. **可执行魔数**：ELF / Windows PE / Mach-O（不明程序禁发；图片/文档/压缩包不误伤）

白放行：`*.pub`（公钥）、`*.crt`（证书）。

**Agent 行为红线**（skill 包写死）：不得私自发密钥/凭据/私有端口配置/不明程序；不得自行加 `--force`；
不得自动执行从 P2P 收到的任何远程文件。

## 目录结构

```
skill/fengyu/SKILL.md    # ✅ v2 现役：AI agent 操作手册（纯 shell 姿势）
skill/fengyu/install.sh  # ✅ v2 现役：纯 sh 安装器（官方二进制 + 国内镜像 fallback）
bin/fengyu.js            # ⚠ DEPRECATED v1 wrapper（过渡期保留）
lib/p2p.js               # ⚠ DEPRECATED v1 P2P 命令层
lib/tailcat-adapter.js   # ⚠ DEPRECATED v1 tailcat 引擎封装
lib/privacy-guard.js     # ⚠ DEPRECATED v1 隐私护栏（规则本体已写进 SKILL.md 红线）
scripts/install-tailcat.js # ⚠ DEPRECATED v1 Node 安装器
share/                   # files 服务白名单默认目录（v1；v2 默认 ~/.fengyu/share/）
test/                    # 名片 round-trip / 护栏 15 用例（v1 wrapper 测试）
```

## 与 zhixia-net 的关系

本仓库从 `jireh-he/zhixia-net` 的 P2P 层独立而来：
- **保留**：tailcat 传输层（唯一经双机实测验证的底座）+ 隐私护栏规则 + 消息治理规则
- **屏蔽**：原 zhixia 的 MVP/蓝图设计（DHT、分布式存储、信誉/治理/经济/市场、三级连接策略等），
  未经验证，已移至 `zhixia-net/archive/`，不再作为活跃设计维护
- **兼容**：key 名沿用 `zhixia-default`。**注意**：身份稳定性取决于 key 文件本身不重新生成；
  容器重建等场景会重新生成 key 文件 → 旧 tc 地址全部作废，需重新交换地址（见上文"已实测的坑" #1）
