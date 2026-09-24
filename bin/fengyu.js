#!/usr/bin/env node
'use strict';
// ⚠ DEPRECATED (v2.0, 2026-09-24): 本 JS 封装层已废弃。
// fengyu 现在是纯 skill：agent 直接用 shell 调用 ~/.fengyu/tailcat-<os>-<arch> 官方二进制，
// 零 JS/Node、零 cwd 依赖、零通讯录解析故障面。
// 安装: sh skill/fengyu/install.sh   文档: skill/fengyu/SKILL.md
// 本文件保留仅作历史参考，不再维护。请改用 SKILL.md 中的 shell 命令。
//
// 原用途（v1）：给 AI Agent 的 P2P 通讯 & 文件传输 CLI
// 引擎：Tailscale 官方 tailcat（WireGuard 端到端加密 + 公共 DERP 中继 bootstrap + NAT 打洞）
// 零 npm 依赖：P2P 路径纯 Node stdlib + bin/tailcat/ 静态二进制（scripts/install-tailcat.js 自动下载）。
//
// 由 zhixia-net P2P 层独立而来（tailcat 是唯一保留的传输底座；
// 原 zhixia 的 MVP/蓝图设计——DHT、分布式存储、治理/经济/市场、三级连接策略——
// 均未验证，已归档屏蔽，见 zhixia-net 仓库 archive/）。
const p2p = require('../lib/p2p');

const argv = process.argv;
const cmd = argv[2];

if (cmd && !['-h', '--help', 'help'].includes(cmd)) {
  p2p.main(argv.slice(2));
  return; // 监听类命令靠事件循环保活，不能 process.exit
}

p2p.main(['help']);
process.exit(0);
