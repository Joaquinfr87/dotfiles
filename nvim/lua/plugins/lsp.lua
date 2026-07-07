return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      diagnostics = {
        virtual_text = false,
        float = {
          border = "rounded",
          source = "if_many",
        },
      },
    },
  },
}
