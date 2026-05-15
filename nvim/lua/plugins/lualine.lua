return {
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      -- Vaciamos la sección Z para eliminar el reloj
      opts.sections.lualine_z = {}
    end,
  },
}
