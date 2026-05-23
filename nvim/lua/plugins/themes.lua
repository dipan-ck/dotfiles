-- return {
--   { "Shatur/neovim-ayu" },
--
--   {
--     "LazyVim/LazyVim",
--     opts = {
--       colorscheme = "ayu-dark",
--     },
--   },
-- }

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
--
return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,

    opts = {
      flavour = "mocha",

      background = {
        light = "latte",
        dark = "mocha",
      },

      transparent_background = false,

      float = {
        transparent = false,
        solid = false,
      },

      term_colors = false,

      dim_inactive = {
        enabled = false,
        shade = "dark",
        percentage = 0.15,
      },

      no_italic = false,
      no_bold = false,
      no_underline = false,

      styles = {
        comments = { "italic" },
        conditionals = { "italic" },
        loops = {},
        functions = { "italic" },
        keywords = { "italic" },
        strings = {},
        variables = {},
        numbers = {},
        booleans = {},
        properties = {},
        types = {},
        operators = {},
      },

      lsp_styles = {
        virtual_text = {
          errors = { "italic" },
          hints = { "italic" },
          warnings = { "italic" },
          information = { "italic" },
          ok = { "italic" },
        },

        underlines = {
          errors = { "underline" },
          hints = { "underline" },
          warnings = { "underline" },
          information = { "underline" },
          ok = { "underline" },
        },

        inlay_hints = {
          background = true,
        },
      },

      color_overrides = {},
      custom_highlights = {},

      default_integrations = true,
      auto_integrations = false,

      integrations = {
        cmp = true,
        gitsigns = true,
        nvimtree = true,
        notify = false,

        mini = {
          enabled = true,
          indentscope_color = "",
        },
      },
    },
  },

  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin",
    },
  },
}
