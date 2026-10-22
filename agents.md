# AI Agents Guide — Freebuff and OpenCode

AI agent configuration for projects: Freebuff and OpenCode.

> **Repos:**
> - Freebuff: [CodebuffAI/freebuff](https://github.com/CodebuffAI/freebuff)
> - OpenCode: [opencode-ai/opencode](https://github.com/opencode-ai/opencode)

---

## 1. Structure

### Freebuff

Each project keeps its configuration in `.agents/`:

```
~/your-project/
└── .agents/
    ├── skills/              # installed skills
    │   ├── supabase/
    │   │   └── SKILL.md
    │   ├── shadcn/
    │   ├── vercel-*/
    │   └── ...
    └── mcp.json             # configured MCP servers
```

### OpenCode

OpenCode looks for skills in multiple locations:

```
# Project (high priority)
~/your-project/
├── .opencode/
│   └── skills/<name>/SKILL.md
├── .claude/
│   └── skills/<name>/SKILL.md
└── .agents/
    └── skills/<name>/SKILL.md

# Global (all sessions)
~/.config/opencode/
├── opencode.jsonc           # global configuration
└── skills/<name>/SKILL.md
~/.claude/skills/<name>/SKILL.md
~/.agents/skills/<name>/SKILL.md
```

> **Advantage:** OpenCode reuses the same `.agents/skills/` as Freebuff. Installing skills once works for both.

---

## 2. Skills

Skills are reusable instructions that agents load for specific tasks.

### Install a skill (community)

```bash
# Search available skills
npx skills find <query>

# Preview skills from a repo
npx skills add <owner/repo> --list

# Install a specific skill
npx skills add <owner/repo> --skill <name> --yes
```

### Create a custom skill

Create `SKILL.md` with YAML frontmatter:

```markdown
---
name: my-skill
description: Clear description of the skill
license: MIT
---

## What I do
- Specific instructions...

## When to use me
- When to activate this skill...
```

**Name rules:** lowercase, alphanumeric, single hyphens (`^[a-z0-9]+(-[a-z0-9]+)*$`), 1-64 characters.

### Skills installed in this project

| Skill | Description |
|---|---|
| `supabase` | Supabase CLI and config |
| `supabase-postgres-best-practices` | PostgreSQL + Supabase best practices |
| `shadcn` | shadcn/ui components |
| `vercel-optimize` | Vercel app optimization |
| `vercel-react-best-practices` | React best practices |
| `vercel-react-native-skills` | React Native + Vercel |
| `vercel-react-view-transitions` | View Transitions API |
| `vercel-composition-patterns` | Composition patterns |
| `vercel-cli-with-tokens` | Vercel CLI with tokens |
| `deploy-to-vercel` | Deploy to Vercel |
| `interface-design` | Interface design |
| `web-design-guidelines` | Web design guidelines |
| `writing-guidelines` | Writing guidelines |

---

## 3. MCP Servers (Model Context Protocol)

MCPs let agents connect to external services.

### Freebuff — `.agents/mcp.json`

```json
{
  "mcpServers": {
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp"],
      "env": {
        "CONTEXT7_API_KEY": "$CONTEXT7_API_KEY"
      }
    }
  }
}
```

### OpenCode — `~/.config/opencode/opencode.jsonc`

```jsonc
{
  "$schema": "https://opencode.ai/config.json",
  "mcp": {
    "context7": {
      "type": "remote",
      "url": "https://mcp.context7.com/mcp",
      "headers": {
        "Authorization": "ctx7sk-YOUR_API_KEY"
      },
      "enabled": true
    }
  }
}
```

> **Difference:** Freebuff uses MCPs via `npx` (local), while OpenCode supports remote MCPs directly.

### Available MCPs

| MCP | Description | Environment variable |
|---|---|---|
| `context7` | Contextual library documentation | `CONTEXT7_API_KEY` |

---

## 4. Synchronization between PCs

### Recommended option: include `.agents/` in git

Skills and MCPs are lightweight files (markdown and JSON). It is safe to commit them to the repo:

```bash
# Verify that .agents/ is not in .gitignore
cat .gitignore | grep -v ".agents"

# Add and commit
git add .agents/
git commit -m "feat: add skills and MCPs"
git push
```

On the other PC, you only need:

```bash
git clone <repo>
# Skills and MCPs are already included
```

### If `.agents/` is in .gitignore

Remove the line from `.gitignore`:

```bash
# Edit .gitignore and remove the line that excludes .agents/
nano .gitignore
```

---

## 5. Global configuration

### Freebuff — `~/.config/manicode/`

| File | Contents |
|---|---|
| `settings.json` | Model, mode, preferences |
| `credentials.json` | Authentication |
| `freebuff-metadata.json` | Installation metadata |
| `projects/` | Chat history per project |

### OpenCode — `~/.config/opencode/`

| File | Contents |
|---|---|
| `opencode.jsonc` | Global configuration (MCPs, permissions, model) |
| `skills/` | Global skills (available in all projects) |

> **Freebuff:** `settings.json` syncs automatically with your account.
> **OpenCode:** `opencode.jsonc` syncs via git (add it to dotfiles).

---

## 6. Reference

### Freebuff
- Site: https://freebuff.com
- Docs: https://www.codebuff.com/docs
- Skills CLI: `npx skills --help`

### OpenCode
- Site: https://opencode.ai
- Docs: https://opencode.ai/docs
- Skills: https://opencode.ai/docs/skills/
- Agents: https://opencode.ai/docs/agents/
- Config: `~/.config/opencode/opencode.jsonc`
