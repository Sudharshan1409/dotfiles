-- mason.nvim is a portable package manager for Neovim that simplifies the 
-- installation and management of LSP servers, linters, and formatters. It 
-- ensures that all necessary external tools are easily accessible. Features 
-- include automatic installation and a user-friendly UI.
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

		if vim.lsp.config then
			vim.lsp.config("pyright", {
				before_init = function(_, config)
					local root = config.root_dir or vim.fn.getcwd()
					local venv = vim.env.VIRTUAL_ENV
						or vim.fs.find({ ".venv", "venv" }, { path = root, upward = true, type = "directory" })[1]
					if venv and vim.fn.executable(venv .. "/bin/python") == 1 then
						config.settings = config.settings or {}
						config.settings.python = config.settings.python or {}
						config.settings.python.pythonPath = venv .. "/bin/python"
					end
				end,
			})
		end

		mason_lspconfig.setup({
			ensure_installed = lspUtils.lspconfig_ensure_installed,
			automatic_installation = true,
			handlers = {
				lsp_zero.default_setup,
				lua_ls = function()
					-- (Optional) Configure lua language server for neovim
					lspconfig.lua_ls.setup(lspUtils.lua_opts)
				end,
				yamlls = function()
					lspconfig.yamlls.setup(lspUtils.yamlls_setup)
				end,
				pylsp = function()
					-- Explicitly disable pylsp to prevent it from attaching
				end,
				pyright = function()
					lspconfig.pyright.setup({
						capabilities = capabilities,
						on_attach = lsp_zero.on_attach,
						before_init = function(_, config)
							local root = config.root_dir or vim.fn.getcwd()
							local venv = vim.env.VIRTUAL_ENV
								or vim.fs.find({ ".venv", "venv" }, { path = root, upward = true, type = "directory" })[1]
							if venv and vim.fn.executable(venv .. "/bin/python") == 1 then
								config.settings.python.pythonPath = venv .. "/bin/python"
							end
						end,
						settings = {
							python = {
								analysis = {
									autoSearchPaths = true,
									useLibraryCodeForTypes = true,
									diagnosticMode = "workspace",
								},
							},
						},
					})
				end,
				ruff = function()
					lspconfig.ruff.setup({
						capabilities = capabilities,
						on_attach = function(client, bufnr)
							client.server_capabilities.hoverProvider = false
							lsp_zero.on_attach(client, bufnr)
						end,
					})
				end,
				ts_ls = function()
					lspconfig.ts_ls.setup({ capabilities = capabilities, on_attach = lsp_zero.on_attach })
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
