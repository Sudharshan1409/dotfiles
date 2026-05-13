# The Enigma Shell Environment

This repository contains my personal, highly-automated Zsh configuration. It is designed to be modular, robust, and easy to manage, centered around a powerful, custom-built command-line tool called `enigma`.

The core philosophy is to keep `~/.zshrc` as a minimal loader, with all logic self-contained within this configuration.

### Core Features

- **Unified Management CLI (`enigma`)**: A single, elegant entry point to manage every aspect of the shell environment.
- **Python-Powered Tooling**: Custom backends for managing aliases, functions, environment variables, and projects, all with interactive TUI elements.
- **Automated First-Time Setup**: The shell automatically creates a Python virtual environment and installs all dependencies on first launch.
- **Polyglot Function Support**: Seamlessly create and run both Zsh and Python scripts as shell functions.
- **GitHub Integration**: A powerful, `fzf`-driven interface for browsing and managing your GitHub repositories.
- **Modern CLI Integrations**: Tightly integrated with best-in-class tools like `fzf`, `eza`, `bat`, and `zoxide`.

---

## Installation

Follow these steps to set up the configuration on a new machine (macOS or Linux).

### Step 1: Prerequisites

Ensure you have the following installed first:

- [Homebrew](https://brew.sh/)
- [Git](https://git-scm.com/downloads)
- [Stow](https://www.gnu.org/software/stow/) (for symlinking dotfiles)
- Python 3 & Pip

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

### Step 3: Configure `~/.zshrc`

Your main `~/.zshrc` file should be extremely minimal. **Replace its entire contents** with the following single line. This is all that's needed to bootstrap the entire system.

```sh
# Load the custom Zsh environment
source ~/.config/zsh/init.sh
```

### Step 4: Automated First-Time Setup

The next step is the easiest. **Simply open a new terminal window or tab.**

The first time you start a new shell, you will see a message like this:

```
Enigma: First-time setup detected. Please wait...
  -> Found requirements.txt file.
  -> Creating Python virtual environment at ~/.config/zsh/venv...
  -> Installing dependencies from requirements.txt...
✅ Enigma setup complete. Your shell will now load.
```

This process automatically creates a dedicated Python virtual environment and installs the required libraries (`rich`, `InquirerPy`, etc.). This only happens once.

Your shell is now fully configured and the `enigma` command is available.

---

## The `enigma` Command Suite

The `enigma` command is the single entry point for managing all aspects of your shell.

**Usage:** `enigma <command> [subcommand] [arguments]`

### `enigma alias` - Alias Management

Manages shell command aliases.

- `enigma alias ls`: Lists all aliases in a styled table.
- `enigma alias add <name>`: Interactively adds a new alias.
- `enigma alias edit <name>`: Interactively edits an existing alias.
- `enigma alias rm <name>`: Removes an alias.
- `enigma alias mv <name>`: Moves an alias to a different group.

### `enigma func` - Function Management

Manages both Zsh and Python functions.

- `enigma func ls`: Lists all functions with syntax-highlighted bodies.
- `enigma func add <name>`: Interactively adds a new Zsh or Python function.
- `enigma func edit <name>`: Edits an existing function in your editor.
- `enigma func rm <name>`: Removes a function.
- `enigma func mv <name>`: Moves a function to a different group.

### `enigma env` - Environment Management

Manages environment variables, exports, and OS-specific configurations.

- `enigma env ls`: Lists all environment entries.
- `enigma env add`: Interactively adds a new environment entry (variable, path, dynamic, etc.).
- `enigma env edit`: Interactively edits an existing entry.
- `enigma env rm`: Removes an environment entry.

### `enigma proj` - Project Management

Manages project configurations for quick environment launching.

- `enigma proj ls`: Lists all configured projects.
- `enigma proj add <name>`: Interactively adds a new project by selecting its directory.
- `enigma proj edit <name>`: Edits a project's configuration.
- `enigma proj rm <name>`: Removes a project.
- `enigma proj launch`: Interactively select and launch a project in a `tmux` session.

### `enigma gh` - GitHub Integration

Provides a powerful, `fzf`-driven interface for interacting with your GitHub repositories.

- `enigma gh repos`: Opens an interactive browser of your GitHub repositories.
    - **Smart Detection**: Automatically detects locally cloned repositories—even in custom directories—by maintaining a local database of clone locations.
    - **Interactive Actions**: After selecting a repository, a menu provides options to:
        - `cd` into the local directory.
        - Clone the repository (with options for default or custom paths).
        - Open the repository in the browser.
        - View the README in the terminal.
        - Copy the HTTPS or SSH clone URL.
        - Remove a locally cloned repository (with a confirmation prompt).

---

## Convenience Commands

For frequent operations, a short, user-facing command is available:

- **`proj`**: A convenience alias for `enigma proj launch`. Simply type `proj` to open the project launcher.

---

## Recommended Tools (Dependencies)

For the best experience, a number of modern command-line tools should be installed via Homebrew (macOS native, or linuxbrew on Linux).

| Tool          | Description                                 | Installation Command     |
| ------------- | ------------------------------------------- | ------------------------ |
| **fzf**       | A command-line fuzzy finder                 | `brew install fzf`       |
| **eza**       | A modern replacement for `ls`               | `brew install eza`       |
| **lsd**       | Another modern `ls` with icons and features | `brew install lsd`       |
| **zoxide**    | A smarter `cd` command                      | `brew install zoxide`    |
| **bat**       | A `cat` clone with syntax highlighting      | `brew install bat`       |
| **git-delta** | A syntax-highlighting pager for git         | `brew install git-delta` |
| **jq**        | A command-line JSON processor               | `brew install jq`        |
| **gh**        | The official GitHub command-line tool       | `brew install gh`        |

**Important `fzf` Setup:** After installing `fzf`, you must also run its installation script:

```bash
$(brew --prefix)/opt/fzf/install
```
