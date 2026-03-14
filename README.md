# 雨落烟尘-robot

「雨落烟尘」公会专属 QQ 群机器人，基于 OpenClaw 构建。服务于魔兽世界血色十字军服务器。

## 功能

- **公会信息查询** — 活动时间、分团、进度、入会规则、联系人
- **团本报名管理** — 报名/请假/迟到登记，SQLite 持久化
- **WoW 实时查询** — Boss 攻略、天赋、BiS 装备（外部搜索，不依赖旧训练数据）
- **定时任务** — 开团提醒、次日预告、周报、词缀播报

## 文件结构

```
hsky-agent/
├── SOUL.md              # Bot 身份、语气、行为规则（核心）
├── IDENTITY.md          # 对外展示方式
├── AGENTS.md            # Session 启动顺序、权限控制
├── USER.md              # 运营者档案
├── HEARTBEAT.md         # 定时任务定义（5个任务）
├── guild_config.json    # 公会配置（活动时间、分团、规则等）
├── guild.db             # 动态数据库（报名/事件/成员）
├── memory.md            # Bot 长期记忆（公会大事件）
├── memory/              # 每日报名日志 YYYY-MM-DD.md
├── db/
│   └── init.sql         # 数据库初始化脚本
└── skills/
    ├── guild-info/      # 公会信息查询
    ├── raid-signup/     # 报名管理（需要 sqlite3）
    └── wow-lookup/      # WoW 实时查询（需要 curl）
```

## 快速开始

**1. 填写配置**

编辑 `guild_config.json`，填写所有 `TODO:` 字段（团长、进度、阵营、QQ号等）。

**2. 初始化数据库**

```bash
sqlite3 guild.db < db/init.sql
```

**3. 配置定时任务**

按 `HEARTBEAT.md` 中的 cron 表达式在 OpenClaw 调度器中配置5个定时任务。

**4. 启动 Bot**

Bot 启动时依次读取：`SOUL.md` → `IDENTITY.md` → `guild_config.json` → `memory.md` → 当日日志。

## 待完成

- [ ] 填写 `guild_config.json` 中的 TODO 字段
- [ ] 执行 `db/init.sql` 初始化数据库
- [ ] 测试 wow-lookup 搜索链路（需 curl + 外网访问）
- [ ] 在 OpenClaw 中配置 HEARTBEAT.md 定时任务
- [ ] 创建初始 `memory.md`

## 技术依赖

| 依赖 | 用途 |
|------|------|
| OpenClaw | QQ 机器人框架 |
| SQLite 3 | 报名/事件数据持久化 |
| curl | WoW 实时信息查询 |
| WoWHead / NGA / Icy Veins | 游戏信息数据源 |
