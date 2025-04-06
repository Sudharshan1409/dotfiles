-- luacheck: globals vim
-- Keymap setup
local keymap = vim.keymap.set

local basicUtils = require("utils.basic")

local opts = { noremap = true, silent = true }

-- Visual Mode Keymaps
keymap("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move line up/down in visual mode" })
keymap("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move line up/down in visual mode" })

-- Navigation Keymaps
keymap("n", "<C-j>", "TmuxNavigateDown", { desc = "Navigate Window Down" })
keymap("n", "<C-k>", "TmuxNavigateUp", { desc = "Navigate Window Up" })
keymap("n", "<C-l>", "TmuxNavigateRight", { desc = "Navigate Window Right" })
keymap("n", "<C-h>", "TmuxNavigateLeft", { desc = "Navigate Window Left" })

-- Cursor and Scrolling Keymaps
keymap("n", "J", "mzJ`z", { desc = "Keep cursor in the beginning when joining lines" })
keymap("n", "G", "Gzz", { desc = "Keep line in the middle when going to last line" })
keymap("i", "<C-j>", "<Down><Down><Down><Down><Down>", { desc = "Move cursor 5 lines down" })
keymap("i", "<C-k>", "<Up><Up><Up><Up><Up>", { desc = "Move cursor 5 lines up" })
keymap("n", "n", "nzzzv", { desc = "Keep line in the middle when searching next" })
keymap("n", "N", "Nzzzv", { desc = "Keep line in the middle when searching previous" })

-- keymap to create buffer and open file
keymap("n", "<leader>fo", "<cmd>e hello.txt<CR>", { silent = true, desc = "Open buffer for reference" })

