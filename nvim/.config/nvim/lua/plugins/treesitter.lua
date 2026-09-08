-- nvim-treesitter provides an interface to use tree-sitter library in 
-- Neovim. It is essential for advanced syntax highlighting, indentation, 
-- and code navigation. Features include fast parsing, support for 
-- numerous languages, and a powerful text objects extension.
local function setup_treesitter()
	local parsers = {
		"javascript",
		"typescript",
		"c",
		"lua",
		"vim",
		"vimdoc",
		"query",
		"python",
		"yaml",
		"go",
		"json",
		"html",
		"css",
		"bash",
		"dockerfile",
		"rust",
		"toml",
		"regex",
		"tsx",
		"htmldjango",
		"c_sharp",
		"markdown",
		"markdown_inline",
	}

	require("nvim-treesitter.configs").setup({
		ensure_installed = parsers,
		sync_install = false,
		auto_install = true,
		highlight = {
			enable = true,
			additional_vim_regex_highlighting = true,
		},
		indent = {
			enable = true,
		},
		textobjects = {
			select = {
				enable = true,
				lookahead = true, -- Automatically jump forward to textobj, similar to targets.vim
				keymaps = {
					-- You can use the capture groups defined in textobjects.scm
					["aa"] = "@parameter.outer",
					["ia"] = "@parameter.inner",
					["af"] = "@function.outer",
					["if"] = "@function.inner",
					["ac"] = "@class.outer",
					["ic"] = "@class.inner",
				},
			},
			move = {
				enable = true,
				set_jumps = true, -- whether to set jumps in the jumplist
				goto_next_start = {
					["]m"] = "@function.outer",
					["]]"] = "@class.outer",
				},
				goto_next_end = {
					["]M"] = "@function.outer",
					["]["] = "@class.outer",
				},
				goto_previous_start = {
					["[m"] = "@function.outer",
					["[["] = "@class.outer",
				},
				goto_previous_end = {
					["[M"] = "@function.outer",
					["[]"] = "@class.outer",
				},
			},
		},
	})

	require("nvim-treesitter.install").compilers = { "gcc", "clang", "clan" }

	-- Compatibility shim for Neovim 0.10+ / 0.11 / 0.12 where query directives
	-- receive captures as a table of nodes (TSNode[]) rather than a single TSNode.
	local query = require("vim.treesitter.query")
	local function unwrap_node(node)
		if type(node) == "table" and not node.range then
			return node[#node] or node[1]
		end
		return node
	end

	query.add_directive("downcase!", function(match, _, bufnr, pred, metadata)
		local id = pred[2]
		local node = unwrap_node(match[id])
		if not node then
			return
		end

		local text = vim.treesitter.get_node_text(node, bufnr, { metadata = metadata[id] }) or ""
		if not metadata[id] then
			metadata[id] = {}
		end
		metadata[id].text = string.lower(text)
	end, { force = true })

	query.add_directive("set-lang-from-info-string!", function(match, _, bufnr, pred, metadata)
		local capture_id = pred[2]
		local node = unwrap_node(match[capture_id])
		if not node then
			return
		end
		local injection_alias = vim.treesitter.get_node_text(node, bufnr):lower()
		local aliases = {
			ex = "elixir",
			pl = "perl",
			sh = "bash",
			uxn = "uxntal",
			ts = "typescript",
		}
		local match_ft = vim.filetype.match({ filename = "a." .. injection_alias })
		metadata["injection.language"] = match_ft or aliases[injection_alias] or injection_alias
	end, { force = true })

	query.add_directive("set-lang-from-mimetype!", function(match, _, bufnr, pred, metadata)
		local capture_id = pred[2]
		local node = unwrap_node(match[capture_id])
		if not node then
			return
		end
		local type_attr_value = vim.treesitter.get_node_text(node, bufnr)
		local html_script_type_languages = {
			["importmap"] = "json",
			["module"] = "javascript",
			["application/ecmascript"] = "javascript",
			["text/ecmascript"] = "javascript",
		}
		local configured = html_script_type_languages[type_attr_value]
		if configured then
			metadata["injection.language"] = configured
		else
			local parts = vim.split(type_attr_value, "/", {})
			metadata["injection.language"] = parts[#parts]
		end
	end, { force = true })
end

return {
	{
		"nvim-treesitter/nvim-treesitter",
		branch = "master",
		build = ":TSUpdate",
		config = setup_treesitter,
	},
	{ "nvim-treesitter/playground" },
	{
		"nvim-treesitter/nvim-treesitter-textobjects",
		branch = "master",
	},
}
