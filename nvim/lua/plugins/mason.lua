-- ~/.config/nvim/lua/plugins/mason.lua
return {
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "eslint-lsp",
        "pyright",
        "rust-analyzer",
        "gopls",
        "json-lsp",
        "yamlls",
        "taplo",
        "typescript-language-server",
        "clangd", -- ← ADD THIS
      },
    },
  },
}
