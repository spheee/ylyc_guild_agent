---
name: raid-signup
description: "处理公会团本报名、请假和迟到登记。当群成员说'报名''我来''+1''请假''来不了''鸽了''迟到''晚到'等关键词时触发此技能。也处理报名查询、出勤统计等请求。"
metadata:
  openclaw:
    emoji: "📋"
    requires:
      bins: ["sqlite3"]
---

# 团本报名管理

处理「雨落烟尘」公会的团本报名、请假、迟到登记，以及报名情况查询。

## 数据存储

所有报名数据存储在 `{baseDir}/../../guild.db`（workspace 根目录）。

首次使用时，如果数据库不存在，执行以下 SQL 初始化：

```sql
CREATE TABLE IF NOT EXISTS raid_signups (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    date TEXT NOT NULL,          -- 活动日期 YYYY-MM-DD
    team TEXT NOT NULL,          -- team_1 或 team_2
    character_name TEXT NOT NULL, -- 角色名
    role TEXT DEFAULT '',        -- 职责：tank/healer/dps/未知
    status TEXT NOT NULL,        -- signed_up / absent / late
    reason TEXT DEFAULT '',      -- 请假或迟到原因
    estimated_arrival TEXT DEFAULT '', -- 迟到预计到达时间
    created_at TEXT DEFAULT (datetime('now', 'localtime')),
    updated_at TEXT DEFAULT (datetime('now', 'localtime'))
);

CREATE INDEX IF NOT EXISTS idx_signups_date ON raid_signups(date);
CREATE INDEX IF NOT EXISTS idx_signups_date_team ON raid_signups(date, team);
```

## 触发条件

当群消息中出现以下内容时激活：

**报名类：**
- "报名" "我来" "+1" "算我一个" "今晚到" "到"
- 如果附带职责信息（如"T位""奶""DPS"），一并记录

**请假类：**
- "请假" "来不了" "鸽了" "有事" "不来了" "缺席"
- 尝试提取原因（如"加班""有事""出差"）

**迟到类：**
- "迟到" "晚到" "晚点到" "晚半小时" "晚一会"
- 尝试提取预计到达时间

**查询类：**
- "今晚谁来" "报名情况" "几个人了" "还差谁"

## Instructions

### 报名登记

1. 识别发言人（从群消息上下文获取昵称/角色名）
2. 判断目标日期：默认为最近的下一个活动日（周一/周二/周四）
3. 判断分团：如果用户指定了就用指定的，否则询问
4. 解析职责（tank/healer/dps），如未提及标记为空
5. 写入数据库
6. 回复确认，语气轻松

**判断下一个活动日的逻辑：**
- 读取 guild_config.json 中 raid_schedule.days
- 如果当前是活动日且当前时间 < 20:00，目标日期为今天
- 如果当前是活动日且当前时间 >= 20:00，目标日期为下一个活动日
- 如果当前不是活动日，目标日期为最近的下一个活动日

### 请假登记

1. 识别发言人
2. 判断目标日期（同上逻辑，也可能是"周四请假"这种指定日期）
3. 如果该日期已有报名记录，更新 status 为 absent
4. 如果没有记录，直接插入 status=absent 的记录
5. 提取原因（如果有的话）
6. 回复确认

### 迟到登记

1. 识别发言人
2. 判断目标日期
3. 插入或更新记录为 status=late
4. 提取预计到达时间
5. 回复确认

### 报名查询

当有人查询时，执行：

```sql
SELECT character_name, role, status, reason, estimated_arrival
FROM raid_signups
WHERE date = ? AND team = ?
ORDER BY status, created_at;
```

输出格式（纯文本，适配QQ群）：

```
📋 [日期] [团别] 报名情况

已报名（X人）：
  角色名1(T) / 角色名2(奶) / 角色名3(DPS) ...

请假（Y人）：
  角色名4(加班) / 角色名5(有事)

迟到（Z人）：
  角色名6(预计8:30到)
```

### 同一人重复操作

- 同一天同一团，同一个角色名只保留一条记录
- 先报名后请假 → 更新为请假
- 先请假后报名 → 更新为报名
- 用 UPSERT 或先查后更新的方式处理

## Rules

- 只在活动日当天或前一天处理报名，太早的报名提醒"还早呢，到时候再报"
- 不自行编造角色名，必须从消息上下文获取
- 报名数据按天归档，过期数据不删除（留作出勤统计）
- 数据库操作失败时，告知用户"记录失败了，手动跟团长说一下"，不要静默失败
- 不要在群里公开 DKP 或其他敏感积分信息，除非用户主动查询自己的