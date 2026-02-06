return {
	"nvim-treesitter/nvim-treesitter-context",
	event = "BufReadPre",
	enabled = true,
	opts = { mode = "cursor", max_lines = 3 },
}
