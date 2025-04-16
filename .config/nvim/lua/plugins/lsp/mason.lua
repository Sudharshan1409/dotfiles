local lspUtils = require("utils.lsp")

return {
	"williamboman/mason.nvim",
	dependencies = {
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		"williamboman/mason-lspconfig.nvim",
		"hrsh7th/cmp-nvim-lsp",
		"VonHeikemen/lsp-zero.nvim",
	},
	lazy = false,
	config = function()
		local mason = require("mason")
		mason.setup({
			ui = {
				icons = {
					package_installed = "✓",
					package_pending = "➜",
					package_uninstalled = "✗",
				},
			},
		})

		-- mason lspconfig setup

		local mason_lspconfig = require("mason-lspconfig")
		local lspconfig = require("lspconfig")
		local lsp_zero = require("lsp-zero")
		local capabilities = require("cmp_nvim_lsp").default_capabilities()
		mason_lspconfig.setup({
			ensure_installed = lspUtils.lspconfig_ensure_installed,
			automatic_installation = true,
			handlers = {
				lsp_zero.default_setup,
				lua_ls = function()
					-- (Optional) Configure lua language server for neovim
					lspconfig.lua_ls.setup(lspUtils.lua_opts)
					lspconfig.yamlls.setup(lspUtils.yamlls_setup)
					lspconfig.pylsp.setup(lspUtils.pylsp_setup)
					lspconfig.ts_ls.setup({ capabilities = capabilities, on_attach = require("lsp-zero").on_attach })
				end,
			},
		})

		-- mason tool installer setup

		local mason_tool_installer = require("mason-tool-installer")

		mason_tool_installer.setup({
			ensure_installed = lspUtils.mason_tools_ensure_installed,
		})
	end,
}
