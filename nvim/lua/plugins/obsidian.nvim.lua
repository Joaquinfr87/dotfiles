return {
  "obsidian-nvim/obsidian.nvim",
  version = "*", -- use latest release, remove to use latest commit
  cmd = { "Obsidian" },
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
    -- Follow the link under the cursor
    { "<leader>oo", "<cmd>Obsidian follow_link<CR>", desc = "Obsidian: Follow link" },

    -- Create a new note
    { "<leader>on", "<cmd>Obsidian new<CR>", desc = "Obsidian: New note" },

    -- Search notes (fuzzy find)
    { "<leader>os", "<cmd>Obsidian quick_switch<CR>", desc = "Obsidian: Quick switch" },

    -- Search note content
    { "<leader>og", "<cmd>Obsidian search<CR>", desc = "Obsidian: Search" },

    -- Today's daily note
    { "<leader>od", "<cmd>Obsidian today<CR>", desc = "Obsidian: Today" },

    -- Template
    { "<leader>ot", "<cmd>Obsidian template<CR>", desc = "Obsidian: Template" },

    -- Backlinks
    { "<leader>ob", "<cmd>Obsidian backlinks<CR>", desc = "Obsidian: Backlinks" },

    -- Toggle checkbox
    { "<leader>ch", "<cmd>Obsidian toggle_checkbox<CR>", desc = "Obsidian: Toggle checkbox" },

    -- Rename note
    { "<leader>or", "<cmd>Obsidian rename<CR>", desc = "Obsidian: Rename note" },

    -- Tags
    { "<leader>oT", "<cmd>Obsidian tags<CR>", desc = "Obsidian: Tags" },

    -- Weekly notes
    { "<leader>ow", function() require("utils.weekly_notes").open_weekly_note() end, desc = "Obsidian: Weekly note" },
    { "<leader>oW", function() require("utils.weekly_notes").open_previous_week() end, desc = "Obsidian: Previous week" },
  },
}
