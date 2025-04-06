# Neovim Configuration Setup


This repository contains my Neovim configuration written in Lua. Follow the steps below to clone the repository and set up your Neovim environment.

## Prerequisites

Ensure you have the following software installed on your system:

- Neovim (v0.5 or later)
- Git

## Installation

1. **Clone the Repository**

   Open your terminal and run the following command to clone the repository into your Neovim configuration directory:

   For HTTPS

   ```sh
   git clone https://github.com/Sudharshan1409/NVIM-Config-LUA.git ~/.config/nvim
   ```

   For SSH

   ```sh
   git clone git@github.com:Sudharshan1409/NVIM-Config-LUA.git ~/.config/nvim
   ```

2. **Install Plugins**

   Open Neovim and run the following command to install the plugins:

   ```vim
   :Lazy install
   ```

3. **Install LSP Servers**

   Open Neovim and run the following command to install the LSP servers:

   ```vim
   :LspInstall <server_name>
   ```

   Replace `<server_name>` with the name of the LSP server you want to install. For example, to install the `tsserver` LSP server, run the following command:

   ```vim
   :LspInstall tsserver
   ```

4. **Install Treesitter Parsers**

   Open Neovim and run the following command to install the Treesitter parsers:

   ```vim
   :TSInstall <parser_name>
   ```

   Replace `<parser_name>` with the name of the Treesitter parser you want to install. For example, to install the `typescript` Treesitter parser, run the following command:

   ```vim
   :TSInstall typescript
   ```

5. **File Structure**

   The configuration is structured as follows:

   ```plaintext
   nvim-config/
   ├── lua
   │   ├── core                                # Core configurations
   │   │   ├── functions.lua
   │   │   ├── git_config.lua
   │   │   ├── hello.json
   │   │   ├── init.lua
   │   │   ├── plugins.lua
   │   │   ├── remap.lua
   │   │   ├── set.lua
   │   │   ├── utils.lua
   │   └── plugin-config                       # Plugin-specific configurations
   │       ├── appearance                      # Appearance-related configurations
   │       │   ├── changes-in-files.lua
   │       │   ├── colors.lua
   │       │   ├── illuminate.lua
   │       │   ├── init.lua
   │       │   ├── lualine.lua
   │       │   ├── treesitter.lua
   │       ├── code-helpers                    # Helpers for better coding experience
   │       │   ├── auto-pairs-config.lua
   │       │   ├── barbecue-config.lua
   │       │   ├── cfn-lsp-extra.lua
   │       │   ├── conform.lua
   │       │   ├── filetype.lua
   │       │   ├── harpoon.lua
   │       │   ├── indent-line-config.lua
   │       │   ├── init.lua
   │       │   ├── undotree.lua
   │       │   ├── venv_selector.lua
   │       ├── fugitive.lua
   │       ├── init.lua
   │       ├── oil.lua
   │       ├── telescope.lua
   │       ├── toggleterm.lua
   │       ├── worktree.lua
   ├── init.lua                                # Main configuration file
   ├── README.md                               # Documentation file

   ```

6. **Key Bindings**

   The key bindings are defined in the `lua/core/remap.lua` file. You can modify the key bindings according to your preference.

7. **Customization**

   You can customize the configuration by modifying the Lua files in the `lua` directory. You can add new plugins, change the appearance, or add new key bindings to suit your workflow.

8. **Update Plugins**

   To update the plugins, open Neovim and run the following command:

   ```vim
   :Lazy update
   ```

9. **Uninstall Plugins**

   To uninstall a plugin, open Neovim and run the following command:

   ```vim
   :Lazy clean
   ```

10. **Troubleshooting**

    If you encounter any issues with the configuration, you can check the Neovim logs for error messages. You can also refer to the documentation of the plugins used in the configuration for troubleshooting tips.

11. **Feedback**

    If you have any feedback or suggestions for improving the configuration, feel free to open an issue or pull request on the GitHub repository.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

```

```
