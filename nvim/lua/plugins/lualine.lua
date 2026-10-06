return {
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      opts.sections.lualine_z = {} -- quita el reloj
      -- o si quers dejar solo lneas/columna, por ejemplo:
      -- opts.sections.lualine_z = { "location" },
    end,
  },
}
