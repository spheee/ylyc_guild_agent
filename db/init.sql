-- 「雨落烟尘」公会数据库初始化脚本
-- 数据库文件：guild.db（SQLite 3）
-- 执行方式：sqlite3 guild.db < db/init.sql
-- 可安全重复执行（所有语句使用 IF NOT EXISTS）

-- ================================================================
-- 1. 团本报名表
-- ================================================================

CREATE TABLE IF NOT EXISTS raid_signups (
    id                INTEGER PRIMARY KEY AUTOINCREMENT,
    date              TEXT NOT NULL,           -- 活动日期 YYYY-MM-DD
    team              TEXT NOT NULL,           -- team_1 或 team_2
    character_name    TEXT NOT NULL,           -- 角色名（来自QQ群昵称或自报）
    qq_id             TEXT DEFAULT '',         -- 发言人QQ号（可选，用于去重）
    role              TEXT DEFAULT '',         -- 职责：tank / healer / dps / unknown
    status            TEXT NOT NULL,           -- signed_up / absent / late
    reason            TEXT DEFAULT '',         -- 请假或迟到原因
    estimated_arrival TEXT DEFAULT '',         -- 迟到预计到达时间，如 20:30
    created_at        TEXT DEFAULT (datetime('now', 'localtime')),
    updated_at        TEXT DEFAULT (datetime('now', 'localtime'))
);

CREATE INDEX IF NOT EXISTS idx_signups_date
    ON raid_signups(date);

CREATE INDEX IF NOT EXISTS idx_signups_date_team
    ON raid_signups(date, team);

CREATE INDEX IF NOT EXISTS idx_signups_date_team_char
    ON raid_signups(date, team, character_name);

-- ================================================================
-- 2. 公会大事记（首杀、活动变更、人员变动等）
-- ================================================================

CREATE TABLE IF NOT EXISTS guild_events (
    id           INTEGER PRIMARY KEY AUTOINCREMENT,
    event_date   TEXT NOT NULL,               -- 事件日期 YYYY-MM-DD
    event_type   TEXT NOT NULL,               -- first_kill / schedule_change / member_join / member_leave / announcement
    title        TEXT NOT NULL,               -- 事件标题，如"虚影尖塔 Boss1 首杀"
    description  TEXT DEFAULT '',             -- 详细描述
    team         TEXT DEFAULT '',             -- 关联团（team_1 / team_2 / all）
    recorded_by  TEXT DEFAULT 'bot',          -- 记录者
    created_at   TEXT DEFAULT (datetime('now', 'localtime'))
);

CREATE INDEX IF NOT EXISTS idx_events_date
    ON guild_events(event_date);

CREATE INDEX IF NOT EXISTS idx_events_type
    ON guild_events(event_type);

-- ================================================================
-- 3. 成员档案（轻量，仅记录QQ群内的基本信息）
-- ================================================================

CREATE TABLE IF NOT EXISTS members (
    id             INTEGER PRIMARY KEY AUTOINCREMENT,
    qq_id          TEXT UNIQUE NOT NULL,       -- QQ号
    qq_nickname    TEXT DEFAULT '',            -- QQ群昵称
    character_name TEXT DEFAULT '',            -- 游戏角色名（主号）
    class          TEXT DEFAULT '',            -- 职业（warrior / paladin / etc.）
    spec           TEXT DEFAULT '',            -- 专精
    role           TEXT DEFAULT '',            -- 主要职责：tank / healer / dps
    team           TEXT DEFAULT '',            -- 所在团：team_1 / team_2 / none
    join_date      TEXT DEFAULT '',            -- 入会日期 YYYY-MM-DD
    notes          TEXT DEFAULT '',            -- 备注
    is_officer     INTEGER DEFAULT 0,          -- 是否管理员：0/1
    is_active      INTEGER DEFAULT 1,          -- 是否活跃：0/1
    created_at     TEXT DEFAULT (datetime('now', 'localtime')),
    updated_at     TEXT DEFAULT (datetime('now', 'localtime'))
);

-- ================================================================
-- 4. Bot 操作日志（异常行为记录）
-- ================================================================

CREATE TABLE IF NOT EXISTS bot_logs (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    log_time    TEXT DEFAULT (datetime('now', 'localtime')),
    level       TEXT NOT NULL,                -- info / warn / error
    event       TEXT NOT NULL,               -- 事件类型，如 signup / admin_cmd / permission_denied
    qq_id       TEXT DEFAULT '',             -- 触发者QQ
    message     TEXT NOT NULL,               -- 日志内容
    raw_input   TEXT DEFAULT ''              -- 原始消息（敏感信息不记录）
);

CREATE INDEX IF NOT EXISTS idx_logs_time
    ON bot_logs(log_time);

CREATE INDEX IF NOT EXISTS idx_logs_level
    ON bot_logs(level);

-- ================================================================
-- 初始化完成提示
-- ================================================================

SELECT 'guild.db 初始化完成。Tables: raid_signups, guild_events, members, bot_logs' AS status;
