#!/usr/bin/env sh
# fengyu 纯 skill 安装 — agent 直接用 shell 调 tailcat 二进制（零 Node、零 JS 封装）
#
# 用法：
#   sh skill/fengyu/install.sh                 # 装到 ~/.fengyu（默认，推荐）
#   FENGYU_HOME=$HOME/.fy sh skill/fengyu/install.sh
#
# 产物（全部在 $FENGYU_HOME，与 cwd 无关）：
#   $FENGYU_HOME/tailcat-<os>-<arch>   官方静态二进制（4 国内镜像 fallback + 续传）
#   $FENGYU_HOME/book.txt              通讯录（昵称<TAB>tc地址）
#   $FENGYU_HOME/inbox/                文件收件箱
#   $FENGYU_HOME/share/                files 白名单目录
#
# 依赖：仅 sh + curl（+ tar/unzip）。无 Node、无 npm。
set -eu

VERSION="${FENGYU_VERSION:-0.6.0}"
ROOT="${FENGYU_HOME:-$HOME/.fengyu}"

# 1) 平台探测
case "$(uname -s)" in
  Linux)  os=linux ;;
  Darwin) os=darwin ;;
  *) echo "[fengyu] ✗ 不支持的 OS: $(uname -s)" >&2; exit 1 ;;
esac
case "$(uname -m)" in
  x86_64|amd64) arch=amd64 ;;
  arm64|aarch64) arch=arm64 ;;
  armv7l) arch=armv7 ;;
  *) echo "[fengyu] ✗ 不支持的架构: $(uname -m)" >&2; exit 1 ;;
esac
target="tailcat-${os}-${arch}"
BIN="$ROOT/$target"

# 2) 建目录
mkdir -p "$ROOT/inbox" "$ROOT/share"
touch "$ROOT/book.txt"

# 3) 若已有可用二进制则跳过下载
if [ -x "$BIN" ] && "$BIN" --version >/dev/null 2>&1; then
  echo "[fengyu] 复用已装二进制: $BIN ($("$BIN" --version 2>/dev/null | head -1))"
  exit 0
fi

# 4) 下载：官方 + 4 镜像轮询，断点续传；平台：linux/darwin tar.gz，windows zip
case "$(uname -s)" in
  Darwin) ext=tar.gz ;;
  *) case "$(uname -m)" in
       x86_64|amd64) ext=tar.gz ;;
       *) ext=tar.gz ;;
     esac ;;
esac
if [ "$os" = "darwin" ]; then
  case "$arch" in
    arm64) asset_arch=arm64 ;;
    *) asset_arch=amd64 ;;
  esac
else
  asset_arch="$arch"
fi
filename="tailcat_${VERSION}_${os}_${asset_arch}.${ext}"
base="https://github.com/tailscale/tailcat/releases/download/v${VERSION}/${filename}"
urls="
$base
https://github.moeyy.xyz/$base
https://gh-proxy.com/$base
https://mirror.ghproxy.com/$base
https://ghproxy.net/$base
"
dl="$ROOT/.dl-${target}"
ok=0
echo "[fengyu] 下载 tailcat v$VERSION ($os-$arch) → $BIN"
# 最多 10 轮：每轮依次试各源，失败则续传继续
try=0
while [ $try -lt 10 ] && [ "$ok" != "1" ]; do
  try=$((try + 1))
  i=0
  for u in $(echo "$urls" | grep -v '^$'); do
    i=$((i + 1))
    if [ $i -eq 1 ]; then
      curl -sL --max-time 120 -o "$dl" "$u" 2>/dev/null || continue
    else
      curl -sL --max-time 120 -C - -o "$dl" "$u" 2>/dev/null || continue
    fi
    if [ -f "$dl" ]; then
      if [ "$ext" = "tar.gz" ]; then
        tar -tzf "$dl" >/dev/null 2>&1 && { ok=1; echo "[fengyu] 下载成功: $u"; break; }
      else
        unzip -t "$dl" >/dev/null 2>&1 && { ok=1; echo "[fengyu] 下载成功: $u"; break; }
      fi
      echo "[fengyu] 下载不完整（$(stat -c%s "$dl" 2>/dev/null || stat -f%z "$dl" 2>/dev/null || echo ?)B），续传..."
    fi
  done
done
if [ "$ok" != "1" ]; then
  echo "[fengyu] ✗ 全部下载源失败。手工：" >&2
  echo "  curl -L $base" >&2
  exit 1
fi
mkdir -p "$ROOT"
if [ "$ext" = "tar.gz" ]; then tar -xzf "$dl" -C "$ROOT"; else unzip -o "$dl" -d "$ROOT"; fi
if [ -f "$ROOT/tailcat" ]; then mv "$ROOT/tailcat" "$BIN"; fi
chmod +x "$BIN"
rm -f "$dl"
echo "[fengyu] ✓ 安装完成: $BIN ($("$BIN" --version 2>/dev/null | head -1))"

# 5) 用法提示
echo "  生成稳定身份: $BIN genkey --key=zhixia-default   # 首次输出 tc 地址"
echo "  之后所有命令: $BIN --key=zhixia-default <subcmd>  # 全局 --key 在子命令前"
echo "  通讯录:   $ROOT/book.txt   收件箱: $ROOT/inbox   白名单: $ROOT/share"
echo "  详细命令见 skill/fengyu/SKILL.md（agent 直接用 shell 调此二进制）"
