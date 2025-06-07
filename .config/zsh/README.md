# My Ultimate Zsh Environment

This repository contains my personal, highly-automated Zsh configuration. It is designed to be modular, robust, and easy to manage, leveraging Python for powerful custom tooling.

The core philosophy is to keep `~/.zshrc` as a minimal loader, with all logic self-contained within this configuration. Key features include:

- **Python-Powered Management**: Custom CLI tools, `malias` and `mfunc`, for interactively managing aliases and functions.
- **Automated First-Time Setup**: The shell automatically detects if it's a new installation, creates a Python virtual environment, and installs all necessary dependencies.
- **Interactive UI**: Uses `rich` and `InquirerPy` for beautiful, syntax-highlighted tables and interactive dropdown menus.
- **Modern Tooling**: Tightly integrated with best-in-class tools like `fzf`, `eza`, `bat`, `zoxide`, and `git-delta`.

---

## Installation

Follow these steps to set up the configuration on a new macOS machine.

### Step 1: Prerequisites

Ensure you have the following installed first:

- [Homebrew](https://brew.sh/)
- [Git](https://git-scm.com/downloads)
- [Stow](https://www.gnu.org/software/stow/) (for symlinking dotfiles)
- Python 3 (macOS comes with a compatible version)

### Step 2: Clone the Dotfiles

Clone your dotfiles repository and use `stow` to symlink the Zsh configuration into place.

```bash
# Clone via HTTPS
git clone https://github.com/Sudharshan1409/dotfiles.git ~/dotfiles

# --- OR ---

# Clone via SSH
git clone git@github.com:Sudharshan1409/dotfiles.git ~/dotfiles

# Navigate into the repo and stow the zsh config
cd ~/dotfiles
stow .config/zsh
```

### Step 3: Configure ~/.zshrc

Your main ~/.zshrc file should be extremely minimal. Replace its entire contents with the following line. This is all that's needed to bootstrap the entire system.

```bash
# Load the custom Zsh environment
source ~/.config/zsh/init.sh
```

(Note: You no longer need to set TMUX_PATH manually; it is handled internally where needed.)

### Step 4: Automated First-Time Setup

The next step is the easiest. Simply open a new terminal window or tab.

The first time you start a new shell, you will see a message like this:

```bash
Alias Manager: First-time setup detected. Please wait...
-> Found requirements.txt file.
-> Creating Python virtual environment at /Users/enigma/.config/zsh/venv...
-> Installing dependencies from requirements.txt...
✅ Alias Manager setup complete. Your shell will now load.
```

This process automatically creates a dedicated Python virtual environment and installs the required libraries (rich, InquirerPy, etc.). This only happens once. Every subsequent shell start will be instantaneous.
Your shell is now fully configured.

## Usage

The power of this setup comes from the custom command-line tools for managing your configuration.

### Managing Aliases with `malias`

- List all aliases: Displays a beautifully formatted, syntax-highlighted table of all aliases, grouped by category.
  ```bash
  malias list
  ```
- Add a new alias:
  `bash
malias add la
`
  This will prompt you for the alias command and then present an interactive dropdown menu to select or create a group.

- Edit or Remove an alias:
  ```bash
  malias edit la
  malias rm la
  ```

### Managing Functions with `mfunc`

- List all functions: Displays a table of all your shell functions with full syntax highlighting for the function bodies.
  ```bash
  mfunc list
  ```
- Add a new function:
  `bash
mfunc add my_cool_function
`
  This will open your $EDITOR (nvim) to write the function body. After you save and quit, it will present the interactive dropdown menu to select or create a group for it.

- Edit or Remove a function:
  ```bash
  mfunc edit my_cool_function
  mfunc rm my_cool_function
  ```

## Recommended Tools (Dependencies)

For the best experience, a number of modern command-line tools should be installed. The configuration is built around them.

| Tool          | Description                                 | Installation Command     |
| ------------- | ------------------------------------------- | ------------------------ |
| **fzf**       | A command-line fuzzy finder                 | `brew install fzf`       |
| **eza**       | A modern replacement for `ls`               | `brew install eza`       |
| **lsd**       | Another modern `ls` with icons and features | `brew install lsd`       |
| **zoxide**    | A smarter `cd` command                      | `brew install zoxide`    |
| **bat**       | A `cat` clone with syntax highlighting      | `brew install bat`       |
| **git-delta** | A syntax-highlighting pager for git         | `brew install git-delta` |
| **jq**        | A command-line JSON processor               | `brew install jq`        |

### Important `fzf` Setup

After installing `fzf` via Homebrew, you must also run its installation script to set up the key bindings:

```bash
$(brew --prefix)/opt/fzf/install
```

## Customization & References

- **fzf-git**: For more information on the powerful `fzf` git integrations, refer to the [fzf-git README](./fzf/FZF-GIT-README.md).
- **Bat Theme**: The `bat` theme is set in `~/.config/zsh/exports.sh`. Refer to the [Bat documentation](../bat/README.md) for more theming options.
