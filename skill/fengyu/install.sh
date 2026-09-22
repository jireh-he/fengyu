#!/usr/bin/env sh
# fengyu 一键安装 — 让任何终端/AI agent 获得 P2P 聊天 & 文件传输能力
#
# 用法：
#   sh skill/fengyu/install.sh           # 装到当前 fengyu 仓库根目录（开发模式）
#   FENGYU_HOME=$HOME/.fengyu sh skill/fengyu/install.sh   # 独立安装到 ~/.fengyu
#
# 依赖：git + node(>=16)。P2P 路径零 npm 依赖（静态 tailcat 二进制 + Node 内置模块）。
set -eu

REPO_URL="${FENGYU_REPO:-https://github.com/jireh-he/fengyu.git}"

# 1) 定位工作目录：在仓库内跑 → 原地；否则 clone 到 FENGYU_HOME
in_repo=0
if [ -f "bin/fengyu.js" ] && [ -f "scripts/install-tailcat.js" ]; then in_repo=1; fi

if [ "$in_repo" = "1" ]; then
  ROOT="$(pwd)"
else
  ROOT="${FENGYU_HOME:-$HOME/.fengyu}"
  if [ ! -d "$ROOT/.git" ]; then
    echo "[fengyu] cloning $REPO_URL → $ROOT"
    git clone --depth 1 "$REPO_URL" "$ROOT"
  fi
fi
cd "$ROOT"

# 2) node 检查（P2P 路径 Node 16+ 即可；tailcat 静态二进制与 Node 版本无关）
if ! command -v node >/dev/null 2>&1; then
  echo "[fengyu] ✗ 未找到 node。P2P 能力需要 Node >= 16（只需 node，无需 npm install）。" >&2
  exit 1
fi
NODE_VER="$(node -p 'process.versions.node.split(".")[0]')"
if [ "$NODE_VER" -lt 16 ]; then
  echo "[fengyu] ✗ Node $(node -v) 过低，需要 >= 16" >&2
  exit 1
fi

# 3) 下载 tailcat 静态二进制（国内镜像 fallback + 续传 + sha256）
echo "[fengyu] 安装 tailcat 引擎（bin/tailcat/）..."
node scripts/install-tailcat.js

# 4) 验证 P2P 路径（零 npm 依赖：不跑 npm install 也能通过）
echo "[fengyu] 验证 P2P 命令..."
node --no-warnings bin/fengyu.js help >/dev/null
node --no-warnings bin/fengyu.js key

echo "[fengyu] ✓ 安装完成。用法（在 $ROOT 下）:"
echo "  node --no-warnings bin/fengyu.js key     # 生成本端稳定地址"
echo "  node --no-warnings bin/fengyu.js help    # 全部命令"
