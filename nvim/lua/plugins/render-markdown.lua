return {
  "MeanderingProgrammer/render-markdown.nvim",
  dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
  opts = {
    render_modes = { "n", "c" }, -- only render in normal mode, not while typing
  },
  keys = {
    { "<leader>um", "<cmd>RenderMarkdown toggle<cr>", desc = "Toggle Markdown Render" },
  },
}
