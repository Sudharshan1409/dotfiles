-- Filetype detection and overrides
-- luacheck: globals vim

vim.filetype.add({
	extension = {
		env = "dotenv",
	},
	filename = {
		[".env"] = "dotenv",
		["env"] = "dotenv",
		[".envrc"] = "dotenv",
	},
	pattern = {
		["[%.~]?env$"] = "dotenv",
		["[%.~]?env%.%g+"] = "dotenv",
	},
})

-- Register bash treesitter parser for dotenv files so syntax highlighting works
-- without triggering bashls or shellcheck diagnostics
pcall(vim.treesitter.language.register, "bash", "dotenv")
