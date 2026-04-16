return {
  -- Configurar Tokyonight para que sea transparente
  {
    "folke/tokyonight.nvim",
    lazy = true,
    opts = {
      transparent = true, -- Hace el fondo principal transparente
      styles = {
        sidebars = "transparent", -- Hace transparentes paneles como NeoTree o Outline
        floats = "transparent",   -- Hace transparentes las ventanas flotantes (ej. autocompletado)
      },
    },
  },

  -- Asegurarnos de que LazyVim cargue este tema
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "tokyonight",
    },
  },
}
