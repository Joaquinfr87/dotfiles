return {
  "obsidian-nvim/obsidian.nvim",
  version = "*", -- use latest release, remove to use latest commit
  ---@module 'obsidian'
  ---@type obsidian.config
  opts = {
    legacy_commands = false, -- this will be removed in 4.0.0
    workspaces = {
      {
        name = "study",
        path = "~/repos/notas/",
      },
      -- {
      --   name = "work",
      --   path = "~/vaults/work",
      -- },
    },
    link = {
      style = "markdown",
      format = "shortest",
    },
    daily_notes = {
      enabled = true,
      folder = "daily",
      date_format = "YYYY-MM-DD",
      default_tags = { "daily", "journal" },
    },
    templates = {
      enabled = true,
      folder = "templates",
      date_format = "%Y-%m-%d",
      time_format = "%H:%M",
      substitutions = {},
    },
    ui = {
      enable = true,
      ignore_conceal_warn = true,
    },
  },
  keys = {
    -- Seguir link bajo el cursor
    { "<leader>oo", "<cmd>Obsidian follow_link<CR>", desc = "Obsidian: Follow link" },

    -- Crear nota nueva
    { "<leader>on", "<cmd>Obsidian new<CR>", desc = "Obsidian: New note" },

    -- Buscar notas (fuzzy find)
    { "<leader>os", "<cmd>Obsidian quick_switch<CR>", desc = "Obsidian: Quick switch" },

    -- Buscar contenido en notas
    { "<leader>og", "<cmd>Obsidian search<CR>", desc = "Obsidian: Search" },

    -- Daily note de hoy
    { "<leader>od", "<cmd>Obsidian today<CR>", desc = "Obsidian: Today" },

    -- Template
    { "<leader>ot", "<cmd>Obsidian template<CR>", desc = "Obsidian: Template" },

    -- Backlinks
    { "<leader>ob", "<cmd>Obsidian backlinks<CR>", desc = "Obsidian: Backlinks" },

    -- Toggle checkbox
    { "<leader>ch", "<cmd>Obsidian toggle_checkbox<CR>", desc = "Obsidian: Toggle checkbox" },

    -- Renombrar nota
    { "<leader>or", "<cmd>Obsidian rename<CR>", desc = "Obsidian: Rename note" },

    -- Tags
    { "<leader>oT", "<cmd>Obsidian tags<CR>", desc = "Obsidian: Tags" },
  },
}
