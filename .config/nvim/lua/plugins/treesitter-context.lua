-- nvim-treesitter-context provides a sticky header that shows the current 
-- code context at the top of the window. It enhances the UI by making it 
-- easy to keep track of the scope you are working in. It uses Treesitter 
-- for accurate and fast context identification.
return {
	"nvim-treesitter/nvim-treesitter-context",
	event = "BufReadPre",
	enabled = true,
	opts = { mode = "cursor", max_lines = 3 },
}
