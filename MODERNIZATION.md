# Modernization & Optimization Roadmap

This document tracks modernization, performance improvements, and cleanup tasks for the dotfiles repository.
Tasks can be marked as:
- `[ ] Pending`
- `[x] Done`
- `[-] Ignored`

---

## 1. Neovim Improvements

- [x] **TASK-01: Fix Diagnostic `[` and `]` Keymap Bug in LSP Config**
  - **Category**: Neovim (Bugfix / Performance)
  - **Impact**: High | **Effort**: Low
  - **Problem**: Mapping single `[` and `]` in `lua/plugins/lsp/lsp-config.lua` intercepts and causes a noticeable delay (`timeoutlen`) on all standard Vim bracket motions (`[[`, `]]`, `[m`, `]c`, etc.).
  - **Solution**: Replace with Neovim 0.10+ native `[d` and `]d` for diagnostics or use `vim.keymap.set` without hijacking root motions.
  - **Target Files**: `nvim/.config/nvim/lua/plugins/lsp/lsp-config.lua`

- [x] **TASK-02: Remove Obsolete `vim-closetag` Plugin**
  - **Category**: Neovim (Cleanup)
  - **Impact**: Medium | **Effort**: Low
  - **Problem**: `alvan/vim-closetag` is an old Vimscript plugin from 2017. You already have `nvim-ts-autotag` installed which handles JSX/HTML auto-closing and auto-renaming natively via Treesitter.
  - **Solution**: Remove `alvan/vim-closetag` from `lua/plugins/init.lua`.
  - **Target Files**: `nvim/.config/nvim/lua/plugins/init.lua`

- [x] **TASK-03: Modernize Python LSP (`pyright`/`basedpyright` + `ruff` instead of `pylsp`)**
  - **Category**: Neovim (LSP / Tooling)
  - **Impact**: High | **Effort**: Low
  - **Problem**: `mason.lua` enables `pylsp` and disables `pyright` and `ruff`. `pylsp` is slow, heavy, and outdated compared to the modern standard.
  - **Solution**: Enable `pyright` (or `basedpyright`) for type checking and `ruff` for sub-millisecond linting and code actions.
  - **Target Files**: `nvim/.config/nvim/lua/plugins/lsp/mason.lua`, `nvim/.config/nvim/lua/utils/lsp.lua`

- [x] **TASK-04: Resolve `snacks.nvim` vs Legacy Plugin Overlaps**
  - **Category**: Neovim (Performance / Consolidation)
  - **Impact**: High | **Effort**: Medium
  - **Problem**: Running both `snacks.nvim` and legacy plugins causes duplicate rendering and conflicting keymaps.
  - **Solution**: Keep Telescope and Toggleterm for their essential plugins/extensions, keep `indent-blankline` for rainbow scopes, and retain `vim-illuminate` for buffer-local `]]`/`[[` navigation, while disabling redundant Snacks modules (`indent`, `scope`, `words`).
  - **Target Files**: `nvim/.config/nvim/lua/utils/snacks-utils.lua`

- [x] **TASK-05: Retire `lsp-zero` in Favor of Native Neovim 0.10+ LSP**
  - **Category**: Neovim (Architecture)
  - **Impact**: High | **Effort**: Medium
  - **Problem**: `lsp-zero.nvim` is officially deprecated/sunsetted. Neovim 0.10+ native APIs make server setup clean without an extra wrapper.
  - **Solution**: Configure `mason-lspconfig` and `nvim-lspconfig` directly using native Neovim APIs.
  - **Target Files**: `nvim/.config/nvim/lua/plugins/lsp/lsp-config.lua`, `nvim/.config/nvim/lua/plugins/lsp/mason.lua`, `nvim/.config/nvim/lua/plugins/cmp.lua`

- [x] **TASK-06: Upgrade Completion Engine from `nvim-cmp` to `blink.cmp`**
  - **Category**: Neovim (Performance / Modernization)
  - **Impact**: High | **Effort**: Medium
  - **Problem**: `nvim-cmp` requires 7+ plugin dependencies and is noticeably slower than modern Rust-based fuzzy matching.
  - **Solution**: Migrate to `saghen/blink.cmp` for instant completions, built-in signature help, and snippet support.
  - **Target Files**: `nvim/.config/nvim/lua/plugins/cmp.lua`, `nvim/.config/nvim/lua/plugins/lsp/mason.lua`, `nvim/.config/nvim/lua/utils/lsp.lua`

