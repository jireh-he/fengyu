#!/usr/bin/env node
'use strict';
// fengyu（风语）— 给 AI Agent 的 P2P 通讯 & 文件传输 CLI
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
