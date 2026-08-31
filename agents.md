# Guía de Agentes AI — Freebuff y OpenCode

Configuración de agentes AI para proyectos: Freebuff y OpenCode.

> **Repos:**
> - Freebuff: [CodebuffAI/freebuff](https://github.com/CodebuffAI/freebuff)
> - OpenCode: [opencode-ai/opencode](https://github.com/opencode-ai/opencode)

---

## 1. Estructura

### Freebuff

Cada proyecto tiene su configuración en `.agents/`:

```
~/tu-proyecto/
└── .agents/
    ├── skills/              # skills instalados
    │   ├── supabase/
    │   │   └── SKILL.md
    │   ├── shadcn/
    │   ├── vercel-*/
    │   └── ...
    └── mcp.json             # servidores MCP configurados
```

### OpenCode

OpenCode busca skills en múltiples ubicaciones:

```
# Proyecto (prioridad alta)
~/tu-proyecto/
├── .opencode/
│   └── skills/<name>/SKILL.md
├── .claude/
│   └── skills/<name>/SKILL.md
└── .agents/
    └── skills/<name>/SKILL.md

# Global (todas las sesiones)
~/.config/opencode/
├── opencode.jsonc           # configuración global
└── skills/<name>/SKILL.md
~/.claude/skills/<name>/SKILL.md
~/.agents/skills/<name>/SKILL.md
```

> **Ventaja:** OpenCode reutiliza los mismos `.agents/skills/` que Freebuff. Instalar skills una vez funciona para ambos.

---

## 2. Skills

Los skills son instrucciones reutilizables que los agentes cargan para tareas específicas.

### Instalar un skill (comunidad)

```bash
# Buscar skills disponibles
npx skills find <query>

# Previsualizar skills de un repo
npx skills add <owner/repo> --list

# Instalar un skill específico
npx skills add <owner/repo> --skill <nombre> --yes
```

### Crear un skill personalizado

Crear `SKILL.md` con frontmatter YAML:

```markdown
---
name: mi-skill
description: Descripción clara del skill
license: MIT
---

## Qué hago
- Instrucciones específicas...

## Cuándo usarme
- Cuándo activar este skill...
```

**Reglas de nombre:** minúsculas, alfanumérico, guiones simples (`^[a-z0-9]+(-[a-z0-9]+)*$`), 1-64 caracteres.

### Skills instalados en este proyecto

| Skill | Descripción |
|---|---|
| `supabase` | Supabase CLI y config |
| `supabase-postgres-best-practices` | Mejores prácticas PostgreSQL + Supabase |
| `shadcn` | Componentes shadcn/ui |
| `vercel-optimize` | Optimización de apps Vercel |
| `vercel-react-best-practices` | Mejores prácticas React |
| `vercel-react-native-skills` | React Native + Vercel |
| `vercel-react-view-transitions` | View Transitions API |
| `vercel-composition-patterns` | Patrones de composición |
| `vercel-cli-with-tokens` | CLI de Vercel con tokens |
| `deploy-to-vercel` | Deploy a Vercel |
| `interface-design` | Diseño de interfaces |
| `web-design-guidelines` | Guías de diseño web |
| `writing-guidelines` | Guías de escritura |

---

## 3. MCP Servers (Model Context Protocol)

Los MCPs permiten a los agentes conectarse a servicios externos.

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
        "Authorization": "ctx7sk-TU_API_KEY"
      },
      "enabled": true
    }
  }
}
```

> **Diferencia:** Freebuff usa MCPs vía `npx` (local), OpenCode soporta MCPs remotos directamente.

### MCPs disponibles

| MCP | Descripción | Variable de entorno |
|---|---|---|
| `context7` | Documentación contextual de librerías | `CONTEXT7_API_KEY` |

---

## 4. Sincronización entre PCs

### Opción recomendada: Incluir `.agents/` en git

Los skills y MCPs son archivos ligeros (markdown y JSON). Es seguro subirlos al repo:

```bash
# Verificar que .agents/ no esté en .gitignore
cat .gitignore | grep -v ".agents"

# Agregar y commitear
git add .agents/
git commit -m "feat: agregar skills y MCPs"
git push
```

En la otra PC, solo necesitas:

```bash
git clone <repo>
# Skills y MCPs ya vienen incluidos
```

### Si `.agents/` está en .gitignore

Eliminar la línea de `.gitignore`:

```bash
# Editar .gitignore y eliminar la línea que excluye .agents/
nano .gitignore
```

---

## 5. Configuración global

### Freebuff — `~/.config/manicode/`

| Archivo | Contenido |
|---|---|
| `settings.json` | Modelo, modo, preferencias |
| `credentials.json` | Autenticación |
| `freebuff-metadata.json` | Metadata de la instalación |
| `projects/` | Historial de chats por proyecto |

### OpenCode — `~/.config/opencode/`

| Archivo | Contenido |
|---|---|
| `opencode.jsonc` | Configuración global (MCPs, permisos, modelo) |
| `skills/` | Skills globales (disponibles en todos los proyectos) |

> **Freebuff:** `settings.json` se sincroniza automáticamente con tu cuenta.
> **OpenCode:** `opencode.jsonc` se sincroniza vía git (agregar a dotfiles).

---

## 6. Referencia

### Freebuff
- Sitio: https://freebuff.com
- Docs: https://www.codebuff.com/docs
- Skills CLI: `npx skills --help`

### OpenCode
- Sitio: https://opencode.ai
- Docs: https://opencode.ai/docs
- Skills: https://opencode.ai/docs/skills/
- Agents: https://opencode.ai/docs/agents/
- Config: `~/.config/opencode/opencode.jsonc`
