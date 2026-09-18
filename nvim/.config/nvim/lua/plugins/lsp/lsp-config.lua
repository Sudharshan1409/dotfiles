-- This file contains the core LSP configuration using lsp-zero and 
-- nvim-lspconfig. It provides an easy way to set up language servers with 
-- sensible defaults and customized keybindings for definition jumps, 
-- code actions, and diagnostic navigation.
-- luacheck: globals vim
local basicUtils = require("utils.basic")

return {
	-- LSP
	{
		"neovim/nvim-lspconfig",
		cmd = { "LspInfo", "LspInstall", "LspStart" },
		event = { "BufReadPre", "BufNewFile" },
		opts = {
			servers = {
				lua_ls = {},
			},
		},
		config = function(_, _)
			local basicUtils = require("utils.basic")

			-- Native diagnostic signs and display configuration
			vim.diagnostic.config({
				signs = {
					text = {
						[vim.diagnostic.severity.ERROR] = "✘",
						[vim.diagnostic.severity.WARN] = "▲",
						[vim.diagnostic.severity.HINT] = "⚑",
						[vim.diagnostic.severity.INFO] = "»",
					},
				},
				virtual_text = {
					source = "always",
				},
			})

			-- Native LspAttach autocmd for setting buffer-local keymaps
			vim.api.nvim_create_autocmd("LspAttach", {
				desc = "LSP keybindings",
				callback = function(event)
					local bufnr = event.buf
					local options = { buffer = bufnr, remap = false }
					local keymap = vim.keymap.set

					keymap("n", "gd", vim.lsp.buf.definition, basicUtils.addDesc(options, "LSP: Go to definition"))
					keymap("n", "gD", vim.lsp.buf.declaration, basicUtils.addDesc(options, "LSP: Go to declaration"))
					keymap("n", "gi", vim.lsp.buf.implementation, basicUtils.addDesc(options, "LSP: Go to implementation"))
					keymap("n", "go", vim.lsp.buf.type_definition, basicUtils.addDesc(options, "LSP: Go to type definition"))
					keymap("n", "K", vim.lsp.buf.hover, basicUtils.addDesc(options, "LSP: Show hover"))
					keymap("n", "<leader>skw", vim.lsp.buf.workspace_symbol, basicUtils.addDesc(options, "LSP: Search workspace symbols"))
					keymap("n", "gl", vim.diagnostic.open_float, basicUtils.addDesc(options, "LSP: Open error in float"))
					keymap("n", "[d", vim.diagnostic.goto_prev, basicUtils.addDesc(options, "LSP: Go to previous error"))
					keymap("n", "]d", vim.diagnostic.goto_next, basicUtils.addDesc(options, "LSP: Go to next error"))
					keymap("n", "<leader>ca", vim.lsp.buf.code_action, basicUtils.addDesc(options, "LSP: Code action"))
					keymap("n", "<leader>gr", vim.lsp.buf.references, basicUtils.addDesc(options, "LSP: Find references"))
					keymap("n", "<leader>rn", vim.lsp.buf.rename, basicUtils.addDesc(options, "LSP: Rename symbol"))
					keymap("i", "<C-h>", vim.lsp.buf.signature_help, basicUtils.addDesc(options, "LSP: Signature help"))
				end,
			})
		end,
	},
}
