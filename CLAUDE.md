# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

An OpenClaw agent workspace for 「雨落烟尘-robot」— a QQ group bot serving the 「雨落烟尘」WoW guild on the 血色十字军 (CN) server. This repo is **configuration and prompt files only**, no executable application code.

## Database

Initialize the SQLite database (required before first run):
```bash
sqlite3 guild.db < db/init.sql
```

The script is idempotent (`IF NOT EXISTS` throughout). Four tables: `raid_signups`, `guild_events`, `members`, `bot_logs`.

## Architecture

### File Loading Order (Session Start)

The agent reads files in this fixed order on every session start (defined in `AGENTS.md`):

```
SOUL.md → IDENTITY.md → guild_config.json → memory.md → memory/YYYY-MM-DD.md
```

**SOUL.md is the authority.** When any other file conflicts with SOUL.md, SOUL.md wins.

### Skills

Skills live in `skills/<name>/SKILL.md`. Each skill is a self-contained instruction set with a YAML frontmatter declaring its name, trigger description, emoji, and binary dependencies (`curl`, `sqlite3`).

Currently registered skills (also listed in `AGENTS.md`):

| Skill | Trigger | Deps |
|-------|---------|------|
| `guild-info` | Activity times, team info, join rules | — |
| `raid-signup` | Signup / absence / late registration | sqlite3 |
| `wow-lookup` | Boss guides, talents, BiS gear | curl |
| `raider-io` | IO scores, guild progression, affixes | curl |

### Data Sources

Two tiers:

- **Static:** `guild_config.json` — activity schedule, team config, rules, contacts. Updated manually by admins. Fields still marked `TODO:` are unfilled.
- **Dynamic:** `guild.db` — raid signups, guild events, member records, bot logs.

External APIs (all require `curl`, no auth keys):
- Raider.io public API — guild progression, character IO, weekly affixes
- WoWHead / Icy Veins / NGA — scraped via web search for game guides
- Raider.io affixes endpoint: `GET https://raider.io/api/v1/mythic-plus/affixes?region=cn`
- Guild profile: `GET https://raider.io/api/v1/guilds/profile?region=cn&realm=scarlet-crusade&name=...`
- Character: `GET https://raider.io/api/v1/characters/profile?region=cn&realm={slug}&name=...` — realm must be the English slug, not Chinese name

### Memory

- `memory.md` — long-term facts: first kills, rule changes, FAQ, WoW data cache entries (format: `[WoW缓存 YYYY-MM-DD] ...`, expire after 14 days)
- `memory/YYYY-MM-DD.md` — daily raid signup logs

### Scheduled Tasks

Defined in `HEARTBEAT.md` as cron expressions (Asia/Shanghai). Five tasks: pre-raid reminder (19:30), last call (19:55), next-day preview (22:00), weekly progress report (Fri 20:00), affix broadcast (Tue 09:00). Must be configured in the OpenClaw scheduler separately.

## Key Constraints

- **Admin gate:** Only QQ IDs in `guild_config.json → bot_config.admin_qq_ids` can trigger data mutations.
- **QQ format:** All responses must be plain text, ≤500 chars per message (`bot_config.response_max_length`).
- **Realm slugs:** Raider.io character API requires English realm slugs (e.g. `scarlet-crusade`, `dark-iron`). The guild members list endpoint returns the slug directly in the `character.realm` field.
- **NGA direct curl returns 403** — use web search to reach NGA content instead.
- Guild faction is **Horde** (confirmed via Raider.io API).