- [x] **TASK-07: Clean Up Deprecated Treesitter Plugins (Keep `Comment.nvim`)**
  - **Category**: Neovim (Cleanup)
  - **Impact**: Low | **Effort**: Low
  - **Problem**: `nvim-treesitter/playground` is officially archived and superseded by native `:Inspect` and `:InspectTree`.
  - **Solution**: Retain `numToStr/Comment.nvim` for rich commenting motions (`gbc`, `gco`, `gcO`, `gcA`), and retire deprecated `nvim-treesitter/playground`.
  - **Target Files**: `nvim/.config/nvim/lua/plugins/treesitter.lua`

---

## 2. Shell & Runtime Environment (Zsh, CLI)

- [x] **TASK-08: Migrate Prompt Fully to `starship` (Retire `powerlevel10k`)**
  - **Category**: Shell (Performance / Modernization)
  - **Impact**: High | **Effort**: Low
  - **Problem**: `powerlevel10k` is in maintenance mode. You already maintain a `starship/.config/starship.toml` in your dotfiles, creating split configuration.
  - **Solution**: Remove obsolete `p10k-instant-prompt` checks and source lines from `.zshrc` and remove `zsh/.p10k.zsh` (Starship config and evaluation handled by your environment scripts).
  - **Target Files**: `zsh/.zshrc`, `zsh/.p10k.zsh`

- [x] **TASK-09: Replace Slow `nvm` Shell Function with `mise` or `fnm`**
  - **Category**: Shell (Performance)
  - **Impact**: High | **Effort**: Low
  - **Problem**: `nvm` script execution slows down shell startup and interactive subshells.
  - **Solution**: Install and configure `fnm` for instant sub-millisecond environment loading; sync across setup scripts and dotfiles doctor.
  - **Target Files**: `zsh/.zshrc`, `setup_arch.sh`, `setup_ubuntu.sh`, `scripts/dotfiles-doctor.sh`

- [x] **TASK-10: Modernize Python Script Execution in Zsh using `uv`**
  - **Category**: Shell (Tooling / Stability)
  - **Impact**: Medium | **Effort**: Medium
  - **Problem**: Maintaining a manual Python virtual environment at `~/.config/zsh/venv` for `mai.py`, `mgithub.py`, etc. is brittle and requires manual pip maintenance.
  - **Solution**: Auto-install and bootstrap Enigma CLI virtualenv via `uv` across shell runtime, `setup_arch.sh`, `setup_ubuntu.sh`, and `dotfiles-doctor.sh`.
  - **Target Files**: `zsh/.config/zsh/init.sh`, `setup_arch.sh`, `setup_ubuntu.sh`, `scripts/dotfiles-doctor.sh`

---

## 3. Desktop Environment & Window Management (Hyprland, Launchers)

- [ ] **TASK-11: Consolidate App Launchers (`rofi` vs `wofi` vs `walker`)**
  - **Category**: Desktop (Cleanup / Modernization)
  - **Impact**: Medium | **Effort**: Low
  - **Problem**: You maintain configuration for 3 different launchers (`rofi`, `wofi`, `walker`), while only `rofi` is actively mapped.
  - **Solution**: Either remove unused `wofi`/`walker` or migrate to `walker` if you want an ultrafast Wayland-native runner.
  - **Target Files**: `wofi/`, `walker/`, `hypr/.config/hypr/bindings/apps.conf`

- [ ] **TASK-12: Standardize Terminal Configurations (`ghostty` vs `wezterm` vs `kitty`)**
  - **Category**: Desktop (Cleanup)
  - **Impact**: Low | **Effort**: Low
  - **Problem**: Three terminal configs exist. Ghostty is now primary on Hyprland.
  - **Solution**: Retain Ghostty as primary; document or clean up WezTerm/Kitty if no longer used.
  - **Target Files**: `kitty/`, `wezterm/`, `ghostty/`

- [ ] **TASK-13: Add Smart Terminal Session Manager (`sesh` + `zoxide`)**
  - **Category**: CLI / Multiplexer (Workflow)
  - **Impact**: Medium | **Effort**: Low
  - **Problem**: Switching between git repositories and tmux sessions requires manual commands.
  - **Solution**: Configure `sesh` with `fzf` / `zoxide` for one-key session switching.
  - **Target Files**: `tmux/`, `zsh/`

- [x] **TASK-14: Automatic Virtualenv Detection for Python LSP (`.venv` / `venv`)**
  - **Category**: Neovim (Python / DX)
  - **Impact**: High | **Effort**: Low
  - **Problem**: Pyright defaults to system python and cannot resolve third-party project packages installed in local `.venv` or `venv` environments.
  - **Solution**: Add dynamic `before_init` hook or `venv-selector` in Neovim to automatically find `.venv` in root workspace and set `pythonPath`.
  - **Target Files**: `nvim/.config/nvim/lua/plugins/lsp/mason.lua`
