-- luacheck: globals vim
local basicUtils = require("utils.basic")

return {
	{
		"VonHeikemen/lsp-zero.nvim",
		branch = "v3.x",
		lazy = true,
		config = false,
		init = function()
			-- Disable automatic setup, we are doing it manually
			vim.g.lsp_zero_extend_cmp = 0
			vim.g.lsp_zero_extend_lspconfig = 0
		end,
	},

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
		dependencies = {
			{ "hrsh7th/cmp-nvim-lsp" },
			{ "saghen/blink.cmp" },
		},
		config = function(_, _)
			-- This is where all the LSP shenanigans will live
			local lsp_zero = require("lsp-zero")
			lsp_zero.extend_lspconfig()
			lsp_zero.set_preferences({
				suggest_lsp_servers = true,
			})

			local sign_icons = {
				error = "✘",
				warn = "▲",
				hint = "⚑",
				info = "»",
			}
			lsp_zero.set_sign_icons(sign_icons)

			lsp_zero.on_attach(function(_, bufnr)
				-- see :help lsp-zero-keybindings
				-- to learn the available actions

				local options = { buffer = bufnr, remap = false }
				local keymap = vim.keymap.set

				keymap("n", "gd", function()
					vim.lsp.buf.definition()
				end, basicUtils.addDesc(options, "LSP: Go to definition"))
				keymap("n", "K", function()
					vim.lsp.buf.hover()
				end, basicUtils.addDesc(options, "LSP: Show hover"))
				keymap("n", "<leader>skw", function()
					vim.lsp.buf.workspace_symbol()
				end, basicUtils.addDesc(options, "LSP: Search workspace symbols"))
				keymap("n", "gl", function()
					vim.diagnostic.open_float()
				end, basicUtils.addDesc(options, "LSP: Open error in float"))
				keymap("n", "[", function()
					vim.diagnostic.goto_prev()
				end, basicUtils.addDesc(options, "LSP: Go to previous error"))
				keymap("n", "]", function()
					vim.diagnostic.goto_next()
				end, basicUtils.addDesc(options, "LSP: Go to next error"))
				keymap("n", "<leader>ca", function()
					vim.lsp.buf.code_action()
				end, basicUtils.addDesc(options, "LSP: Code action"))
				keymap("n", "<leader>gr", function()
					vim.lsp.buf.references()
				end, basicUtils.addDesc(options, "LSP: Find references"))
				keymap("n", "<leader>rn", function()
					vim.lsp.buf.rename()
				end, basicUtils.addDesc(options, "LSP: Rename symbol"))
				keymap("i", "<C-h>", function()
					vim.lsp.buf.signature_help()
				end, basicUtils.addDesc(options, "LSP: Signature help"))
				lsp_zero.default_keymaps({ buffer = bufnr })
			end)

			lsp_zero.setup()
			vim.diagnostic.config({
				virtual_text = true,
			})
		end,
	},
}