-- Clipboard and Register Keymaps
keymap(
	"x",
	"<leader>p",
	[["_dPgv=gv]],
	{ silent = true, desc = "While pasting in visual mode retain copied content at top of register" }
)
keymap("n", "<leader>p", [["+p]], { desc = "Paste from system clipboard down" })
keymap("n", "<leader>P", [["+P]], { desc = "Paste from system clipboard up" })

-- Clipboard Copy Keymaps
keymap({ "n", "v" }, "<leader>y", [["+y]], { desc = "Copy to system clipboard" })
keymap("n", "<leader>Y", [["+Y]], { desc = "Copy to system clipboard" })

keymap({ "n", "v" }, "<leader>d", [["_d]], { desc = "Delete to blackhole register" })

-- Tmux Integration Keymaps
keymap("n", "<C-f>", "<cmd>silent !tmux neww tmux-sessionizer<CR>", { desc = "Open tmux sessionizer" })

-- Line Insertion Keymaps
keymap("n", "<leader>o", "o<Esc>", { desc = "Insert line below and stay in normal mode" })
keymap("n", "<leader>O", "O<Esc>", { desc = "Insert line above and stay in normal mode" })

-- Quickfix Navigation Keymaps
keymap("n", "<leader>k", "<cmd>cnext<CR>zz", { desc = "Go to next quickfix" })
keymap("n", "<leader>j", "<cmd>cprev<CR>zz", { desc = "Go to previous quickfix" })

-- Search and Replace Keymaps
keymap("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], { desc = "Search and replace" })
keymap("n", "<leader>sl", ":lua SEARCH_AND_REPLACE_DYNAMIC()<CR>", { desc = "Search and replace for N lines" })
keymap("n", "<leader>sn", "/<C-r><C-w><cr>", { desc = "Move to next occurrence of the word" })
keymap("n", "<leader>sp", "?<C-r><C-w><cr>", { desc = "Move to previous occurrence of the word" })

-- File Management Keymaps
keymap("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true, desc = "Make file executable" }) -- make file executabe

keymap(
	{ "n", "x" },
	"<leader>r",
	"<cmd>lua vim.lsp.buf.format{async=true}<cr>",
	{ desc = "Reformat Code", silent = true }
)

-- Nvim Configuration Keymaps
keymap(
	"n",
	"<leader>nvim",
	"<cmd>lua require('telescope.builtin').find_files({prompt_title = 'Nvim  Config', cwd = '~/.config/nvim/', hidden = fale})<CR>",
	{ desc = "Open Nvim Config" }
)

-- URL Manipulation Keymaps
keymap("n", "ci/", "T/vt/c", { desc = "Change inside URL Slash" })
keymap("n", "vi/", "T/vt/", { desc = "Select inside URL Slash" })
keymap("n", "di/", "T/vt/d", { desc = "Delete inside URL Slash" })
keymap("n", "yi/", "T/vt/y", { desc = "Copy inside URL Slash" })

keymap("n", "ca/", "T/vf/c", { desc = "Change inside URL Slach with Slach" })
keymap("n", "va/", "T/vf/", { desc = "Select inside URL Slash with Slach" })
keymap("n", "da/", "T/vf/d", { desc = "Delete inside URL Slash with Slach" })
keymap("n", "ya/", "T/vf/y", { desc = "Copy inside URL Slash with Slach" })

-- Camel Case Manipulation Keymaps
keymap("n", "ci_", "T_vt_c", { desc = "Change inside Underscore" })
keymap("n", "vi_", "T_vt_", { desc = "Select inside Underscore" })
keymap("n", "di_", "T_vt_d", { desc = "Delete inside Underscore" })
keymap("n", "yi_", "T_vt_y", { desc = "Copy inside Underscore" })

-- Exit Insert Mode Keymaps
keymap("i", "jk", "<esc>", basicUtils.addDesc(opts, "Exit Insert Mode"))
keymap("i", "kj", "<esc>", basicUtils.addDesc(opts, "Exit Insert Mode"))
keymap("i", "JK", "<esc>", basicUtils.addDesc(opts, "Exit Insert Mode"))
keymap("i", "KJ", "<esc>", basicUtils.addDesc(opts, "Exit Insert Mode"))

-- Visual Mode Indentation Keymaps
keymap("v", ">", ">gv", basicUtils.addDesc(opts, "Left Indent but stay in visual mode")) -- Left Indentation

-- Barbar Buffer Management Keymaps
-- Move to previous/next
keymap("n", "<s-tab>", "<Cmd>BufferPrevious<CR>", basicUtils.addDesc(opts, "Go to Previous Buffer"))
keymap("n", "<tab>", "<Cmd>BufferNext<CR>", basicUtils.addDesc(opts, "Go to Next Buffer"))

-- Pin the buffer
keymap("n", "<leader>pb", "<Cmd>BufferPin<CR>", basicUtils.addDesc(opts, "Pin Buffer"))

-- Close all buffer except pinned
keymap(
	"n",
	"<leader>bcp",
	"<Cmd>BufferCloseAllButPinned<CR>",
	basicUtils.addDesc(opts, "Close all buffer except pinned")
)

-- Re-order to previous/next
keymap("n", "<leader>bp", "<Cmd>BufferPick<CR>", basicUtils.addDesc(opts, "Pick Buffer"))

keymap("n", "zs", "<Cmd>SymbolsOutline<CR>", basicUtils.addDesc(opts, "Open Symbols Outline"))

-- Replace ' by " in entire file
keymap("n", "<leader>std", ":%s/'/\"/g<CR>")

-- Replace " by ' in entire file
keymap("n", "<leader>dts", ":%s/\"/'/g<CR>")

-- Basic Vim Commands
keymap("t", "<C-q>", "<C-\\><C-n>")

keymap("n", "<leader><leader>", function()
	vim.cmd("so")
end)

keymap("n", "<leader>W", function()
	vim.cmd("wa!")
end)

keymap("n", "<leader>w", function()
	vim.cmd("w!")
end)
keymap("n", "<leader>q", "<cmd>:q<CR>", { silent = true, desc = "Quit NeoVim Session" }) -- Quit Neovim after saving thefile

keymap("n", "<leader>Q", function()
	vim.cmd("qa")
end)

-- Window Management Keymaps
keymap("n", "<leader>hs", "<cmd>split<CR>", { desc = "Split window horizontally" })
keymap("n", "<leader>vs", "<cmd>vsplit<CR>", { desc = "Split window vertically" })

-- lazy
keymap("n", "<leader>ll", "<cmd>Lazy<cr>", { desc = "Open Lazy" })
