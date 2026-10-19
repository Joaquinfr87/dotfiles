return {
  "folke/persistence.nvim",
  event = "BufReadPre", -- this will only start session saving when an actual file was opened
  opts = {
    -- add custom options here
    dir = vim.fn.expand(vim.fn.stdpath("state") .. "/sessions/"), -- directory where session files are saved
    options = { "buffers", "curdir", "tabpages", "winsize", "help", "globals", "skiprtp", "folds" },
  },
  keys = {
    {
      "<leader>qs",
      function() require("persistence").load() end,
      desc = "Restore Session",
    },
    {
      "<leader>ql",
      function() require("persistence").load({ last = true }) end,
      desc = "Restore Last Session",
    },
    {
      "<leader>qd",
      function() require("persistence").stop() end,
      desc = "Don't Save Current Session",
    },
  },
}
