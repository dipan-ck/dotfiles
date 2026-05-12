return {
  { "Shatur/neovim-ayu" },

  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "ayu-dark",
    },
  },
}

--
-- return {
--   {
--     "folke/tokyonight.nvim",
--     opts = {
--       style = "night", -- ← THIS is the variant you want
--     },
--   },
-- }

-- return {
--   "tiagovla/tokyodark.nvim",
--   opts = {
--     styles = {
--       comments = { italic = false },
--       keywords = { italic = false },
--       identifiers = { italic = false },
--       functions = {},
--       variables = {},
--     },
--   },
--   config = function(_, opts)
--     require("tokyodark").setup(opts)
--     vim.cmd([[colorscheme tokyodark]])
--   end,
-- }
