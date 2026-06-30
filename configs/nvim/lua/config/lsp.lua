-- Neovim LSP Configuration

local mason = require("mason")
local mason_lspconfig = require("mason-lspconfig")
local lspconfig = require("lspconfig")

mason.setup()
mason_lspconfig.setup({
  ensure_installed = {
    "lua_ls",
    "tsserver",
    "rust_analyzer",
    "eslint",
    "jsonls",
    "yamlls",
    "bashls",
    "cssls",
    "html",
    "tailwindcss",
  },
  automatic_installation = true,
})

-- nvim-cmp setup
local cmp = require("cmp")
local cmp_lsp = require("cmp_nvim_lsp")

local capabilities = vim.tbl_deep_extend(
  "force",
  vim.lsp.protocol.make_client_capabilities(),
  cmp_lsp.default_capabilities()
)

cmp.setup({
  snippet = {
    expand = function(args)
      require("luasnip").lsp_expand(args.body)
    end,
  },
  mapping = cmp.mapping.preset.insert({
    ["<C-b>"] = cmp.mapping.scroll_docs(-4),
    ["<C-f>"] = cmp.mapping.scroll_docs(4),
    ["<C-Space>"] = cmp.mapping.complete(),
    ["<C-e>"] = cmp.mapping.abort(),
    ["<CR>"] = cmp.mapping.confirm({ select = true }),
  }),
  sources = cmp.config.sources({
    { name = "nvim_lsp" },
    { name = "luasnip" },
  }, {
    { name = "buffer" },
    { name = "path" },
  }),
})

-- LSP servers
mason_lspconfig.setup_handlers({
  function(server_name)
    lspconfig[server_name].setup({
      capabilities = capabilities,
    })
  end,

  ["lua_ls"] = function()
    lspconfig.lua_ls.setup({
      capabilities = capabilities,
      settings = {
        Lua = {
          diagnostics = { globals = { "vim" } },
        },
      },
    })
  end,

  ["tsserver"] = function()
    lspconfig.tsserver.setup({
      capabilities = capabilities,
      init_options = {
        preferences = {
          importModuleSpecifierPreference = "relative",
        },
      },
    })
  end,

  ["rust_analyzer"] = function()
    lspconfig.rust_analyzer.setup({
      capabilities = capabilities,
      settings = {
        ["rust-analyzer"] = {
          check = { command = "clippy" },
          cargo = { allFeatures = true },
        },
      },
    })
  end,
})

-- fidget (LSP progress)
require("fidget").setup()
