---
name: raider-io
description: "查询 Raider.io 数据：角色大秘境分数、公会团本进度、本周词缀。当有人问'我的 IO 多少''公会打到哪了''这周词缀'等问题时触发。无需 API Key，直接 curl。"
metadata:
  openclaw:
    emoji: "📊"
    requires:
      bins: ["curl"]
---

# Raider.io 数据查询

通过 Raider.io 公开 API 获取「雨落烟尘」公会及成员的实时数据。

## 常量

```
REGION=cn
GUILD_NAME=雨落烟尘（URL编码：%E9%9B%A8%E8%90%BD%E7%83%9F%E5%B0%98）
GUILD_REALM=scarlet-crusade（血色十字军的英文 slug）
BASE_URL=https://raider.io/api/v1
```

## 触发条件

- "我的 IO 多少" "xxx 的大秘境分" "IO 查一下" → 角色查询
- "公会进度" "打到几了" "团本进度" → 公会进度查询
- "这周词缀" "词缀是什么" "词缀怎么处理" → 词缀查询
- "公会成员排行" "谁 IO 最高" → 公会成员列表

---

## Instructions

### 1. 查角色大秘境分数

**API：**
```
GET {BASE_URL}/characters/profile
  ?region=cn
  &realm={realm_slug}
  &name={角色名}
  &fields=mythic_plus_scores_by_season:current
```

**注意事项：**
- `realm` 必须是英文 slug（如 `scarlet-crusade`、`dark-iron`），不是中文服名
- 血色十字军 slug：`scarlet-crusade`
- 如果角色不在血色十字军，先从公会成员列表中查找其真实 realm
- 如果查不到，告知用户"找不到这个角色，可能角色名或服务器有误"

**提取字段：**
```
mythic_plus_scores_by_season[0].scores.all   → 综合 IO 分
mythic_plus_scores_by_season[0].scores.dps   → DPS IO
mythic_plus_scores_by_season[0].scores.healer → 治疗 IO
mythic_plus_scores_by_season[0].scores.tank  → 坦克 IO
```

**回复示例：**
> "黑手叔叔（恶魔猎手·浩劫，DPS）本赛季 IO：综合 2847 / DPS 2847。"

---

### 2. 查公会团本进度

**API：**
```
GET {BASE_URL}/guilds/profile
  ?region=cn
  &realm=scarlet-crusade
  &name=%E9%9B%A8%E8%90%BD%E7%83%9F%E5%B0%98
  &fields=raid_progression
```

**提取字段：**
```json
raid_progression["tier-mn-1"] = {
  "summary": "3/9 N",
  "normal_bosses_killed": 3,
  "heroic_bosses_killed": 0,
  "mythic_bosses_killed": 0,
  "total_bosses": 9
}
```

**说明：** `tier-mn-1` 中 total_bosses=9 对应当前三个团本合计：
- 虚影尖塔（6 Boss）
- 梦境裂隙（1 Boss）
- 进军奎尔丹纳斯（2 Boss）

**回复示例：**
> "雨落烟尘当前进度（Raider.io）：普通 3/9，英雄 0/9，史诗 0/9。"

如果 guild_config.json 中 teams 有更具体的分团进度，结合两者一起说。

---

### 3. 查本周大秘境词缀

**API：**
```
GET {BASE_URL}/mythic-plus/affixes?region=cn&locale=zh_CN
```

**提取字段：**`affix_details` 数组，每个词缀含 `name` 和 `description`。

词缀中文名映射（常见词缀）：

| 英文 | 中文 |
|------|------|
| Fortified | 强韧 |
| Tyrannical | 暴君 |
| Xal'atath's Bargain: Ascendant | 沙拉塔斯的契约：飞升 |
| Xal'atath's Guile | 沙拉塔斯的狡诈 |
| Bolstering | 鼓舞 |
| Bursting | 爆裂 |
| Grievous | 悲痛 |
| Incorporeal | 无形 |
| Raging | 狂暴 |
| Sanguine | 血池 |
| Storming | 风暴 |
| Volcanic | 火山 |
| Entangling | 缠绕 |
| Spiteful | 怨恨 |

**回复示例：**
> "本周词缀：沙拉塔斯的契约：飞升 / 强韧 / 暴君 / 沙拉塔斯的狡诈。
> 强韧周小怪血厚，打完小怪注意时间。"

词缀简评（1 句话）可参考 SOUL.md 中的老玩家口吻给出。

---

### 4. 查公会成员列表（含 realm 信息）

当需要查某角色所在 realm 时，先查公会成员列表：

**API：**
```
GET {BASE_URL}/guilds/profile
  ?region=cn
  &realm=scarlet-crusade
  &name=%E9%9B%A8%E8%90%BD%E7%83%9F%E5%B0%98
  &fields=members
```

在 `members` 数组中按 `character.name` 匹配，取 `character.realm` 字段，转为 slug 后用于角色查询。

常见服务器中文→slug 对照（部分）：

| 中文 | Slug |
|------|------|
| 血色十字军 | scarlet-crusade |
| 黑暗之铁 | dark-iron |
| 祖尔金 | zul-jin |
| 伊利丹 | illidan |
| 末日祈祷 | doomhammer |
| 狂野之心 | wild-heart |

如果碰到未知的服名，从 API 返回的 `realm` 字段（已经是 slug 格式）直接用即可。

---

## 缓存策略

将以下内容缓存到 memory.md（格式：`[WoW缓存 YYYY-MM-DD] 内容`）：

- 本周词缀 → 每周二重置后更新一次
- 公会进度 → 每次查询后更新（进度变化频繁）
- 角色 IO 分 → 不缓存（每次实时查）

---

## Rules

- 所有数据标注来源："数据来自 Raider.io，最后爬取时间 {last_crawled_at}"
- `last_crawled_at` 超过 7 天时，提醒用户数据可能不够新
- 角色查不到时，不乱猜——告知用户确认角色名和服务器
- 不在群里公开比较成员间的 IO 排名，除非用户主动要求
- API 请求失败（非 200）时，告知用户"Raider.io 暂时查不到，稍后再试"
