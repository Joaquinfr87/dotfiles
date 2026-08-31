# Guía de Freebuff — Skills y MCPs

Configuración del agente AI Freebuff para proyectos.

> **Repo de referencia:** [CodebuffAI/freebuff](https://github.com/CodebuffAI/freebuff)

---

## 1. Estructura

Cada proyecto tiene su propia configuración de Freebuff en `.agents/`:

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

---

## 2. Skills

Los skills son instrucciones reutilizables que Freebuff carga para tareas específicas.

### Instalar un skill (comunidad)

```bash
# Buscar skills disponibles
npx skills find <query>

# Previsualizar skills de un repo
npx skills add <owner/repo> --list

# Instalar un skill específico
npx skills add <owner/repo> --skill <nombre> --yes
```

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

### Listar skills instalados

```bash
npx skills add <owner/repo> --list
```

---

## 3. MCP Servers (Model Context Protocol)

Los MCPs permiten a Freebuff conectarse a servicios externos.

### Configuración

El archivo `.agents/mcp.json` define los servidores MCP:

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

### MCPs disponibles

| MCP | Descripción | Variable de entorno |
|---|---|---|
| `context7` | Documentación contextual de librerías | `CONTEXT7_API_KEY` |

### Agregar un nuevo MCP

Editar `.agents/mcp.json` y agregar:

```json
{
  "mcpServers": {
    "context7": { ... },
    "nuevo-mcp": {
      "command": "npx",
      "args": ["-y", "paquete-del-mcp"],
      "env": {
        "API_KEY": "$NUEVA_API_KEY"
      }
    }
  }
}
```

---

## 4. Sincronización entre PCs

### Opción recomendada: Incluir `.agents/` en git

Los skills y MCPs son archivos ligeros (markdown y JSON). Es seguro subirlos al repo:

```bash
# Verificar que .agents/ no esté en .gitignore
cat .gitignore | grep -v ".agents"

# Agregar y commitear
git add .agents/
git commit -m "feat: agregar skills y MCPs de Freebuff"
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

## 5. Configuración global de Freebuff

Freebuff guarda configuración global en `~/.config/manicode/`:

| Archivo | Contenido |
|---|---|
| `settings.json` | Modelo, modo, preferencias |
| `credentials.json` | Autenticación |
| `freebuff-metadata.json` | Metadata de la instalación |
| `projects/` | Historial de chats por proyecto |

> **Nota:** `~/.config/manicode/settings.json` se sincroniza automáticamente con tu cuenta. No es necesario copiarlo manualmente.

---

## 6. Referencia

- Freebuff: https://freebuff.com
- Codebuff Docs: https://www.codebuff.com/docs
- Skills CLI: `npx skills --help`
