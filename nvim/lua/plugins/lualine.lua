return {
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      opts.sections.lualine_z = {} -- remove the clock
      -- or, if you want to keep only line/column, for example:
      -- opts.sections.lualine_z = { "location" },
    end,
  },
}
