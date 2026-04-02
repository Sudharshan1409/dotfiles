-- nvim-config-local allows you to use project-specific Neovim 
-- configurations. It enhances management by allowing you to tailor 
-- settings for different projects. Features include support for lua and 
-- vimrc files, security hashing, and automatic loading on directory change.
-- luacheck: globals vim
return {
	"klen/nvim-config-local",
	config = function()
		require("config-local").setup({
			-- Default options (optional)

			-- Config file patterns to load (lua supported)
			config_files = { ".nvim.lua", ".nvimrc", ".exrc" },

			-- Where the plugin keeps files data
			hashfile = vim.fn.stdpath("data") .. "/config-local",

			autocommands_create = true, -- Create autocommands (VimEnter, DirectoryChanged)
			commands_create = true, -- Create commands (ConfigLocalSource, ConfigLocalEdit, ConfigLocalTrust, ConfigLocalDeny)
			silent = false, -- Disable plugin messages (Config loaded/denied)
			lookup_parents = false, -- Lookup config files in parent directories
		})
	end,
}
