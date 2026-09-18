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

- [ ] **TASK-03: Modernize Python LSP (`pyright`/`basedpyright` + `ruff` instead of `pylsp`)**
  - **Category**: Neovim (LSP / Tooling)
  - **Impact**: High | **Effort**: Low
  - **Problem**: `mason.lua` enables `pylsp` and disables `pyright` and `ruff`. `pylsp` is slow, heavy, and outdated compared to the modern standard.
  - **Solution**: Enable `pyright` (or `basedpyright`) for type checking and `ruff` for sub-millisecond linting and code actions.
  - **Target Files**: `nvim/.config/nvim/lua/plugins/lsp/mason.lua`, `nvim/.config/nvim/lua/utils/lsp.lua`

- [ ] **TASK-04: Resolve `snacks.nvim` vs Legacy Plugin Overlaps**
  - **Category**: Neovim (Performance / Consolidation)
  - **Impact**: High | **Effort**: Medium
  - **Problem**: Running both `snacks.nvim` and the 6 legacy plugins it replaces (`telescope`, `toggleterm`, `nvim-notify`, `indent-blankline`, `vim-illuminate`, `undotree`) causes duplicate rendering, conflicting UI handlers, and bloated startup.
  - **Solution**: Decide whether to fully adopt Snacks modules and prune legacy plugins, or disable redundant Snacks modules.
  - **Target Files**: `nvim/.config/nvim/lua/plugins/snacks.lua`, `nvim/.config/nvim/lua/plugins/init.lua`, etc.

- [ ] **TASK-05: Retire `lsp-zero` in Favor of Native Neovim 0.10+ LSP**
  - **Category**: Neovim (Architecture)
  - **Impact**: High | **Effort**: Medium
  - **Problem**: `lsp-zero.nvim` is officially deprecated/sunsetted. Neovim 0.10+ native APIs make server setup clean without an extra wrapper.
  - **Solution**: Configure `mason-lspconfig` and `nvim-lspconfig` directly using native Neovim APIs.
  - **Target Files**: `nvim/.config/nvim/lua/plugins/lsp/lsp-config.lua`, `nvim/.config/nvim/lua/plugins/lsp/mason.lua`

- [ ] **TASK-06: Upgrade Completion Engine from `nvim-cmp` to `blink.cmp`**
  - **Category**: Neovim (Performance / Modernization)
  - **Impact**: High | **Effort**: Medium
  - **Problem**: `nvim-cmp` requires 7+ plugin dependencies and is noticeably slower than modern Rust-based fuzzy matching.
  - **Solution**: Migrate to `saghen/blink.cmp` for instant completions, built-in signature help, and snippet support.
  - **Target Files**: `nvim/.config/nvim/lua/plugins/cmp.lua`

- [ ] **TASK-07: Clean Up Neovim 0.10+ Commenting & Treesitter Shims**
  - **Category**: Neovim (Cleanup)
  - **Impact**: Low | **Effort**: Low
  - **Problem**: Neovim 0.10+ has built-in `gc`/`gcc` commenting (making `Comment.nvim` redundant) and handles query directives natively without custom shims.
  - **Solution**: Remove `numToStr/Comment.nvim` and clean up `treesitter.lua` shims.
  - **Target Files**: `nvim/.config/nvim/lua/plugins/init.lua`, `nvim/.config/nvim/lua/plugins/treesitter.lua`

---

## 2. Shell & Runtime Environment (Zsh, CLI)

- [ ] **TASK-08: Migrate Prompt Fully to `starship` (Retire `powerlevel10k`)**
  - **Category**: Shell (Performance / Modernization)
  - **Impact**: High | **Effort**: Low
  - **Problem**: `powerlevel10k` is in maintenance mode. You already maintain a `starship/.config/starship.toml` in your dotfiles, creating split configuration.
  - **Solution**: Switch `.zshrc` to load Starship prompt across both Linux and macOS.
  - **Target Files**: `zsh/.zshrc`

- [ ] **TASK-09: Replace Slow `nvm` Shell Function with `mise` or `fnm`**
  - **Category**: Shell (Performance)
  - **Impact**: High | **Effort**: Low
  - **Problem**: `nvm` script execution slows down shell startup and interactive subshells.
  - **Solution**: Install and configure `mise` (or `fnm`) for instant sub-millisecond environment loading.
  - **Target Files**: `zsh/.zshrc`

- [ ] **TASK-10: Modernize Python Script Execution in Zsh using `uv`**
  - **Category**: Shell (Tooling / Stability)
  - **Impact**: Medium | **Effort**: Medium
  - **Problem**: Maintaining a manual Python virtual environment at `~/.config/zsh/venv` for `mai.py`, `mgithub.py`, etc. is brittle and requires manual pip maintenance.
  - **Solution**: Use `uv tool` or standalone ephemeral environments for custom Python CLI utilities.
  - **Target Files**: `zsh/.config/zsh/init.sh`, `zsh/.config/zsh/python/`

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
