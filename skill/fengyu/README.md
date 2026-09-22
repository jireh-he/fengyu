# fengyu skill 包

给 AI agent（Hermes / Claude / 任意能读 SKILL.md 的终端智能体）安装 fengyu P2P 能力。

- `SKILL.md` — agent 读的能力说明：命令速查、建连三步、隐私护栏红线、消息治理、踩坑清单
- `install.sh` — 人类/agent 一键安装（clone + 下载 tailcat 二进制 + 验证）

## 快速使用

```sh
# 独立安装到 ~/.fengyu
FENGYU_HOME=$HOME/.fengyu sh skill/fengyu/install.sh

# 或在 fengyu 仓库内开发模式直跑
cd fengyu && node --no-warnings bin/fengyu.js key
```

仓库主文档：`README.md`。隐私护栏单测：`node test/_privacy_guard.js`。
