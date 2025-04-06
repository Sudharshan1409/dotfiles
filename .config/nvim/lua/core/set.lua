-- luacheck: globals vim
local opt = vim.opt
-- Global settings
vim.g.mapleader = " "
vim.opt.laststatus = 3

-- Number settings
opt.nu = true
opt.relativenumber = true

-- Tab and indentation settings
opt.tabstop = 4
opt.softtabstop = 4
opt.shiftwidth = 4
opt.expandtab = true
opt.smartindent = true
opt.autoindent = true

-- Search settings
opt.ignorecase = true
opt.hlsearch = false
opt.incsearch = true
opt.inccommand = "nosplit"
opt.smartcase = true

-- Display settings
opt.wrap = true
opt.linebreak = true
opt.splitbelow = true
opt.splitright = true
opt.termguicolors = true
opt.scrolloff = 8
opt.signcolumn = "yes"
opt.cursorline = true
opt.foldmethod = "indent"
opt.foldlevel = 99
opt.foldenable = false
opt.foldcolumn = "1"
opt.mouse = "a"
opt.encoding = "utf-8"
opt.spelllang = { "en" }
vim.g.markdown_recommended_style = 0

-- File and backup settings
opt.swapfile = false
opt.backup = false
opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
opt.undofile = true

-- Cursor and highlight settings
vim.api.nvim_command('let &t_SI = "\\e[6 q"')
vim.api.nvim_create_augroup("custom_buffer", { clear = true })
vim.api.nvim_create_autocmd("TextYankPost", {
	group = "custom_buffer",
	pattern = "*",
	callback = function()
		vim.highlight.on_yank({ timeout = 200 })
	end,
})

-- Command-line completion
opt.wildmenu = true

-- Performance settings
opt.lazyredraw = false

-- Visual enhancements
opt.cursorcolumn = false

-- Miscellaneous settings
opt.updatetime = 50
opt.timeoutlen = 500
opt.ttimeoutlen = 10
opt.showmode = true
opt.isfname:append("@-@")
opt.formatoptions:remove("r")
vim.g["netrw_localrmdir"] = "rm -r"
vim.cmd([[autocmd FileType * set formatoptions-=ro]])
vim.api.nvim_create_augroup("Mkdir", { clear = true })
vim.api.nvim_create_autocmd("BufWritePre", {
	group = "Mkdir",
	pattern = "*",
	callback = function()
		vim.fn.mkdir(vim.fn.expand("<afile>:p:h"), "p")
	end,
})
