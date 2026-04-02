-- tabnine-nvim provides AI-powered code completion by integrating Tabnine into 
-- Neovim. It enhances coding assistance with smart, context-aware 
-- suggestions. Features include support for various languages, 
-- customizable suggestion colors, and debounced completion.
return {
	enabled = false,
	"codota/tabnine-nvim",
	build = "./dl_binaries.sh",
	config = function()
		require("tabnine").setup({
			disable_auto_comment = true,
			accept_keymap = "<tab>",
			dismiss_keymap = "<C-i>",
			debounce_ms = 800,
			suggestion_color = { gui = "#808080", cterm = 244 },
			exclude_filetypes = { "TelescopePrompt", "NvimTree" },
			log_file_path = nil, -- absolute path to Tabnine log file
			ignore_certificate_errors = false,
		})
	end,
}
