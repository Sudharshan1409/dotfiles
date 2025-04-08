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

### git-delta

A syntax-highlighting pager for git and diff output.

#### Installation

```bash
# Using Homebrew
brew install git-delta
```

## Step 4: Customize `bat` with Themes

`bat` allows you to use and customize themes for syntax highlighting. Here's how you can explore and install themes:

### Explore Available Themes

To see examples of all the themes you can use, execute the following command:

```bash
bat --list-themes | fzf --preview="bat --theme={} --color=always /path/to/file"
```

### Install a Custom Theme

If you find a theme on GitHub or elsewhere, you can install it by following these steps:

```bash
mkdir -p "$(bat --config-dir)/themes"
```

2. **Navigate to the Themes Directory**:

```bash
cd "$(bat --config-dir)/themes"
```

3. **Download the Theme File**:

Download the theme file with the `.tmTheme` extension. For example, to install the night version of the tokyonight theme:

```bash
curl -O https://raw.githubusercontent.com/folke/tokyonight.nvim/main/extras/sublime/tokyonight_night.tmTheme
```

4. **Build the Theme Cache**:

```bash
bat cache --build
```

5. **Set the Theme in the `exports.sh` file**:

Edit the following line to the `exports.sh` file:

```bash
# ----- Bat (better cat) -----
export BAT_THEME=tokyonight_night
```

Replace `tokyonight_night` with the name of the theme you would like to use.

After saving the changes, make sure to source it or restart your terminal session to apply the changes.

## Reference for fzf-git

For more detailed information on configuring and using `fzf-git`, please refer to the [fzf-git README](./fzf/FZF-GIT-README.md).
