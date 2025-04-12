local lspUtils = require("utils.lsp")

return {
	"williamboman/mason.nvim",
	dependencies = {
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		"williamboman/mason-lspconfig.nvim",
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
		local lsp_zero = require("lsp-zero")
		mason_lspconfig.setup({
			ensure_installed = lspUtils.lspconfig_ensure_installed,
			automatic_installation = true,
			handlers = {
				lsp_zero.default_setup,
				lua_ls = function()
					-- (Optional) Configure lua language server for neovim
					local lua_opts = lsp_zero.nvim_lua_ls()
					require("lspconfig").lua_ls.setup(lua_opts)
					require("lspconfig").yamlls.setup(lspUtils.yamlls_setup)
					require("lspconfig").pylsp.setup(lspUtils.pylsp_setup)
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
