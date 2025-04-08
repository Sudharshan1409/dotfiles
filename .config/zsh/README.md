# Shell Configuration Setup

Follow the steps below to set up your Shell configuration:

## Step 1: Clone the Repository

Clone the repository to the `~/.config/zsh` folder using the following command:

### For HTTPS

```bash
git clone https://github.com/Sudharshan1409/dotfiles.git ~/dotfiles
cd ~/dotfiles
stow .config/zsh
```

### For SSH

```bash
git clone git@github.com:Sudharshan1409/dotfiles.git ~/dotfiles
cd ~/dotfiles
stow .config/zsh
```

## Step 2: Update the Main `~/.zshrc` File

```plaintext
export TMUX_PATH="Path of your tmux"
source ~/.config/zsh/init.sh
```

## Step 3: Install Additional Tools

To enhance your shell experience, you can install the following tools:

### fzf

A command-line fuzzy finder.

#### Installation

```bash
# Using Homebrew
brew install fzf

# Install useful key bindings and fuzzy completion
$(brew --prefix)/opt/fzf/install
```

### eza

A modern replacement for `ls`.

#### Installation

```bash
# Using Homebrew
brew install eza
```

### lsd

A modern replacement for `ls` with a lot of additional features.

#### Installation

```bash
# Using Homebrew
brew install lsd
```

### zoxide

A smarter cd command, inspired by z and autojump.

#### Installation

```bash
# Using Homebrew
brew install zoxide
```

### bat

A cat clone with syntax highlighting and Git integration.

#### Installation

```bash
# Using Homebrew
brew install bat
```

Refer [Bat Customization](../bat/FZF-GIT-README.md) for customization options.

### git-delta

A syntax-highlighting pager for git and diff output.

#### Installation

```bash
# Using Homebrew
brew install git-delta
```

## Reference for fzf-git

For more detailed information on configuring and using `fzf-git`, please refer to the [fzf-git README](./fzf/FZF-GIT-README.md).
