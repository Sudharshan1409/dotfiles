# `bat` - A Cat Clone with Wings

`bat` is a `cat` clone with syntax highlighting and Git integration. This README provides instructions for installing `bat`, customizing it with themes, and additional resources.

## Installation

To install `bat`, follow these steps:

### On macOS

You can install `bat` using Homebrew:

```bash
brew install bat
```

## Customize `bat` with Themes

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
